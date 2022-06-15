// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@description('[Dev Box] Resource ID of an existing Azure Compute Gallery to use for the Dev Box Definitions.')
param computeGalleryId string = ''

var cloudPcPrincipalId = 'df65ee7f-8ea9-481d-a20f-e7e23bcf25ed'
var computeGalleryName = empty(computeGalleryId) ? '' : last(split(computeGalleryId, '/'))
var galleryReaderAssignmentIdName = guid('galleryreader${computeGalleryId}${cloudPcPrincipalId}')
var galleryReaderRoleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource computeGallery 'Microsoft.Compute/galleries@2022-01-03' existing = if (!empty(computeGalleryId)) {
  name: computeGalleryName
}

resource galleryReaderAssignmentId 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (!empty(computeGalleryId)) {
  name: galleryReaderAssignmentIdName
  properties: {
    roleDefinitionId: galleryReaderRoleDefinitionId
    principalId: cloudPcPrincipalId
  }
  scope: computeGallery
}
