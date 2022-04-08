targetScope = 'subscription'

@secure()
@description('The password to be set on the `azureuser` account inside the builder VM')
param adminPassword string

@description('Azure region where resources will be deployed')
param location string = 'westus3'

// Reference to the `Contributor` built-in role
resource contributor 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

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

// Grant the builder VM the `Contributor` role on the Subscription so it can create VMs for validation
resource vmRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(subscription().id, 'builder', contributor.id)
  properties: {
    roleDefinitionId: contributor.id
    principalId: builder.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}
