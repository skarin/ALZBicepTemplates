// ============================================================================
// Design Area E: Network Topology - Spoke Virtual Network
// ============================================================================
// This module creates a spoke VNet in a hub-spoke topology for application
// workloads with appropriate subnets and NSGs.

targetScope = 'resourceGroup'

// Parameters
@description('The name of the spoke virtual network')
param spokeVNetName string

@description('The location where resources will be deployed')
param location string = resourceGroup().location

@description('Spoke VNet address space')
param spokeVNetAddressSpace array

@description('Application subnet configuration')
param applicationSubnets array = [
  {
    name: 'ApplicationSubnet'
    addressPrefix: ''
    delegations: []
  }
]

@description('Data subnet configuration')
param dataSubnets array = [
  {
    name: 'DataSubnet'
    addressPrefix: ''
    serviceEndpoints: []
  }
]

@description('Enable private endpoints subnet')
param enablePrivateEndpoints bool = true

@description('Private endpoints subnet address prefix')
param privateEndpointsSubnetPrefix string = ''

@description('DNS servers for the VNet (empty for Azure DNS)')
param dnsServers array = []

@description('Route table ID for user-defined routes')
param routeTableId string = ''

@description('Tags to apply to resources')
param tags object = {}

// Spoke Virtual Network
resource spokeVNet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: spokeVNetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: spokeVNetAddressSpace
    }
    dhcpOptions: !empty(dnsServers) ? {
      dnsServers: dnsServers
    } : null
    subnets: concat(
      // Application subnets
      [for subnet in applicationSubnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
          networkSecurityGroup: {
            id: applicationNsg.id
          }
          routeTable: !empty(routeTableId) ? {
            id: routeTableId
          } : null
          delegations: subnet.?delegations ?? []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }],
      // Data subnets
      [for subnet in dataSubnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
          networkSecurityGroup: {
            id: dataNsg.id
          }
          routeTable: !empty(routeTableId) ? {
            id: routeTableId
          } : null
          serviceEndpoints: subnet.?serviceEndpoints ?? []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }],
      // Private endpoints subnet
      enablePrivateEndpoints ? [
        {
          name: 'PrivateEndpointsSubnet'
          properties: {
            addressPrefix: privateEndpointsSubnetPrefix
            privateEndpointNetworkPolicies: 'Disabled'
            privateLinkServiceNetworkPolicies: 'Enabled'
          }
        }
      ] : []
    )
  }
}

// Network Security Group for application subnets
resource applicationNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${spokeVNetName}-app-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          description: 'Allow HTTPS inbound traffic'
        }
      }
      {
        name: 'AllowHttpInbound'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          description: 'Allow HTTP inbound traffic'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          description: 'Deny all other inbound traffic'
        }
      }
    ]
  }
}

// Network Security Group for data subnets
resource dataNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${spokeVNetName}-data-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowSqlInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          description: 'Allow SQL traffic from VNet'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          description: 'Deny all other inbound traffic'
        }
      }
    ]
  }
}

// Outputs
output spokeVNetId string = spokeVNet.id
output spokeVNetName string = spokeVNet.name
output applicationNsgId string = applicationNsg.id
output dataNsgId string = dataNsg.id
output subnets array = [for (subnet, i) in spokeVNet.properties.subnets: {
  name: subnet.name
  id: subnet.id
  addressPrefix: subnet.properties.addressPrefix
}]
