// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@description('Name of the Dev Center')
param name string

@description('Location of the Dev Center')
param location string = resourceGroup().location

@description('Name of the project.')
param projectName string = ''

@description('[Dev Box] The principal id of users to assign the role of Project Admin to.  This is required in order to create a Dev Box.')
param projectAdmins array = []

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

@description('[Environments] An object with property keys containing the Environment Type name and values containing Subscription and Description properties. See main.bicep for examples')
param environmentTypeConfigs object = {}

@description('Tags to apply to the resources')
param tags object = {}

var vaultName = '${take(replace(name, ' ', '-'), 14)}-${take(uniqueString(resourceGroup().id), 8)}'

var projadminRoleDefinitionId = '/providers/Microsoft.Authorization/roleDefinitions/331c37c6-af14-46d9-b9f4-e1909e1b95a0'

var identityName = empty(identityId) ? '' : last(split(identityId, '/'))
var identityGroup = empty(identityId) ? '' : first(split(last(split(replace(identityId, 'resourceGroups', 'resourcegroups'), '/resourcegroups/')), '/'))

var networkConnectionName = last(split(networkConnectionResourceId, '/'))

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
        uri: 'https://github.com/Azure/Deployment-Environments-PrivatePreview.git'
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
  resource environmentTypes 'environmentTypes@2022-03-01-privatepreview' = [for item in items(environmentTypeConfigs): {
    name: item.key
    properties: {
      description: item.value.Description
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

module galleryReader 'galleryReader.bicep' = if (!empty(computeGalleryId)) {
  name: 'galleryReader'
  scope: resourceGroup(computeGalleryGroup)
  params: {
    computeGalleryId: computeGalleryId
  }
}

#disable-next-line BCP081
resource gallery 'Microsoft.Fidalgo/devcenters/galleries@2022-03-01-privatepreview' = if (!empty(computeGalleryId)) {
  name: '${devCenter.name}/${computeGalleryName}'
  properties: {
    galleryResourceId: computeGalleryId
  }
  dependsOn: [
    galleryReader
  ]
}

#disable-next-line BCP081
resource devBoxDefsCustom 'Microsoft.Fidalgo/devcenters/devboxdefinitions@2022-03-01-privatepreview' = [for image in computeGalleryImages: if (!empty(computeGalleryId) && !empty(computeGalleryImages)) {
  name: '${devCenter.name}/${image}'
  location: location
  properties: {
    imageReference: {
      id: '${gallery.id}/images/${image}'
    }
    sku: {
      name: 'PrivatePreview'
    }
  }
}]

#disable-next-line BCP081
resource devBoxDefs 'Microsoft.Fidalgo/devcenters/devboxdefinitions@2022-03-01-privatepreview' = {
  name: '${devCenter.name}/Win11'
  location: location
  properties: {
    imageReference: {
      id: '${devCenter.id}/galleries/Default/images/MicrosoftWindowsDesktop_windows-ent-cpc_win11-21h2-ent-cpc-m365'
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
    name: 'Win11Box'
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

resource projectAdminAssignmentIds 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for admin in projectAdmins: if (!empty(projectName) && !empty(projectAdmins)) {
  name: guid('projadmin${resourceGroup().id}${name}${admin}${projectName}')
  properties: {
    roleDefinitionId: projadminRoleDefinitionId
    principalId: admin
    principalType: 'User'
  }
  scope: project
}]

#disable-next-line BCP081
resource mappings 'Microsoft.Fidalgo/devcenters/mappings@2022-03-01-privatepreview' = [for item in items(environmentTypeConfigs): if (!empty(projectName)) {
  name: '${devCenter.name}/${item.key}'
  properties: {
    environmentType: item.key
    mappedSubscriptionId: '/subscriptions/${item.value.Subscription}'
    projectId: project.id
  }
}]

output galleryId string = gallery.id
output galleryRef string = '${gallery.id}/images/VSCodeBox/latest'
