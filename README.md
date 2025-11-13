# Azure Landing Zone - Bicep Implementation

## Overview
This repository contains a comprehensive, audit-ready Azure Landing Zone implementation using Bicep modules. The solution is designed to meet Microsoft specialization audit requirements and follows the Azure Cloud Adoption Framework (CAF) Landing Zone conceptual architecture.

## Audit Compliance Mapping

### Repeatable Deployment Requirements ✓
This implementation demonstrates adherence to Azure Landing Zone design areas through a repeatable, modular deployment approach.

#### 1. Identity Management
- **Design Area A & B**: Azure billing/tenant and Identity & Access Management
- **Implementation**: `modules/identity/` - Entra ID integration, RBAC role assignments, managed identities
- **Audit Evidence**: Demonstrated in both customer parameter files

#### 2. Network Topology and Connectivity
- **Design Area E**: Network topology and connectivity
- **Implementation**: `modules/networking/` - Hub-spoke architecture with hybrid connectivity
- **Features**:
  - Hub VNet with Azure Firewall
  - ExpressRoute Gateway for enterprise connectivity
  - VPN Gateway for site-to-site connections
  - Multi-regional redundancy support
  - Network Security Groups and Azure Bastion

#### 3. Resource Organization
- **Design Area C**: Resource organization
- **Implementation**: `modules/management-groups/`, `modules/naming-conventions/`
- **Features**:
  - Management group hierarchy (Platform, Landing Zones, Sandboxes)
  - Tagging standards enforcement
  - Naming convention standards
  - Subscription organization

### Design Areas Coverage

| Design Area | Focus | Implementation |
|------------|-------|----------------|
| **A** | Azure billing and Active Directory tenant | `modules/identity/tenant.bicep` |
| **B** | Identity and access management | `modules/identity/rbac.bicep` |
| **C** | Resource organization | `modules/management-groups/`, `modules/naming-conventions/` |
| **E** | Network topology and connectivity | `modules/networking/hub-spoke/` |
| **F** | Security | `modules/security/`, `policies/security-baseline/` |
| **G/H** | Management and Governance | `modules/management/`, `policies/governance/` |
| **I** | Platform automation and DevOps | `main.bicep`, `scripts/deploy.ps1` |

## Deployment Approaches

This solution supports both ALZ deployment approaches:

### 1. Start Small and Expand
Deploy core infrastructure first, add governance later:
```bash
./scripts/deploy.ps1 -Customer customer1 -Phase core
./scripts/deploy.ps1 -Customer customer1 -Phase governance
```

### 2. Full ALZ (Recommended for Audit)
Deploy complete configuration including governance and operations:
```bash
./scripts/deploy.ps1 -Customer customer1 -Phase full
```

### 3. Brownfield Scenario Support
Update existing environments to align with CAF best practices:
```bash
./scripts/deploy.ps1 -Customer customer1 -Mode brownfield
```

## Repository Structure

```
.
├── main.bicep                          # Main orchestration file
├── README.md                           # This file
├── modules/                            # Reusable Bicep modules
│   ├── identity/                       # Design Area A & B
│   │   ├── entra-id.bicep
│   │   ├── rbac.bicep
│   │   └── managed-identities.bicep
│   ├── management-groups/              # Design Area C
│   │   ├── hierarchy.bicep
│   │   └── subscriptions.bicep
│   ├── naming-conventions/             # Design Area C
│   │   └── standards.bicep
│   ├── networking/                     # Design Area E
│   │   ├── hub-spoke/
│   │   │   ├── hub-vnet.bicep
│   │   │   ├── spoke-vnet.bicep
│   │   │   └── peering.bicep
│   │   ├── expressroute.bicep
│   │   ├── vpn-gateway.bicep
│   │   ├── firewall.bicep
│   │   └── nsg.bicep
│   ├── security/                       # Design Area F
│   │   ├── defender.bicep
│   │   ├── key-vault.bicep
│   │   └── security-baseline.bicep
│   └── management/                     # Design Area G & H
│       ├── log-analytics.bicep
│       ├── monitoring.bicep
│       └── backup.bicep
├── policies/                           # Azure Policy definitions
│   ├── governance/
│   │   ├── tagging-policy.bicep
│   │   └── naming-policy.bicep
│   └── security-baseline/
│       ├── cis-benchmark.bicep
│       └── azure-security-benchmark.bicep
├── parameters/                         # Customer-specific configurations
│   ├── customer1.bicepparam            # Customer 1 deployment
│   └── customer2.bicepparam            # Customer 2 deployment
├── scripts/                            # Deployment automation
│   ├── deploy.ps1
│   ├── deploy.sh
│   └── validate.ps1
└── docs/                               # Additional documentation
    ├── architecture-diagram.md
    ├── deployment-runbook.md
    └── audit-evidence-template.md
```

## Prerequisites

- Azure CLI 2.50+ or Azure PowerShell 10.0+
- Bicep CLI 0.20+
- Azure subscription with Owner or Contributor + User Access Administrator roles
- Management Group creation permissions

## Quick Start

### 1. Validate Prerequisites
```bash
./scripts/validate.ps1
```

### 2. Deploy for Customer 1
```powershell
./scripts/deploy.ps1 -Customer customer1 -Phase full -Location eastus
```

### 3. Deploy for Customer 2
```powershell
./scripts/deploy.ps1 -Customer customer2 -Phase full -Location westeurope
```

## Customer Configurations

### Customer 1 - Example Corp
- **Primary Region**: East US
- **Secondary Region**: West US 2
- **Hybrid Connectivity**: ExpressRoute + VPN Gateway
- **Management Groups**: Full hierarchy with Corp and Online landing zones
- **Network**: Hub-spoke with Azure Firewall

### Customer 2 - Example Ltd
- **Primary Region**: West Europe
- **Secondary Region**: North Europe
- **Hybrid Connectivity**: VPN Gateway only
- **Management Groups**: Simplified hierarchy
- **Network**: Hub-spoke with Network Virtual Appliance

## Multi-Regional Redundancy

This implementation includes:
- **Primary Region**: Specified in customer parameters
- **Secondary Region**: Paired region for disaster recovery
- **Traffic Manager**: Global load balancing (optional)
- **Geo-redundant Storage**: For backup and logs
- **Zone Redundancy**: Where supported by region

## Azure Landing Zone Review Assessment

Before deployment, use the [Azure Landing Zone Review](https://learn.microsoft.com/en-us/assessments/?mode=pre-assessment&id=azure-landing-zone-review) assessment tool to validate:
- Multi-regional redundancy policy configuration
- Security baseline alignment
- Governance policy compliance
- Network topology best practices

## Audit Evidence

The `docs/audit-evidence-template.md` file provides a template for documenting:
1. Customer environment details
2. Deployment screenshots
3. Configuration validation
4. Policy compliance reports
5. Azure Landing Zone Review assessment results

## Support and Maintenance

### Version History
- **v1.0.0** (Current): Initial implementation with full ALZ design areas

### Contributing
This is a template repository. Customize for your organization's specific requirements.

## References

- [Azure Landing Zone Documentation](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- [ALZ Design Areas](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-areas)
- [ALZ Conceptual Architecture](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/architecture)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)

## License

This solution is provided as-is for audit and deployment purposes.
