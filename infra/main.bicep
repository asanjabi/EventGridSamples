targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string


param resourceGroupName string = ''
param applicationInsightsName string = ''
param logAnalyticsName string = ''
param appservicePlanName string = ''
param storeTransactionTopicName string = 'storeTransactions'

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  'azd-env-name': environmentName
}

// Generate a unique token to be used in naming resources.
var resourceToken = toLower(uniqueString(subscription().id, rg.id, environmentName, location))


// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module inventoryMonitor './InventoryMonitor.bicep' = {
  name: 'inventoryMonitor'
  scope: rg
  params: {
    location: location
    tags: tags
    parentResourceToken: resourceToken
    applicationInsightsConnectionString: sharedInfra.outputs.applicationInsightsConnectionString
    applicationInsightsKey: sharedInfra.outputs.applicationInsightsKey
    appservicePlanId: sharedInfra.outputs.appServicePlanId
    logAnalyticsId: sharedInfra.outputs.logAnalyticsWorkspaceId
    
    }
}

module sharedInfra './shared.bicep'={
  name: 'sharedInfra'
  scope: rg
  params: {
    location: location
    tags: tags
    parentResourceToken: resourceToken
    applicationInsightsName: applicationInsightsName
    logAnalyticsName: logAnalyticsName
    appservicePlanName: appservicePlanName
    storeTransactionTopicName: storeTransactionTopicName
  }
}


output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
