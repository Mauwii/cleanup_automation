@description('Name which will be used to generate the Resource names')
param appname string = 'cleanupautomation'

@description('Location where Resources will be deployed to')
param location string = resourceGroup().location

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageSku string = 'Standard_LRS'

@description('Name of the hosting-plan SKU.')
@allowed([
  'F1'
  'Y1'
])
param planSkuName string = 'F1'

@description('How many instances our app service will be scaled out to')
param planSkuCapacity int = 1

var hostingPlanName = toLower('asp-${appname}')
var storageAccountName = '${toLower(appname)}${take(uniqueString(resourceGroup().id), 4)}'
var appinsightsName = toLower('appinsights-${appname}')
var functionAppName = toLower('${appname}')

resource FunctionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    'hidden-link: /app-insights-resource-id': appInsights.id
  }
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
      ]
      use32BitWorkerProcess: true
      powerShellVersion: '~7'
      netFrameworkVersion: 'v6.0'
      ftpsState: 'FtpsOnly'
    }
    serverFarmId: hostingPlan.id
    clientAffinityEnabled: false
    virtualNetworkSubnetId: null
    httpsOnly: true
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  kind: 'functionapp'
  sku: {
    name: planSkuName
    capacity: planSkuCapacity
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appinsightsName
  kind: 'functionapp'
  location: location
  tags: {
  }
  properties: {
    Request_Source: 'rest'
    Flow_Type: 'Bluefield'
    Application_Type: 'web'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  kind: 'Storage'
  location: location
  tags: {
  }
  sku: {
    name: storageSku
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}
