// ============================================================================
// Design Area D: Governance - Naming Policy
// ============================================================================
// This policy enforces naming conventions for Azure resources

targetScope = 'managementGroup'

// Parameters
@description('Management group ID where the policy will be assigned')
param managementGroupId string

@description('Naming pattern to enforce (regex)')
param namingPattern string = '^[a-z]{2,4}-[a-z0-9]+-[a-z]{3,4}-[a-z]{2,5}-[0-9]{3}$'

@description('Enforcement mode')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'DoNotEnforce' // Audit mode by default

// Policy Definition - Naming convention
resource namingPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'enforce-naming-convention-policy'
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: 'Enforce resource naming convention'
    description: 'Enforces naming convention pattern for Azure resources following CAF standards'
    metadata: {
      category: 'Naming'
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
        metadata: {
          displayName: 'Effect'
          description: 'Enable or disable the execution of the policy'
        }
      }
      namingPattern: {
        type: 'String'
        metadata: {
          displayName: 'Naming Pattern'
          description: 'Regular expression pattern for resource names'
        }
        defaultValue: namingPattern
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            in: [
              'Microsoft.Compute/virtualMachines'
              'Microsoft.Network/virtualNetworks'
              'Microsoft.Network/networkSecurityGroups'
              'Microsoft.Storage/storageAccounts'
              'Microsoft.KeyVault/vaults'
              'Microsoft.Sql/servers'
              'Microsoft.ContainerService/managedClusters'
            ]
          }
          {
            not: {
              field: 'name'
              match: '[parameters(\'namingPattern\')]'
            }
          }
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
      }
    }
  }
}

// Policy Definition - Resource group naming
resource rgNamingPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'enforce-rg-naming-policy'
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: 'Enforce resource group naming convention'
    description: 'Ensures resource groups follow naming pattern: rg-<workload>-<env>-<region>-<instance>'
    metadata: {
      category: 'Naming'
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
        metadata: {
          displayName: 'Effect'
          description: 'Enable or disable the execution of the policy'
        }
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Resources/subscriptions/resourceGroups'
          }
          {
            not: {
              field: 'name'
              match: 'rg-*-*-*-*'
            }
          }
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
      }
    }
  }
}

// Policy Assignment - Naming convention
resource namingPolicyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'naming-convention-assignment'
  properties: {
    policyDefinitionId: namingPolicy.id
    displayName: 'Enforce resource naming convention'
    description: 'Audits resources that do not follow naming convention'
    enforcementMode: enforcementMode
    parameters: {
      effect: {
        value: 'Audit'
      }
      namingPattern: {
        value: namingPattern
      }
    }
  }
}

// Outputs
output namingPolicyId string = namingPolicy.id
output rgNamingPolicyId string = rgNamingPolicy.id
output namingPolicyAssignmentId string = namingPolicyAssignment.id

output namingGuidance object = {
  pattern: '<resource-type>-<workload>-<environment>-<region>-<instance>'
  examples: {
    virtualMachine: 'vm-finance-prod-eus-001'
    virtualNetwork: 'vnet-hub-prod-eus-001'
    storageAccount: 'stfinanceprodeus001 (no hyphens)'
    keyVault: 'kv-finance-prod-eus (24 char limit)'
    resourceGroup: 'rg-finance-prod-eus-001'
  }
  regex: namingPattern
}
