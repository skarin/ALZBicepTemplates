# Audit Evidence Template

## Azure Landing Zone Deployment Evidence

### Overview
This document provides evidence of the Azure Landing Zone deployment for audit and compliance purposes, specifically for Microsoft specialization requirements.

---

## Customer Information

**Customer Name:** `[Customer Name]`  
**Deployment Date:** `[YYYY-MM-DD]`  
**Environment:** `[Production/Development]`  
**Primary Region:** `[Azure Region]`  
**Secondary Region:** `[Azure Region]`

---

## 1. Repeatable Deployment Evidence

### 1.1 Identity Management

#### ✅ Design Area A & B: Azure Tenant and Identity

**Evidence:**
- [ ] Entra ID (Azure Active Directory) configured
- [ ] RBAC role assignments at management group level
- [ ] Managed identities deployed
- [ ] Conditional Access policies configured (manual step)
- [ ] MFA enforced for administrative access

**Bicep Modules Used:**
- `modules/identity/entra-id.bicep`
- `modules/identity/rbac.bicep`
- `modules/identity/managed-identities.bicep`

**Screenshots:**
1. Management group RBAC assignments
2. Entra ID conditional access policies
3. Managed identity configurations

**Configuration Details:**
```
Management Groups Created:
- Root Management Group: [Name]
- Platform Management Groups: Management, Connectivity, Identity
- Landing Zone Management Groups: Corp, Online
- Sandboxes Management Group
```

---

### 1.2 Network Topology and Connectivity

#### ✅ Design Area E: Hybrid Network Architecture

**Evidence:**
- [ ] Hub-spoke network topology deployed
- [ ] ExpressRoute Gateway configured (if applicable)
- [ ] VPN Gateway configured
- [ ] Azure Firewall deployed
- [ ] Azure Bastion deployed
- [ ] Network Security Groups configured
- [ ] Multi-regional redundancy implemented

**Bicep Modules Used:**
- `modules/networking/hub-spoke/hub-vnet.bicep`
- `modules/networking/hub-spoke/spoke-vnet.bicep`
- `modules/networking/hub-spoke/peering.bicep`
- `modules/networking/expressroute.bicep`
- `modules/networking/vpn-gateway.bicep`
- `modules/networking/nsg.bicep`

**Network Architecture:**
```
Hub VNet: [Address Space]
├── Azure Firewall Subnet: [CIDR]
├── Azure Bastion Subnet: [CIDR]
├── Gateway Subnet: [CIDR]
├── Management Subnet: [CIDR]
└── Shared Services Subnet: [CIDR]

Spoke VNets:
- Spoke 1: [Address Space] - Peered to Hub
- Spoke 2: [Address Space] - Peered to Hub
```

**Hybrid Connectivity:**
- **ExpressRoute:** `[Yes/No]` - Circuit ID: `[ID]`
- **VPN Gateway:** `[Yes/No]` - Gateway SKU: `[SKU]`

**Screenshots:**
1. Network topology diagram
2. Hub VNet configuration
3. Gateway configurations
4. Azure Firewall rules
5. Peering status

---

### 1.3 Resource Organization

#### ✅ Design Area C: Management Groups and Tagging

**Evidence:**
- [ ] Management group hierarchy implemented
- [ ] Naming conventions enforced
- [ ] Tagging standards applied
- [ ] Subscription organization configured

**Bicep Modules Used:**
- `modules/management-groups/hierarchy.bicep`
- `modules/naming-conventions/standards.bicep`
- `modules/naming-conventions/tagging-standards.bicep`

**Tagging Standards Enforced:**
| Tag Name | Purpose | Example Value |
|----------|---------|---------------|
| Environment | Deployment environment | Production |
| CostCenter | Cost allocation | IT-1000 |
| BusinessOwner | Business stakeholder | cto@company.com |
| TechnicalOwner | Technical contact | ops@company.com |
| Workload | Application/workload | FinanceApp |
| Criticality | Business impact | Critical |
| DataClassification | Sensitivity level | Confidential |

**Screenshots:**
1. Management group hierarchy
2. Resource tagging examples
3. Azure Policy enforcement for tags

---

## 2. Deployment Approach Evidence

### Approach Used: `[Select One]`

#### ☐ Start Small and Expand
Deployed core infrastructure first, governance added incrementally.

#### ☑ Full Azure Landing Zone (Recommended)
Deployed complete ALZ with all governance and operations configurations from the start.

#### ☐ Alternative Approach
`[Describe custom approach]`

#### ☐ Brownfield Scenario
Updated existing environment to align with ALZ best practices.

**Evidence of Approach:**
- Deployment timeline: `[Date Started]` to `[Date Completed]`
- Phases deployed: `[List phases]`
- Deployment scripts used: `scripts/deploy.ps1` or `scripts/deploy.sh`

---

## 3. Deployment Automation Evidence

### 3.1 Bicep Templates

**Main Orchestration File:** `main.bicep`

**Customer-Specific Parameters:**
- Customer 1: `parameters/customer1.bicepparam`
- Customer 2: `parameters/customer2.bicepparam`

**Deployment Command Used:**
```powershell
./scripts/deploy.ps1 -Customer customer1 -Phase full -Location eastus
```

**Deployment Output:**
```
[Paste deployment output or attach deployment log file]
```

---

### 3.2 ARM Template Validation

**Bicep Build Output:**
```bash
az bicep build --file main.bicep
```

**Validation Result:**
```
[Paste validation output]
```

---

## 4. Multi-Regional Redundancy

### 4.1 Redundancy Policy

**Primary Region:** `[Region]`  
**Secondary Region:** `[Region]`  
**Availability Zones Used:** `[Yes/No]`

**Zone-Redundant Resources:**
- [ ] ExpressRoute Gateway (ErGw1AZ/ErGw2AZ/ErGw3AZ)
- [ ] VPN Gateway (VpnGw1AZ/VpnGw2AZ)
- [ ] Azure Firewall (Standard/Premium with AZ support)
- [ ] Public IP Addresses (Standard SKU with zones)
- [ ] Azure Bastion (Standard tier)

**Geo-Redundant Resources:**
- [ ] Recovery Services Vault (GRS enabled)
- [ ] Log Analytics Workspace (data replication)
- [ ] Storage Accounts (GRS/GZRS)

**Screenshots:**
1. Availability zone configuration
2. Geo-replication settings

---

## 5. Azure Landing Zone Review Assessment

### Assessment Completion

**Assessment Link:** [Azure Landing Zone Review](https://learn.microsoft.com/en-us/assessments/?mode=pre-assessment&id=azure-landing-zone-review)

**Assessment Date:** `[YYYY-MM-DD]`  
**Assessment Score:** `[Score/Total]`

**Key Findings:**
- Multi-regional redundancy: `[Pass/Fail]`
- Security baseline: `[Pass/Fail]`
- Governance policies: `[Pass/Fail]`
- Network topology: `[Pass/Fail]`

**Assessment Report:** `[Attach PDF or provide link]`

---

## 6. Compliance and Governance

### 6.1 Azure Policy Assignments

**Policies Deployed:**
- [ ] Azure Security Benchmark
- [ ] Tagging policy (required tags)
- [ ] Naming convention policy
- [ ] Encryption at rest policy
- [ ] HTTPS-only policy for storage
- [ ] Diagnostic settings policy

**Policy Compliance Status:**
```
Policy: Azure Security Benchmark
Status: [Compliant/Non-Compliant]
Resources: [X] compliant, [Y] non-compliant

Policy: Required Tags
Status: [Compliant/Non-Compliant]
Resources: [X] compliant, [Y] non-compliant
```

**Screenshots:**
1. Policy assignments at management group
2. Compliance dashboard
3. Policy remediation tasks

---

### 6.2 Security Configuration

**Microsoft Defender for Cloud:**
- [ ] Defender for Servers: Enabled
- [ ] Defender for Storage: Enabled
- [ ] Defender for SQL: Enabled
- [ ] Defender for Containers: Enabled
- [ ] Defender for Key Vault: Enabled
- [ ] Defender for Resource Manager: Enabled
- [ ] Defender for DNS: Enabled

**Security Score:** `[Score]%`

**Security Contacts Configured:**
- Primary: `[Email]`
- Secondary: `[Email]`

**Screenshots:**
1. Defender for Cloud dashboard
2. Security score
3. Recommendations and alerts

---

### 6.3 Monitoring and Logging

**Log Analytics Workspace:**
- Workspace ID: `[ID]`
- Retention Period: `[90] days`
- Daily Cap: `[Enabled/Disabled]`

**Solutions Deployed:**
- [ ] Security Solution
- [ ] Update Management
- [ ] Change Tracking
- [ ] VM Insights
- [ ] Container Insights
- [ ] Key Vault Analytics

**Alert Rules Configured:**
- High CPU usage
- High memory usage
- Low disk space
- VM unavailable

**Screenshots:**
1. Log Analytics workspace configuration
2. Solutions deployed
3. Alert rules

---

## 7. Deployment Evidence Summary

### Customer 1 Deployment

**Organization:** `[Name]`  
**Deployment Date:** `[Date]`  
**Deployment Duration:** `[HH:MM]`  
**Deployment Status:** `[Success/Failed]`

**Key Resources Deployed:**
| Resource Type | Resource Name | Status |
|---------------|---------------|--------|
| Management Groups | [Count] groups | ✅ |
| Hub VNet | [Name] | ✅ |
| ExpressRoute Gateway | [Name] | ✅ |
| VPN Gateway | [Name] | ✅ |
| Azure Firewall | [Name] | ✅ |
| Azure Bastion | [Name] | ✅ |
| Log Analytics | [Name] | ✅ |
| Recovery Vault | [Name] | ✅ |

---

### Customer 2 Deployment

**Organization:** `[Name]`  
**Deployment Date:** `[Date]`  
**Deployment Duration:** `[HH:MM]`  
**Deployment Status:** `[Success/Failed]`

**Key Resources Deployed:**
| Resource Type | Resource Name | Status |
|---------------|---------------|--------|
| Management Groups | [Count] groups | ✅ |
| Hub VNet | [Name] | ✅ |
| VPN Gateway | [Name] | ✅ |
| Azure Firewall | [Name] | ✅ |
| Azure Bastion | [Name] | ✅ |
| Log Analytics | [Name] | ✅ |
| Recovery Vault | [Name] | ✅ |

**Note:** Customer 2 uses VPN Gateway only (no ExpressRoute)

---

## 8. Audit Checklist

### Required Evidence Checklist

- [ ] Two (2) unique customer deployments completed
- [ ] Bicep/ARM templates provided and documented
- [ ] Parameter files for both customers included
- [ ] Deployment scripts (PowerShell/Bash) included
- [ ] Identity management configured (Entra ID)
- [ ] Network topology implemented (hub-spoke)
- [ ] Hybrid connectivity enabled (ExpressRoute and/or VPN)
- [ ] Resource organization standards applied (tags, naming)
- [ ] Management groups hierarchy created
- [ ] Azure Policy assignments configured
- [ ] Multi-regional redundancy policy configured
- [ ] Azure Landing Zone Review assessment completed
- [ ] Security baseline implemented (Microsoft Defender)
- [ ] Monitoring and logging configured (Log Analytics)
- [ ] Backup policies configured
- [ ] Documentation complete and comprehensive

---

## 9. Supporting Documentation

### Files Attached

1. `main.bicep` - Main orchestration template
2. `parameters/customer1.bicepparam` - Customer 1 parameters
3. `parameters/customer2.bicepparam` - Customer 2 parameters
4. `scripts/deploy.ps1` - PowerShell deployment script
5. `scripts/deploy.sh` - Bash deployment script
6. `scripts/validate.ps1` - Validation script
7. `README.md` - Solution documentation
8. Deployment logs for both customers
9. Azure Landing Zone Review assessment reports
10. Architecture diagrams
11. Screenshots of key configurations

---

## 10. Sign-Off

**Prepared By:**  
Name: `[Name]`  
Title: `[Title]`  
Date: `[YYYY-MM-DD]`  
Signature: `___________________`

**Reviewed By:**  
Name: `[Name]`  
Title: `[Title]`  
Date: `[YYYY-MM-DD]`  
Signature: `___________________`

**Approved By:**  
Name: `[Name]`  
Title: `[Title]`  
Date: `[YYYY-MM-DD]`  
Signature: `___________________`

---

## Appendix

### A. Deployment Logs
[Attach full deployment logs]

### B. Azure Landing Zone Review Reports
[Attach assessment reports]

### C. Architecture Diagrams
[Attach network and management group diagrams]

### D. Policy Compliance Reports
[Attach Azure Policy compliance reports]

### E. Security Configuration Details
[Attach Defender for Cloud configuration]
