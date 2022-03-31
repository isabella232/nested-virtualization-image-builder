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
    securityRules: []
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

resource jit 'Microsoft.Security/locations/jitNetworkAccessPolicies@2020-01-01' = {
  name: '${location}/jit-builder'
  kind: 'Basic'
  properties: {
    virtualMachines: [
      {
        id: vm.id
        ports: [
          {
            maxRequestAccessDuration: 'PT8H'
            allowedSourceAddressPrefix: '*'
            protocol: '*'
            number: 3389
          }
        ]
      }
    ]
  }
}

resource bootstrapScript 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  parent: vm
  name: 'bootstrap'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure-Samples/nested-virtualization-image-builder/main/builder/Initialize-Builder.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Initialize-Builder.ps1'
    }
  }
}

output principalId string = vm.identity.principalId
