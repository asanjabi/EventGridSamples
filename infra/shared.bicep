param parentResourceToken string
param location string = resourceGroup().location
param tags object = {}

param logAnalyticsName string = ''
param applicationInsightsName string = ''
param eventGridNamespaceName string = ''
param appservicePlanName string = ''
param vnetName string = ''
param vNETaddPrefixes array = ['10.0.0.0/16']

var resourceToken = toLower(uniqueString(subscription().id, parentResourceToken, location, 'shared-resources'))

var abbrs = loadJsonContent('./abbreviations.json')
var c = loadJsonContent('./constants.json')

var _logAnalyticsName = !empty(logAnalyticsName) ? logAnalyticsName : take('${abbrs.operationalInsightsWorkspaces}${resourceToken}', c.logAnalyticsMaxNameLength)
var _applicationInsightsName = !empty(applicationInsightsName) ? applicationInsightsName : take('${abbrs.insightsComponents}${resourceToken}', c.appInsightsMaxNameLength)
var _eventGridNamespaceName = !empty(eventGridNamespaceName) ? eventGridNamespaceName : take('${abbrs.eventGridNamespaces}${resourceToken}', c.eventgridNamespaceMaxLength)
var _appServicePlanName = !empty(appservicePlanName) ? appservicePlanName : take('${abbrs.webServerFarms}${resourceToken}', c.appServicePlanMaxNameLength)
var _vnetName = !empty(vnetName) ? vnetName : take('${abbrs.networkVirtualNetworks}${resourceToken}', c.networkVirtualNetworksMaxLength)

module vnet 'core/network/vnet.bicep' = {
  name: _vnetName
  params: {
    location: location
    vnetAddressSpace: {
      addressPrefixes: vNETaddPrefixes
    }
    vnetName: _vnetName
    diagnosticWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// Creating Private DNS Zone for Azure App Service
module privatednsAppZone 'core/network/privatednszone.bicep' = {
  name: 'privatednsAppZone'
  params: {
    privateDNSZoneName: 'privatelink.azurewebsites.net'
  }
}

// Linking Private DNS Zone for Azure App Service to VNet
module privateDNSLinkApp 'core/network/privatednslink.bicep' = {
  name: 'privateDNSLinkACR'
  params: {
    privateDnsZoneName: privatednsAppZone.outputs.privateDNSZoneName
    vnetId: vnet.outputs.vnetId
  }
}



module eventgridNamespace 'core/eventgrid/eventgrid_namespace.bicep' = {
  name: 'eventgridNamespace'
  params: {
    eventGridNamespaceName: _eventGridNamespaceName
    location: location
    tags: tags
  }
}

module appservicePlan 'core/hosting/appservicePlan.bicep' = {
  name: 'appServicePlan'
  params: {
    appservicePlanName: _appServicePlanName
    location: location
    tags: tags
    sku: {
      name: 'P1V3'
      tier: 'PremiumV3'
    } 
    logAnalyticsId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

module monitoring 'core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    logAnalyticsName: _logAnalyticsName
    applicationInsightsName: _applicationInsightsName
    location: location
    tags: tags
  }
}

output applicationInsightsConnectionString string = monitoring.outputs.applicationInsightsConnectionString
output applicationInsightsKey string = monitoring.outputs.applicationInsightsInstrumentationKey
output applicationInsightsName string = monitoring.outputs.applicationInsightsName
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId
output logAnalyticsWorkspaceName string = monitoring.outputs.logAnalyticsWorkspaceName

output appServicePlanId string = appservicePlan.outputs.id
output appServicePlanName string = appservicePlan.outputs.name
output vnetName string = vnet.name


