targetScope = 'resourceGroup'

@description('Resource name to check in current scope (resource group)')
param resourceName string

param location string = resourceGroup().location
param utcValue string = utcNow()

// used to pass into deployment script
var resourceGroupName = resourceGroup().name

// The script below performs an 'az resource list' command to determine whether a resource exists
resource resource_exists_script 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'resource_exists'
  location: location
  kind: 'AzureCLI'
  properties: {
    forceUpdateTag: utcValue
    azCliVersion: '2.15.0'
    timeout: 'PT10M'
    arguments: '\'${resourceGroupName}\' \'${resourceName}\''
    scriptContent: 'result=$(az resource list --resource-group ${resourceGroupName} --name ${resourceName}); echo $result; echo $result | jq -c \'{Result: map({name: .name})}\' > $AZ_SCRIPTS_OUTPUT_PATH'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

output exists bool = length(resource_exists_script.properties.outputs.Result) > 0
