// Execute this main file to configure Digitization of claims processing 
targetScope = 'subscription'

// Parameters
@minLength(2)
@maxLength(10)
@description('Prefix for all resource names.')
param prefix string

@description('Azure region used for the deployment of all resources.')
param location string

@description('Set of tags to apply to all resources.')
param tags object = {}

// Variables
var name = toLower('${prefix}')

// Create a short, unique suffix, that will be unique to each resource group
//var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 4)

module rG 'modules/resourcegroup.bicep' = {
  //name: 'rg${name}-${uniqueSuffix}-deployment'
  name: 'rg${name}-deployment'
  params: {
    location: location
    resourceGroupName: '${name}rg'
    tags: tags
  }
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'kv${name}-deployment'
  scope: resourceGroup('${name}rg')
  params: {
    location: location
    keyvaultName: '${name}kv'
    tags: tags
  }
}

module storage 'modules/storage.bicep' = {
  name: 'st${name}-deployment'
  scope: resourceGroup('${name}rg')
  params: {
    location: location
    storageName: '${name}stor'
    storageSkuName: 'Standard_LRS'
    tags: tags
  }
}

module formrecognizer 'modules/formrecognizer.bicep' = {
  name: 'fr${name}-deployment'
  scope: resourceGroup('${name}rg')
  params: {
    location: location
    cognitiveServiceName: '${name}frcogsvc'
    sku: 'S0'
    tags: tags
  }
}

module cognitiveservice 'modules/cognitiveservice.bicep' = {
  name: 'cg${name}-deployment'
  scope: resourceGroup('${name}rg')
  params: {
    location: location
    cognitiveServiceName: '${name}cogsvc'
    sku: 'S0'
    tags: tags
  }
}

module customvision 'modules/customvision.bicep' = {
  name: 'cv${name}-deployment'
  scope: resourceGroup('${name}rg')
  params: {
    location: location
    customvisonPredictionName: '${name}cpcogsvc'
    customvisonTrainingName: '${name}ctcogsvc'
    sku: 'S0'
    tags: tags
  }
}

module language 'modules/language.bicep' = {
  name: 'lg${name}-deployment'
  scope: resourceGroup('${name}rg')
  params: {
    location: location
    languageServiceName: '${name}tacogsvc'
    sku: 'S'
    tags: tags
  }
}

module appserviceplan 'modules/appserviceplan.bicep' = {
  name: 'asp${name}-deployment'
  scope: resourceGroup('${name}rg')
  params: {
    location: location
    appServicePlanName: '${name}asp'
    sku: 'F1'
  }
}

module search 'modules/cognitivesearch.bicep' = {
  name: 'az${name}-deployment'
  scope: resourceGroup('${name}rg')
  params: {
    location: location
    name: '${name}acs'
    sku: 'basic'
  }
}

module cosmosdb 'modules/cosmosdb.bicep' = {
  name: 'cdb${name}-deployment'
  scope: resourceGroup('${name}rg')
  params: {
    location: location
    accountName: '${name}cdb'
    databaseName: 'fsihack'
    claimsContainer: 'claims'
    drivingLicenseContainer: 'drivinglicense'
    insuranceContainer: 'insurance'
    serviceEstimateContainer: 'serviceestimate'
    defaultConsistencyLevel: 'BoundedStaleness'
    maxIntervalInSeconds: 300
    maxStalenessPrefix: 100000
    primaryRegion: 'westus'
    secondaryRegion: 'eastus'
  }
}

module applicationInsights 'modules/applicationinsights.bicep' = {
  name: 'appi-${name}-deployment'
  scope: resourceGroup('${name}rg')
  params: {
    location: location
    applicationInsightsName: '${name}appi'
    tags: tags
  }
}

module blob 'modules/blobupload.bicep' = {
  name: 'blob-${name}-deployment'
  scope: resourceGroup('${name}rg')
  params: {
    location: location
    storageAccountName:storage.outputs.storageAccountName
    containerName:'train'
    filename:'temp.jpg'
  }
}

// Get a reference to the existing storage
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  scope: resourceGroup('${name}rg')
  name: storage.outputs.storageAccountName
}

resource formRecognizer 'Microsoft.CognitiveServices/accounts@2021-10-01' existing = {
  name: formrecognizer.outputs.formRecognizerName
}

// $storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=' + $storageAccountName + ';AccountKey=' + $storageAccountKey + ';EndpointSuffix=core.windows.net' 
// output storageKey string = '${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
// output cognitiveServiceName string = cognitiveservice.outputs.cognitiveSvcName
// output formRecognizerName string = formrecognizer.outputs.formRecognizerName
// output frKey string = '${listKeys(formRecognizer.id, formRecognizer.apiVersion).keys[0].value}'
// output frEndPoint string = formRecognizer.properties.endpoint
