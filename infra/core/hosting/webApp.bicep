param location string = resourceGroup().location
param appservicePlanId string
param webAppName string
param applicationInsightsKey string
param applicationInsightsConnectionString string
param logAnalyticsId string
param additionalSettings array = []
param tags object = {}
param VNetIntegrationSubnetName string
param vnetName string 
param subnetName string
param appPrivateEndpointName string



var settings=[
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: applicationInsightsKey
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING' 
    value: applicationInsightsConnectionString
  }
  {
    name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
    value: '~3'
  }
  {
    name: 'XDT_MicrosoftApplicationInsights_Mode'
     value: 'Recommended'
  }
]

var finalAppSettings = union (settings, additionalSettings)

// Defining Private Endpoint Subnet
resource servicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: '${vnetName}/${subnetName}'
}

// Defining Integration Subnet
resource VNetIntegrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: '${vnetName}/${VNetIntegrationSubnetName}'
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appservicePlanId
    httpsOnly: true
    virtualNetworkSubnetId: VNetIntegrationSubnet.id
    siteConfig:{
      alwaysOn: true
      appSettings:finalAppSettings

      linuxFxVersion: 'DOTNETCORE|7.0'
      ftpsState: 'FtpsOnly'
    }
  }
  tags: tags
}


output id string = webApp.id
output url string = 'https://${webApp.properties.defaultHostName}'
output name string = webApp.name




resource logs 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: webApp
  name: 'logs'
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Information'
      }
    }
    detailedErrorMessages: {
      enabled: true
    }
    failedRequestsTracing: {
      enabled: true
    }
    httpLogs: {
      fileSystem: {
        enabled: true
        retentionInDays: 1
        retentionInMb: 35
      }
    }
  }
}

resource webAppDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsId)) {
  name: 'Send_To_LogAnalytics'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsId
    logs: [
      {
        enabled: true
        category: 'AppServiceAppLogs'
      }
      {
        enabled: true
        category: 'AppServiceAuditLogs'
      }
      {
        enabled: true
        category: 'Appserviceconsolelogs'
      }
      {
        enabled: true
        category: 'AppServiceHTTPLogs'
      }
      {
        enabled: true
        category: 'AppServiceIPSecAuditLogs'
      }
      {
        enabled: true
        category: 'AppServicePlatformLogs'
      }
      {
        enabled: true
        category: 'AppServiceFileAuditLogs'
      }
    ]
    metrics: [
      {
        enabled: true
        category: 'AllMetrics'
      }
    ]
  }
}

module privateEndpointApp '../network/privateendpoint.bicep' = {
  name: appPrivateEndpointName
  params: {
    location: location
    groupIds: [
      'sites'
    ]
    privateEndpointName: appPrivateEndpointName
    privatelinkConnName: '${appPrivateEndpointName}-conn'
    resourceId: webApp.id
    subnetid: servicesSubnet.id
  }
  dependsOn:[
    webAppDiagnosticSettings
    logs 
  ]
}
