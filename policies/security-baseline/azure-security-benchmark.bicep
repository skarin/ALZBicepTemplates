// ============================================================================
// Design Area F: Security - Azure Security Benchmark Policy
// ============================================================================
// This policy initiative assigns the Azure Security Benchmark for
// comprehensive security and compliance monitoring.

targetScope = 'managementGroup'

// Parameters
@description('Management group ID where the policy will be assigned')
param managementGroupId string

@description('Log Analytics Workspace ID for security data')
param logAnalyticsWorkspaceId string

@description('Enforcement mode')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'Default'

// Built-in policy initiative - Azure Security Benchmark
resource asbInitiativeAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'asb-initiative-assignment'
  properties: {
    policyDefinitionId: '/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8' // Azure Security Benchmark
    displayName: 'Azure Security Benchmark'
    description: 'Azure Security Benchmark initiative for comprehensive security controls'
    enforcementMode: enforcementMode
    parameters: {
      logAnalyticsWorkspaceIdforVMReporting: {
        value: logAnalyticsWorkspaceId
      }
    }
  }
}

// Custom Policy - Require HTTPS for storage accounts
resource httpsStoragePolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'require-https-storage-policy'
  properties: {
    policyType: 'Custom'
    mode: 'Indexed'
    displayName: 'Storage accounts should only allow HTTPS traffic'
    description: 'Ensures storage accounts require secure transfer (HTTPS)'
    metadata: {
      category: 'Storage'
      version: '1.0.0'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Storage/storageAccounts'
          }
          {
            anyOf: [
              {
                field: 'Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly'
                notEquals: true
              }
              {
                field: 'Microsoft.Storage/storageAccounts/minimumTlsVersion'
                notEquals: 'TLS1_2'
              }
            ]
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

// Custom Policy - Require encryption for data at rest
resource encryptionPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'require-encryption-at-rest-policy'
  properties: {
    policyType: 'Custom'
    mode: 'Indexed'
    displayName: 'Require encryption at rest for all storage resources'
    description: 'Ensures all storage resources have encryption enabled'
    metadata: {
      category: 'Storage'
      version: '1.0.0'
    }
    policyRule: {
      if: {
        anyOf: [
          {
            allOf: [
              {
                field: 'type'
                equals: 'Microsoft.Storage/storageAccounts'
              }
              {
                field: 'Microsoft.Storage/storageAccounts/encryption.services.blob.enabled'
                notEquals: true
              }
            ]
          }
          {
            allOf: [
              {
                field: 'type'
                equals: 'Microsoft.Compute/disks'
              }
              {
                field: 'Microsoft.Compute/disks/encryption.type'
                equals: 'EncryptionAtRestWithPlatformKey'
              }
            ]
          }
        ]
      }
      then: {
        effect: 'audit'
      }
    }
  }
}

// Custom Policy - Require diagnostic settings
resource diagnosticsPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'require-diagnostics-policy'
  properties: {
    policyType: 'Custom'
    mode: 'Indexed'
    displayName: 'Require diagnostic settings for all resources'
    description: 'Ensures diagnostic settings are configured for monitoring and compliance'
    metadata: {
      category: 'Monitoring'
      version: '1.0.0'
    }
    parameters: {
      effect: {
        type: 'String'
        defaultValue: 'AuditIfNotExists'
        allowedValues: [
          'AuditIfNotExists'
          'DeployIfNotExists'
          'Disabled'
        ]
      }
      logAnalytics: {
        type: 'String'
        metadata: {
          displayName: 'Log Analytics workspace'
          description: 'The Log Analytics workspace to send diagnostic data'
        }
      }
    }
    policyRule: {
      if: {
        field: 'type'
        in: [
          'Microsoft.KeyVault/vaults'
          'Microsoft.Network/networkSecurityGroups'
          'Microsoft.Network/publicIPAddresses'
          'Microsoft.Network/loadBalancers'
          'Microsoft.Network/applicationGateways'
          'Microsoft.Sql/servers/databases'
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
        details: {
          type: 'Microsoft.Insights/diagnosticSettings'
          existenceCondition: {
            field: 'Microsoft.Insights/diagnosticSettings/workspaceId'
            equals: '[parameters(\'logAnalytics\')]'
          }
        }
      }
    }
  }
}

// Custom Policy - Deny public IP addresses (optional)
resource denyPublicIpPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'deny-public-ip-policy'
  properties: {
    policyType: 'Custom'
    mode: 'Indexed'
    displayName: 'Restrict creation of public IP addresses'
    description: 'Restricts creation of public IPs to approved subnets only'
    metadata: {
      category: 'Network'
      version: '1.0.0'
    }
    parameters: {
      effect: {
        type: 'String'
        defaultValue: 'Audit'
        allowedValues: [
          'Audit'
          'Deny'
          'Disabled'
        ]
      }
      allowedSubnets: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed Subnets'
          description: 'List of subnet IDs where public IPs are allowed'
        }
        defaultValue: []
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Network/publicIPAddresses'
          }
          {
            count: {
              field: 'Microsoft.Network/publicIPAddresses/ipConfiguration[*].subnet.id'
              where: {
                field: 'Microsoft.Network/publicIPAddresses/ipConfiguration[*].subnet.id'
                in: '[parameters(\'allowedSubnets\')]'
              }
            }
            equals: 0
          }
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
      }
    }
  }
}

// Security Baseline Initiative
resource securityBaselineInitiative 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: 'custom-security-baseline-initiative'
  properties: {
    policyType: 'Custom'
    displayName: 'Custom Security Baseline Initiative'
    description: 'Custom security policies for Azure Landing Zone'
    metadata: {
      category: 'Security'
      version: '1.0.0'
    }
    parameters: {
      logAnalyticsWorkspaceId: {
        type: 'String'
        metadata: {
          displayName: 'Log Analytics Workspace ID'
        }
      }
    }
    policyDefinitions: [
      {
        policyDefinitionId: httpsStoragePolicy.id
        parameters: {}
      }
      {
        policyDefinitionId: encryptionPolicy.id
        parameters: {}
      }
      {
        policyDefinitionId: diagnosticsPolicy.id
        parameters: {
          effect: {
            value: 'AuditIfNotExists'
          }
          logAnalytics: {
            value: '[parameters(\'logAnalyticsWorkspaceId\')]'
          }
        }
      }
    ]
  }
}

// Outputs
output asbAssignmentId string = asbInitiativeAssignment.id
output httpsStoragePolicyId string = httpsStoragePolicy.id
output encryptionPolicyId string = encryptionPolicy.id
output diagnosticsPolicyId string = diagnosticsPolicy.id
output denyPublicIpPolicyId string = denyPublicIpPolicy.id
output securityBaselineInitiativeId string = securityBaselineInitiative.id
