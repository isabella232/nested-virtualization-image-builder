// Creates a Windows Server VM and configures it with the Hyper-V role to build custom images

@description('The username for the admin account inside the builder VM')
param adminUsername string = 'azureuser'

@secure()
@description('The password to be set on the admin account inside the builder VM')
param adminPassword string

@description('The size for the builder VM. The chosen size must support Nested Virtualization')
param vmSize string = 'Standard_D4s_v5'

@description('Azure region where the builder VM will be deployed')
param location string = resourceGroup().location

// Reference to the `Contributor` built-in role
resource contributor 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

// Reference to the `Virtual Machine Contributor` built-in role
resource virtualMachineContributor 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
}

// Enable RDP to the builder available over the Internet for demonstration purposes only
resource pip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'builder'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

// Enable RDP to the builder available over the Internet for demonstration purposes only
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

// Create a standalone VNet with a single subnet for the builder VM
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

  // Create a variable so we can refer to the `default` subnet during NIC creation
  resource defaultSubnet 'subnets' existing = {
    name: 'default'
  }
}

// Create the builder VM NIC
resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: 'builder'
  location: location
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ip0'
        properties: {
          // Enable RDP to the builder available over the Internet for demonstration purposes only
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

// Create the builder VM
resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: 'builder'
  location: location

  // Enable Managed Identity so the VM can upload blobs and register images as itself
  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }

    // Azure VMs use the Hyper-V format, so we use a Windows Server OS
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

// Grant the builder VM the `Contributor` role on the Resource Group so it can run `az image create`
resource vmRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, vm.id, contributor.id)
  properties: {
    roleDefinitionId: contributor.id
    principalId: vm.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Creating images from scratch is a very infrequent operation
// Enable an auto-shutdown policy to control costs
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

// Create a Managed Identity that will be used to configure the builder VM
resource bootstrapIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'bootstrap'
  location: location
}

// Grant the bootstrap identity the `Virtual Machine Contributor` role to run commands and restart the VM
resource bootstrapRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  scope: vm
  name: guid(vm.id, bootstrapIdentity.id, virtualMachineContributor.id)
  properties: {
    roleDefinitionId: virtualMachineContributor.id
    principalId: bootstrapIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Run a deployment script to configure the builder VM
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
  // Use Azure CLI to execute commands
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.33.1'
    scriptContent: '''
      set -euxo pipefail

      # Install Windows Server roles and tools
      az vm run-command invoke --command-id RunPowerShellScript -g $RESOURCE_GROUP -n $VM --scripts @Initialize-Builder.ps1

      # The Hyper-V role requires a restart, so we'll do that and wait for the VM to become available again
      az vm restart -g $RESOURCE_GROUP -n $VM

      # After Hyper-V is installed, we can configure networking inside the builder VM
      az vm run-command invoke --command-id RunPowerShellScript -g $RESOURCE_GROUP -n $VM --scripts @Initialize-Network.ps1
    '''
    retentionInterval: 'PT6H'

    // Reference scripts from the sample repo
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

// Capture the builder VM's Managed Identity principalId for use in role assignments
output principalId string = vm.identity.principalId
