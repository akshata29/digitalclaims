@description('Azure Cosmos DB account name, max length 44 characters')
param accountName string = 'sql-${uniqueString(resourceGroup().id)}'

@description('Location for the Azure Cosmos DB account.')
param location string = resourceGroup().location

@description('The primary region for the Azure Cosmos DB account.')
param primaryRegion string

@description('The secondary region for the Azure Cosmos DB account.')
param secondaryRegion string

@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
@description('The default consistency level of the Cosmos DB account.')
param defaultConsistencyLevel string = 'Session'

@minValue(10)
@maxValue(2147483647)
@description('Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 2147483647. Multi Region: 100000 to 2147483647.')
param maxStalenessPrefix int = 100000

@minValue(5)
@maxValue(86400)
@description('Max lag time (minutes). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.')
param maxIntervalInSeconds int = 300

@allowed([
  true
  false
])
@description('Enable system managed failover for regions')
param systemManagedFailover bool = true

@description('The name for the database')
param databaseName string = 'fsihack'

@description('The name for the insurance container')
param insuranceContainer string = 'insurance'

@description('The name for the drivinglicense container')
param drivingLicenseContainer string = 'drivinglicense'

@description('The name for the serviceestimates container')
param serviceEstimateContainer string = 'serviceestimates'

@description('The name for the claims container')
param claimsContainer string = 'claims'

@minValue(400)
@maxValue(1000000)
@description('The throughput for the container')
param throughput int = 400

var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}
var locations = [
  {
    locationName: primaryRegion
    failoverPriority: 0
    isZoneRedundant: false
  }
  {
    locationName: secondaryRegion
    failoverPriority: 1
    isZoneRedundant: false
  }
]

resource account 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: toLower(accountName)
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    locations: locations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: systemManagedFailover
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  name: '${account.name}/${databaseName}'
  properties: {
    resource: {
      id: databaseName
    }
  }
}

// resource insurancecontainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
//   name: '${database.name}/${insuranceContainer}'
//   properties: {
//     resource: {
//       id: insuranceContainer
//       partitionKey: {
//         paths: [
//           '/FormType'
//         ]
//         kind: 'Hash'
//       }
//       indexingPolicy: {
//         indexingMode: 'consistent'
//         includedPaths: [
//           {
//             path: '/*'
//           }
//         ]
//         excludedPaths: [
//           {
//             path: '/_etag/?'
//           }
//         ]
//       }
//       defaultTtl: 86400
//     }
//     options: {
//       throughput: throughput
//     }
//   }
// }

// resource drivingLicensecontainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
//   name: '${database.name}/${drivingLicenseContainer}'
//   properties: {
//     resource: {
//       id: drivingLicenseContainer
//       partitionKey: {
//         paths: [
//           '/FormType'
//         ]
//         kind: 'Hash'
//       }
//       indexingPolicy: {
//         indexingMode: 'consistent'
//         includedPaths: [
//           {
//             path: '/*'
//           }
//         ]
//         excludedPaths: [
//           {
//             path: '/_etag/?'
//           }
//         ]
//       }
//       defaultTtl: 86400
//     }
//     options: {
//       throughput: throughput
//     }
//   }
// }

// resource serviceEstimatecontainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
//   name: '${database.name}/${serviceEstimateContainer}'
//   properties: {
//     resource: {
//       id: serviceEstimateContainer
//       partitionKey: {
//         paths: [
//           '/FormType'
//         ]
//         kind: 'Hash'
//       }
//       indexingPolicy: {
//         indexingMode: 'consistent'
//         includedPaths: [
//           {
//             path: '/*'
//           }
//         ]
//         excludedPaths: [
//           {
//             path: '/_etag/?'
//           }
//         ]
//       }
//       defaultTtl: 86400
//     }
//     options: {
//       throughput: throughput
//     }
//   }
// }

resource claimscontainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  name: '${database.name}/${claimsContainer}'
  properties: {
    resource: {
      id: claimsContainer
      partitionKey: {
        paths: [
          '/FormType'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/_etag/?'
          }
        ]
      }
      defaultTtl: 86400
    }
    options: {
      throughput: throughput
    }
  }
}
