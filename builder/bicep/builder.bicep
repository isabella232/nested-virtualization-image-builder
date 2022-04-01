param adminUsername string = 'azureuser'

@secure()
param adminPassword string

param vmSize string = 'Standard_D4s_v5'
param location string = resourceGroup().location

resource pip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'builder'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'default'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowRDPInbound'
        properties: {
          direction: 'Inbound'
          priority: 2000
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }

  resource defaultSubnet 'subnets' existing = {
    name: 'default'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: 'builder'
  location: location
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ip0'
        properties: {
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: vnet::defaultSubnet.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: 'builder'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    osProfile: {
      computerName: 'builder'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    licenseType: 'Windows_Server'
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource contributor 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource vmRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, vm.id, contributor.id)
  properties: {
    roleDefinitionId: contributor.id
    principalId: vm.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-builder'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '19:00'
    }
    timeZoneId: 'Pacific Standard Time'
    targetResourceId: vm.id
  }
}

resource bootstrapIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'bootstrap'
  location: location
}

resource virtualMachineContributor 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
}

resource bootstrapRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  scope: vm
  name: guid(vm.id, bootstrapIdentity.id, virtualMachineContributor.id)
  properties: {
    roleDefinitionId: virtualMachineContributor.id
    principalId: bootstrapIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource configurationScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  dependsOn: [
    bootstrapRoleAssignment
  ]
  name: 'configureBuilder'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${bootstrapIdentity.id}': {}
    }
  }
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.33.1'
    scriptContent: '''
      set -euxo pipefail
      az vm run-command invoke --command-id RunPowerShellScript -g $RESOURCE_GROUP -n $VM --scripts @Initialize-Builder.ps1
      az vm restart -g $RESOURCE_GROUP -n $VM
      az vm run-command invoke --command-id RunPowerShellScript -g $RESOURCE_GROUP -n $VM --scripts @Initialize-Network.ps1
    '''
    retentionInterval: 'PT6H'
    supportingScriptUris: [
      'https://raw.githubusercontent.com/Azure-Samples/nested-virtualization-image-builder/main/builder/Initialize-Builder.ps1'
      'https://raw.githubusercontent.com/Azure-Samples/nested-virtualization-image-builder/main/builder/Initialize-Network.ps1'
    ]
    environmentVariables: [
      {
        name: 'RESOURCE_GROUP'
        value: resourceGroup().name
      }
      {
        name: 'VM'
        value: vm.name
      }
    ]
  }
}

output principalId string = vm.identity.principalId
