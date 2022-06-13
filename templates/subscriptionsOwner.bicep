// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

// needed to work around https://github.com/Azure/bicep/issues/1754

@description('An array of Azure subscription IDs identity Owner role')
param subscriptions array

@description('The identity principalId to assign Ownership role')
param principalId string

module subownerAssignmentIds 'subscriptionOwner.bicep' = [for (sub, index) in subscriptions: {
  name: 'assignOwner${guid(sub, principalId)}'
  scope: subscription(sub)
  params: {
    principalId: principalId
  }
}]
