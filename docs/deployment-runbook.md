# Azure Landing Zone Deployment Runbook

## Purpose
This runbook provides step-by-step instructions for deploying the Azure Landing Zone using the provided Bicep templates. Follow this guide to ensure a consistent, repeatable deployment that meets audit requirements.

---

## Prerequisites

### 1. Azure Subscriptions
You need at least three Azure subscriptions:
- **Management Subscription** - For platform management resources (Log Analytics, monitoring, backup)
- **Connectivity Subscription** - For networking resources (hub VNet, gateways, firewall)
- **Identity Subscription** - For identity services (optional, can use Management subscription)

### 2. Azure Permissions
- **Tenant Root** - Owner or User Access Administrator role
- **Management Group** - Ability to create and manage management groups
- **Subscriptions** - Owner role on all target subscriptions

### 3. Tools Required
- Azure CLI 2.50+ ([Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- Bicep CLI 0.20+ (Install: `az bicep install`)
- PowerShell 7+ or Bash shell
- Git (optional, for version control)

### 4. Network Planning
Document the following before deployment:
- Hub VNet address space (e.g., 10.100.0.0/16)
- Subnet allocations for firewall, bastion, gateway, management
- On-premises network ranges (for ExpressRoute/VPN configuration)
- DNS server addresses (if custom DNS required)

---

## Phase 1: Pre-Deployment

### Step 1: Clone or Download Repository
```bash
git clone <repository-url>
cd "Examinetics Landing Zone Bicep"
```

### Step 2: Authenticate to Azure
```bash
az login
az account set --subscription "<subscription-id>"
```

### Step 3: Verify Tenant Permissions
```bash
# Check if you can list management groups
az account management-group list

# If no access, request Owner role at tenant root or specific management group
```

### Step 4: Configure Customer Parameters

Edit the appropriate parameter file:
- `parameters/customer1.bicepparam` for first customer
- `parameters/customer2.bicepparam` for second customer

**Required Updates:**
1. Replace `organizationName` with customer name
2. Update `managementGroupPrefix` (lowercase, no spaces)
3. Set `primaryRegion` and `secondaryRegion`
4. **CRITICAL:** Replace subscription IDs:
   - `managementSubscriptionId`
   - `connectivitySubscriptionId`
   - `identitySubscriptionId`
5. Update `hubVNetConfig` address spaces to avoid conflicts
6. Set `costCenter`, `businessOwner`, `technicalOwner` emails
7. Configure `securityContactEmails`
8. Adjust `complianceRequirements` as needed

### Step 5: Run Validation Script

#### PowerShell:
```powershell
./scripts/validate.ps1 -Customer customer1
```

#### Bash:
```bash
chmod +x ./scripts/validate.sh
./scripts/validate.sh -c customer1
```

**Expected Output:**
- All validations passed
- No errors
- Warnings (if any) are reviewed and acceptable

---

## Phase 2: Deployment

### Step 1: Perform WhatIf Deployment

Test the deployment without making changes:

#### PowerShell:
```powershell
./scripts/deploy.ps1 -Customer customer1 -Location eastus -WhatIf
```

#### Bash:
```bash
./scripts/deploy.sh -c customer1 -l eastus --what-if
```

**Review:**
- Resources to be created
- Configuration changes
- Any potential issues

### Step 2: Execute Deployment

Deploy the Azure Landing Zone:

#### PowerShell:
```powershell
./scripts/deploy.ps1 -Customer customer1 -Phase full -Location eastus
```

#### Bash:
```bash
./scripts/deploy.sh -c customer1 -p full -l eastus
```

**Deployment Timeline:**
- Management Groups: ~2-5 minutes
- Hub Network: ~10-15 minutes
- ExpressRoute Gateway: ~30-45 minutes
- VPN Gateway: ~30-45 minutes
- Azure Firewall: ~5-10 minutes
- Policies and Defender: ~5-10 minutes

**Total Expected Time: 60-90 minutes**

### Step 3: Monitor Deployment

1. **Azure Portal:**
   - Navigate to Subscriptions → Deployments
   - Monitor deployment progress
   - Check for any errors

2. **CLI:**
   ```bash
   az deployment tenant show --name <deployment-name>
   ```

3. **Deployment Logs:**
   - Automatically saved to `outputs/` directory
   - Review for any warnings or errors

---

## Phase 3: Post-Deployment Configuration

### Step 1: Configure Entra ID (Manual Steps)

These steps cannot be automated via Bicep:

1. **Enable Conditional Access:**
   - Navigate to Entra ID → Security → Conditional Access
   - Create policy: Require MFA for all administrators
   - Create policy: Require MFA for Azure management

2. **Configure Emergency Access Accounts:**
   - Create 2 break-glass accounts
   - Document credentials securely
   - Exclude from Conditional Access policies

3. **Enable Identity Protection:**
   - Navigate to Entra ID → Security → Identity Protection
   - Review and configure risk policies

### Step 2: Configure Hybrid Connectivity

#### For ExpressRoute:
```bash
# Create ExpressRoute circuit (if not exists)
az network express-route create \
  --name <circuit-name> \
  --resource-group <resource-group> \
  --bandwidth 50 \
  --provider "<provider-name>" \
  --peering-location "<location>" \
  --sku-tier Standard \
  --sku-family MeteredData

# Create connection
az network vpn-connection create \
  --name <connection-name> \
  --resource-group <resource-group> \
  --vnet-gateway1 <gateway-id> \
  --express-route-circuit2 <circuit-id>
```

#### For VPN:
```bash
# Create local network gateway
az network local-gateway create \
  --name <local-gateway-name> \
  --resource-group <resource-group> \
  --gateway-ip-address <on-prem-ip> \
  --local-address-prefixes <on-prem-cidr>

# Create VPN connection
az network vpn-connection create \
  --name <connection-name> \
  --resource-group <resource-group> \
  --vnet-gateway1 <gateway-id> \
  --local-gateway2 <local-gateway-id> \
  --shared-key <pre-shared-key>
```

### Step 3: Create Spoke Virtual Networks

For each workload:

```bash
# Deploy spoke network
az deployment group create \
  --resource-group rg-workload-prod-eastus-001 \
  --template-file modules/networking/hub-spoke/spoke-vnet.bicep \
  --parameters \
    spokeVNetName=vnet-workload-prod-eastus-001 \
    spokeVNetAddressSpace='["10.110.0.0/16"]' \
    applicationSubnets='[{"name":"AppSubnet","addressPrefix":"10.110.1.0/24"}]' \
    dataSubnets='[{"name":"DataSubnet","addressPrefix":"10.110.2.0/24"}]'

# Create peering to hub
az deployment group create \
  --resource-group rg-connectivity-prod-eastus-001 \
  --template-file modules/networking/hub-spoke/peering.bicep \
  --parameters \
    hubVNetName=vnet-hub-prod-eastus-001 \
    hubVNetId=<hub-vnet-id> \
    spokeVNetName=vnet-workload-prod-eastus-001 \
    spokeVNetId=<spoke-vnet-id>
```

### Step 4: Configure Azure Firewall Rules

Create application and network rules as needed:

```bash
# Create application rule collection
az network firewall application-rule create \
  --collection-name AllowWeb \
  --firewall-name <firewall-name> \
  --priority 100 \
  --action Allow \
  --name AllowHTTPS \
  --protocols Https=443 \
  --source-addresses 10.100.0.0/16 \
  --target-fqdns '*.microsoft.com' '*.azure.com'

# Create network rule collection
az network firewall network-rule create \
  --collection-name AllowDNS \
  --firewall-name <firewall-name> \
  --priority 200 \
  --action Allow \
  --name AllowDNS \
  --protocols UDP \
  --source-addresses 10.100.0.0/16 \
  --destination-addresses '*' \
  --destination-ports 53
```

### Step 5: Configure Backup Policies

Enable backup for VMs and other resources:

```bash
# Enable VM backup
az backup protection enable-for-vm \
  --resource-group <vm-resource-group> \
  --vault-name <vault-name> \
  --vm <vm-name> \
  --policy-name DefaultVMPolicy
```

### Step 6: Enable Microsoft Sentinel (Optional)

For advanced SIEM capabilities:

```bash
az sentinel workspace create \
  --resource-group <management-rg> \
  --workspace-name <log-analytics-workspace-name>
```

---

## Phase 4: Validation and Testing

### Step 1: Run Azure Landing Zone Review

1. Navigate to: [Azure Landing Zone Review Assessment](https://learn.microsoft.com/en-us/assessments/?mode=pre-assessment&id=azure-landing-zone-review)
2. Complete the assessment for your deployment
3. Review recommendations
4. Document results for audit evidence

### Step 2: Verify Network Connectivity

#### Test Hub Network:
```bash
# Check firewall status
az network firewall show --name <firewall-name> --resource-group <rg-name>

# Check gateway status
az network vnet-gateway show --name <gateway-name> --resource-group <rg-name>

# Check peering status
az network vnet peering list --vnet-name <vnet-name> --resource-group <rg-name>
```

#### Test Hybrid Connectivity:
- VPN: Verify connection status in Azure Portal
- ExpressRoute: Check circuit provisioning and BGP status

### Step 3: Verify Security Configuration

```bash
# Check Defender status
az security pricing list

# Check policy compliance
az policy state list \
  --management-group <mg-name> \
  --filter "complianceState eq 'NonCompliant'"

# Review security score
az security secure-score list
```

### Step 4: Test Monitoring and Alerting

1. Verify Log Analytics data ingestion
2. Test alert rules by simulating conditions
3. Confirm action group notifications

---

## Phase 5: Documentation for Audit

### Step 1: Collect Deployment Evidence

1. **Deployment Outputs:**
   - Located in `outputs/` directory
   - Contains all resource IDs and configurations

2. **Screenshots:**
   - Management group hierarchy
   - Network topology diagram
   - Policy compliance dashboard
   - Security score
   - Defender for Cloud status

3. **Configuration Files:**
   - Customer parameter files
   - Bicep templates
   - Deployment scripts

### Step 2: Complete Audit Evidence Template

1. Open `docs/audit-evidence-template.md`
2. Fill in all sections with actual values
3. Attach screenshots and reports
4. Document any deviations from standard deployment

### Step 3: Run Compliance Reports

```bash
# Export policy compliance report
az policy state list \
  --management-group <mg-name> \
  --output json > compliance-report.json

# Export security recommendations
az security assessment list \
  --output json > security-assessment.json
```

---

## Phase 6: Repeat for Second Customer

### Step 1: Update Parameters

Edit `parameters/customer2.bicepparam`:
- Different organization name
- Different subscription IDs
- Different IP address ranges (no conflicts with customer1)
- Different region if desired

### Step 2: Run Validation

```powershell
./scripts/validate.ps1 -Customer customer2
```

### Step 3: Deploy

```powershell
./scripts/deploy.ps1 -Customer customer2 -Phase full -Location westeurope
```

### Step 4: Post-Deployment Configuration

Repeat Phase 3 steps for customer2

### Step 5: Document

Complete audit evidence for customer2

---

## Troubleshooting

### Common Issues

#### 1. Insufficient Permissions
**Error:** "Authorization failed"  
**Solution:** Verify you have Owner role at tenant/management group level

#### 2. Subscription Not Found
**Error:** "Subscription <id> not found"  
**Solution:** Update parameter file with correct subscription IDs

#### 3. IP Address Conflicts
**Error:** "Address space overlaps"  
**Solution:** Use different IP ranges for each customer/environment

#### 4. Gateway Deployment Timeout
**Error:** "Deployment timed out"  
**Solution:** Gateways take 30-45 minutes, check portal for actual status

#### 5. Policy Assignment Conflicts
**Error:** "Policy already assigned"  
**Solution:** Remove existing policy or update assignment name

### Support Resources

- [Azure Landing Zone Documentation](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure CLI Reference](https://learn.microsoft.com/en-us/cli/azure/)

---

## Rollback Procedures

If deployment fails and rollback is required:

### Option 1: Delete Resource Groups
```bash
az group delete --name rg-connectivity-prod-eastus-001 --yes
az group delete --name rg-management-prod-eastus-001 --yes
```

### Option 2: Delete Management Groups
```bash
az account management-group delete --name <mg-name>
```

**Note:** Delete in reverse order (child before parent)

---

## Appendix

### A. Quick Reference Commands

```bash
# Login
az login

# Set subscription
az account set --subscription <id>

# Validate template
./scripts/validate.ps1 -Customer customer1

# Deploy (WhatIf)
./scripts/deploy.ps1 -Customer customer1 -Location eastus -WhatIf

# Deploy (Full)
./scripts/deploy.ps1 -Customer customer1 -Phase full -Location eastus

# Check deployment status
az deployment tenant show --name <deployment-name>

# List resources
az resource list --resource-group <rg-name> --output table
```

### B. Deployment Checklist

- [ ] Prerequisites verified (subscriptions, permissions, tools)
- [ ] Parameter files configured with actual values
- [ ] Validation script passed
- [ ] WhatIf deployment reviewed
- [ ] Full deployment executed successfully
- [ ] Entra ID conditional access configured
- [ ] Hybrid connectivity established
- [ ] Spoke networks created and peered
- [ ] Azure Firewall rules configured
- [ ] Backup policies enabled
- [ ] Azure Landing Zone Review completed
- [ ] Audit evidence documented
- [ ] Second customer deployment completed

### C. Contact Information

**Technical Support:** [Your contact info]  
**Audit Questions:** [Audit team contact]  
**Microsoft Resources:** [Partner support channel]
