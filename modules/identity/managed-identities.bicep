// ============================================================================
// Design Area B: Identity and Access Management - Managed Identities
// ============================================================================
// This module creates User-Assigned Managed Identities for Azure resources
// to authenticate without storing credentials in code.

targetScope = 'resourceGroup'

// Parameters
@description('The name of the managed identity')
param identityName string

@description('The location where the managed identity will be created')
param location string = resourceGroup().location

@description('Tags to apply to the managed identity')
param tags object = {}

@description('Enable federated identity credential for workload identity')
param enableFederatedIdentity bool = false

@description('Federated identity credential configuration')
param federatedIdentityCredential object = {}

// Managed Identity resource
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
  tags: tags
}

// Federated Identity Credential (for workload identity scenarios like GitHub Actions, AKS)
resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = if (enableFederatedIdentity) {
  parent: managedIdentity
  name: federatedIdentityCredential.?name ?? '${identityName}-federated-cred'
  properties: {
    issuer: federatedIdentityCredential.issuer
    subject: federatedIdentityCredential.subject
    audiences: federatedIdentityCredential.audiences
  }
}

// Outputs
output identityId string = managedIdentity.id
output identityName string = managedIdentity.name
output principalId string = managedIdentity.properties.principalId
output clientId string = managedIdentity.properties.clientId
output tenantId string = managedIdentity.properties.tenantId
