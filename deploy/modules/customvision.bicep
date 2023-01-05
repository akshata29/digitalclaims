@description('That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
param customvisonPredictionName string = 'CognitiveService-${uniqueString(resourceGroup().id)}'

@description('That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
param customvisonTrainingName string = 'CognitiveService-${uniqueString(resourceGroup().id)}'

@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object

@allowed([
  'S0'
])

@description('Cognitive Services SKU')
param sku string = 'S0'

resource customvisonpred 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: customvisonPredictionName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'CustomVision.Prediction'
  // properties: {
  //   apiProperties: {
  //     statisticsEnabled: false
  //   }
  // }
}

resource customvisontrain 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: customvisonTrainingName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'CustomVision.Training'
  // properties: {
  //   apiProperties: {
  //     statisticsEnabled: false
  //   }
  // }
}

output customvisonPredSvc string = customvisonpred.name
output customvisonTrainSvc string = customvisontrain.name
