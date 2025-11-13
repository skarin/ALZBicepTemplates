// ============================================================================
// Design Area G: Management - Azure Monitor Configuration
// ============================================================================
// This module configures Azure Monitor with action groups, alert rules,
// and diagnostic settings for comprehensive monitoring.

targetScope = 'resourceGroup'

// Parameters
@description('The name of the action group')
param actionGroupName string

@description('The location where the action group will be deployed')
param location string = 'global'

@description('Short name for the action group (max 12 chars)')
@maxLength(12)
param actionGroupShortName string

@description('Email receivers for alerts')
param emailReceivers array = []

@description('SMS receivers for alerts')
param smsReceivers array = []

@description('Webhook receivers for alerts')
param webhookReceivers array = []

@description('Enable common metric alerts')
param enableCommonAlerts bool = true

@description('Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Tags to apply to resources')
param tags object = {}

// Action Group
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: location
  tags: tags
  properties: {
    groupShortName: actionGroupShortName
    enabled: true
    emailReceivers: [for receiver in emailReceivers: {
      name: receiver.name
      emailAddress: receiver.emailAddress
      useCommonAlertSchema: true
    }]
    smsReceivers: [for receiver in smsReceivers: {
      name: receiver.name
      countryCode: receiver.countryCode
      phoneNumber: receiver.phoneNumber
    }]
    webhookReceivers: [for receiver in webhookReceivers: {
      name: receiver.name
      serviceUri: receiver.serviceUri
      useCommonAlertSchema: true
    }]
  }
}

// Common Alert Rules
// CPU Usage Alert
resource cpuAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableCommonAlerts) {
  name: 'High-CPU-Usage-Alert'
  location: location
  tags: tags
  properties: {
    displayName: 'High CPU Usage Alert'
    description: 'Alert when CPU usage exceeds 80% for 5 minutes'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      logAnalyticsWorkspaceId
    ]
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'Perf | where ObjectName == "Processor" and CounterName == "% Processor Time" | summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 5m) | where AggregatedValue > 80'
          timeAggregation: 'Average'
          operator: 'GreaterThan'
          threshold: 80
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}

// Memory Usage Alert
resource memoryAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableCommonAlerts) {
  name: 'High-Memory-Usage-Alert'
  location: location
  tags: tags
  properties: {
    displayName: 'High Memory Usage Alert'
    description: 'Alert when memory usage exceeds 85% for 5 minutes'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      logAnalyticsWorkspaceId
    ]
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'Perf | where ObjectName == "Memory" and CounterName == "% Committed Bytes In Use" | summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 5m) | where AggregatedValue > 85'
          timeAggregation: 'Average'
          operator: 'GreaterThan'
          threshold: 85
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}

// Disk Space Alert
resource diskAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableCommonAlerts) {
  name: 'Low-Disk-Space-Alert'
  location: location
  tags: tags
  properties: {
    displayName: 'Low Disk Space Alert'
    description: 'Alert when disk free space is below 10%'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT15M'
    scopes: [
      logAnalyticsWorkspaceId
    ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: 'Perf | where ObjectName == "LogicalDisk" and CounterName == "% Free Space" | summarize AggregatedValue = avg(CounterValue) by Computer, InstanceName, bin(TimeGenerated, 15m) | where AggregatedValue < 10'
          timeAggregation: 'Average'
          operator: 'LessThan'
          threshold: 10
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}

// VM Availability Alert
resource vmAvailabilityAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableCommonAlerts) {
  name: 'VM-Unavailable-Alert'
  location: location
  tags: tags
  properties: {
    displayName: 'VM Unavailable Alert'
    description: 'Alert when a VM has not sent a heartbeat for 5 minutes'
    severity: 0
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      logAnalyticsWorkspaceId
    ]
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'Heartbeat | summarize LastHeartbeat = max(TimeGenerated) by Computer | where LastHeartbeat < ago(5m)'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}

// Outputs
output actionGroupId string = actionGroup.id
output actionGroupName string = actionGroup.name

output alertsDeployed array = enableCommonAlerts ? [
  'High-CPU-Usage-Alert'
  'High-Memory-Usage-Alert'
  'Low-Disk-Space-Alert'
  'VM-Unavailable-Alert'
] : []

output monitoringConfiguration object = {
  actionGroupConfigured: true
  emailReceiversCount: length(emailReceivers)
  smsReceiversCount: length(smsReceivers)
  webhookReceiversCount: length(webhookReceivers)
  commonAlertsEnabled: enableCommonAlerts
}
