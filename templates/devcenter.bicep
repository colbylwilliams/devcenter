// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@description('Name of the Dev Center')
param name string

@description('Location of the Dev Center')
param location string = resourceGroup().location

@description('Name of the project.')
param projectName string = ''

@description('[Dev Box] The principal id of the user to assign the role of Project Admin to.  This is required in order to create a Dev Box.')
param userId string = ''

@description('[Dev Box] Resource ID of an existing Azure Compute Gallery to use for the Dev Box Definitions.')
param computeGalleryId string = ''

@description('[Dev Box] Names of images in the Azure Compute Gallery provided in the computeGalleryId param to create Dev Box Definitions.')
param computeGalleryImages array = []

@secure()
@description('[Environments] Personal Access Token from GitHub with the repo scope')
param pat string = ''

@description('[Environments] An array of Azure subscription IDs to give the DevCenter identity Owner role')
param subscriptions array = []

@description('[Environments] If true deploy the sample catalog')
param sampleCatalog bool = true

@description('[Environments] If true create a Sandbox environment type')
param sandbox bool = false

param networkConnectionResourceId string

@description('Resource ID of an Identity to assign to the dev center and give owner role to subscriptions passed in the subscriptions paramater. If none is provided a identity will be created')
param identityId string = ''

@description('[Environments] An array of Environment Type names.  If provided, the environmentTypeConfigs paramaeter must also be provided with matching names. See main.bicep for examples.')
param environmentTypeNames array = []

@description('[Environments] An string with a json object of Environment Type configs.  If provided, the environmentTypeNames parameter must also be provided with matching names. See main.bicep for examples.')
param environmentTypeConfigs string = ''

@description('Tags to apply to the resources')
param tags object = {}

var environments = empty(environmentTypeConfigs) ? json('{}') : json(environmentTypeConfigs)

var vaultName = 'DC-${take(replace(name, ' ', '-'), 12)}-${take(uniqueString(resourceGroup().id), 8)}'

var projadminAssignmentIdName = guid('projadmin${resourceGroup().id}${name}${userId}${projectName}')
var projadminRoleDefinitionId = '/providers/Microsoft.Authorization/roleDefinitions/331c37c6-af14-46d9-b9f4-e1909e1b95a0'

var identityName = empty(identityId) ? '' : last(split(identityId, '/'))
var identityGroup = empty(identityId) ? '' : first(split(last(split(replace(identityId, 'resourceGroups', 'resourcegroups'), '/resourcegroups/')), '/'))

var networkConnectionName = last(split(networkConnectionResourceId, '/'))

var configuredEnvironmentTypes = !empty(environmentTypeNames) && !empty(environmentTypeConfigs)
var configureSampleCatalog = sampleCatalog && !empty(pat)

var computeGalleryName = empty(computeGalleryId) ? '' : last(split(computeGalleryId, '/'))
var computeGalleryGroup = empty(computeGalleryId) ? '' : first(split(last(split(replace(computeGalleryId, 'resourceGroups', 'resourcegroups'), '/resourcegroups/')), '/'))

resource identity_n 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = if (empty(identityId)) {
  name: name
  location: location
  tags: tags
}

resource identity_e 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = if (!empty(identityId)) {
  name: identityName
  scope: resourceGroup(identityGroup)
}

module vault 'keyvault.bicep' = if (!empty(pat)) {
  name: 'keyvault'
  params: {
    vaultName: vaultName
    location: location
    principalId: empty(identityId) ? identity_n.properties.principalId : identity_e.properties.principalId
    pat: pat
    tags: tags
  }
}

module subownerAssignmentIds 'subscriptionsOwner.bicep' = if (empty(identityId) && !empty(subscriptions)) {
  name: 'subscriptionsOwner'
  params: {
    principalId: empty(identityId) ? identity_n.properties.principalId : identity_e.properties.principalId
    subscriptions: subscriptions
  }
}

#disable-next-line BCP081
resource devCenter 'Microsoft.Fidalgo/devcenters@2022-03-01-privatepreview' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${empty(identityId) ? identity_n.id : identity_e.id}': {}
    }
  }
  tags: tags
  dependsOn: [
    subownerAssignmentIds
  ]

  #disable-next-line BCP081
  resource catalog 'catalogs@2022-03-01-privatepreview' = if (configureSampleCatalog) {
    name: 'SampleCatalog'
    properties: {
      gitHub: {
        uri: 'https://github.com/Azure/Project-Fidalgo-PrivatePreview.git'
        branch: 'main'
        secretIdentifier: vault.outputs.patUrl
        path: '/Catalog'
      }
    }
  }

  #disable-next-line BCP081
  resource environmentType 'environmentTypes@2022-03-01-privatepreview' = if (sandbox) {
    name: 'Sandbox'
    properties: {
      description: 'Sandbox environments'
    }
    tags: {
      sandbox: 'true'
    }
  }

  #disable-next-line BCP081
  resource environmentTypes 'environmentTypes@2022-03-01-privatepreview' = [for (name, i) in environmentTypeNames: if (configuredEnvironmentTypes) {
    name: name
    properties: {
      description: environments[name].Description
    }
    tags: tags
  }]
}

#disable-next-line BCP081
resource networkConnection 'Microsoft.Fidalgo/devcenters/attachednetworks@2022-03-01-privatepreview' = {
  name: '${devCenter.name}/${networkConnectionName}'
  properties: {
    networkConnectionResourceId: networkConnectionResourceId
  }
}

#disable-next-line BCP081
resource devBoxDefs 'Microsoft.Fidalgo/devcenters/devboxdefinitions@2022-03-01-privatepreview' = {
  name: '${devCenter.name}/Win11'
  location: location
  properties: {
    imageReference: {
      id: '${resourceGroup().id}/providers/Microsoft.Fidalgo/devcenters/${name}/galleries/Default/images/MicrosoftWindowsDesktop_windows-ent-cpc_win11-21h2-ent-cpc-m365'
    }
    sku: {
      name: 'PrivatePreview'
    }
  }
}

#disable-next-line BCP081
resource project 'Microsoft.Fidalgo/projects@2022-03-01-privatepreview' = if (!empty(projectName)) {
  name: projectName
  location: location
  properties: {
    devCenterId: devCenter.id
  }
  tags: tags

  #disable-next-line BCP081
  resource devBoxPool 'pools@2022-03-01-privatepreview' = {
    name: '${projectName}-main'
    location: location
    properties: {
      devBoxDefinitionName: 'Win11'
      networkConnectionName: networkConnectionName
    }
    dependsOn: [
      devCenter
      devBoxDefs
      networkConnection
    ]
  }
}

resource projectAdminAssignmentId 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (!empty(projectName) && !empty(userId)) {
  name: projadminAssignmentIdName
  properties: {
    roleDefinitionId: projadminRoleDefinitionId
    principalId: userId
    principalType: 'User'
  }
  scope: project
}

#disable-next-line BCP081
resource mappings 'Microsoft.Fidalgo/devcenters/mappings@2022-03-01-privatepreview' = [for (name, i) in environmentTypeNames: if (!empty(projectName) && configuredEnvironmentTypes) {
  name: '${devCenter.name}/${name}'
  properties: {
    environmentType: name
    mappedSubscriptionId: '/subscriptions/${environments[name].Subscription}'
    projectId: project.id
  }
}]
