// ============================================================================
// Design Area C: Resource Organization - Naming Convention Standards
// ============================================================================
// This module defines standardized naming conventions for Azure resources
// following Microsoft Cloud Adoption Framework best practices.
//
// Format: <resource-type>-<workload/app>-<environment>-<region>-<instance>
// Example: vnet-finance-prod-eus-001

targetScope = 'subscription'

// Parameters
@description('The workload or application name')
param workloadName string

@description('Environment type')
@allowed([
  'prod'
  'dev'
  'test'
  'qa'
  'uat'
  'staging'
])
param environment string

@description('Azure region abbreviation')
param regionAbbreviation string

@description('Instance number')
param instance string = '001'

@description('Enable strict naming validation')
param enforceNamingStandards bool = true

// Resource type abbreviations based on CAF recommendations
var resourceTypeAbbreviations = {
  // Management and governance
  managementGroup: 'mg'
  policyDefinition: 'policy'
  policyAssignment: 'assign'
  
  // Networking
  virtualNetwork: 'vnet'
  subnet: 'snet'
  networkSecurityGroup: 'nsg'
  applicationSecurityGroup: 'asg'
  routeTable: 'route'
  loadBalancer: 'lb'
  publicIpAddress: 'pip'
  applicationGateway: 'agw'
  vpnGateway: 'vpng'
  expressRouteCircuit: 'erc'
  firewall: 'afw'
  bastionHost: 'bas'
  natGateway: 'ng'
  
  // Compute
  virtualMachine: 'vm'
  virtualMachineScaleSet: 'vmss'
  availabilitySet: 'avail'
  
  // Containers
  aksCluster: 'aks'
  containerInstance: 'aci'
  containerRegistry: 'acr'
  
  // Storage
  storageAccount: 'st'
  storageAccountVM: 'stvm'
  
  // Databases
  sqlServer: 'sql'
  sqlDatabase: 'sqldb'
  cosmosDb: 'cosmos'
  
  // Web and mobile
  appServicePlan: 'plan'
  appService: 'app'
  functionApp: 'func'
  
  // Identity
  managedIdentity: 'id'
  keyVault: 'kv'
  
  // Monitoring and management
  logAnalyticsWorkspace: 'log'
  applicationInsights: 'appi'
  recoveryServicesVault: 'rsv'
}

// Region abbreviations mapping
var regionAbbreviations = {
  eastus: 'eus'
  eastus2: 'eus2'
  westus: 'wus'
  westus2: 'wus2'
  westus3: 'wus3'
  centralus: 'cus'
  northcentralus: 'ncus'
  southcentralus: 'scus'
  westcentralus: 'wcus'
  canadacentral: 'cac'
  canadaeast: 'cae'
  brazilsouth: 'brs'
  northeurope: 'neu'
  westeurope: 'weu'
  uksouth: 'uks'
  ukwest: 'ukw'
  francecentral: 'frc'
  germanywestcentral: 'gwc'
  norwayeast: 'nwe'
  switzerlandnorth: 'chn'
  swedencentral: 'swc'
  eastasia: 'eas'
  southeastasia: 'seas'
  japaneast: 'jpe'
  japanwest: 'jpw'
  australiaeast: 'aue'
  australiasoutheast: 'ause'
  centralindia: 'inc'
  southindia: 'ins'
  westindia: 'inw'
  koreacentral: 'krc'
  koreasouth: 'krs'
  uaenorth: 'uan'
  southafricanorth: 'san'
}

// Helper function to generate resource name
func generateResourceName(resourceType string) string => '${resourceTypeAbbreviations[resourceType]}-${workloadName}-${environment}-${regionAbbreviation}-${instance}'

// Outputs - Pre-generated names for common resources
output namingConvention object = {
  pattern: '<resource-type>-<workload>-<environment>-<region>-<instance>'
  example: generateResourceName('virtualNetwork')
  
  // Pre-generated names for common resources
  names: {
    // Networking
    virtualNetwork: generateResourceName('virtualNetwork')
    subnet: generateResourceName('subnet')
    networkSecurityGroup: generateResourceName('networkSecurityGroup')
    routeTable: generateResourceName('routeTable')
    publicIpAddress: generateResourceName('publicIpAddress')
    loadBalancer: generateResourceName('loadBalancer')
    applicationGateway: generateResourceName('applicationGateway')
    vpnGateway: generateResourceName('vpnGateway')
    expressRouteCircuit: generateResourceName('expressRouteCircuit')
    firewall: generateResourceName('firewall')
    bastionHost: generateResourceName('bastionHost')
    
    // Compute
    virtualMachine: generateResourceName('virtualMachine')
    virtualMachineScaleSet: generateResourceName('virtualMachineScaleSet')
    availabilitySet: generateResourceName('availabilitySet')
    
    // Containers
    aksCluster: generateResourceName('aksCluster')
    containerRegistry: toLower('${resourceTypeAbbreviations.containerRegistry}${workloadName}${environment}${regionAbbreviation}${instance}') // ACR doesn't allow hyphens
    
    // Storage
    storageAccount: toLower('${resourceTypeAbbreviations.storageAccount}${workloadName}${environment}${regionAbbreviation}${instance}') // Storage accounts don't allow hyphens
    
    // Databases
    sqlServer: generateResourceName('sqlServer')
    sqlDatabase: generateResourceName('sqlDatabase')
    cosmosDb: generateResourceName('cosmosDb')
    
    // Web
    appServicePlan: generateResourceName('appServicePlan')
    appService: generateResourceName('appService')
    functionApp: generateResourceName('functionApp')
    
    // Identity and security
    managedIdentity: generateResourceName('managedIdentity')
    keyVault: '${resourceTypeAbbreviations.keyVault}-${workloadName}-${environment}-${regionAbbreviation}' // Key Vault has 24 char limit
    
    // Management
    logAnalyticsWorkspace: generateResourceName('logAnalyticsWorkspace')
    applicationInsights: generateResourceName('applicationInsights')
    recoveryServicesVault: generateResourceName('recoveryServicesVault')
  }
  
  abbreviations: resourceTypeAbbreviations
  regionAbbreviations: regionAbbreviations
}

output resourceGroupName string = 'rg-${workloadName}-${environment}-${regionAbbreviation}-${instance}'

output validationRules object = {
  enforceStandards: enforceNamingStandards
  maxLengths: {
    resourceGroup: 90
    virtualNetwork: 64
    storageAccount: 24
    keyVault: 24
    sqlServer: 63
  }
  allowedCharacters: {
    general: 'Alphanumeric, hyphen, underscore, period'
    storageAccount: 'Lowercase alphanumeric only'
    keyVault: 'Alphanumeric and hyphen only'
  }
}
