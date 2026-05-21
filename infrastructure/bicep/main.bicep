targetScope = 'resourceGroup'

@description('Azure region for all Rand Enterprises lab resources.')
param location string = resourceGroup().location

@description('Prefix used for resource names.')
param projectPrefix string = 'rand'

@description('Linux administrator username for both test VMs.')
param adminUsername string

@description('SSH public key for VM administrator access.')
param adminSshPublicKey string

@description('VM size for the test workloads.')
param vmSize string = 'Standard_B1s'

@description('CIDR allowed to SSH to the test VMs.')
param adminSourceAddressPrefix string

var vnetAName = '${projectPrefix}-workload-vnet-a'
var vnetBName = '${projectPrefix}-workload-vnet-b'
var subnetAName = 'workload-subnet-a'
var subnetBName = 'workload-subnet-b'
var vmAName = '${projectPrefix}-vm-a'
var vmBName = '${projectPrefix}-vm-b'
var nsgName = '${projectPrefix}-workload-nsg'
var storageName = toLower('${projectPrefix}${uniqueString(resourceGroup().id)}st')
var subnetAId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetAName, subnetAName)
var subnetBId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetBName, subnetBName)

resource workloadNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpFromInternet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowSshFromInternet'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: adminSourceAddressPrefix
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowIcmpBetweenWorkloads'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Icmp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnetA 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetAName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetAName
        properties: {
          addressPrefix: '10.10.1.0/24'
          networkSecurityGroup: {
            id: workloadNsg.id
          }
        }
      }
    ]
  }
}

resource vnetB 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetBName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetBName
        properties: {
          addressPrefix: '10.20.1.0/24'
          networkSecurityGroup: {
            id: workloadNsg.id
          }
        }
      }
    ]
  }
}

resource peerAToB 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  name: '${vnetA.name}/peer-to-${vnetB.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetB.id
    }
  }
}

resource peerBToA 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  name: '${vnetB.name}/peer-to-${vnetA.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetA.id
    }
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

module vmA 'modules/linux-web-vm.bicep' = {
  name: 'deploy-${vmAName}'
  params: {
    location: location
    vmName: vmAName
    vmSize: vmSize
    adminUsername: adminUsername
    adminSshPublicKey: adminSshPublicKey
    subnetId: subnetAId
    customDataMessage: 'Rand workload A'
  }
}

module vmB 'modules/linux-web-vm.bicep' = {
  name: 'deploy-${vmBName}'
  params: {
    location: location
    vmName: vmBName
    vmSize: vmSize
    adminUsername: adminUsername
    adminSshPublicKey: adminSshPublicKey
    subnetId: subnetBId
    customDataMessage: 'Rand workload B'
  }
}

output networkNames array = [
  vnetA.name
  vnetB.name
]
output workloadVmNames array = [
  vmAName
  vmBName
]
output vmPrivateIps object = {
  vmA: vmA.outputs.privateIp
  vmB: vmB.outputs.privateIp
}
output vmPublicIps object = {
  vmA: vmA.outputs.publicIp
  vmB: vmB.outputs.publicIp
}
output storageAccountName string = storage.name
output peeringNames array = [
  peerAToB.name
  peerBToA.name
]
