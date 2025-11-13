// ============================================================================
// Design Area G: Management - Log Analytics Workspace
// ============================================================================
// This module creates a centralized Log Analytics workspace for collecting
// logs, metrics, and telemetry from all Azure resources.

targetScope = 'resourceGroup'

// Parameters
@description('The name of the Log Analytics workspace')
param workspaceName string

@description('The location where the workspace will be deployed')
param location string = resourceGroup().location

@description('Workspace SKU')
@allowed([
  'PerGB2018'
  'CapacityReservation'
])
param sku string = 'PerGB2018'

@description('Capacity reservation level in GB (required if SKU is CapacityReservation)')
@allowed([
  100
  200
  300
  400
  500
  1000
  2000
  5000
])
param capacityReservationLevel int = 100

@description('Data retention in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 90

@description('Enable daily quota (cap) in GB')
param enableDailyQuota bool = false

@description('Daily quota in GB')
param dailyQuotaGb int = 10

@description('Enable public network access')
param publicNetworkAccessForIngestion string = 'Enabled'

@description('Enable public network access for queries')
param publicNetworkAccessForQuery string = 'Enabled'

@description('Tags to apply to resources')
param tags object = {}

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
      capacityReservationLevel: sku == 'CapacityReservation' ? capacityReservationLevel : null
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
      disableLocalAuth: false
    }
    workspaceCapping: enableDailyQuota ? {
      dailyQuotaGb: dailyQuotaGb
    } : null
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
  }
}

// Security Solution
resource securitySolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'Security(${workspaceName})'
  location: location
  tags: tags
  plan: {
    name: 'Security(${workspaceName})'
    product: 'OMSGallery/Security'
    promotionCode: ''
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Update Management Solution
resource updatesSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'Updates(${workspaceName})'
  location: location
  tags: tags
  plan: {
    name: 'Updates(${workspaceName})'
    product: 'OMSGallery/Updates'
    promotionCode: ''
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Change Tracking Solution
resource changeTrackingSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'ChangeTracking(${workspaceName})'
  location: location
  tags: tags
  plan: {
    name: 'ChangeTracking(${workspaceName})'
    product: 'OMSGallery/ChangeTracking'
    promotionCode: ''
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}

// VM Insights Solution
resource vmInsightsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'VMInsights(${workspaceName})'
  location: location
  tags: tags
  plan: {
    name: 'VMInsights(${workspaceName})'
    product: 'OMSGallery/VMInsights'
    promotionCode: ''
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Container Insights Solution
resource containerInsightsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'ContainerInsights(${workspaceName})'
  location: location
  tags: tags
  plan: {
    name: 'ContainerInsights(${workspaceName})'
    product: 'OMSGallery/ContainerInsights'
    promotionCode: ''
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}

// KeyVault Analytics Solution
resource keyVaultAnalyticsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'KeyVaultAnalytics(${workspaceName})'
  location: location
  tags: tags
  plan: {
    name: 'KeyVaultAnalytics(${workspaceName})'
    product: 'OMSGallery/KeyVaultAnalytics'
    promotionCode: ''
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Outputs
output workspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name
output customerId string = logAnalyticsWorkspace.properties.customerId
output workspaceResourceId string = logAnalyticsWorkspace.id

output solutionsDeployed array = [
  'Security'
  'Updates'
  'ChangeTracking'
  'VMInsights'
  'ContainerInsights'
  'KeyVaultAnalytics'
]

output configuration object = {
  sku: sku
  retentionInDays: retentionInDays
  dailyQuotaEnabled: enableDailyQuota
  dailyQuotaGb: enableDailyQuota ? dailyQuotaGb : null
}
