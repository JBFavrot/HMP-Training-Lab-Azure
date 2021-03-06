param virtualMachines_VM_WINDOWS_name string = 'VM-WINDOWS'
param networkInterface_VM_Windows_Name string = 'networkInterface-vm-windows001'
param publicIP_VM_Windows_Name string = 'publicIP-VM-WINDOWS'
param NSG_Name string = 'nsg-SimpleEnvironment'
param VNET_simpleDeploy string = 'RG_ADMIN_TestDeployements-vnet'
param location string = 'francecentral'
param adminUserName string = 'azureuser'
@secure()
param adminPassword string
param owner string
param approver string
param endDate string


resource NSG_SimpleEnvironment 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: NSG_Name
  location: location
  tags: {
    owner: owner
    approver: approver
    endDate: endDate
  }
  properties: {
      securityRules: [
        {
          name: 'SSH_FE_BE'
          properties: {
            protocol: 'Tcp'
            sourcePortRange: '*'
            sourceApplicationSecurityGroups: [
              {
                id: Application_Security_Group_FE.id
                location: location
              }
            ]
            destinationPortRange: '22'
            destinationApplicationSecurityGroups: [
              {
                id: Application_Security_Group_BE.id
                location: location
              }
            ]
            access: 'Allow'
            priority: 310
            direction: 'Inbound'
          }
        }
        {
          name: 'RDP_Inbound'
          properties: {
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '3389'
            sourceAddressPrefix: '*'
            destinationApplicationSecurityGroups: [
              {
                id: Application_Security_Group_FE.id
                location: location
              }
            ]
            access: 'Allow'
            priority: 300
            direction: 'Inbound'
          }
        }
      ]
  }
}

resource publicIP_VM_Windows 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: publicIP_VM_Windows_Name
  location: location
  tags: {
    owner: owner
    approver: approver
    endDate: endDate
  }
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
  }
}

resource VNET_SimpleDeployement 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: VNET_simpleDeploy
  location: location
  tags: {
    owner: owner
    approver: approver
    endDate: endDate
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.3.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.3.0.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource VM_Windows 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: virtualMachines_VM_WINDOWS_name
  location: location
  tags: {
    owner: owner
    approver: approver
    endDate: endDate
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-gensecond'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: '${virtualMachines_VM_WINDOWS_name}_OSdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        deleteOption: 'Delete'
      }
      dataDisks: []
    }
    osProfile: {
      computerName: virtualMachines_VM_WINDOWS_name
      adminUsername: adminUserName
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface_VM_Windows_Name_resource.id
          properties: {
            deleteOption: 'Delete'
          }
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

resource Application_Security_Group_FE 'Microsoft.Network/applicationSecurityGroups@2021-05-01' = {
  name: 'FrontEndServer'
  location : location
  
}

resource Application_Security_Group_BE 'Microsoft.Network/applicationSecurityGroups@2021-05-01' = {
  name: 'BackEndServer'
  location: location
}

resource VNET__default 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: VNET_SimpleDeployement
  name: 'default'
  properties: {
    addressPrefix: '10.3.0.0/24'
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource networkInterface_VM_Windows_Name_resource 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: networkInterface_VM_Windows_Name
  location: location
  tags: {
    owner: owner
    approver: approver
    endDate: endDate
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP_VM_Windows.id
          }
          subnet: {
            id: VNET__default.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
          applicationSecurityGroups: [
            {
              id: Application_Security_Group_FE.id
            }
            {
              id: Application_Security_Group_BE.id
            }
            
          ]
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: NSG_SimpleEnvironment.id
    }
  }
}
