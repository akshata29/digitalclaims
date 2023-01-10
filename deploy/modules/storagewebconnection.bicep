@description('Web connection name')
param name string 

@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object

@description('Azure region of the deployment')
param storageAccountName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

resource blobStorageConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    displayName: name
    parameterValues: {
      accountName: storageAccountName
      accessKey: storageAccount.listKeys().keys[0].value
    }
    api: {
      name: 'azureblob'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/azureblob'
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}
