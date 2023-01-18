@description('The name of the logic app to create.')
param logicAppName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Blob web connection name.')
param blobConnName string

@description('Cognitive Service Custom vision connection name.')
param cgcvConnName string 

@description('Document Db connection name')
param cdbConnName string 

@description('Form Recognizer connection name')
param frConnName string 

var workflowSchema = 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'

resource stg 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: {
    displayName: logicAppName
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': workflowSchema
      'actions': {
        'Copy_file_to_processing_folder': {
            'inputs': {
                'host': {
                    'connection': {
                        'name': '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
                    }
                }
                'method': 'post'
                'path': '/datasets/default/copyFile'
                'queries': {
                    'destination': '/processing/@{triggerBody()?[\'Name\']}'
                    'overwrite': true
                    'queryParametersSingleEncoded': true
                    'source': '@triggerBody()?[\'Path\']'
                }
            }
            'runAfter': {
                'Initialize_variable': [
                    'Succeeded'
                ]
            }
            'type': 'ApiConnection'
        }
        'Create_SAS_URI_by_path': {
            'inputs': {
                'body': {
                    'Permissions': 'ReadWriteList'
                }
                'host': {
                    'connection': {
                        'name': '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
                    }
                }
                'method': 'post'
                'path': '/datasets/default/CreateSharedLinkByPath'
                'queries': {
                    'path': '@body(\'Copy_file_to_processing_folder\')?[\'Path\']'
                }
            }
            'runAfter': {
                'Delete_file_from_original_folder': [
                    'Succeeded'
                ]
            }
            'type': 'ApiConnection'
        }
        'Delete_file_from_original_folder': {
            'inputs': {
                'host': {
                    'connection': {
                        'name': '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
                    }
                }
                'method': 'delete'
                'path': '/datasets/default/files/@{encodeURIComponent(encodeURIComponent(triggerBody()?[\'Id\']))}'
            }
            'runAfter': {
                'Copy_file_to_processing_folder': [
                    'Succeeded'
                ]
            }
            'type': 'ApiConnection'
        }
        'Filter_Probability': {
            'inputs': {
                'from': '@body(\'Parse_Json_Response\')'
                'where': '@greater(item()[\'probability\'] 0.85)'
            }
            'runAfter': {
                'Parse_Json_Response': [
                    'Succeeded'
                ]
            }
            'type': 'Query'
        }
        'For_each_tags': {
            'actions': {
                'Copy_file_to_Success_Folder': {
                    'inputs': {
                        'headers': {
                            'ReadFileMetadataFromServer': true
                        }
                        'host': {
                            'connection': {
                                'name': '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
                            }
                        }
                        'method': 'post'
                        'path': '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'AccountNameFromSettings\'))}/copyFile'
                        'queries': {
                            'destination': '/succeeded/@{body(\'Copy_file_to_processing_folder\')?[\'Name\']}'
                            'overwrite': true
                            'queryParametersSingleEncoded': true
                            'source': '@body(\'Copy_file_to_processing_folder\')?[\'Path\']'
                        }
                    }
                    'runAfter': {
                        'Switch': [
                            'Succeeded'
                        ]
                    }
                    'type': 'ApiConnection'
                }
                'Delete_Processed_Blob': {
                    'inputs': {
                        'headers': {
                            'SkipDeleteIfFileNotFoundOnServer': false
                        }
                        'host': {
                            'connection': {
                                'name': '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
                            }
                        }
                        'method': 'delete'
                        'path': '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'AccountNameFromSettings\'))}/files/@{encodeURIComponent(encodeURIComponent(body(\'Copy_file_to_processing_folder\')?[\'Path\']))}'
                    }
                    'runAfter': {
                        'Copy_file_to_Success_Folder': [
                            'Succeeded'
                        ]
                    }
                    'type': 'ApiConnection'
                }
                'Switch': {
                    'cases': {
                        'Driving_License': {
                            'actions': {
                                'Analyze_Driving_License': {
                                    'inputs': {
                                        'headers': {
                                            'inputFileUrl': '@body(\'Create_SAS_URI_by_path\')?[\'WebUrl\']'
                                        }
                                        'host': {
                                            'connection': {
                                                'name': '@parameters(\'$connections\')[\'formrecognizer\'][\'connectionId\']'
                                            }
                                        }
                                        'method': 'post'
                                        'path': '/v2.1/prebuilt/idDocument/analyze'
                                        'queries': {
                                            'includeTextDetails': true
                                        }
                                    }
                                    'runAfter': {}
                                    'type': 'ApiConnection'
                                }
                                'For_each_Id': {
                                    'actions': {
                                        'Create_or_UpdateId': {
                                            'inputs': {
                                                'body': {
                                                    'Address': '@{items(\'For_each_Id\')?[\'fields\']?[\'Address\']?[\'text\']}'
                                                    'CountryRegion': '@{items(\'For_each_Id\')?[\'fields\']?[\'CountryRegion\']?[\'valueCountryRegion\']}'
                                                    'DateOfBirth': '@{items(\'For_each_Id\')?[\'fields\']?[\'DateOfBirth\']?[\'text\']}'
                                                    'DateOfExpiration': '@{items(\'For_each_Id\')?[\'fields\']?[\'DateOfExpiration\']?[\'text\']}'
                                                    'DocumentNumber': '@{items(\'For_each_Id\')?[\'fields\']?[\'DocumentNumber\']?[\'text\']}'
                                                    'DocumentType': '@{items(\'For_each_Id\')?[\'fields\']?[\'DocumentType\']?[\'text\']}'
                                                    'FileName': '@{triggerBody()?[\'Name\']}'
                                                    'FirstName': '@{items(\'For_each_Id\')?[\'fields\']?[\'FirstName\']?[\'text\']}'
                                                    'LastName': '@{items(\'For_each_Id\')?[\'fields\']?[\'LastName\']?[\'text\']}'
                                                    'MachineReadableZone': '@{items(\'For_each_Id\')?[\'fields\']?[\'MachineReadableZone\']?[\'text\']}'
                                                    'Nationality': '@{items(\'For_each_Id\')?[\'fields\']?[\'Nationality\']?[\'valueCountryRegion\']}'
                                                    'Region': '@{items(\'For_each_Id\')?[\'fields\']?[\'Region\']?[\'text\']}'
                                                    'Sex': '@{items(\'For_each_Id\')?[\'fields\']?[\'Sex\']?[\'text\']}'
                                                    'claimId': '@{variables(\'claimId\')}'
                                                    'formtype': 'Driving License'
                                                    'id': '@{guid()}'
                                                }
                                                'host': {
                                                    'connection': {
                                                        'name': '@parameters(\'$connections\')[\'documentdb\'][\'connectionId\']'
                                                    }
                                                }
                                                'method': 'post'
                                                'path': '/v3/dbs/@{encodeURIComponent(\'fsihack\')}/colls/@{encodeURIComponent(\'claims\')}/docs'
                                            }
                                            'runAfter': {}
                                            'type': 'ApiConnection'
                                        }
                                    }
                                    'foreach': '@body(\'Analyze_Driving_License\')?[\'analyzeResult\']?[\'documentResults\']'
                                    'runAfter': {
                                        'Analyze_Driving_License': [
                                            'Succeeded'
                                        ]
                                    }
                                    'type': 'Foreach'
                                }
                            }
                            'case': 'driving license'
                        }
                        'Insurance': {
                            'actions': {
                                'Analyze_Insurance': {
                                    'inputs': {
                                        'headers': {
                                            'inputFileUrl': '@body(\'Create_SAS_URI_by_path\')?[\'WebUrl\']'
                                        }
                                        'host': {
                                            'connection': {
                                                'name': '@parameters(\'$connections\')[\'formrecognizer\'][\'connectionId\']'
                                            }
                                        }
                                        'method': 'post'
                                        'path': '/v2.1/custom/models/@{encodeURIComponent(\'Insurance\')}/analyze'
                                        'queries': {
                                            'includeTextDetails': true
                                        }
                                    }
                                    'runAfter': {}
                                    'type': 'ApiConnection'
                                }
                                'For_each_insurance': {
                                    'actions': {
                                        'Create_or_Update_Insurance': {
                                            'inputs': {
                                                'body': {
                                                    'Agency': ''
                                                    'Agency Address': '@{items(\'For_each_insurance\')?[\'fields\']?[\'Agency Address\']?[\'text\']}'
                                                    'Company': '@{items(\'For_each_insurance\')?[\'fields\']?[\'Company\']?[\'text\']}'
                                                    'Effective Date': '@{items(\'For_each_insurance\')?[\'fields\']?[\'Effective date\']?[\'text\']}'
                                                    'Expiration Date': '@{items(\'For_each_insurance\')?[\'fields\']?[\'Expiration Date\']?[\'text\']}'
                                                    'FileName': '@{triggerBody()?[\'Name\']}'
                                                    'Insured': '@{items(\'For_each_insurance\')?[\'fields\']?[\'Insured\']?[\'text\']}'
                                                    'Insured Address': '@{items(\'For_each_insurance\')?[\'fields\']?[\'Insured Address\']?[\'text\']}'
                                                    'Make': '@{items(\'For_each_insurance\')?[\'fields\']?[\'Make\']?[\'text\']}'
                                                    'Model': '@{items(\'For_each_insurance\')?[\'fields\']?[\'Model\']?[\'text\']}'
                                                    'PolicyNumber': '@{items(\'For_each_insurance\')?[\'fields\']?[\'Policy Number\']?[\'text\']}'
                                                    'State': '@{items(\'For_each_insurance\')?[\'fields\']?[\'State\']?[\'text\']}'
                                                    'VIN': '@{items(\'For_each_insurance\')?[\'fields\']?[\'VIN\']?[\'text\']}'
                                                    'Year': '@{items(\'For_each_insurance\')?[\'fields\']?[\'Year\']?[\'text\']}'
                                                    'claimId': '@{variables(\'claimId\')}'
                                                    'formtype': 'Insurance'
                                                    'id': '@{guid()}'
                                                }
                                                'host': {
                                                    'connection': {
                                                        'name': '@parameters(\'$connections\')[\'documentdb\'][\'connectionId\']'
                                                    }
                                                }
                                                'method': 'post'
                                                'path': '/v3/dbs/@{encodeURIComponent(\'fsihack\')}/colls/@{encodeURIComponent(\'claims\')}/docs'
                                            }
                                            'runAfter': {}
                                            'type': 'ApiConnection'
                                        }
                                    }
                                    'foreach': '@body(\'Parse_Insurance_Response\')'
                                    'runAfter': {
                                        'Parse_Insurance_Response': [
                                            'Succeeded'
                                        ]
                                    }
                                    'type': 'Foreach'
                                }
                                'Parse_Insurance_Response': {
                                    'inputs': {
                                        'content': '@body(\'Analyze_Insurance\')?[\'analyzeResult\']?[\'documentResults\']'
                                        'schema': {
                                            'items': {
                                                'properties': {
                                                    '_fields': {
                                                        'items': {
                                                            'properties': {
                                                                'fieldName': {
                                                                    'type': 'string'
                                                                }
                                                                'fieldValue': {
                                                                    'properties': {
                                                                        'boundingBox': {
                                                                            'items': {
                                                                                'type': 'integer'
                                                                            }
                                                                            'type': 'array'
                                                                        }
                                                                        'confidence': {
                                                                            'type': 'number'
                                                                        }
                                                                        'elements': {
                                                                            'items': {
                                                                                'type': 'string'
                                                                            }
                                                                            'type': 'array'
                                                                        }
                                                                        'page': {
                                                                            'type': 'integer'
                                                                        }
                                                                        'text': {
                                                                            'type': 'string'
                                                                        }
                                                                        'type': {
                                                                            'type': 'string'
                                                                        }
                                                                        'valueString': {
                                                                            'type': 'string'
                                                                        }
                                                                    }
                                                                    'type': 'object'
                                                                }
                                                            }
                                                            'required': [
                                                                'fieldName'
                                                                'fieldValue'
                                                            ]
                                                            'type': 'object'
                                                        }
                                                        'type': 'array'
                                                    }
                                                    'docType': {
                                                        'type': 'string'
                                                    }
                                                    'docTypeConfidence': {
                                                        'type': 'number'
                                                    }
                                                    'fields': {
                                                        'properties': {
                                                            'Agency': {
                                                                'properties': {
                                                                    'boundingBox': {
                                                                        'items': {
                                                                            'type': 'integer'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'confidence': {
                                                                        'type': 'number'
                                                                    }
                                                                    'elements': {
                                                                        'items': {
                                                                            'type': 'string'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'page': {
                                                                        'type': 'integer'
                                                                    }
                                                                    'text': {
                                                                        'type': 'string'
                                                                    }
                                                                    'type': {
                                                                        'type': 'string'
                                                                    }
                                                                    'valueString': {
                                                                        'type': 'string'
                                                                    }
                                                                }
                                                                'type': 'object'
                                                            }
                                                            'Agency Address': {
                                                                'properties': {
                                                                    'boundingBox': {
                                                                        'items': {
                                                                            'type': 'integer'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'confidence': {
                                                                        'type': 'number'
                                                                    }
                                                                    'elements': {
                                                                        'items': {
                                                                            'type': 'string'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'page': {
                                                                        'type': 'integer'
                                                                    }
                                                                    'text': {
                                                                        'type': 'string'
                                                                    }
                                                                    'type': {
                                                                        'type': 'string'
                                                                    }
                                                                    'valueString': {
                                                                        'type': 'string'
                                                                    }
                                                                }
                                                                'type': 'object'
                                                            }
                                                            'Company': {
                                                                'properties': {
                                                                    'boundingBox': {
                                                                        'items': {
                                                                            'type': 'integer'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'confidence': {
                                                                        'type': 'number'
                                                                    }
                                                                    'elements': {
                                                                        'items': {
                                                                            'type': 'string'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'page': {
                                                                        'type': 'integer'
                                                                    }
                                                                    'text': {
                                                                        'type': 'string'
                                                                    }
                                                                    'type': {
                                                                        'type': 'string'
                                                                    }
                                                                    'valueString': {
                                                                        'type': 'string'
                                                                    }
                                                                }
                                                                'type': 'object'
                                                            }
                                                            'Effective date': {
                                                                'properties': {
                                                                    'boundingBox': {
                                                                        'items': {
                                                                            'type': 'integer'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'confidence': {
                                                                        'type': 'number'
                                                                    }
                                                                    'elements': {
                                                                        'items': {
                                                                            'type': 'string'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'page': {
                                                                        'type': 'integer'
                                                                    }
                                                                    'text': {
                                                                        'type': 'string'
                                                                    }
                                                                    'type': {
                                                                        'type': 'string'
                                                                    }
                                                                    'valueString': {
                                                                        'type': 'string'
                                                                    }
                                                                }
                                                                'type': 'object'
                                                            }
                                                            'Expiration Date': {
                                                                'properties': {
                                                                    'boundingBox': {
                                                                        'items': {
                                                                            'type': 'integer'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'confidence': {
                                                                        'type': 'number'
                                                                    }
                                                                    'elements': {
                                                                        'items': {
                                                                            'type': 'string'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'page': {
                                                                        'type': 'integer'
                                                                    }
                                                                    'text': {
                                                                        'type': 'string'
                                                                    }
                                                                    'type': {
                                                                        'type': 'string'
                                                                    }
                                                                    'valueString': {
                                                                        'type': 'string'
                                                                    }
                                                                }
                                                                'type': 'object'
                                                            }
                                                            'Insured': {
                                                                'properties': {
                                                                    'boundingBox': {
                                                                        'items': {
                                                                            'type': 'integer'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'confidence': {
                                                                        'type': 'number'
                                                                    }
                                                                    'elements': {
                                                                        'items': {
                                                                            'type': 'string'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'page': {
                                                                        'type': 'integer'
                                                                    }
                                                                    'text': {
                                                                        'type': 'string'
                                                                    }
                                                                    'type': {
                                                                        'type': 'string'
                                                                    }
                                                                    'valueString': {
                                                                        'type': 'string'
                                                                    }
                                                                }
                                                                'type': 'object'
                                                            }
                                                            'Insured Address': {
                                                                'properties': {
                                                                    'boundingBox': {
                                                                        'items': {
                                                                            'type': 'integer'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'confidence': {
                                                                        'type': 'number'
                                                                    }
                                                                    'elements': {
                                                                        'items': {
                                                                            'type': 'string'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'page': {
                                                                        'type': 'integer'
                                                                    }
                                                                    'text': {
                                                                        'type': 'string'
                                                                    }
                                                                    'type': {
                                                                        'type': 'string'
                                                                    }
                                                                    'valueString': {
                                                                        'type': 'string'
                                                                    }
                                                                }
                                                                'type': 'object'
                                                            }
                                                            'Make': {
                                                                'properties': {
                                                                    'boundingBox': {
                                                                        'items': {
                                                                            'type': 'integer'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'confidence': {
                                                                        'type': 'number'
                                                                    }
                                                                    'elements': {
                                                                        'items': {
                                                                            'type': 'string'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'page': {
                                                                        'type': 'integer'
                                                                    }
                                                                    'text': {
                                                                        'type': 'string'
                                                                    }
                                                                    'type': {
                                                                        'type': 'string'
                                                                    }
                                                                    'valueString': {
                                                                        'type': 'string'
                                                                    }
                                                                }
                                                                'type': 'object'
                                                            }
                                                            'Model': {
                                                                'properties': {
                                                                    'boundingBox': {
                                                                        'items': {
                                                                            'type': 'integer'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'confidence': {
                                                                        'type': 'number'
                                                                    }
                                                                    'elements': {
                                                                        'items': {
                                                                            'type': 'string'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'page': {
                                                                        'type': 'integer'
                                                                    }
                                                                    'text': {
                                                                        'type': 'string'
                                                                    }
                                                                    'type': {
                                                                        'type': 'string'
                                                                    }
                                                                    'valueString': {
                                                                        'type': 'string'
                                                                    }
                                                                }
                                                                'type': 'object'
                                                            }
                                                            'Policy Number': {
                                                                'properties': {
                                                                    'boundingBox': {
                                                                        'items': {
                                                                            'type': 'integer'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'confidence': {
                                                                        'type': 'number'
                                                                    }
                                                                    'elements': {
                                                                        'items': {
                                                                            'type': 'string'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'page': {
                                                                        'type': 'integer'
                                                                    }
                                                                    'text': {
                                                                        'type': 'string'
                                                                    }
                                                                    'type': {
                                                                        'type': 'string'
                                                                    }
                                                                    'valueString': {
                                                                        'type': 'string'
                                                                    }
                                                                }
                                                                'type': 'object'
                                                            }
                                                            'State': {
                                                                'properties': {
                                                                    'confidence': {
                                                                        'type': 'number'
                                                                    }
                                                                    'type': {
                                                                        'type': 'string'
                                                                    }
                                                                }
                                                                'type': 'object'
                                                            }
                                                            'VIN': {
                                                                'properties': {
                                                                    'boundingBox': {
                                                                        'items': {
                                                                            'type': 'integer'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'confidence': {
                                                                        'type': 'number'
                                                                    }
                                                                    'elements': {
                                                                        'items': {
                                                                            'type': 'string'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'page': {
                                                                        'type': 'integer'
                                                                    }
                                                                    'text': {
                                                                        'type': 'string'
                                                                    }
                                                                    'type': {
                                                                        'type': 'string'
                                                                    }
                                                                    'valueString': {
                                                                        'type': 'string'
                                                                    }
                                                                }
                                                                'type': 'object'
                                                            }
                                                            'Year': {
                                                                'properties': {
                                                                    'boundingBox': {
                                                                        'items': {
                                                                            'type': 'integer'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'confidence': {
                                                                        'type': 'number'
                                                                    }
                                                                    'elements': {
                                                                        'items': {
                                                                            'type': 'string'
                                                                        }
                                                                        'type': 'array'
                                                                    }
                                                                    'page': {
                                                                        'type': 'integer'
                                                                    }
                                                                    'text': {
                                                                        'type': 'string'
                                                                    }
                                                                    'type': {
                                                                        'type': 'string'
                                                                    }
                                                                    'valueString': {
                                                                        'type': 'string'
                                                                    }
                                                                }
                                                                'type': 'object'
                                                            }
                                                        }
                                                        'type': 'object'
                                                    }
                                                    'modelId': {
                                                        'type': 'string'
                                                    }
                                                    'pageRange': {
                                                        'items': {
                                                            'type': 'integer'
                                                        }
                                                        'type': 'array'
                                                    }
                                                }
                                                'required': [
                                                    'docType'
                                                    'modelId'
                                                    'pageRange'
                                                    'fields'
                                                    'docTypeConfidence'
                                                    '_fields'
                                                ]
                                                'type': 'object'
                                            }
                                            'type': 'array'
                                        }
                                    }
                                    'runAfter': {
                                        'Analyze_Insurance': [
                                            'Succeeded'
                                        ]
                                    }
                                    'type': 'ParseJson'
                                }
                            }
                            'case': 'insurance'
                        }
                        'Service_Estimate': {
                            'actions': {
                                'Analyze_Service_Estimate': {
                                    'inputs': {
                                        'headers': {
                                            'inputFileUrl': '@body(\'Create_SAS_URI_by_path\')?[\'WebUrl\']'
                                        }
                                        'host': {
                                            'connection': {
                                                'name': '@parameters(\'$connections\')[\'formrecognizer\'][\'connectionId\']'
                                            }
                                        }
                                        'method': 'post'
                                        'path': '/v2.1/prebuilt/invoice/analyze'
                                        'queries': {
                                            'includeTextDetails': true
                                        }
                                    }
                                    'runAfter': {}
                                    'type': 'ApiConnection'
                                }
                                'For_each_Invoice': {
                                    'actions': {
                                        'Create_or_Update_Invoice': {
                                            'inputs': {
                                                'body': {
                                                    'AmountDue': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'AmountDue\']}'
                                                    'BillingAddress': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'BillingAddress\']?[\'text\']}'
                                                    'BillingAddressRecipient': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'BillingAddressRecipient\']?[\'text\']}'
                                                    'CustomerAddress': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'CustomerAddress\']?[\'text\']}'
                                                    'CustomerAddressRecipient': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'CustomerAddressRecipient\']?[\'text\']}'
                                                    'CustomerId': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'CustomerId\']?[\'text\']}'
                                                    'CustomerName': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'CustomerName\']?[\'text\']}'
                                                    'DueDate': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'DueDate\']?[\'text\']}'
                                                    'FileName': '@{triggerBody()?[\'Name\']}'
                                                    'InvoiceDate': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'InvoiceDate\']?[\'text\']}'
                                                    'InvoiceId': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'InvoiceId\']?[\'text\']}'
                                                    'InvoiceTotal': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'InvoiceTotal\']?[\'text\']}'
                                                    'PreviousUnpaidBalance': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'PreviousUnpaidBalance\']?[\'text\']}'
                                                    'PurchaseOrder': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'PurchaseOrder\']?[\'text\']}'
                                                    'RemittanceAddress': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'RemittanceAddress\']?[\'text\']}'
                                                    'RemittanceAddressRecipient': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'RemittanceAddressRecipient\']?[\'text\']}'
                                                    'ServiceAddress': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'ServiceAddress\']?[\'text\']}'
                                                    'ServiceAddressRecipient': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'ServiceAddressRecipient\']?[\'text\']}'
                                                    'ServiceEndDate': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'ServiceEndDate\']?[\'text\']}'
                                                    'ServiceStartDate': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'ServiceStartDate\']?[\'text\']}'
                                                    'ShippingAddress': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'ShippingAddress\']?[\'text\']}'
                                                    'ShippingAddressRecipient': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'ShippingAddressRecipient\']?[\'text\']}'
                                                    'SubTotal': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'SubTotal\']?[\'text\']}'
                                                    'TotalTax': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'TotalTax\']?[\'text\']}'
                                                    'VendorAddress': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'VendorAddress\']?[\'text\']}'
                                                    'VendorAddressRecipient': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'VendorAddressRecipient\']?[\'text\']}'
                                                    'VendorName': '@{items(\'For_each_Invoice\')?[\'fields\']?[\'VendorName\']?[\'text\']}'
                                                    'claimId': '@{variables(\'claimId\')}'
                                                    'formtype': 'Service Estimate'
                                                    'id': '@{guid()}'
                                                }
                                                'host': {
                                                    'connection': {
                                                        'name': '@parameters(\'$connections\')[\'documentdb\'][\'connectionId\']'
                                                    }
                                                }
                                                'method': 'post'
                                                'path': '/v3/dbs/@{encodeURIComponent(\'fsihack\')}/colls/@{encodeURIComponent(\'claims\')}/docs'
                                            }
                                            'runAfter': {}
                                            'type': 'ApiConnection'
                                        }
                                    }
                                    'foreach': '@body(\'Analyze_Service_Estimate\')?[\'analyzeResult\']?[\'documentResults\']'
                                    'runAfter': {
                                        'Analyze_Service_Estimate': [
                                            'Succeeded'
                                        ]
                                    }
                                    'type': 'Foreach'
                                }
                            }
                            'case': 'service estimates'
                        }
                    }
                    'default': {
                        'actions': {}
                    }
                    'expression': '@items(\'For_each_tags\')?[\'tagName\']'
                    'runAfter': {}
                    'type': 'Switch'
                }
            }
            'foreach': '@body(\'Filter_Probability\')'
            'runAfter': {
                'Filter_Probability': [
                    'Succeeded'
                ]
            }
            'type': 'Foreach'
        }
        'Image_Classification': {
            'inputs': {
                'body': {
                    'Url': '@body(\'Create_SAS_URI_by_path\')?[\'WebUrl\']'
                }
                'host': {
                    'connection': {
                        'name': '@parameters(\'$connections\')[\'cognitiveservicescustomvision\'][\'connectionId\']'
                    }
                }
                'method': 'post'
                'path': '/v2/customvision/v3.0/Prediction/@{encodeURIComponent(\'00efc47c-9c30-4d92-a21d-2caac17b8eba\')}/classify/iterations/@{encodeURIComponent(\'latest\')}/url'
            }
            'runAfter': {
                'Create_SAS_URI_by_path': [
                    'Succeeded'
                ]
            }
            'type': 'ApiConnection'
        }
        'Initialize_variable': {
            'inputs': {
                'variables': [
                    {
                        'name': 'claimId'
                        'type': 'string'
                        'value': '@{substring(triggerBody()?[\'DisplayName\']0indexOf(triggerBody()?[\'DisplayName\'] \'_\'))}'
                    }
                ]
            }
            'runAfter': {}
            'type': 'InitializeVariable'
        }
        'Parse_Json_Response': {
            'inputs': {
                'content': '@body(\'Image_Classification\')?[\'predictions\']'
                'schema': {
                    'items': {
                        'properties': {
                            'probability': {
                                'type': 'number'
                            }
                            'tagId': {
                                'type': 'string'
                            }
                            'tagName': {
                                'type': 'string'
                            }
                        }
                        'required': [
                            'probability'
                            'tagId'
                            'tagName'
                        ]
                        'type': 'object'
                    }
                    'type': 'array'
                }
            }
            'runAfter': {
                'Image_Classification': [
                    'Succeeded'
                ]
            }
            'type': 'ParseJson'
        }
    }
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_document_uploaded: {
            recurrence: {
                frequency: 'Second'
                interval: 5
            }
            evaluatedRecurrence: {
                frequency: 'Second'
                interval: 5
            }
            splitOn: '@triggerBody()'
            metadata: {
                JTJmdXBsb2Fk: '/upload'
                JTJmemlwLWZpbGVz: '/zip-files'
            }
            type: 'ApiConnection'
            inputs: {
                host: {
                    connection: {
                        name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
                    }
                }
                method: 'get'
                path: '/datasets/default/triggers/batch/onupdatedfile'
                queries: {
                    folderId: '/upload'
                    maxFileCount: 1
                }
            }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azureblob: {
            connectionId: '/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${blobConnName}'
            connectionName: '${blobConnName}'
            id: '/subscriptions/${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/azureblob'
          }
          cognitiveservicescustomvision: {
            connectionId: '/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${cgcvConnName}'
            connectionName: '${cgcvConnName}'
            id: '/subscriptions/${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/cognitiveservicescustomvision'
          }
          documentdb: {
            connectionId: '/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${cdbConnName}'
            connectionName: '${cdbConnName}'
            id: '/subscriptions/${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/documentdb'
          }
          formrecognizer: {
            connectionId: '/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${frConnName}'
            connectionName: '${frConnName}'
            id: '/subscriptions/${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/formrecognizer'
          }
        }
      }
    }  
  }
}
