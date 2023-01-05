@description('That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
param cognitiveServiceName string = 'CognitiveService-${uniqueString(resourceGroup().id)}'

@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object

@allowed([
  'S0'
])

@description('Cognitive Services SKU')
param sku string = 'S0'

resource formrecognizer 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: cognitiveServiceName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'FormRecognizer'
  // properties: {
  //   apiProperties: {
  //     statisticsEnabled: false
  //   }
  // }
}

output formRecognizerName string = formrecognizer.name
