@description('Web connection name')
param name string 

@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object

@description('Azure region of the deployment')
param cosmodbAccountName string

@description('Azure region of the deployment')
param cosmosdbDatabaseName string

resource cosmosdbaccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' existing = {
  name: cosmodbAccountName
}

resource cosmosdbconnection 'Microsoft.Web/connections@2016-06-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    displayName: name
    // customParameterValuesSet: {
    //   predictionKey: cosmosdbaccount.listKeys().primaryMasterKey
    // }
    // nonSecretParameterValuesSet: {
    //   databaseAccount: cosmosdbDatabaseName
    //   accountId:cosmodbAccountName
    // }
    api: {
      name: 'documentdb'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/documentdb'
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

