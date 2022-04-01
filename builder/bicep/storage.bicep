// Creates a Storage Account with a single blob container, and assigns an account write access

@description('A principalId that will be granted the `Storage Blob Data Contributor` role')
param principalId string

@description('Azure region where the storage account will be deployed')
param location string = resourceGroup().location

// Storage Account names must be globally unique
// Generate a random suffix based on the current Resource Group + region
var suffix = take(uniqueString(resourceGroup().id, location), 6)

// Reference to the `Storage Blob Data Contributor` built-in role
resource storageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

// Create a storage account to hold uploaded images
resource storage 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: 'builder${suffix}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

// Create a Blob container for images
resource imageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${storage.name}/default/images'
  properties: {
    publicAccess: 'None'
  }
}

// Grant `Storage Blob Data Contributor` to the target account
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(storage.id, principalId, storageBlobDataContributor.id)
  properties: {
    roleDefinitionId: storageBlobDataContributor.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

// Capture the generated Storage Account name in the output parameters
output storageAccount string = storage.name
