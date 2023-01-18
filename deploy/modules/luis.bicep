@description('That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
param luisPredictionName string = 'CognitiveService-${uniqueString(resourceGroup().id)}'

@description('That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
param luisTrainingName string = 'CognitiveService-${uniqueString(resourceGroup().id)}'

@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object

@allowed([
  'S0'
  'F0'
])

@description('Cognitive Services SKU')
param sku string = 'S0'

resource luispred 'Microsoft.CognitiveServices/accounts@2022-10-01' = {
  name: luisPredictionName
  //location: location
  location: 'westus'
  tags: tags
  sku: {
    name: sku
  }
  kind: 'LUIS'
  // properties: {
  //   apiProperties: {
  //     statisticsEnabled: false
  //   }
  // }
}

resource luistrain 'Microsoft.CognitiveServices/accounts@2022-10-01' = {
  name: luisTrainingName
  //location: location
  location: 'westus'
  tags: tags
  sku: {
    name: sku
  }
  kind: 'LUIS.Authoring'
  // properties: {
  //   apiProperties: {
  //     statisticsEnabled: false
  //   }
  // }
}

output luisPredSvc string = luispred.name
output luisTrainSvc string = luistrain.name
