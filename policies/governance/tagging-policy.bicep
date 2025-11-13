// ============================================================================
// Design Area D: Governance - Tagging Policy
// ============================================================================
// This policy enforces required tags on resources and resource groups

targetScope = 'managementGroup'

// Parameters
@description('Management group ID where the policy will be assigned')
param managementGroupId string

@description('Required tags to enforce')
param requiredTags array = [
  'Environment'
  'CostCenter'
  'BusinessOwner'
  'TechnicalOwner'
  'Workload'
]

@description('Enforcement mode')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'Default'

// Policy Definition - Require specific tags
resource tagPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'require-tags-policy'
  properties: {
    policyType: 'Custom'
    mode: 'Indexed'
    displayName: 'Require specific tags on resources'
    description: 'Enforces required tags on resources following Azure Landing Zone standards'
    metadata: {
      category: 'Tags'
      version: '1.0.0'
    }
    parameters: {
      tagNames: {
        type: 'Array'
        metadata: {
          displayName: 'Tag Names'
          description: 'List of tag names to require'
        }
        defaultValue: requiredTags
      }
    }
    policyRule: {
      if: {
        anyOf: [for tag in requiredTags: {
          field: 'tags[\'${tag}\']'
          exists: false
        }]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

// Policy Definition - Inherit tags from resource group
resource inheritTagsPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'inherit-tags-from-rg-policy'
  properties: {
    policyType: 'Custom'
    mode: 'Indexed'
    displayName: 'Inherit tags from resource group'
    description: 'Automatically inherits specific tags from the parent resource group'
    metadata: {
      category: 'Tags'
      version: '1.0.0'
    }
    parameters: {
      tagName: {
        type: 'String'
        metadata: {
          displayName: 'Tag Name'
          description: 'Name of the tag to inherit'
        }
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: '[concat(\'tags[\', parameters(\'tagName\'), \']\')]'
            exists: false
          }
          {
            value: '[resourceGroup().tags[parameters(\'tagName\')]]'
            notEquals: ''
          }
        ]
      }
      then: {
        effect: 'modify'
        details: {
          roleDefinitionIds: [
            '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
          ]
          operations: [
            {
              operation: 'add'
              field: '[concat(\'tags[\', parameters(\'tagName\'), \']\')]'
              value: '[resourceGroup().tags[parameters(\'tagName\')]]'
            }
          ]
        }
      }
    }
  }
}

// Policy Assignment - Require tags
resource tagPolicyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'require-tags-assignment'
  properties: {
    policyDefinitionId: tagPolicy.id
    displayName: 'Require specific tags on resources'
    description: 'Enforces required tags on all resources'
    enforcementMode: enforcementMode
    parameters: {
      tagNames: {
        value: requiredTags
      }
    }
  }
}

// Policy Initiative (Set) - Tag governance
resource tagInitiative 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: 'tag-governance-initiative'
  properties: {
    policyType: 'Custom'
    displayName: 'Tag Governance Initiative'
    description: 'Collection of tag governance policies'
    metadata: {
      category: 'Tags'
      version: '1.0.0'
    }
    parameters: {}
    policyDefinitions: [
      {
        policyDefinitionId: tagPolicy.id
        parameters: {
          tagNames: {
            value: requiredTags
          }
        }
      }
      {
        policyDefinitionId: inheritTagsPolicy.id
        parameters: {
          tagName: {
            value: 'Environment'
          }
        }
      }
    ]
  }
}

// Outputs
output tagPolicyId string = tagPolicy.id
output inheritTagsPolicyId string = inheritTagsPolicy.id
output tagInitiativeId string = tagInitiative.id
output tagPolicyAssignmentId string = tagPolicyAssignment.id
