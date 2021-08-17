param webAppName string = 'imaugBicepAppTry'
param functionAppName string = 'functionBicepAppName'
param location string = resourceGroup().location
param storageSKU string = 'B1'
param linuxFxVersion string = 'NODE|15'
@secure()
param password string

var appServicePlanPortalName = 'AppServicePlan-${webAppName}'
var storageAccountName = 'imaugazbicepfunctionsa'
var applicationInsightsName = 'aiBicepTest'

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource serverFarm 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanPortalName
  location: location
  sku: {
    name: storageSKU
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2020-06-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: serverFarm.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
  }
  // What? Why is this that cool?! 
  /* 
    You can also get a resource id by serverFarm.Id if needed
    but why is this so simple now?!
    I wanted to show off multi line comments for fun
  */
  dependsOn: [
    serverFarm
  ]
}

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: applicationInsightsName
  location: 'centralus'
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource functionApp 'Microsoft.Web/sites@2020-06-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  dependsOn: [
    serverFarm
    storageAccount
  ]
  properties: {
    serverFarmId: serverFarm.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          'name': 'APPINSIGHTS_INSTRUMENTATIONKEY'
          'value': appInsights.properties.InstrumentationKey
        }
        // WEBSITE_CONTENTSHARE will also be auto-generated
        // WEBSITE_RUN_FROM_PACKAGE will be set to 1 by func azure functionapp publish]
        // Credit https://markheath.net/post/azure-functions-bicep
      ]
    }
  }
}
