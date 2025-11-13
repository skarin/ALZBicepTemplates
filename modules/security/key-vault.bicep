// ============================================================================
// Design Area F: Security - Azure Key Vault
// ============================================================================
// This module creates an Azure Key Vault for storing secrets, keys, and
// certificates with appropriate access policies and security settings.

targetScope = 'resourceGroup'

// Parameters
@description('The name of the Key Vault')
param keyVaultName string

@description('The location where the Key Vault will be deployed')
param location string = resourceGroup().location

@description('SKU name for Key Vault')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'premium'

@description('Enable soft delete')
param enableSoftDelete bool = true

@description('Soft delete retention days')
@minValue(7)
@maxValue(90)
param softDeleteRetentionDays int = 90

@description('Enable purge protection')
param enablePurgeProtection bool = true

@description('Enable RBAC authorization (recommended over access policies)')
param enableRbacAuthorization bool = true

@description('Enable public network access')
param enablePublicNetworkAccess bool = false

@description('Allowed IP addresses for firewall rules')
param allowedIpAddresses array = []

@description('Virtual Network rules (subnet IDs)')
param virtualNetworkRules array = []

@description('Enable diagnostic logging')
param enableDiagnostics bool = true

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string = ''

@description('Tags to apply to resources')
param tags object = {}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: tenant().tenantId
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionDays
    enablePurgeProtection: enablePurgeProtection
    enableRbacAuthorization: enableRbacAuthorization
    publicNetworkAccess: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    
    // Network ACLs
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: enablePublicNetworkAccess ? 'Allow' : 'Deny'
      ipRules: [for ip in allowedIpAddresses: {
        value: ip
      }]
      virtualNetworkRules: [for vnetRule in virtualNetworkRules: {
        id: vnetRule
        ignoreMissingVnetServiceEndpoint: false
      }]
    }
    
    // Advanced security features
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
  }
}

// Diagnostic Settings
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && !empty(logAnalyticsWorkspaceId)) {
  scope: keyVault
  name: '${keyVaultName}-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        categoryGroup: 'audit'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 365
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
  }
}

// Outputs
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultResourceId string = keyVault.id

output securityConfiguration object = {
  softDeleteEnabled: enableSoftDelete
  softDeleteRetentionDays: softDeleteRetentionDays
  purgeProtectionEnabled: enablePurgeProtection
  rbacAuthorizationEnabled: enableRbacAuthorization
  publicNetworkAccess: enablePublicNetworkAccess
  diagnosticsEnabled: enableDiagnostics
}

output rbacRoles object = {
  keyVaultAdministrator: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
  keyVaultReader: '21090545-7ca7-4776-b22c-e363652d74d2'
  keyVaultSecretsUser: '4633458b-17de-408a-b874-0445c86b69e6'
  keyVaultCryptoUser: '12338af0-0e69-4776-bea7-57ae8d297424'
  keyVaultCertificatesOfficer: 'a4417e6f-fecd-4de8-b567-7b0420556985'
}
