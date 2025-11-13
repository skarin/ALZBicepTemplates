// ============================================================================
// Design Area E: Network Topology - ExpressRoute Gateway
// ============================================================================
// This module creates an ExpressRoute Gateway for hybrid connectivity between
// Azure and on-premises datacenters with high-bandwidth, private connections.

targetScope = 'resourceGroup'

// Parameters
@description('The name of the ExpressRoute Gateway')
param gatewayName string

@description('The location where the gateway will be deployed')
param location string = resourceGroup().location

@description('The resource ID of the hub VNet')
param hubVNetId string

@description('Gateway SKU')
@allowed([
  'Standard'
  'HighPerformance'
  'UltraPerformance'
  'ErGw1AZ'
  'ErGw2AZ'
  'ErGw3AZ'
])
param gatewaySku string = 'ErGw1AZ'

@description('Enable zone redundancy (requires AZ SKU)')
param enableZoneRedundancy bool = true

@description('Tags to apply to resources')
param tags object = {}

// Public IP for ExpressRoute Gateway (Zone-redundant)
resource gatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${gatewayName}-pip'
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

// ExpressRoute Gateway
resource expressRouteGateway 'Microsoft.Network/virtualNetworkGateways@2023-05-01' = {
  name: gatewayName
  location: location
  tags: tags
  properties: {
    gatewayType: 'ExpressRoute'
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${hubVNetId}/subnets/GatewaySubnet'
          }
          publicIPAddress: {
            id: gatewayPublicIp.id
          }
        }
      }
    ]
    enableBgp: true
  }
}

// Outputs
output gatewayId string = expressRouteGateway.id
output gatewayName string = expressRouteGateway.name
output gatewayPublicIp string = gatewayPublicIp.properties.ipAddress

output connectionInstructions string = '''
To connect this ExpressRoute Gateway to your circuit:

1. Create an ExpressRoute circuit (if not already created)
2. Authorize the connection from the circuit
3. Create a connection resource linking the gateway to the circuit

Example Azure CLI command:
az network vpn-connection create \\
  --name <connection-name> \\
  --resource-group <resource-group> \\
  --vnet-gateway1 ${expressRouteGateway.id} \\
  --express-route-circuit2 <circuit-id> \\
  --location ${location}
'''
