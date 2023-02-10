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


resource rG 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: name
  location: location
}


module logicapp 'modules/logicappempty.bicep' = {
  name: 'lappconn-${name}-deployment'
  scope: rG
  params: {
    location: location
    logicAppName:'${name}lapp'
  }
}

