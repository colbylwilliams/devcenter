// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

targetScope = 'subscription'

@description('Name of the thing')
param name string

@description('Location of the thing')
param locaiton string

@description('Name of the project.')
param projectName string = ''

@description('[Dev Box] The principal id of the user to assign the role of Project Admin to.  This is required in order to create a Dev Box.')
param userId string = ''

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

@description('[Environments] An array of Environment Type names.  If provided, the environmentTypeConfigs paramaeter must also be provided with matching names.')
param environmentTypeNames array = []

// EXAMPLE:
// param environmentTypeNames array = [
//   'Dev'
//   'Test'
//   'Prod'
// ]

@description('[Environments] An string with a json object of Environment Type configs.  If provided, the environmentTypeNames parameter must also be provided with matching names.')
param environmentTypeConfigs string = ''

// EXAMPLE:
// param environmentTypeConfigs string = '''
// {
//   "Dev": {
//     "Subscription": "00000000-0000-0000-0000-000000000000",
//     "Description": "Development environments",
//   },
//   "Test": {
//     "Subscription": "00000000-0000-0000-0000-000000000000",
//     "Description": "Testing environments",
//   },
//   "Prod": {
//     "Subscription": "00000000-0000-0000-0000-000000000000",
//     "Description": "Production environments",
//   }
// }
// '''

@description('Tags to apply to the resources')
param tags object = {}

resource group_dc 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-DevCenter'
  location: locaiton
}

resource group_net 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-Network'
  location: locaiton
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
    name: '${name}DC'
    location: group_dc.location
    identityId: identityId
    pat: pat
    projectName: projectName
    sampleCatalog: sampleCatalog
    sandbox: sandbox
    environmentTypeNames: environmentTypeNames
    environmentTypeConfigs: environmentTypeConfigs
    subscriptions: subscriptions
    networkConnectionResourceId: network.outputs.networkSettingsId
    tags: tags
    userId: userId
  }
}
