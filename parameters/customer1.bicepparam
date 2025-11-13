// ============================================================================
// Customer 1 - Example Corp - Parameter File
// ============================================================================
// This parameter file configures the Azure Landing Zone for Customer 1
// demonstrating a full deployment with ExpressRoute and VPN Gateway.

using './main.bicep'

// Organization Configuration
param organizationName = 'Example Corp'
param managementGroupPrefix = 'examplecorp'

// Geographic Configuration
param primaryRegion = 'eastus'
param secondaryRegion = 'westus2'
param environment = 'Production'

// Subscription IDs (Replace with actual subscription IDs)
param managementSubscriptionId = '00000000-0000-0000-0000-000000000001'
param connectivitySubscriptionId = '00000000-0000-0000-0000-000000000002'
param identitySubscriptionId = '00000000-0000-0000-0000-000000000003'

// Hub Network Configuration
param hubVNetConfig = {
  name: 'vnet-hub-prod-eastus-001'
  addressSpace: ['10.100.0.0/16']
  firewallSubnetPrefix: '10.100.1.0/26'
  bastionSubnetPrefix: '10.100.2.0/26'
  gatewaySubnetPrefix: '10.100.3.0/27'
  managementSubnetPrefix: '10.100.4.0/24'
  sharedServicesSubnetPrefix: '10.100.5.0/24'
}

// Hybrid Connectivity
param enableExpressRoute = true
param enableVpnGateway = true

// Security Features
param enableFirewall = true
param enableBastion = true
param enableDefender = true

// Security Contacts
param securityContactEmails = [
  'security@examplecorp.com'
  'soc@examplecorp.com'
]

// Tagging Configuration
param costCenter = 'IT-1000'
param businessOwner = 'cto@examplecorp.com'
param technicalOwner = 'cloudops@examplecorp.com'

// Compliance Requirements
param complianceRequirements = [
  'SOC2'
  'ISO27001'
  'NIST'
]

// Common Tags
param commonTags = {
  Customer: 'Example Corp'
  Project: 'Azure Landing Zone'
  Criticality: 'Critical'
  DataClassification: 'Confidential'
  BackupRequired: 'true'
  DisasterRecovery: 'true'
}
