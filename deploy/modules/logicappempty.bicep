@description('The name of the logic app to create.')
param logicAppName string

@description('Location for all resources.')
param location string = resourceGroup().location


resource stg 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
      state: 'Enabled'
      definition: {
          '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
          contentVersion: '1.0.0.0'
          parameters: {}
          triggers: {}
          actions: {}
          outputs: {}
      }
      parameters: {}
  }
}
