// ============================================================================
// Customer 2 - Example Ltd - Parameter File
// ============================================================================
// This parameter file configures the Azure Landing Zone for Customer 2
// demonstrating a deployment with VPN Gateway only (no ExpressRoute).

using './main.bicep'

// Organization Configuration
param organizationName = 'Example Ltd'
param managementGroupPrefix = 'exampleltd'

// Geographic Configuration
param primaryRegion = 'westeurope'
param secondaryRegion = 'northeurope'
param environment = 'Production'

// Subscription IDs (Replace with actual subscription IDs)
param managementSubscriptionId = '00000000-0000-0000-0000-000000000011'
param connectivitySubscriptionId = '00000000-0000-0000-0000-000000000012'
param identitySubscriptionId = '00000000-0000-0000-0000-000000000013'

// Hub Network Configuration
param hubVNetConfig = {
  name: 'vnet-hub-prod-westeurope-001'
  addressSpace: ['10.200.0.0/16']
  firewallSubnetPrefix: '10.200.1.0/26'
  bastionSubnetPrefix: '10.200.2.0/26'
  gatewaySubnetPrefix: '10.200.3.0/27'
  managementSubnetPrefix: '10.200.4.0/24'
  sharedServicesSubnetPrefix: '10.200.5.0/24'
}

// Hybrid Connectivity
param enableExpressRoute = false  // VPN only for this customer
param enableVpnGateway = true

// Security Features
param enableFirewall = true
param enableBastion = true
param enableDefender = true

// Security Contacts
param securityContactEmails = [
  'security@exampleltd.com'
]

// Tagging Configuration
param costCenter = 'FINANCE-2000'
param businessOwner = 'cfo@exampleltd.com'
param technicalOwner = 'itops@exampleltd.com'

// Compliance Requirements
param complianceRequirements = [
  'GDPR'
  'ISO27001'
  'PCI-DSS'
]

// Common Tags
param commonTags = {
  Customer: 'Example Ltd'
  Project: 'Azure Landing Zone'
  Criticality: 'High'
  DataClassification: 'Internal'
  BackupRequired: 'true'
  DisasterRecovery: 'true'
}
