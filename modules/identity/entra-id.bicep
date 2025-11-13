// ============================================================================
// Design Area A & B: Tenant and Identity - Entra ID (Azure AD) Configuration
// ============================================================================
// This module establishes identity baselines including conditional access
// policies, named locations, and identity protection settings.
// Note: Some Entra ID configurations require Microsoft Graph API and may need
// to be configured outside of ARM/Bicep using Azure CLI or PowerShell.

targetScope = 'subscription'

// Parameters
@description('Enable Entra ID Conditional Access policies')
param enableConditionalAccess bool = true

@description('Named locations for conditional access (office IPs, trusted locations)')
param namedLocations array = []

@description('Emergency access (break-glass) account UPNs')
param emergencyAccessAccounts array = []

@description('Entra ID Premium features enabled')
param entraIdPremiumEnabled bool = true

@description('Tags for documentation purposes')
param tags object = {}

// Note: Direct Entra ID resource configuration requires Azure AD provider
// which is not available in standard ARM/Bicep deployments.
// This module serves as documentation and can integrate with:
// 1. Azure CLI commands in deployment scripts
// 2. Microsoft Graph API calls
// 3. Azure Policy for Entra ID governance

// Outputs for integration with deployment scripts
output configuration object = {
  conditionalAccessEnabled: enableConditionalAccess
  namedLocationsCount: length(namedLocations)
  emergencyAccountsConfigured: length(emergencyAccessAccounts)
  premiumFeaturesEnabled: entraIdPremiumEnabled
  recommendedSettings: {
    mfaRequired: true
    selfServicePasswordReset: true
    securityDefaults: false // Use Conditional Access instead
    passwordProtection: true
    identityProtection: entraIdPremiumEnabled
    privilegedIdentityManagement: entraIdPremiumEnabled
  }
}

// Configuration documentation
output deploymentInstructions string = '''
To complete Entra ID configuration, run these Azure CLI commands:

# Enable MFA for all users via Conditional Access
az rest --method put --url "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies" --body "@conditional-access-mfa.json"

# Configure named locations
az rest --method post --url "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations" --body "@named-locations.json"

# Enable Identity Protection
az security pricing create --name "Servers" --tier "Standard"

# Configure PIM settings (if Premium P2 enabled)
# See: https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/
'''
