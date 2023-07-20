
param location string = resourceGroup().location
param tags object = {}
param eventGridNamespaceName string


resource ns 'Microsoft.EventGrid/namespaces@2023-06-01-preview'={
  name: eventGridNamespaceName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output name string = ns.name
output id string = ns.id
