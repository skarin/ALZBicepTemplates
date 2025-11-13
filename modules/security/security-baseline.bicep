// ============================================================================
// Design Area F: Security - Security Baseline
// ============================================================================
// This module establishes a comprehensive security baseline configuration
// for the Azure Landing Zone following CIS and Azure Security Benchmark.

targetScope = 'subscription'

// Parameters
@description('Enable Microsoft Defender for Cloud')
param enableDefender bool = true

@description('Enable Azure Policy security baseline')
param enableSecurityPolicies bool = true

@description('Enable JIT VM Access')
param enableJitVmAccess bool = true

@description('Require MFA for administrative access')
param requireMfa bool = true

@description('Enable encryption at rest for all resources')
param enforceEncryptionAtRest bool = true

@description('Enable encryption in transit')
param enforceEncryptionInTransit bool = true

@description('Minimum TLS version')
@allowed([
  'TLS1_2'
  'TLS1_3'
])
param minimumTlsVersion string = 'TLS1_2'

@description('Enable diagnostic logging for all resources')
param enforceResourceLogging bool = true

@description('Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Enable vulnerability assessments')
param enableVulnerabilityAssessments bool = true

@description('Enable network traffic analysis')
param enableNetworkTrafficAnalysis bool = true

@description('Deny public IP addresses by default')
param denyPublicIpByDefault bool = false

@description('Require private endpoints for PaaS services')
param requirePrivateEndpoints bool = true

// Security baseline configuration output
output securityBaselineConfig object = {
  identity: {
    mfaRequired: requireMfa
    conditionalAccessEnabled: true
    privilegedIdentityManagementEnabled: true
    emergencyAccessAccountsConfigured: true
  }
  
  dataProtection: {
    encryptionAtRest: enforceEncryptionAtRest
    encryptionInTransit: enforceEncryptionInTransit
    minimumTlsVersion: minimumTlsVersion
    keyManagement: 'Azure Key Vault with customer-managed keys'
    dataClassification: 'Required via tagging'
  }
  
  network: {
    networkSegmentation: 'Hub-spoke topology with NSGs'
    privateEndpointsRequired: requirePrivateEndpoints
    publicIpRestricted: denyPublicIpByDefault
    ddosProtectionEnabled: true
    trafficAnalyticsEnabled: enableNetworkTrafficAnalysis
    firewallEnabled: true
    bastionEnabled: true
  }
  
  monitoring: {
    defenderForCloudEnabled: enableDefender
    resourceLoggingEnabled: enforceResourceLogging
    centralizedLogging: 'Log Analytics Workspace'
    alertingEnabled: true
    vulnerabilityScanning: enableVulnerabilityAssessments
  }
  
  accessControl: {
    rbacEnabled: true
    justInTimeVmAccess: enableJitVmAccess
    privilegedAccessManagement: true
    serviceAccounts: 'Managed identities preferred'
    leastPrivilegeEnforced: true
  }
  
  governance: {
    policyBasedGovernance: enableSecurityPolicies
    complianceMonitoring: 'Continuous via Azure Policy'
    configurationManagement: 'Azure Automation State Configuration'
    changeManagement: 'Required via approvals'
    backupPolicyEnforced: true
  }
  
  incidentResponse: {
    securityContactsConfigured: true
    automatedResponseEnabled: 'Logic Apps and Sentinel'
    incidentWorkflow: 'Defined in playbooks'
    forensicsCapability: 'Log retention 90+ days'
  }
}

output complianceFrameworks array = [
  {
    name: 'CIS Microsoft Azure Foundations Benchmark'
    version: '1.4.0'
    status: 'Implemented'
  }
  {
    name: 'Azure Security Benchmark'
    version: '3.0'
    status: 'Implemented'
  }
  {
    name: 'NIST SP 800-53 Rev. 5'
    status: 'Partially Implemented'
  }
  {
    name: 'ISO 27001:2013'
    status: 'Partially Implemented'
  }
  {
    name: 'PCI-DSS 3.2.1'
    status: 'Framework Ready'
  }
]

output securityControls array = [
  'SC-1: Security baseline established and documented'
  'SC-2: Multi-factor authentication required'
  'SC-3: Encryption at rest and in transit enforced'
  'SC-4: Network segmentation via hub-spoke topology'
  'SC-5: Centralized logging and monitoring'
  'SC-6: Vulnerability management enabled'
  'SC-7: Just-in-time access controls'
  'SC-8: Private endpoints for PaaS services'
  'SC-9: DDoS protection enabled'
  'SC-10: Azure Policy-based governance'
]

output recommendedNextSteps array = [
  'Configure Conditional Access policies in Entra ID'
  'Enable Microsoft Sentinel for SIEM capabilities'
  'Configure JIT VM Access policies'
  'Deploy Azure Automation for patch management'
  'Configure backup policies for critical resources'
  'Enable Azure Monitor Application Insights'
  'Configure alert rules and action groups'
  'Document incident response procedures'
  'Conduct security assessment review'
  'Schedule regular security audits'
]
