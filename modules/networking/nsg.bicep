// ============================================================================
// Design Area E: Network Topology - Network Security Groups
// ============================================================================
// This module creates Network Security Groups with common security rules
// following Azure security best practices.

targetScope = 'resourceGroup'

// Parameters
@description('The name of the Network Security Group')
param nsgName string

@description('The location where the NSG will be deployed')
param location string = resourceGroup().location

@description('Security rules to apply to the NSG')
param securityRules array = []

@description('Enable flow logs')
param enableFlowLogs bool = true

@description('Log Analytics Workspace ID for flow logs')
param logAnalyticsWorkspaceId string = ''

@description('Storage Account ID for flow logs')
param storageAccountId string = ''

@description('Tags to apply to resources')
param tags object = {}

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: securityRules
  }
}

// NSG Flow Logs (requires Network Watcher)
resource flowLog 'Microsoft.Network/networkWatchers/flowLogs@2023-05-01' = if (enableFlowLogs && !empty(storageAccountId)) {
  name: 'NetworkWatcher_${location}/${nsgName}-flowlog'
  location: location
  tags: tags
  properties: {
    targetResourceId: nsg.id
    storageId: storageAccountId
    enabled: true
    retentionPolicy: {
      days: 90
      enabled: true
    }
    format: {
      type: 'JSON'
      version: 2
    }
    flowAnalyticsConfiguration: !empty(logAnalyticsWorkspaceId) ? {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceResourceId: logAnalyticsWorkspaceId
        trafficAnalyticsInterval: 60
      }
    } : null
  }
}

// Common Security Rules Templates
var commonRules = {
  allowHttps: {
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
      description: 'Allow HTTPS inbound'
    }
  }
  allowRdp: {
    name: 'AllowRdpInbound'
    properties: {
      priority: 200
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3389'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: '*'
      description: 'Allow RDP from VNet only'
    }
  }
  allowSsh: {
    name: 'AllowSshInbound'
    properties: {
      priority: 210
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '22'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: '*'
      description: 'Allow SSH from VNet only'
    }
  }
  denyAllInbound: {
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
}

// Outputs
output nsgId string = nsg.id
output nsgName string = nsg.name
output flowLogEnabled bool = enableFlowLogs
output commonSecurityRulesReference object = commonRules
