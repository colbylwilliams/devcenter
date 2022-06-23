# devcenter

Useful templates and scripts for working with Azure DevCenters.

## Usage

```sh
az deployment sub create -f templates/main.bicep -p @local.parameters.json -n mydeploymentname
```

### Example local.parameters.json file

Note: some parameters are optional, see [`main.bicep`](https://github.com/colbylwilliams/devcenter/blob/main/templates/main.bicep) for more details.

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "name": {
      "value": "MyUniqueDevCenterName"
    },
    "projectName": {
      "value": "MyProjectName"
    },
    "location": {
      "value": "eastus"
    },
    "identityId": {
      "value": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MY-RG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/MyIdentityIfIAlreadyHaveOne"
    },
    "projectAdmins": {
      "value": [
        "00000000-0000-0000-0000-000000000000",
        "00000000-0000-0000-0000-000000000000"
      ]
    },
    "computeGalleryId": {
      "value": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MY-RG/providers/Microsoft.Compute/galleries/MyGalleryIfIAlreadyHaveOne"
    },
    "computeGalleryImages": {
      "value": [
        "ImageFromGalleryAbove",
        "ImageFromGalleryAbove"
      ]
    },
    "pat": {
      "value": "my_personal_access_token_only_for_environments"
    },
    "subscriptions": {
      "value": [
        "00000000-0000-0000-0000-000000000000",
        "00000000-0000-0000-0000-000000000000"
      ]
    },
    "sampleCatalog": {
      "value": true
    },
    "sandbox": {
      "value": false
    },
    "environmentTypeConfigs": {
      "value": {
        "Dev": {
          "Subscription": "00000000-0000-0000-0000-000000000000",
          "Description": "Development environments"
        },
        "Test": {
          "Subscription": "00000000-0000-0000-0000-000000000000",
          "Description": "Testing environments"
        },
        "Prod": {
          "Subscription": "00000000-0000-0000-0000-000000000000",
          "Description": "Production environments"
        }
      }
    },
    "tags": {
      "value": {}
    }
  }
}
```
