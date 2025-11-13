// ============================================================================
// Azure Landing Zone - Main Orchestration
// ============================================================================
// This is the main Bicep file that orchestrates the deployment of all
// Azure Landing Zone components following the ALZ conceptual architecture.
//
// Design Areas Covered:
// A - Azure billing and Active Directory tenant
// B - Identity and access management
// C - Resource organization
// E - Network topology and connectivity
// F - Security
// G/H - Management and Governance
// I - Platform automation and DevOps

targetScope = 'managementGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('The name of the organization')
param organizationName string

@description('Management group prefix for naming')
param managementGroupPrefix string = 'alz'

@description('Primary Azure region for resources')
param primaryRegion string

@description('Secondary Azure region for disaster recovery')
param secondaryRegion string

@description('Environment type')
@allowed([
  'Production'
  'Development'
  'Testing'
])
param environment string = 'Production'

@description('Subscription ID for Platform Management')
param managementSubscriptionId string

@description('Subscription ID for Platform Connectivity')
param connectivitySubscriptionId string

@description('Subscription ID for Platform Identity')
param identitySubscriptionId string

@description('Hub VNet configuration')
param hubVNetConfig object = {
  name: 'vnet-hub-${environment}-${primaryRegion}-001'
  addressSpace: ['10.0.0.0/16']
  firewallSubnetPrefix: '10.0.1.0/26'
  bastionSubnetPrefix: '10.0.2.0/26'
  gatewaySubnetPrefix: '10.0.3.0/27'
  managementSubnetPrefix: '10.0.4.0/24'
  sharedServicesSubnetPrefix: '10.0.5.0/24'
}

@description('Enable ExpressRoute Gateway')
param enableExpressRoute bool = true

@description('Enable VPN Gateway')
param enableVpnGateway bool = true

@description('Enable Azure Firewall')
param enableFirewall bool = true

@description('Enable Azure Bastion')
param enableBastion bool = true

@description('Enable Microsoft Defender for Cloud')
param enableDefender bool = true

@description('Security contact email addresses')
param securityContactEmails array = []

@description('Cost center for tagging')
param costCenter string

@description('Business owner email for tagging')
param businessOwner string

@description('Technical owner email for tagging')
param technicalOwner string

@description('Compliance requirements')
param complianceRequirements array = []

@description('Deployment timestamp')
param deploymentTimestamp string = utcNow('yyyy-MM-dd-HH-mm-ss')

@description('Tags to apply to all resources')
param commonTags object = {}

// ============================================================================
// Variables
// ============================================================================

var namingConvention = {
  workload: 'platform'
  environment: toLower(environment)
  regionAbbreviation: primaryRegion
  instance: '001'
}

var standardTags = union({
  Organization: organizationName
  Environment: environment
  CostCenter: costCenter
  BusinessOwner: businessOwner
  TechnicalOwner: technicalOwner
  DeploymentMethod: 'Bicep'
  DeploymentTimestamp: deploymentTimestamp
  ManagedBy: 'Azure Landing Zone'
}, commonTags)

// ============================================================================
// Design Area C: Management Groups (Tenant Scope)
// ============================================================================

module managementGroups 'modules/management-groups/hierarchy.bicep' = {
  name: 'deploy-management-groups-${deploymentTimestamp}'
  scope: tenant()
  params: {
    organizationName: organizationName
    managementGroupPrefix: managementGroupPrefix
    tags: standardTags
  }
}

// ============================================================================
// Design Area G: Platform Management Resources
// ============================================================================

module logAnalytics 'modules/management/log-analytics.bicep' = {
  name: 'deploy-log-analytics-${deploymentTimestamp}'
  scope: resourceGroup(managementSubscriptionId, 'rg-management-${environment}-${primaryRegion}-001')
  params: {
    workspaceName: 'log-${namingConvention.workload}-${namingConvention.environment}-${primaryRegion}-001'
    location: primaryRegion
    retentionInDays: 90
    tags: standardTags
  }
  dependsOn: [
    managementResourceGroup
  ]
}

module monitoring 'modules/management/monitoring.bicep' = {
  name: 'deploy-monitoring-${deploymentTimestamp}'
  scope: resourceGroup(managementSubscriptionId, 'rg-management-${environment}-${primaryRegion}-001')
  params: {
    actionGroupName: 'ag-${namingConvention.workload}-${namingConvention.environment}-${primaryRegion}-001'
    actionGroupShortName: 'ALZ-Alerts'
    emailReceivers: [
      {
        name: 'TechnicalOwner'
        emailAddress: technicalOwner
      }
    ]
    enableCommonAlerts: true
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: standardTags
  }
  dependsOn: [
    managementResourceGroup
    logAnalytics
  ]
}

module backup 'modules/management/backup.bicep' = {
  name: 'deploy-backup-${deploymentTimestamp}'
  scope: resourceGroup(managementSubscriptionId, 'rg-management-${environment}-${primaryRegion}-001')
  params: {
    vaultName: 'rsv-${namingConvention.workload}-${namingConvention.environment}-${primaryRegion}-001'
    location: primaryRegion
    storageType: 'GeoRedundant'
    enableCrossRegionRestore: true
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: standardTags
  }
  dependsOn: [
    managementResourceGroup
    logAnalytics
  ]
}

// Resource Group for Management
resource managementResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  scope: subscription(managementSubscriptionId)
  name: 'rg-management-${environment}-${primaryRegion}-001'
  location: primaryRegion
  tags: standardTags
}

// ============================================================================
// Design Area F: Security - Microsoft Defender
// ============================================================================

module defender 'modules/security/defender.bicep' = {
  name: 'deploy-defender-${deploymentTimestamp}'
  scope: subscription(managementSubscriptionId)
  params: {
    enableDefenderForServers: enableDefender
    enableDefenderForAppService: enableDefender
    enableDefenderForStorage: enableDefender
    enableDefenderForSql: enableDefender
    enableDefenderForContainers: enableDefender
    enableDefenderForKeyVault: enableDefender
    enableDefenderForResourceManager: enableDefender
    enableDefenderForDns: enableDefender
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    securityContactEmails: securityContactEmails
  }
  dependsOn: [
    logAnalytics
  ]
}

// ============================================================================
// Design Area E: Connectivity - Hub Network
// ============================================================================

module hubNetwork 'modules/networking/hub-spoke/hub-vnet.bicep' = {
  name: 'deploy-hub-network-${deploymentTimestamp}'
  scope: resourceGroup(connectivitySubscriptionId, 'rg-connectivity-${environment}-${primaryRegion}-001')
  params: {
    hubVNetName: hubVNetConfig.name
    location: primaryRegion
    hubVNetAddressSpace: hubVNetConfig.addressSpace
    firewallSubnetPrefix: hubVNetConfig.firewallSubnetPrefix
    bastionSubnetPrefix: hubVNetConfig.bastionSubnetPrefix
    gatewaySubnetPrefix: hubVNetConfig.gatewaySubnetPrefix
    managementSubnetPrefix: hubVNetConfig.managementSubnetPrefix
    sharedServicesSubnetPrefix: hubVNetConfig.sharedServicesSubnetPrefix
    enableFirewall: enableFirewall
    enableBastion: enableBastion
    tags: standardTags
  }
  dependsOn: [
    connectivityResourceGroup
  ]
}

module expressRouteGateway 'modules/networking/expressroute.bicep' = if (enableExpressRoute) {
  name: 'deploy-er-gateway-${deploymentTimestamp}'
  scope: resourceGroup(connectivitySubscriptionId, 'rg-connectivity-${environment}-${primaryRegion}-001')
  params: {
    gatewayName: 'erg-${namingConvention.workload}-${namingConvention.environment}-${primaryRegion}-001'
    location: primaryRegion
    hubVNetId: hubNetwork.outputs.hubVNetId
    gatewaySku: 'ErGw1AZ'
    enableZoneRedundancy: true
    tags: standardTags
  }
  dependsOn: [
    hubNetwork
  ]
}

module vpnGateway 'modules/networking/vpn-gateway.bicep' = if (enableVpnGateway) {
  name: 'deploy-vpn-gateway-${deploymentTimestamp}'
  scope: resourceGroup(connectivitySubscriptionId, 'rg-connectivity-${environment}-${primaryRegion}-001')
  params: {
    gatewayName: 'vpng-${namingConvention.workload}-${namingConvention.environment}-${primaryRegion}-001'
    location: primaryRegion
    hubVNetId: hubNetwork.outputs.hubVNetId
    gatewaySku: 'VpnGw1AZ'
    vpnGatewayGeneration: 'Generation2'
    enableBgp: true
    enableActiveActive: false
    enableZoneRedundancy: true
    tags: standardTags
  }
  dependsOn: [
    hubNetwork
    expressRouteGateway // Ensure ER gateway is created first to avoid conflicts
  ]
}

// Resource Group for Connectivity
resource connectivityResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  scope: subscription(connectivitySubscriptionId)
  name: 'rg-connectivity-${environment}-${primaryRegion}-001'
  location: primaryRegion
  tags: standardTags
}

// ============================================================================
// Design Area D: Governance - Azure Policy
// ============================================================================

module tagPolicy 'policies/governance/tagging-policy.bicep' = {
  name: 'deploy-tag-policy-${deploymentTimestamp}'
  params: {
    managementGroupId: managementGroups.outputs.managementGroupIds.root
    requiredTags: [
      'Environment'
      'CostCenter'
      'BusinessOwner'
      'TechnicalOwner'
      'Workload'
    ]
    enforcementMode: 'Default'
  }
  dependsOn: [
    managementGroups
  ]
}

module namingPolicy 'policies/governance/naming-policy.bicep' = {
  name: 'deploy-naming-policy-${deploymentTimestamp}'
  params: {
    managementGroupId: managementGroups.outputs.managementGroupIds.root
    enforcementMode: 'DoNotEnforce' // Audit mode
  }
  dependsOn: [
    managementGroups
  ]
}

module securityPolicy 'policies/security-baseline/azure-security-benchmark.bicep' = {
  name: 'deploy-security-policy-${deploymentTimestamp}'
  params: {
    managementGroupId: managementGroups.outputs.managementGroupIds.root
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    enforcementMode: 'Default'
  }
  dependsOn: [
    managementGroups
    logAnalytics
  ]
}

// ============================================================================
// Outputs
// ============================================================================

output deploymentSummary object = {
  organizationName: organizationName
  deploymentTimestamp: deploymentTimestamp
  primaryRegion: primaryRegion
  secondaryRegion: secondaryRegion
  environment: environment
}

output managementGroupStructure object = managementGroups.outputs.managementGroupIds

output platformResources object = {
  logAnalytics: {
    workspaceId: logAnalytics.outputs.workspaceId
    workspaceName: logAnalytics.outputs.workspaceName
  }
  monitoring: {
    actionGroupId: monitoring.outputs.actionGroupId
    actionGroupName: monitoring.outputs.actionGroupName
  }
  backup: {
    vaultId: backup.outputs.vaultId
    vaultName: backup.outputs.vaultName
  }
}

output networkingResources object = {
  hubVNet: {
    id: hubNetwork.outputs.hubVNetId
    name: hubNetwork.outputs.hubVNetName
    firewallPrivateIp: enableFirewall ? hubNetwork.outputs.firewallPrivateIp : 'Not deployed'
  }
  expressRouteGateway: enableExpressRoute ? {
    id: expressRouteGateway.outputs.gatewayId
    name: expressRouteGateway.outputs.gatewayName
  } : 'Not deployed'
  vpnGateway: enableVpnGateway ? {
    id: vpnGateway.outputs.gatewayId
    name: vpnGateway.outputs.gatewayName
  } : 'Not deployed'
}

output securityConfiguration object = {
  defenderEnabled: enableDefender
  defenderConfiguration: defender.outputs.defenderConfiguration
}

output governancePolicies object = {
  tagPolicy: tagPolicy.outputs.tagPolicyId
  namingPolicy: namingPolicy.outputs.namingPolicyId
  securityBaseline: securityPolicy.outputs.asbAssignmentId
}

output nextSteps array = [
  '1. Configure Entra ID Conditional Access policies'
  '2. Create spoke virtual networks and peer with hub'
  '3. Deploy workload landing zones in Corp/Online management groups'
  '4. Configure ExpressRoute circuit connection (if applicable)'
  '5. Set up VPN Site-to-Site connections (if applicable)'
  '6. Enable Microsoft Sentinel for SIEM'
  '7. Configure backup policies for workload VMs'
  '8. Review and adjust Azure Policy assignments'
  '9. Document custom configurations for audit'
  '10. Run Azure Landing Zone Review assessment'
]
