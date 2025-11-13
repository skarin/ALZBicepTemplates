// ============================================================================
// Design Area F: Security - Microsoft Defender for Cloud
// ============================================================================
// This module enables Microsoft Defender for Cloud (formerly Azure Security
// Center) with enhanced security features and continuous monitoring.

targetScope = 'subscription'

// Parameters
@description('Enable Defender for Servers')
param enableDefenderForServers bool = true

@description('Defender for Servers tier')
@allowed([
  'Standard'
  'Free'
])
param defenderForServersTier string = 'Standard'

@description('Enable Defender for App Service')
param enableDefenderForAppService bool = true

@description('Enable Defender for Storage')
param enableDefenderForStorage bool = true

@description('Enable Defender for SQL')
param enableDefenderForSql bool = true

@description('Enable Defender for Containers')
param enableDefenderForContainers bool = true

@description('Enable Defender for Key Vault')
param enableDefenderForKeyVault bool = true

@description('Enable Defender for Resource Manager')
param enableDefenderForResourceManager bool = true

@description('Enable Defender for DNS')
param enableDefenderForDns bool = true

@description('Log Analytics Workspace ID for security data')
param logAnalyticsWorkspaceId string

@description('Email addresses for security alerts')
param securityContactEmails array = []

@description('Enable high severity alert notifications')
param enableAlertNotifications bool = true

// Defender for Servers
resource defenderForServers 'Microsoft.Security/pricings@2023-01-01' = if (enableDefenderForServers) {
  name: 'VirtualMachines'
  properties: {
    pricingTier: defenderForServersTier
    subPlan: defenderForServersTier == 'Standard' ? 'P2' : null
  }
}

// Defender for App Service
resource defenderForAppService 'Microsoft.Security/pricings@2023-01-01' = if (enableDefenderForAppService) {
  name: 'AppServices'
  properties: {
    pricingTier: 'Standard'
  }
}

// Defender for Storage
resource defenderForStorage 'Microsoft.Security/pricings@2023-01-01' = if (enableDefenderForStorage) {
  name: 'StorageAccounts'
  properties: {
    pricingTier: 'Standard'
  }
}

// Defender for SQL
resource defenderForSqlServers 'Microsoft.Security/pricings@2023-01-01' = if (enableDefenderForSql) {
  name: 'SqlServers'
  properties: {
    pricingTier: 'Standard'
  }
}

resource defenderForSqlServerVMs 'Microsoft.Security/pricings@2023-01-01' = if (enableDefenderForSql) {
  name: 'SqlServerVirtualMachines'
  properties: {
    pricingTier: 'Standard'
  }
}

// Defender for Containers
resource defenderForContainers 'Microsoft.Security/pricings@2023-01-01' = if (enableDefenderForContainers) {
  name: 'Containers'
  properties: {
    pricingTier: 'Standard'
  }
}

// Defender for Key Vault
resource defenderForKeyVault 'Microsoft.Security/pricings@2023-01-01' = if (enableDefenderForKeyVault) {
  name: 'KeyVaults'
  properties: {
    pricingTier: 'Standard'
  }
}

// Defender for Resource Manager
resource defenderForResourceManager 'Microsoft.Security/pricings@2023-01-01' = if (enableDefenderForResourceManager) {
  name: 'Arm'
  properties: {
    pricingTier: 'Standard'
  }
}

// Defender for DNS
resource defenderForDns 'Microsoft.Security/pricings@2023-01-01' = if (enableDefenderForDns) {
  name: 'Dns'
  properties: {
    pricingTier: 'Standard'
  }
}

// Security contacts
resource securityContacts 'Microsoft.Security/securityContacts@2023-01-01' = if (!empty(securityContactEmails)) {
  name: 'default'
  properties: {
    emails: join(securityContactEmails, ';')
    alertNotifications: {
      state: enableAlertNotifications ? 'On' : 'Off'
      minimalSeverity: 'High'
    }
    notificationsByRole: {
      state: 'On'
      roles: [
        'Owner'
        'Contributor'
      ]
    }
  }
}

// Auto provisioning settings
resource autoProvisioningSettings 'Microsoft.Security/autoProvisioningSettings@2023-01-01' = {
  name: 'default'
  properties: {
    autoProvision: 'On'
  }
}

// Workspace settings for Defender
resource workspaceSettings 'Microsoft.Security/workspaceSettings@2023-01-01' = {
  name: 'default'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    scope: subscription().id
  }
}

// Outputs
output defenderConfiguration object = {
  servers: enableDefenderForServers
  appService: enableDefenderForAppService
  storage: enableDefenderForStorage
  sql: enableDefenderForSql
  containers: enableDefenderForContainers
  keyVault: enableDefenderForKeyVault
  resourceManager: enableDefenderForResourceManager
  dns: enableDefenderForDns
  autoProvisioning: 'On'
  workspaceConfigured: true
}

output securityContactsConfigured int = length(securityContactEmails)
