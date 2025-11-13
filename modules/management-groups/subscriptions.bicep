// ============================================================================
// Design Area C: Resource Organization - Subscription Management
// ============================================================================
// This module handles subscription placement into management groups and
// applies subscription-level configurations.

targetScope = 'managementGroup'

// Parameters
@description('The management group ID where the subscription should be placed')
param managementGroupId string

@description('The subscription ID to move/associate')
param subscriptionId string

@description('Display name/alias for the subscription')
param subscriptionAlias string

@description('Workload type: Production, Development, or Testing')
@allowed([
  'Production'
  'DevTest'
])
param workloadType string = 'Production'

@description('Tags to apply at subscription level')
param tags object = {}

// Subscription association with management group
// Note: This requires the subscription to exist already
// Subscriptions are created through Azure Portal, EA Portal, or MCA billing

resource subscriptionAssociation 'Microsoft.Management/managementGroups/subscriptions@2023-04-01' = {
  name: '${managementGroupId}/${subscriptionId}'
}

// Outputs
output subscriptionId string = subscriptionId
output managementGroupId string = managementGroupId
output configuration object = {
  subscriptionAlias: subscriptionAlias
  workloadType: workloadType
  tags: tags
}
