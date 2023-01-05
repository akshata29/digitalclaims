@description('That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
param languageServiceName string = 'CognitiveService-${uniqueString(resourceGroup().id)}'

@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object

@allowed([
  'S0'
  'S1'
  'S'
])

@description('Cognitive Services SKU')
param sku string = 'S0'

resource languageservice 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: languageServiceName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'TextAnalytics'
  // properties: {
  //   apiProperties: {
  //     statisticsEnabled: false
  //   }
  // }
}

output cognitiveSvcName string = languageservice.name
