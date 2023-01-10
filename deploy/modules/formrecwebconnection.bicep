@description('Web connection name')
param name string 

@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object

@description('Azure region of the deployment')
param formRecognizerName string

resource formRecognizer 'Microsoft.CognitiveServices/accounts@2021-10-01' existing = {
  name: formRecognizerName
}

resource customVisionConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    displayName: name
    customParameterValues: {
      predictionKey: formRecognizer.listKeys().key1
      accountKey: formRecognizer.listKeys().key1
    }
    nonSecretParameterValues: {
      //siteUrl: 'https://${resourceGroup().location}.api.cognitive.microsoft.com/'
      siteUrl: formRecognizer.properties.endpoint
      endpointUrl:'https://${resourceGroup().location}.api.cognitive.microsoft.com/'
    }
    api: {
      name: 'formrecognizer'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/formrecognizer'
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

