// ============================================================================
// Design Area E: Network Topology - VPN Gateway
// ============================================================================
// This module creates a VPN Gateway for hybrid connectivity between Azure
// and on-premises or remote sites using IPsec/IKE VPN tunnels.

targetScope = 'resourceGroup'

// Parameters
@description('The name of the VPN Gateway')
param gatewayName string

@description('The location where the gateway will be deployed')
param location string = resourceGroup().location

@description('The resource ID of the hub VNet')
param hubVNetId string

@description('Gateway SKU')
@allowed([
  'VpnGw1'
  'VpnGw2'
  'VpnGw3'
  'VpnGw4'
  'VpnGw5'
  'VpnGw1AZ'
  'VpnGw2AZ'
  'VpnGw3AZ'
  'VpnGw4AZ'
  'VpnGw5AZ'
])
param gatewaySku string = 'VpnGw1AZ'

@description('VPN type')
@allowed([
  'RouteBased'
  'PolicyBased'
])
param vpnType string = 'RouteBased'

@description('Generation for VPN Gateway')
@allowed([
  'Generation1'
  'Generation2'
])
param vpnGatewayGeneration string = 'Generation2'

@description('Enable BGP for dynamic routing')
param enableBgp bool = true

@description('Enable active-active mode (requires two public IPs)')
param enableActiveActive bool = false

@description('Enable zone redundancy (requires AZ SKU)')
param enableZoneRedundancy bool = true

@description('BGP ASN (Autonomous System Number)')
param bgpAsn int = 65515

@description('Tags to apply to resources')
param tags object = {}

// Public IP 1 for VPN Gateway
resource gatewayPublicIp1 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${gatewayName}-pip1'
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
  zones: enableZoneRedundancy ? [
    '1'
    '2'
    '3'
  ] : []
}

// Public IP 2 for VPN Gateway (Active-Active mode)
resource gatewayPublicIp2 'Microsoft.Network/publicIPAddresses@2023-05-01' = if (enableActiveActive) {
  name: '${gatewayName}-pip2'
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
  zones: enableZoneRedundancy ? [
    '1'
    '2'
    '3'
  ] : []
}

// VPN Gateway
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-05-01' = {
  name: gatewayName
  location: location
  tags: tags
  properties: {
    gatewayType: 'Vpn'
    vpnType: vpnType
    vpnGatewayGeneration: vpnGatewayGeneration
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    ipConfigurations: concat(
      [
        {
          name: 'default'
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            subnet: {
              id: '${hubVNetId}/subnets/GatewaySubnet'
            }
            publicIPAddress: {
              id: gatewayPublicIp1.id
            }
          }
        }
      ],
      enableActiveActive ? [
        {
          name: 'activeActive'
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            subnet: {
              id: '${hubVNetId}/subnets/GatewaySubnet'
            }
            publicIPAddress: {
              id: gatewayPublicIp2.id
            }
          }
        }
      ] : []
    )
    enableBgp: enableBgp
    activeActive: enableActiveActive
    bgpSettings: enableBgp ? {
      asn: bgpAsn
    } : null
  }
}

// Outputs
output gatewayId string = vpnGateway.id
output gatewayName string = vpnGateway.name
output gatewayPublicIp1 string = gatewayPublicIp1.properties.ipAddress
output gatewayPublicIp2 string = enableActiveActive ? gatewayPublicIp2.properties.ipAddress : ''
output bgpSettings object = enableBgp ? vpnGateway.properties.bgpSettings : {}

output connectionInstructions string = '''
To create a Site-to-Site VPN connection:

1. Create a Local Network Gateway representing your on-premises network
2. Create a Connection resource linking the VPN Gateway to the Local Network Gateway
3. Configure your on-premises VPN device with the shared key and gateway settings

Example Azure CLI commands:
# Create Local Network Gateway
az network local-gateway create \\
  --name <local-gateway-name> \\
  --resource-group <resource-group> \\
  --gateway-ip-address <on-prem-vpn-device-ip> \\
  --local-address-prefixes <on-prem-address-space>

# Create Connection
az network vpn-connection create \\
  --name <connection-name> \\
  --resource-group <resource-group> \\
  --vnet-gateway1 ${vpnGateway.id} \\
  --local-gateway2 <local-gateway-id> \\
  --shared-key <your-shared-key>
'''
