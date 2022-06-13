// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@description('The Principal ID of an Identity to grant access to the Key Vault.')
param principalId string = ''

@description('Name of the Key Vault')
param vaultName string

@description('Location of the Key Vault')
param location string = resourceGroup().location

@secure()
@description('Personal Access Token from GitHub with the repo scope')
param pat string = ''

@description('Tags to apply to the resources')
param tags object = {}

var ownerAssignmentIdName = guid('owner${resourceGroup().id}${vaultName}')
var kvadminAssignmentIdName = guid('kvadmin${resourceGroup().id}${vaultName}')

var ownerRoleDefinitionId = '/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
var kvadminRoleDefinitionId = '/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483'

resource vault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: vaultName
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: false
    enabledForDiskEncryption: false
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
  tags: tags
}

resource kvownerAssignmentId 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (!empty(principalId)) {
  name: ownerAssignmentIdName
  properties: {
    roleDefinitionId: ownerRoleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
  scope: vault
}

resource kvadminAssignmentId 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (!empty(principalId)) {
  name: kvadminAssignmentIdName
  properties: {
    roleDefinitionId: kvadminRoleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
  scope: vault
}

resource patSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = if (!empty(pat)) {
  name: '${vaultName}/pat'
  properties: {
    value: pat
    attributes: {
      enabled: true
    }
  }
  tags: tags
  dependsOn: [
    vault
  ]
}

#disable-next-line outputs-should-not-contain-secrets
output patUrl string = empty(pat) ? '' : patSecret.properties.secretUri
