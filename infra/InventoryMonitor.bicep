param parentResourceToken string
param location string = resourceGroup().location
param tags object = {}
param appservicePlanId string
param applicationInsightsKey string
param applicationInsightsConnectionString string
param logAnalyticsId string
param inventoryWebAppName string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var c = loadJsonContent('./constants.json')

var resourceToken = toLower(uniqueString(subscription().id, parentResourceToken, location, 'inventory-monitor'))

var _inventoryWebAppName = !empty(inventoryWebAppName) ? inventoryWebAppName : take('${abbrs.webSitesAppService}${resourceToken}', c.webAppMaxNameLength)

var inventoryTags = union(tags, { 'azd-service-name': 'inventory-monitor' })

module webApp './core/hosting/webApp.bicep' = {
  name: 'apiWebApp'
  params: {
    location: location
    appservicePlanId: appservicePlanId
    webAppName: _inventoryWebAppName
    tags: inventoryTags
    applicationInsightsConnectionString: applicationInsightsConnectionString
    applicationInsightsKey: applicationInsightsKey
    logAnalyticsId: logAnalyticsId
  }
}
