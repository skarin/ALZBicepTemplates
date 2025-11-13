// ============================================================================
// Design Area G: Management - Azure Backup Configuration
// ============================================================================
// This module creates a Recovery Services Vault and backup policies for
// protecting Azure resources with automated backup and retention.

targetScope = 'resourceGroup'

// Parameters
@description('The name of the Recovery Services Vault')
param vaultName string

@description('The location where the vault will be deployed')
param location string = resourceGroup().location

@description('Vault SKU')
@allowed([
  'Standard'
  'RS0'
])
param vaultSku string = 'Standard'

@description('Storage redundancy for backup data')
@allowed([
  'LocallyRedundant'
  'GeoRedundant'
  'ZoneRedundant'
])
param storageType string = 'GeoRedundant'

@description('Enable cross-region restore')
param enableCrossRegionRestore bool = true

@description('Enable soft delete for backup data')
param enableSoftDelete bool = true

@description('Soft delete retention in days')
@minValue(14)
@maxValue(180)
param softDeleteRetentionDays int = 14

@description('Enable diagnostic logging')
param enableDiagnostics bool = true

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string = ''

@description('Tags to apply to resources')
param tags object = {}

// Recovery Services Vault
resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2023-06-01' = {
  name: vaultName
  location: location
  tags: tags
  sku: {
    name: vaultSku
    tier: vaultSku == 'Standard' ? 'Standard' : 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

// Backup Storage Configuration
resource vaultStorageConfig 'Microsoft.RecoveryServices/vaults/backupstorageconfig@2023-06-01' = {
  parent: recoveryServicesVault
  name: 'vaultstorageconfig'
  properties: {
    storageModelType: storageType
    crossRegionRestoreFlag: enableCrossRegionRestore
  }
}

// Enhanced Security Settings
resource securitySettings 'Microsoft.RecoveryServices/vaults/backupconfig@2023-06-01' = {
  parent: recoveryServicesVault
  name: 'vaultconfig'
  properties: {
    enhancedSecurityState: 'Enabled'
    softDeleteFeatureState: enableSoftDelete ? 'Enabled' : 'Disabled'
    softDeleteRetentionPeriodInDays: softDeleteRetentionDays
  }
}

// VM Backup Policy - Daily
resource vmBackupPolicyDaily 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-06-01' = {
  parent: recoveryServicesVault
  name: 'DefaultVMPolicy'
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: 5
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        '2023-01-01T02:00:00Z'
      ]
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          '2023-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        daysOfTheWeek: [
          'Sunday'
        ]
        retentionTimes: [
          '2023-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: 12
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Weekly'
        retentionScheduleWeekly: {
          daysOfTheWeek: [
            'Sunday'
          ]
          weeksOfTheMonth: [
            'First'
          ]
        }
        retentionTimes: [
          '2023-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: 12
          durationType: 'Months'
        }
      }
      yearlySchedule: {
        retentionScheduleFormatType: 'Weekly'
        monthsOfYear: [
          'January'
        ]
        retentionScheduleWeekly: {
          daysOfTheWeek: [
            'Sunday'
          ]
          weeksOfTheMonth: [
            'First'
          ]
        }
        retentionTimes: [
          '2023-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: 7
          durationType: 'Years'
        }
      }
    }
    timeZone: 'UTC'
  }
}

// File Share Backup Policy
resource fileShareBackupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-06-01' = {
  parent: recoveryServicesVault
  name: 'DefaultFileSharePolicy'
  properties: {
    backupManagementType: 'AzureStorage'
    workloadType: 'AzureFileShare'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        '2023-01-01T03:00:00Z'
      ]
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          '2023-01-01T03:00:00Z'
        ]
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
      }
    }
    timeZone: 'UTC'
  }
}

// SQL Database Backup Policy
resource sqlBackupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-06-01' = {
  parent: recoveryServicesVault
  name: 'DefaultSQLPolicy'
  properties: {
    backupManagementType: 'AzureWorkload'
    workloadType: 'SQLDataBase'
    settings: {
      timeZone: 'UTC'
      issqlcompression: true
    }
    subProtectionPolicy: [
      {
        policyType: 'Full'
        schedulePolicy: {
          schedulePolicyType: 'SimpleSchedulePolicy'
          scheduleRunFrequency: 'Daily'
          scheduleRunTimes: [
            '2023-01-01T02:00:00Z'
          ]
        }
        retentionPolicy: {
          retentionPolicyType: 'LongTermRetentionPolicy'
          dailySchedule: {
            retentionTimes: [
              '2023-01-01T02:00:00Z'
            ]
            retentionDuration: {
              count: 30
              durationType: 'Days'
            }
          }
        }
      }
      {
        policyType: 'Log'
        schedulePolicy: {
          schedulePolicyType: 'LogSchedulePolicy'
          scheduleFrequencyInMins: 120
        }
        retentionPolicy: {
          retentionPolicyType: 'SimpleRetentionPolicy'
          retentionDuration: {
            count: 15
            durationType: 'Days'
          }
        }
      }
    ]
  }
}

// Diagnostic Settings
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && !empty(logAnalyticsWorkspaceId)) {
  scope: recoveryServicesVault
  name: '${vaultName}-diagnostics'
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
    ]
    metrics: [
      {
        category: 'Health'
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
output vaultId string = recoveryServicesVault.id
output vaultName string = recoveryServicesVault.name

output backupPolicies object = {
  vmPolicy: vmBackupPolicyDaily.id
  fileSharePolicy: fileShareBackupPolicy.id
  sqlPolicy: sqlBackupPolicy.id
}

output vaultConfiguration object = {
  storageType: storageType
  crossRegionRestoreEnabled: enableCrossRegionRestore
  softDeleteEnabled: enableSoftDelete
  softDeleteRetentionDays: softDeleteRetentionDays
  enhancedSecurityEnabled: true
}

output retentionSummary object = {
  vmBackup: {
    daily: '30 days'
    weekly: '12 weeks'
    monthly: '12 months'
    yearly: '7 years'
  }
  fileShareBackup: {
    daily: '30 days'
  }
  sqlBackup: {
    full: '30 days'
    log: '15 days'
  }
}
