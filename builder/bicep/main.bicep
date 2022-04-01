targetScope = 'subscription'

@secure()
param adminPassword string

param location string = 'westus3'

resource builderRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'builder'
  location: location
}

module builder 'builder.bicep' = {
  name: 'builder'
  scope: builderRG
  params: {
    location: location
    adminPassword: adminPassword
  }
}

module storage 'storage.bicep' = {
  name: 'storage'
  scope: builderRG
  params: {
    location: location
    principalId: builder.outputs.principalId
  }
}
