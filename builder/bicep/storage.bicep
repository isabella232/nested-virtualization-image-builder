param principalId string
param location string = resourceGroup().location

var suffix = take(uniqueString(resourceGroup().id, location), 6)

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

resource imageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${storage.name}/default/images'
  properties: {
    publicAccess: 'None'
  }
}

resource storageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(storage.id, principalId, storageBlobDataContributor.id)
  properties: {
    roleDefinitionId: storageBlobDataContributor.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
