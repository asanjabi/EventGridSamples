param location string = resourceGroup().location
param appservicePlanName string
param sku object = {
  name: 'P1V3'
  tier: 'PremiumV3'
}
param logAnalyticsId string
param tags object = {}

resource appservicePlan 'Microsoft.Web/serverfarms@2022-03-01' ={
  location: location
  name: appservicePlanName
  kind: 'linux'
  tags: tags
  sku: sku
properties: {
    reserved: true
  }
}

resource appServicePlanDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsId)) {
  name: 'Send_To_LogAnalytics'
  scope: appservicePlan
  properties: {
    workspaceId: logAnalyticsId
    metrics: [
      {
        enabled: true
        category: 'AllMetrics'
      }
    ]
  }
}


output name string = appservicePlan.name
output id string = appservicePlan.id
