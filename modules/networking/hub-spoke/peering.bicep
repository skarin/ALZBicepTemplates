// ============================================================================
// Design Area E: Network Topology - VNet Peering
// ============================================================================
// This module creates bi-directional VNet peering between hub and spoke VNets

targetScope = 'resourceGroup'

// Parameters
@description('The name of the hub virtual network')
param hubVNetName string

@description('The resource ID of the hub virtual network')
param hubVNetId string

@description('The name of the spoke virtual network')
param spokeVNetName string

@description('The resource ID of the spoke virtual network')
param spokeVNetId string

@description('Resource group name where the hub VNet exists')
param hubVNetResourceGroupName string

@description('Resource group name where the spoke VNet exists')
param spokeVNetResourceGroupName string

@description('Allow forwarded traffic from spoke to hub')
param allowSpokeForwardedTraffic bool = true

@description('Allow gateway transit from hub to spoke')
param allowHubGatewayTransit bool = true

@description('Use remote gateway in spoke (requires gateway in hub)')
param useRemoteGateway bool = true

// Hub VNet reference
resource hubVNet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: hubVNetName
  scope: resourceGroup(hubVNetResourceGroupName)
}

// Spoke VNet reference
resource spokeVNet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: spokeVNetName
  scope: resourceGroup(spokeVNetResourceGroupName)
}

// Peering from Hub to Spoke
resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: hubVNet
  name: '${hubVNetName}-to-${spokeVNetName}'
  properties: {
    remoteVirtualNetwork: {
      id: spokeVNetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: allowSpokeForwardedTraffic
    allowGatewayTransit: allowHubGatewayTransit
    useRemoteGateways: false
  }
}

// Peering from Spoke to Hub
resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: spokeVNet
  name: '${spokeVNetName}-to-${hubVNetName}'
  properties: {
    remoteVirtualNetwork: {
      id: hubVNetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: useRemoteGateway
  }
}

// Outputs
output hubToSpokePeeringId string = hubToSpokePeering.id
output spokeToHubPeeringId string = spokeToHubPeering.id
output peeringState string = hubToSpokePeering.properties.peeringState
