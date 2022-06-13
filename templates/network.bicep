// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@description('Virtual network name')
param vnetName string

@description('Network connection name')
param connectionName string

@description('Virtual network location')
param location string = resourceGroup().location

@description('Name of the resource group in which the NICs will be created. This should not be an existing resource group, it will be created by the service in the same subscription as your vnet')
param networkingResourceGroupName string

@description('Tags to apply to the resources')
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  name: '${vnet.name}/default'
  properties: {
    addressPrefix: '10.0.0.0/24'
  }
}

#disable-next-line BCP081
resource networkSettings 'Microsoft.Fidalgo/networksettings@2022-03-01-privatepreview' = {
  name: connectionName
  location: location
  properties: {
    subnetId: subnet.id
    networkingResourceGroupName: networkingResourceGroupName
    domainJoinType: 'AzureADJoin'
  }
  tags: tags
}

output subnetId string = subnet.id
output networkSettingsId string = networkSettings.id
