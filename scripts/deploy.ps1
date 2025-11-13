#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Azure Landing Zone Deployment Script

.DESCRIPTION
    This script deploys the Azure Landing Zone using Bicep templates.
    It supports full, phased, and brownfield deployments.

.PARAMETER Customer
    Customer parameter file name (e.g., customer1, customer2)

.PARAMETER Phase
    Deployment phase: full, core, governance, or specific component

.PARAMETER Location
    Primary Azure region for deployment

.PARAMETER WhatIf
    Performs a validation-only deployment (no actual deployment)

.PARAMETER Mode
    Deployment mode: greenfield (new) or brownfield (existing)

.EXAMPLE
    ./deploy.ps1 -Customer customer1 -Phase full -Location eastus

.EXAMPLE
    ./deploy.ps1 -Customer customer2 -Phase core -WhatIf

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Customer,

    [Parameter(Mandatory = $false)]
    [ValidateSet('full', 'core', 'governance', 'management', 'connectivity', 'security')]
    [string]$Phase = 'full',

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,

    [Parameter(Mandatory = $false)]
    [ValidateSet('greenfield', 'brownfield')]
    [string]$Mode = 'greenfield',

    [Parameter(Mandatory = $false)]
    [string]$ManagementGroupId = $null
)

# Script variables
$ErrorActionPreference = "Stop"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootPath = Split-Path -Parent $ScriptPath
$ParameterFile = Join-Path $RootPath "parameters" "$Customer.bicepparam"
$MainBicepFile = Join-Path $RootPath "main.bicep"
$DeploymentName = "alz-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Color output functions
function Write-Info { param([string]$Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Error { param([string]$Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Warning { param([string]$Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }

# Banner
Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║         Azure Landing Zone Deployment Script                   ║
║         Bicep Implementation - Audit Ready                      ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Blue

Write-Info "Customer: $Customer"
Write-Info "Phase: $Phase"
Write-Info "Location: $Location"
Write-Info "Mode: $Mode"
Write-Info "WhatIf: $WhatIf"
Write-Host ""

# Prerequisites check
Write-Info "Checking prerequisites..."

# Check Azure CLI
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Success "Azure CLI version: $($azVersion.'azure-cli')"
} catch {
    Write-Error "Azure CLI is not installed or not in PATH"
    exit 1
}

# Check Bicep CLI
try {
    $bicepVersion = az bicep version
    Write-Success "Bicep CLI version: $bicepVersion"
} catch {
    Write-Warning "Bicep CLI not found. Installing..."
    az bicep install
}

# Check if logged in
try {
    $account = az account show | ConvertFrom-Json
    Write-Success "Logged in as: $($account.user.name)"
    Write-Success "Subscription: $($account.name) ($($account.id))"
} catch {
    Write-Error "Not logged in to Azure. Please run 'az login'"
    exit 1
}

# Check parameter file
if (-not (Test-Path $ParameterFile)) {
    Write-Error "Parameter file not found: $ParameterFile"
    exit 1
}
Write-Success "Parameter file found: $ParameterFile"

# Check main Bicep file
if (-not (Test-Path $MainBicepFile)) {
    Write-Error "Main Bicep file not found: $MainBicepFile"
    exit 1
}
Write-Success "Main Bicep file found: $MainBicepFile"

Write-Host ""

# Validate Bicep template
Write-Info "Validating Bicep template..."
try {
    az bicep build --file $MainBicepFile --outdir (Join-Path $RootPath "temp")
    Write-Success "Bicep template validation passed"
} catch {
    Write-Error "Bicep template validation failed: $_"
    exit 1
}

Write-Host ""

# Determine deployment scope
if ($ManagementGroupId) {
    $deploymentScope = "mg"
    Write-Info "Deploying to Management Group: $ManagementGroupId"
} else {
    $deploymentScope = "tenant"
    Write-Info "Deploying at Tenant scope"
    Write-Warning "Ensure you have tenant-level permissions"
}

Write-Host ""

# Build deployment command
$deployCommand = @(
    "az", "deployment", $deploymentScope, "create"
    "--name", $DeploymentName
    "--location", $Location
    "--template-file", $MainBicepFile
    "--parameters", $ParameterFile
)

if ($ManagementGroupId -and $deploymentScope -eq "mg") {
    $deployCommand += "--management-group-id", $ManagementGroupId
}

if ($WhatIf) {
    $deployCommand += "--what-if"
    Write-Warning "Running in WhatIf mode - no resources will be deployed"
}

Write-Host ""

# Confirmation prompt (skip if WhatIf)
if (-not $WhatIf) {
    Write-Warning "This will deploy Azure Landing Zone resources."
    Write-Warning "This may incur costs in your Azure subscription."
    $confirmation = Read-Host "Do you want to continue? (yes/no)"
    
    if ($confirmation -ne "yes") {
        Write-Info "Deployment cancelled by user"
        exit 0
    }
}

Write-Host ""

# Execute deployment
Write-Info "Starting deployment..."
Write-Info "Deployment name: $DeploymentName"
Write-Host ""

try {
    $startTime = Get-Date
    
    # Execute deployment
    & $deployCommand[0] $deployCommand[1..($deployCommand.Length-1)]
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host ""
    Write-Success "Deployment completed successfully!"
    Write-Info "Duration: $($duration.ToString('hh\:mm\:ss'))"
    
    # Get deployment outputs
    Write-Host ""
    Write-Info "Retrieving deployment outputs..."
    
    $outputCommand = @(
        "az", "deployment", $deploymentScope, "show"
        "--name", $DeploymentName
    )
    
    if ($ManagementGroupId -and $deploymentScope -eq "mg") {
        $outputCommand += "--management-group-id", $ManagementGroupId
    }
    
    $outputs = & $outputCommand[0] $outputCommand[1..($outputCommand.Length-1)] --query "properties.outputs" -o json | ConvertFrom-Json
    
    Write-Success "Deployment outputs:"
    $outputs | ConvertTo-Json -Depth 10 | Write-Host
    
    # Save outputs to file
    $outputFile = Join-Path $RootPath "outputs" "$Customer-$DeploymentName.json"
    New-Item -ItemType Directory -Force -Path (Split-Path $outputFile) | Out-Null
    $outputs | ConvertTo-Json -Depth 10 | Set-Content $outputFile
    Write-Success "Outputs saved to: $outputFile"
    
} catch {
    Write-Error "Deployment failed: $_"
    Write-Error "Check Azure Portal for detailed error messages"
    exit 1
}

Write-Host ""

# Next steps
Write-Info "Next Steps:"
Write-Host "1. Review deployment outputs above" -ForegroundColor Yellow
Write-Host "2. Configure Entra ID conditional access policies" -ForegroundColor Yellow
Write-Host "3. Connect ExpressRoute circuit (if applicable)" -ForegroundColor Yellow
Write-Host "4. Create spoke virtual networks" -ForegroundColor Yellow
Write-Host "5. Run Azure Landing Zone Review assessment" -ForegroundColor Yellow
Write-Host "6. Document configuration for audit evidence" -ForegroundColor Yellow

Write-Host ""
Write-Success "Deployment script completed"
