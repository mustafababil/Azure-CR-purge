# Azure Container Registry - Image Purge Script

Currently, Azure Container Registry does not provide a way to clean hoarded images in the registry. The count of the images are increasing as the automated build pipelines run, and most of these images won't be used in major versioning. So, regular cleaning is necessary to save space in repository.
According to proposal [here](https://github.com/AzureCR/specs/tree/master/auto-purge), the feature for managing lifecyle of images will be included in the service in future, but this script saves time till that time.

### Prerequisites
 - Windows host
 - Powershell
 - Azure CLI

### Features

  - Deleting images based on creation date
  - Keeping only X amount of latest created image

### Parameters
  ```-BypassLogin```
  If Azure CLI is already logged in, you might need to skip log in phase. Otherwise, Service Principal info must be provided for login.
  
  ```-ServicePrincipalId```
  Service Principal Id for authentication. Optional unless not bypassing login. More info about creating it [here](https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-create-service-principals)
  
  ```-ServicePrincipalPassword```
  Service Principal account key. Optional unless not bypassing login.
  
  ```-ServicePrincipalTenant```
  Azure Tenant Id. Optional unless not bypassing login.
  
  ```-Subscription```
  Name of the subscription. Optional but you should provide if you have many.
  
  ```-ContainerRegistry```
  Name of the Azure Container Registry. Mandatory.
  
  ```-LastImagesToKeep```
  Count of latest images to keep in repository. Optional. Default *5*.
  
  ```-DeleteDaysLimit```
  Number of days to delete older images. Optional.
  
> ```-LastImagesToKeep``` and ```-DeleteDaysLimit``` parameters are both optional, but they are mutually exclusive. If none of them mentioned action is to keeping latest 5 images in a repository.


### Example commands
   ``` powershell
   .\acr-purge.ps1 -BypassLogin -ContainerRegistry MyRegistryName -DeleteDaysLimit 30
   ```
   Deletes images older than 30 days in registry of already selected subscription in Azure CLI.
   
   ``` powershell
   .\acr-purge.ps1 -ServicePrincipalId fe3543ae-098d-4aac-9b4b-1a657ec9fb53 -ServicePrincipalPassword 455f67ff-8390-4a66-bdeb-a94a80b71507 -ServicePrincipalTenant 1adde7f6-33c7-49d8-a16b-e4dfec4893ae -Subscription MySubscription -ContainerRegistry MyRegistryName -LastImagesToKeep 10
   ```
   Logins to specified Azure account and deletes all images other than latest 10 in repository
   
### License
This project is licensed under the MIT License - see the [LICENSE](https://github.com/mustafababil/Azure-CR-purge/blob/master/LICENSE) file for details