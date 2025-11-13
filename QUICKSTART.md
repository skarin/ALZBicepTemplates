# Quick Start Guide

## Get Started with Azure Landing Zone in 15 Minutes

This guide will help you quickly deploy a test Azure Landing Zone to validate the solution before using it for production customers.

---

## Prerequisites (5 minutes)

### 1. Install Required Tools

**Azure CLI:**
```bash
# macOS
brew install azure-cli

# Windows (PowerShell as Administrator)
winget install Microsoft.AzureCLI

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Bicep CLI:**
```bash
az bicep install
```

**PowerShell (Windows/macOS/Linux):**
```bash
# macOS/Linux
brew install powershell

# Windows - already installed
```

### 2. Login to Azure

```bash
az login
az account list --output table
az account set --subscription "<your-subscription-name>"
```

---

## Quick Deployment (10 minutes)

### Step 1: Clone or Download

```bash
git clone <your-repo-url>
cd "Examinetics Landing Zone Bicep"
```

### Step 2: Update Parameters

Edit `parameters/customer1.bicepparam`:

**CRITICAL - Update these values:**
```bicep
// Line 7: Your organization name
param organizationName = 'YourCompany'

// Line 8: Management group prefix (lowercase, no spaces)
param managementGroupPrefix = 'yourcompany'

// Lines 15-17: YOUR ACTUAL SUBSCRIPTION IDs
param managementSubscriptionId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
param connectivitySubscriptionId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
param identitySubscriptionId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

// Line 24: Update email addresses
param securityContactEmails = ['your-email@company.com']

// Line 32: Update contact info
param costCenter = 'IT-1000'
param businessOwner = 'owner@company.com'
param technicalOwner = 'admin@company.com'
```

### Step 3: Validate

```powershell
./scripts/validate.ps1 -Customer customer1
```

Expected output: "All validations passed! ✨"

### Step 4: Deploy

**WhatIf mode (no actual deployment):**
```powershell
./scripts/deploy.ps1 -Customer customer1 -Location eastus -WhatIf
```

**Full deployment:**
```powershell
./scripts/deploy.ps1 -Customer customer1 -Phase full -Location eastus
```

**Note:** This will take 60-90 minutes due to gateway deployments.

---

## What Gets Deployed

### Management Groups
```
YourCompany (Root)
├── Platform
│   ├── Management
│   ├── Connectivity
│   └── Identity
├── Landing Zones
│   ├── Corp
│   └── Online
├── Sandboxes
└── Decommissioned
```

### Networking (in Connectivity Subscription)
- **Hub VNet** (10.100.0.0/16)
  - Azure Firewall
  - Azure Bastion
  - ExpressRoute Gateway (30-45 min)
  - VPN Gateway (30-45 min)

### Management (in Management Subscription)
- **Log Analytics Workspace** with solutions
- **Action Group** for alerts
- **Recovery Services Vault** with backup policies

### Security
- **Microsoft Defender for Cloud** (all plans)
- **Azure Policy** assignments
  - Azure Security Benchmark
  - Tagging policies
  - Naming conventions

---

## After Deployment

### 1. Review Outputs

Outputs are saved to: `outputs/customer1-<deployment-name>.json`

Key information includes:
- Management group IDs
- Resource IDs
- Configuration details

### 2. Access Resources

**Azure Portal:**
1. Navigate to Management Groups
2. View resource hierarchy
3. Check Policy compliance
4. Review Defender for Cloud

**Azure CLI:**
```bash
# List management groups
az account management-group list

# List resources in connectivity RG
az resource list --resource-group rg-connectivity-Production-eastus-001

# Check policy compliance
az policy state list --management-group yourcompany-root
```

### 3. Next Steps

- [ ] Configure Entra ID Conditional Access (manual)
- [ ] Create spoke virtual networks
- [ ] Configure ExpressRoute circuit connection
- [ ] Set up VPN Site-to-Site connection
- [ ] Deploy workload resources
- [ ] Run Azure Landing Zone Review assessment

---

## Quick Commands Reference

### Validation
```powershell
# Validate prerequisites and templates
./scripts/validate.ps1 -Customer customer1
```

### Deployment
```powershell
# Test deployment (no changes made)
./scripts/deploy.ps1 -Customer customer1 -Location eastus -WhatIf

# Full deployment
./scripts/deploy.ps1 -Customer customer1 -Phase full -Location eastus

# Deploy only core (no gateways - faster for testing)
./scripts/deploy.ps1 -Customer customer1 -Phase core -Location eastus
```

### Verification
```bash
# Check deployment status
az deployment mg show --name <deployment-name> --management-group yourcompany-root

# List all resources
az resource list --output table

# Check policy compliance
az policy state summarize --management-group yourcompany-root
```

---

## Deployment Phases Explained

### Phase: `full` (Default)
- Management groups
- Hub networking with gateways
- Security baseline
- Monitoring and backup
- **Duration:** 60-90 minutes

### Phase: `core`
- Management groups
- Hub networking WITHOUT gateways
- Basic security
- **Duration:** 15-20 minutes
- **Use case:** Quick testing

### Phase: `governance`
- Azure Policies only
- Tagging and naming enforcement
- **Duration:** 5 minutes

---

## Troubleshooting

### Issue: "Not logged in to Azure"
```bash
az login
az account set --subscription "<subscription-name>"
```

### Issue: "Bicep CLI not found"
```bash
az bicep install
az bicep version
```

### Issue: "Insufficient permissions"
**Solution:** You need Owner role at:
- Management Group level, OR
- Tenant root level

**Check permissions:**
```bash
az role assignment list --include-inherited --output table
```

### Issue: "Subscription not found"
**Solution:** Update parameter file with correct subscription IDs:
```bash
# List your subscriptions
az account list --output table

# Copy the subscription IDs to customer1.bicepparam
```

### Issue: "Address space conflict"
**Solution:** Each deployment needs unique IP ranges:
- Customer 1: 10.100.0.0/16
- Customer 2: 10.200.0.0/16
- Update `hubVNetConfig.addressSpace` in parameter file

---

## Clean Up (Optional)

To remove all deployed resources:

### Delete Resource Groups
```bash
az group delete --name rg-connectivity-Production-eastus-001 --yes --no-wait
az group delete --name rg-management-Production-eastus-001 --yes --no-wait
```

### Delete Management Groups
```bash
# Delete in reverse order (children first)
az account management-group delete --name yourcompany-decommissioned
az account management-group delete --name yourcompany-sandboxes
az account management-group delete --name yourcompany-landingzones-online
az account management-group delete --name yourcompany-landingzones-corp
az account management-group delete --name yourcompany-landingzones
az account management-group delete --name yourcompany-platform-identity
az account management-group delete --name yourcompany-platform-connectivity
az account management-group delete --name yourcompany-platform-management
az account management-group delete --name yourcompany-platform
az account management-group delete --name yourcompany-root
```

**Note:** Management groups have a 24-hour soft-delete retention period.

---

## For Production Deployments

When ready for actual customer deployments:

1. **Review and customize:**
   - Update all email addresses
   - Set appropriate IP address ranges
   - Configure hybrid connectivity details
   - Adjust security policies as needed

2. **Use customer-specific parameters:**
   - `customer1.bicepparam` - First customer
   - `customer2.bicepparam` - Second customer

3. **Document everything:**
   - Use `docs/audit-evidence-template.md`
   - Take screenshots at each step
   - Save deployment outputs
   - Run Azure Landing Zone Review assessment

4. **Follow the runbook:**
   - `docs/deployment-runbook.md` has complete steps
   - Includes post-deployment configuration
   - Contains troubleshooting guide

---

## Getting Help

### Documentation
- `README.md` - Complete solution overview
- `docs/deployment-runbook.md` - Detailed deployment guide
- `docs/architecture-diagram.md` - Architecture explanation
- `docs/audit-evidence-template.md` - Audit compliance checklist

### Microsoft Resources
- [Azure Landing Zone Docs](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure CLI Reference](https://learn.microsoft.com/en-us/cli/azure/)

---

## Quick Win: Deploy in 3 Commands

For the impatient (after updating parameter file):

```powershell
# 1. Validate
./scripts/validate.ps1 -Customer customer1

# 2. WhatIf check
./scripts/deploy.ps1 -Customer customer1 -Location eastus -WhatIf

# 3. Deploy
./scripts/deploy.ps1 -Customer customer1 -Phase full -Location eastus
```

Then grab a coffee ☕ - deployment takes 60-90 minutes!

---

**🎉 You're ready to deploy Azure Landing Zones! 🎉**
