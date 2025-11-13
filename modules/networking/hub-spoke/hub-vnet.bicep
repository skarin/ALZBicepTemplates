// ============================================================================
// Design Area E: Network Topology - Hub Virtual Network
// ============================================================================
// This module creates the hub VNet in a hub-spoke topology, including
// shared services like Azure Firewall, Bastion, and Gateway subnets.

targetScope = 'resourceGroup'

// Parameters
@description('The name of the hub virtual network')
param hubVNetName string

@description('The location where resources will be deployed')
param location string = resourceGroup().location

@description('Hub VNet address space')
param hubVNetAddressSpace array = [
  '10.0.0.0/16'
]

@description('Azure Firewall subnet address prefix')
param firewallSubnetPrefix string = '10.0.1.0/26'

@description('Azure Bastion subnet address prefix')
param bastionSubnetPrefix string = '10.0.2.0/26'

@description('Gateway subnet address prefix (for ExpressRoute/VPN)')
param gatewaySubnetPrefix string = '10.0.3.0/27'

@description('Management subnet address prefix')
param managementSubnetPrefix string = '10.0.4.0/24'

@description('Shared services subnet address prefix')
param sharedServicesSubnetPrefix string = '10.0.5.0/24'

@description('Enable DDoS Protection Standard')
param enableDdosProtection bool = true

@description('DDoS Protection Plan resource ID (if enableDdosProtection is true)')
param ddosProtectionPlanId string = ''

@description('Enable Azure Firewall')
param enableFirewall bool = true

@description('Enable Azure Bastion')
param enableBastion bool = true

@description('DNS servers for the VNet (empty for Azure DNS)')
param dnsServers array = []

@description('Tags to apply to resources')
param tags object = {}

// Hub Virtual Network
resource hubVNet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: hubVNetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: hubVNetAddressSpace
    }
    dhcpOptions: !empty(dnsServers) ? {
      dnsServers: dnsServers
    } : null
    enableDdosProtection: enableDdosProtection
    ddosProtectionPlan: enableDdosProtection && !empty(ddosProtectionPlanId) ? {
      id: ddosProtectionPlanId
    } : null
    subnets: [
      // AzureFirewallSubnet - required name for Azure Firewall
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: firewallSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      // AzureBastionSubnet - required name for Azure Bastion
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      // GatewaySubnet - required name for VPN/ExpressRoute Gateway
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      // Management subnet for jump boxes, etc.
      {
        name: 'ManagementSubnet'
        properties: {
          addressPrefix: managementSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      // Shared services subnet
      {
        name: 'SharedServicesSubnet'
        properties: {
          addressPrefix: sharedServicesSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Public IP for Azure Firewall
resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = if (enableFirewall) {
  name: '${hubVNetName}-firewall-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
  zones: [
    '1'
    '2'
    '3'
  ]
}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' = if (enableFirewall) {
  name: '${hubVNetName}-firewall'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'firewallConfig'
        properties: {
          subnet: {
            id: '${hubVNet.id}/subnets/AzureFirewallSubnet'
          }
          publicIPAddress: {
            id: firewallPublicIp.id
          }
        }
      }
    ]
    threatIntelMode: 'Alert'
    additionalProperties: {
      'Network.DNS.EnableProxy': 'true'
    }
  }
  zones: [
    '1'
    '2'
    '3'
  ]
}

// Public IP for Azure Bastion
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = if (enableBastion) {
  name: '${hubVNetName}-bastion-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
}

// Azure Bastion
resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = if (enableBastion) {
  name: '${hubVNetName}-bastion'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'bastionConfig'
        properties: {
          subnet: {
            id: '${hubVNet.id}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
    enableFileCopy: true
    enableTunneling: true
    enableShareableLink: false
  }
}

// Network Watcher (automatically created per region)
resource networkWatcher 'Microsoft.Network/networkWatchers@2023-05-01' existing = {
  name: 'NetworkWatcher_${location}'
  scope: resourceGroup('NetworkWatcherRG')
}

// Outputs
output hubVNetId string = hubVNet.id
output hubVNetName string = hubVNet.name
output firewallPrivateIp string = enableFirewall ? firewall.properties.ipConfigurations[0].properties.privateIPAddress : ''
output firewallPublicIp string = enableFirewall ? firewallPublicIp.properties.ipAddress : ''
output bastionId string = enableBastion ? bastion.id : ''
output subnets object = {
  firewall: '${hubVNet.id}/subnets/AzureFirewallSubnet'
  bastion: '${hubVNet.id}/subnets/AzureBastionSubnet'
  gateway: '${hubVNet.id}/subnets/GatewaySubnet'
  management: '${hubVNet.id}/subnets/ManagementSubnet'
  sharedServices: '${hubVNet.id}/subnets/SharedServicesSubnet'
}
