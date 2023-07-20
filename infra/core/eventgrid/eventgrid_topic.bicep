
param tags object = {}
param eventGridNamespaceName string
param topicName string


resource ns 'Microsoft.EventGrid/namespaces@2023-06-01-preview' existing={
  name: eventGridNamespaceName
  scope: resourceGroup()
}

resource topic 'Microsoft.EventGrid/namespaces/topics@2023-06-01-preview' = {
  name: topicName
  parent: ns
  properties: {
  }
}
