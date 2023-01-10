@description('Web connection name')
param name string 

@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object

@description('Azure region of the deployment')
param customVisionName string

resource customVision 'Microsoft.CognitiveServices/accounts@2021-10-01' existing = {
  name: customVisionName
}

resource customVisionConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    displayName: name
    customParameterValues: {
      predictionKey: customVision.listKeys().key1
      accountKey: customVision.listKeys().key1
    }
    nonSecretParameterValues: {
      //siteUrl: 'https://${resourceGroup().location}.api.cognitive.microsoft.com/'
      siteUrl: customVision.properties.endpoint
    }
    api: {
      name: 'cognitiveservicescustomvision'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/cognitiveservicescustomvision'
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

