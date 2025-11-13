#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Azure Landing Zone Validation Script

.DESCRIPTION
    This script validates the Azure Landing Zone deployment prerequisites
    and Bicep template syntax before actual deployment.

.PARAMETER Customer
    Customer parameter file name (optional, validates all if not specified)

.EXAMPLE
    ./validate.ps1

.EXAMPLE
    ./validate.ps1 -Customer customer1

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Customer = $null
)

$ErrorActionPreference = "Continue"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootPath = Split-Path -Parent $ScriptPath
$ValidationErrors = 0
$ValidationWarnings = 0

function Write-Info { param([string]$Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-ValidationError { 
    param([string]$Message) 
    Write-Host "❌ $Message" -ForegroundColor Red
    $script:ValidationErrors++
}
function Write-ValidationWarning { 
    param([string]$Message) 
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
    $script:ValidationWarnings++
}

Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║         Azure Landing Zone Validation Script                   ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Blue

Write-Host ""

# 1. Check Azure CLI
Write-Info "Checking Azure CLI..."
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Success "Azure CLI installed: $($azVersion.'azure-cli')"
    
    $minVersion = [Version]"2.50.0"
    $currentVersion = [Version]($azVersion.'azure-cli')
    if ($currentVersion -lt $minVersion) {
        Write-ValidationWarning "Azure CLI version $currentVersion is below recommended $minVersion"
    }
} catch {
    Write-ValidationError "Azure CLI is not installed or not in PATH"
}

# 2. Check Bicep CLI
Write-Info "Checking Bicep CLI..."
try {
    $bicepVersion = az bicep version
    Write-Success "Bicep CLI installed: $bicepVersion"
} catch {
    Write-ValidationError "Bicep CLI is not installed. Run 'az bicep install'"
}

# 3. Check Azure login
Write-Info "Checking Azure authentication..."
try {
    $account = az account show | ConvertFrom-Json
    Write-Success "Authenticated as: $($account.user.name)"
    Write-Success "Subscription: $($account.name)"
    
    # Check tenant-level permissions
    Write-Info "Checking tenant permissions..."
    try {
        az account management-group list --query "[0]" -o json | Out-Null
        Write-Success "Tenant-level access confirmed"
    } catch {
        Write-ValidationWarning "Unable to list management groups. Ensure you have tenant-level permissions."
    }
} catch {
    Write-ValidationError "Not authenticated to Azure. Run 'az login'"
}

Write-Host ""

# 4. Validate directory structure
Write-Info "Validating directory structure..."
$requiredPaths = @(
    "main.bicep",
    "modules/identity",
    "modules/management-groups",
    "modules/networking",
    "modules/security",
    "modules/management",
    "policies/governance",
    "policies/security-baseline",
    "parameters",
    "scripts"
)

foreach ($path in $requiredPaths) {
    $fullPath = Join-Path $RootPath $path
    if (Test-Path $fullPath) {
        Write-Success "Found: $path"
    } else {
        Write-ValidationError "Missing: $path"
    }
}

Write-Host ""

# 5. Validate Bicep files
Write-Info "Validating Bicep syntax..."

$bicepFiles = Get-ChildItem -Path $RootPath -Include "*.bicep" -Recurse

foreach ($file in $bicepFiles) {
    Write-Info "Validating: $($file.Name)"
    try {
        $tempDir = Join-Path $RootPath "temp"
        New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
        az bicep build --file $file.FullName --outdir $tempDir 2>&1 | Out-Null
        Write-Success "Valid: $($file.Name)"
    } catch {
        Write-ValidationError "Invalid Bicep file: $($file.Name) - $($_.Exception.Message)"
    }
}

Write-Host ""

# 6. Validate parameter files
Write-Info "Validating parameter files..."

if ($Customer) {
    $paramFiles = @(Get-Item (Join-Path $RootPath "parameters" "$Customer.bicepparam") -ErrorAction SilentlyContinue)
} else {
    $paramFiles = Get-ChildItem -Path (Join-Path $RootPath "parameters") -Filter "*.bicepparam"
}

if ($paramFiles.Count -eq 0) {
    Write-ValidationWarning "No parameter files found to validate"
} else {
    foreach ($paramFile in $paramFiles) {
        if ($paramFile) {
            Write-Info "Validating: $($paramFile.Name)"
            
            # Check if file references main.bicep
            $content = Get-Content $paramFile.FullName -Raw
            if ($content -match "using\s+'\.\/main\.bicep'") {
                Write-Success "References main.bicep: $($paramFile.Name)"
            } else {
                Write-ValidationError "Does not reference main.bicep: $($paramFile.Name)"
            }
            
            # Check for required parameters
            $requiredParams = @(
                'organizationName',
                'primaryRegion',
                'managementSubscriptionId',
                'connectivitySubscriptionId',
                'costCenter',
                'businessOwner',
                'technicalOwner'
            )
            
            foreach ($param in $requiredParams) {
                if ($content -match "param\s+$param\s*=") {
                    # Parameter found
                } else {
                    Write-ValidationWarning "Missing parameter '$param' in $($paramFile.Name)"
                }
            }
            
            # Check subscription IDs are not default placeholders
            if ($content -match '00000000-0000-0000-0000-000000000') {
                Write-ValidationWarning "Parameter file contains placeholder subscription IDs: $($paramFile.Name)"
            }
        }
    }
}

Write-Host ""

# 7. Check for best practices
Write-Info "Checking best practices..."

# Check if README exists
if (Test-Path (Join-Path $RootPath "README.md")) {
    Write-Success "README.md exists"
} else {
    Write-ValidationWarning "README.md not found"
}

# Check for deployment scripts
$deployScripts = @("deploy.ps1", "deploy.sh")
foreach ($script in $deployScripts) {
    $scriptPath = Join-Path $RootPath "scripts" $script
    if (Test-Path $scriptPath) {
        Write-Success "Deployment script exists: $script"
    } else {
        Write-ValidationWarning "Deployment script not found: $script"
    }
}

Write-Host ""

# 8. Validate Azure quotas and limits
Write-Info "Checking Azure quotas (this may take a moment)..."
try {
    $location = "eastus"
    $vmQuota = az vm list-usage --location $location --query "[?name.value=='cores'].{limit:limit, currentValue:currentValue}" -o json | ConvertFrom-Json
    if ($vmQuota -and $vmQuota.currentValue -lt ($vmQuota.limit - 20)) {
        Write-Success "VM core quota available: $($vmQuota.currentValue)/$($vmQuota.limit)"
    } else {
        Write-ValidationWarning "VM core quota may be insufficient"
    }
} catch {
    Write-ValidationWarning "Unable to check Azure quotas"
}

Write-Host ""

# Summary
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Blue
Write-Host "VALIDATION SUMMARY" -ForegroundColor Blue
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Blue

if ($ValidationErrors -eq 0 -and $ValidationWarnings -eq 0) {
    Write-Success "All validations passed! ✨"
    Write-Info "You can proceed with deployment using ./deploy.ps1"
    exit 0
} else {
    if ($ValidationErrors -gt 0) {
        Write-Host "❌ Errors: $ValidationErrors" -ForegroundColor Red
        Write-Host "Please fix errors before deploying" -ForegroundColor Red
    }
    if ($ValidationWarnings -gt 0) {
        Write-Host "⚠️  Warnings: $ValidationWarnings" -ForegroundColor Yellow
        Write-Host "Review warnings and proceed with caution" -ForegroundColor Yellow
    }
    
    if ($ValidationErrors -gt 0) {
        exit 1
    } else {
        exit 0
    }
}
