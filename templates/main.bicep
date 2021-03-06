// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

targetScope = 'subscription'

@description('Name of the thing')
param name string

@description('Location of the thing')
param location string

@description('Name of the project.')
param projectName string = ''

@description('[Dev Box] The principal id of users to assign the role of Project Admin to.  This is required in order to create a Dev Box.')
param projectAdmins array = []

@description('[Dev Box] Resource ID of an existing Azure Compute Gallery to use for the Dev Box Definitions.')
param computeGalleryId string = ''

@description('[Dev Box] Names of images in the Azure Compute Gallery provided in the computeGalleryId param to create Dev Box Definitions.')
param computeGalleryImages array = []

@description('Resource ID of an Identity to assign to the dev center and give owner role to subscriptions passed in the subscriptions paramater. If none is provided a identity will be created')
param identityId string = ''

@secure()
@description('[Environments] Personal Access Token from GitHub with the repo scope')
param pat string = ''

@description('[Environments] An array of Azure subscription IDs to give the DevCenter identity Owner role')
param subscriptions array = []

@description('[Environments] If true deploy the sample catalog')
param sampleCatalog bool = true

@description('[Environments] If true create a Sandbox environment type')
param sandbox bool = false

@description('[Environments] An object with property keys containing the Environment Type name and values containing Subscription and Description properties. See bicep file for example.')
param environmentTypeConfigs object = {}

// EXAMPLE:
// param environmentTypeConfigs object = {
//   Dev: {
//     Subscription: '00000000-0000-0000-0000-000000000000'
//     Description: 'Development environments'
//   }
//   Test: {
//     Subscription: '00000000-0000-0000-0000-000000000000'
//     Description: 'Testing environments'
//   }
//   Prod: {
//     Subscription: '00000000-0000-0000-0000-000000000000'
//     Description: 'Production environments'
//   }
// }

@description('Tags to apply to the resources')
param tags object = {}

resource group_dc 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-DevCenter'
  location: location
}

resource group_net 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-Network'
  location: location
}

module network 'network.bicep' = {
  scope: group_net
  name: 'network'
  params: {
    vnetName: '${toLower(name)}-vnet'
    connectionName: '${name}Connection'
    networkingResourceGroupName: '${name}-Networking'
    location: group_net.location
    tags: tags
  }
}

module devcenter 'devcenter.bicep' = {
  scope: group_dc
  name: 'devcenter'
  params: {
    name: name
    location: group_dc.location
    identityId: identityId
    pat: pat
    projectName: projectName
    sampleCatalog: sampleCatalog
    sandbox: sandbox
    environmentTypeConfigs: environmentTypeConfigs
    subscriptions: subscriptions
    networkConnectionResourceId: network.outputs.networkSettingsId
    computeGalleryId: computeGalleryId
    computeGalleryImages: computeGalleryImages
    tags: tags
    projectAdmins: projectAdmins
  }
}
