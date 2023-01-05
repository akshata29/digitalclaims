targetScope = 'subscription'

// Creates an Application Insights instance as dependency for Azure ML
@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object = {}

@description('Application Insights resource name')
param resourceGroupName string


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

output resoureceGroupId string = rg.id
