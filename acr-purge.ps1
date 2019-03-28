[CmdletBinding()]
Param(

    #Flag for bypassing Azure CLI Login
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Switch] $BypassLogin = $false,

    #Service Prinicipal Id for Azure
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String] $ServicePrincipalId,
    
    #Service Prinicial key for Azure
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String] $ServicePrincipalPassword,

    #Tenant ID for Azure
    [Parameter (Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String] $ServicePrincipalTenant,

    #Azure Subscription Name
    [Parameter (Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String] $Subscription,
 
    #Azure Container Registry
    [Parameter (Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $ContainerRegistry,
 
    # Number of last images to keep in repository, default: 5
    [Parameter (Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String] $LastImagesToKeep = "5",

    # Days older than will be deleted 
    [Parameter (Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String] $DeleteDaysLimit

)

Write-Host "Azure Container Registry purge is started"

if (-Not $BypassLogin) {
    if ($ServicePrincipalId -and $ServicePrincipalPassword -and $ServicePrincipalTenant) {
        Write-Host "Connecting Azure"
        az login --service-principal -u $ServicePrincipalId -p $ServicePrincipalPassword --tenant $ServicePrincipalTenant
    }
    Write-Host "Azure Auth. credentials are missing!"
    exit
}


if ($Subscription) {
    Write-Host "Setting subscription to: $Subscription"
    az account set --subscription $Subscription
}


Write-Host "Checking container registry: $ContainerRegistry"
$RepoList = az acr repository list --name $ContainerRegistry --output table

for($index=2; $index -lt $RepoList.length; $index++) { #First 2 element are column definition, so skip them
    $RepositoryName = $RepoList[$index]
    Write-Host "Checking repository: $RepositoryName"

    if ($DeleteDaysLimit) { #Delete images by date
        $Images = az acr repository show-tags --name $ContainerRegistry --repository $RepositoryName --detail --orderby time_desc --output table
    
        for($item=2; $item -lt $Images.length; $item++){ #First 2 element are column definition, so skip them
            $ImageDetailRow = $Images[$item].ToString().Split('  ')

            $ImageCreatedDate = $ImageDetailRow[0]
            $ImageCreatedDate = [datetime]::Parse($ImageCreatedDate)

            if($ImageCreatedDate -lt $((Get-Date).AddDays(-$DeleteDaysLimit))) {
                $ImageName = $RepositoryName + ':' + $ImageDetailRow[3]
                az acr repository delete --name $ContainerRegistry --image $ImageName --yes
                Write-Host "Deleted image: $ImageName"
            }
        }
        
    } Else { #Delete images by count
        $RepositoryTags = az acr repository show-tags --name $ContainerRegistry --repository $RepositoryName --orderby time_desc --output table
    
        for($item=2+$LastImagesToKeep; $item -lt $RepositoryTags.length; $item++) { #First 2 element are column definition, so skip them
            $ImageName = $RepositoryName + ":" + $RepositoryTags[$item]
            az acr repository delete --name $ContainerRegistry --image $ImageName --yes
            Write-Host "Deleted image: $ImageName"
        }
    }

}

Write-Host "Azure Container Registry purge is finished"