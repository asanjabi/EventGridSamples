// Parameters
param vnetAddressSpace object = {
  addressPrefixes: [
    '10.0.0.0/16'
  ]
}

param subnets array = [
  {
    name: 'default'
    properties: {
      addressPrefix: '10.0.0.0/24'
    }
  }
  {
    name: 'servicendpoints'
    properties: {
      addressPrefix: '10.0.1.0/24'
    }
  }
  {
    name: 'VnetIntegrationSubnet'
    properties: {
      addressPrefix: '10.0.2.0/24'
      delegations: [
        {
          name: 'delegation'
          properties: {
            serviceName: 'Microsoft.Web/serverfarms'
          }
        }
      ]
      privateEndpointNetworkPolicies: 'Enabled'
    }
  }
]


param location string = resourceGroup().location
param tags object = {}
param vnetName string

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. Resource ID of the diagnostic log analytics workspace.')
param diagnosticWorkspaceId string

@description('Optional. The name of logs that will be streamed. "allLogs" includes all possible logs for the resource.')
@allowed([
  'allLogs'

  'VMProtectionAlerts'
])
param diagnosticLogCategoriesToEnable array = [
  'allLogs'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param diagnosticMetricsToEnable array = [
  'AllMetrics'
]

@description('Optional. The name of the diagnostic setting, if deployed.')
param diagnosticSettingsName string = '${vnetName}-diagnosticSettings-001'

// Variables
var diagnosticsLogsSpecified = [for category in filter(diagnosticLogCategoriesToEnable, item => item != 'allLogs'): {
  category: category
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var diagnosticsLogs = contains(diagnosticLogCategoriesToEnable, 'allLogs') ? [
  {
    categoryGroup: 'allLogs'
    enabled: true
    retentionPolicy: {
      enabled: true
      days: diagnosticLogsRetentionInDays
    }
  }
] : diagnosticsLogsSpecified

var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

// Criating Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: vnetAddressSpace
    subnets: subnets
  }
}

// Defining Diagnostic Settings for Virtual Network
resource virtualNetwork_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticSettingsName
  properties: {
    workspaceId: diagnosticWorkspaceId
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
  scope: vnet
}

// Outputs
output vnetId string = vnet.id
output vnetName string = vnet.name
output vnetSubnets array = vnet.properties.subnets
output pesubnetId string = vnet.properties.subnets[1].id
output appsubnet string = vnet.properties.subnets[2].id
