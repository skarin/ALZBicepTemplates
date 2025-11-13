// ============================================================================
// Design Area B: Identity and Access Management - RBAC Role Assignments
// ============================================================================
// This module assigns Azure built-in and custom RBAC roles at different scopes
// (Management Group, Subscription, Resource Group) following the principle of
// least privilege and Azure Landing Zone best practices.

targetScope = 'managementGroup'

// Parameters
@description('The ID of the management group where roles will be assigned')
param managementGroupId string

@description('Array of role assignments to create')
param roleAssignments array = []

@description('Tags to apply to resources that support tagging')
param tags object = {}

@description('Enable diagnostic logging for role assignments audit trail')
param enableDiagnostics bool = true

// Role assignment resource
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignments: {
  name: guid(managementGroupId, assignment.principalId, assignment.roleDefinitionId)
  properties: {
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionId)
    principalId: assignment.principalId
    principalType: assignment.principalType
    description: assignment.?description ?? 'Managed by Azure Landing Zone deployment'
  }
}]

// Common Azure Built-in Role Definition IDs for reference:
// Owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
// Contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
// Reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
// User Access Administrator: '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
// Security Admin: 'fb1c8493-542b-48eb-b624-b4c8fea62acd'
// Network Contributor: '4d97b98b-1d4f-4787-a291-c67834d212e7'

// Outputs
output roleAssignmentIds array = [for (assignment, i) in roleAssignments: {
  roleAssignmentId: roleAssignment[i].id
  principalId: assignment.principalId
  roleDefinitionId: assignment.roleDefinitionId
}]

output roleAssignmentCount int = length(roleAssignments)
