// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

targetScope = 'subscription'

@description('The identity principalId to assign Ownership role')
param principalId string

resource ownerAssignmentId 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('owner${subscription().subscriptionId}${principalId}')
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
  scope: subscription()
}
