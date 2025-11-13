// ============================================================================
// Design Area C: Resource Organization - Tagging Standards
// ============================================================================
// This module defines and enforces standardized tagging for Azure resources
// to support cost management, governance, operations, and compliance.

targetScope = 'subscription'

// Parameters
@description('The organization or company name')
param organizationName string

@description('The workload or application name')
param workloadName string

@description('Environment type')
@allowed([
  'Production'
  'Development'
  'Testing'
  'QA'
  'UAT'
  'Staging'
])
param environment string

@description('Cost center or billing code')
param costCenter string

@description('Business owner email')
param businessOwner string

@description('Technical owner email')
param technicalOwner string

@description('Criticality level')
@allowed([
  'Critical'
  'High'
  'Medium'
  'Low'
])
param criticality string = 'Medium'

@description('Data classification')
@allowed([
  'Restricted'
  'Confidential'
  'Internal'
  'Public'
])
param dataClassification string = 'Internal'

@description('Compliance requirements')
param complianceRequirements array = []

@description('Backup required')
param backupRequired bool = true

@description('Disaster recovery required')
param disasterRecoveryRequired bool = false

@description('Deployment date')
param deploymentDate string = utcNow('yyyy-MM-dd')

@description('Additional custom tags')
param customTags object = {}

// Standard tag structure following CAF best practices
var standardTags = {
  // Business tags
  Organization: organizationName
  Workload: workloadName
  Environment: environment
  CostCenter: costCenter
  BusinessOwner: businessOwner
  TechnicalOwner: technicalOwner
  
  // Operational tags
  Criticality: criticality
  DataClassification: dataClassification
  BackupRequired: string(backupRequired)
  DisasterRecovery: string(disasterRecoveryRequired)
  
  // Governance tags
  Compliance: !empty(complianceRequirements) ? join(complianceRequirements, ',') : 'None'
  
  // Automation tags
  DeploymentDate: deploymentDate
  DeploymentMethod: 'Bicep'
  ManagedBy: 'Azure Landing Zone'
  
  // Version control
  Version: '1.0.0'
}

// Merge standard and custom tags
var allTags = union(standardTags, customTags)

// Outputs
output tags object = allTags

output requiredTags array = [
  'Organization'
  'Workload'
  'Environment'
  'CostCenter'
  'BusinessOwner'
  'TechnicalOwner'
  'Criticality'
  'DataClassification'
]

output tagGuidance object = {
  description: 'Standard tagging convention for Azure resources'
  
  businessTags: {
    Organization: 'The organization or company name'
    Workload: 'The workload or application name'
    Environment: 'Deployment environment (Production, Development, etc.)'
    CostCenter: 'Cost center or billing code for chargeback'
    BusinessOwner: 'Business stakeholder responsible for the workload'
    TechnicalOwner: 'Technical contact responsible for day-to-day operations'
  }
  
  operationalTags: {
    Criticality: 'Business impact level (Critical, High, Medium, Low)'
    DataClassification: 'Data sensitivity level (Restricted, Confidential, Internal, Public)'
    BackupRequired: 'Whether backup is required for this resource'
    DisasterRecovery: 'Whether DR is required for this resource'
  }
  
  governanceTags: {
    Compliance: 'Applicable compliance requirements (e.g., HIPAA, PCI-DSS, SOC2)'
  }
  
  automationTags: {
    DeploymentDate: 'Date the resource was deployed'
    DeploymentMethod: 'Deployment tool used (Bicep, Terraform, Portal, etc.)'
    ManagedBy: 'Management platform or team'
    Version: 'Version of the deployment template'
  }
  
  bestPractices: [
    'All tags should be treated as case-sensitive'
    'Tag values should be concise but descriptive'
    'Email addresses should be distribution lists when possible'
    'Use standard values for Environment, Criticality, and DataClassification'
    'Update tags when resource ownership or configuration changes'
    'Use Azure Policy to enforce required tags at resource creation'
  ]
}

output complianceMapping object = {
  HIPAA: contains(complianceRequirements, 'HIPAA')
  'PCI-DSS': contains(complianceRequirements, 'PCI-DSS')
  SOC2: contains(complianceRequirements, 'SOC2')
  ISO27001: contains(complianceRequirements, 'ISO27001')
  GDPR: contains(complianceRequirements, 'GDPR')
  NIST: contains(complianceRequirements, 'NIST')
}
