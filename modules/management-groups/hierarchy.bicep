// ============================================================================
// Design Area C: Resource Organization - Management Group Hierarchy
// ============================================================================
// This module creates the Azure Landing Zone management group structure
// following Microsoft Cloud Adoption Framework best practices.
//
// Hierarchy:
// Tenant Root Group
// └── <Customer Name>
//     ├── Platform
//     │   ├── Management
//     │   ├── Connectivity
//     │   └── Identity
//     ├── Landing Zones
//     │   ├── Corp
//     │   └── Online
//     ├── Sandboxes
//     └── Decommissioned

targetScope = 'tenant'

// Parameters
@description('The root management group display name (typically company name)')
param organizationName string

@description('The prefix for management group IDs')
param managementGroupPrefix string = 'alz'

@description('Tags for documentation (not applied to management groups directly)')
param tags object = {}

// Root Management Group for the organization
resource rootManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${managementGroupPrefix}-root'
  properties: {
    displayName: organizationName
    details: {
      parent: {
        id: tenantResourceId('Microsoft.Management/managementGroups', tenant().tenantId)
      }
    }
  }
}

// Platform Management Group
resource platformManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${managementGroupPrefix}-platform'
  properties: {
    displayName: '${organizationName} - Platform'
    details: {
      parent: {
        id: rootManagementGroup.id
      }
    }
  }
}

// Management - Platform Management and Monitoring
resource managementManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${managementGroupPrefix}-platform-management'
  properties: {
    displayName: 'Management'
    details: {
      parent: {
        id: platformManagementGroup.id
      }
    }
  }
}

// Connectivity - Hub Networking and Hybrid Connectivity
resource connectivityManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${managementGroupPrefix}-platform-connectivity'
  properties: {
    displayName: 'Connectivity'
    details: {
      parent: {
        id: platformManagementGroup.id
      }
    }
  }
}

// Identity - Identity Services and AD DS/Entra Domain Services
resource identityManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${managementGroupPrefix}-platform-identity'
  properties: {
    displayName: 'Identity'
    details: {
      parent: {
        id: platformManagementGroup.id
      }
    }
  }
}

// Landing Zones Management Group
resource landingZonesManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${managementGroupPrefix}-landingzones'
  properties: {
    displayName: '${organizationName} - Landing Zones'
    details: {
      parent: {
        id: rootManagementGroup.id
      }
    }
  }
}

// Corp - Corporate applications with on-premises connectivity
resource corpManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${managementGroupPrefix}-landingzones-corp'
  properties: {
    displayName: 'Corp'
    details: {
      parent: {
        id: landingZonesManagementGroup.id
      }
    }
  }
}

// Online - Internet-facing applications
resource onlineManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${managementGroupPrefix}-landingzones-online'
  properties: {
    displayName: 'Online'
    details: {
      parent: {
        id: landingZonesManagementGroup.id
      }
    }
  }
}

// Sandboxes - Development and testing environments
resource sandboxManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${managementGroupPrefix}-sandboxes'
  properties: {
    displayName: '${organizationName} - Sandboxes'
    details: {
      parent: {
        id: rootManagementGroup.id
      }
    }
  }
}

// Decommissioned - Temporary holding for decommissioned subscriptions
resource decommissionedManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${managementGroupPrefix}-decommissioned'
  properties: {
    displayName: '${organizationName} - Decommissioned'
    details: {
      parent: {
        id: rootManagementGroup.id
      }
    }
  }
}

// Outputs
output managementGroupIds object = {
  root: rootManagementGroup.id
  platform: {
    root: platformManagementGroup.id
    management: managementManagementGroup.id
    connectivity: connectivityManagementGroup.id
    identity: identityManagementGroup.id
  }
  landingZones: {
    root: landingZonesManagementGroup.id
    corp: corpManagementGroup.id
    online: onlineManagementGroup.id
  }
  sandboxes: sandboxManagementGroup.id
  decommissioned: decommissionedManagementGroup.id
}

output managementGroupNames object = {
  root: rootManagementGroup.name
  platform: {
    root: platformManagementGroup.name
    management: managementManagementGroup.name
    connectivity: connectivityManagementGroup.name
    identity: identityManagementGroup.name
  }
  landingZones: {
    root: landingZonesManagementGroup.name
    corp: corpManagementGroup.name
    online: onlineManagementGroup.name
  }
  sandboxes: sandboxManagementGroup.name
  decommissioned: decommissionedManagementGroup.name
}
