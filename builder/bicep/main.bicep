targetScope = 'subscription'

@secure()
@description('The password to be set on the `azureuser` account inside the builder VM')
param adminPassword string

@description('Azure region where resources will be deployed')
param location string = 'westus3'

// Everything in this sample is deployed into a `builder` Resource Group for easy cleanup
resource builderRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'builder'
  location: location
}

// Deploy and configure the builder VM
module builder 'builder.bicep' = {
  name: 'builder'
  scope: builderRG
  params: {
    location: location
    adminPassword: adminPassword
  }
}

// Create a Storage Account for VHD uploads
module storage 'storage.bicep' = {
  name: 'storage'
  scope: builderRG
  params: {
    location: location
    principalId: builder.outputs.principalId
  }
}
