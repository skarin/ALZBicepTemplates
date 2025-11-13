# Azure Landing Zone Architecture

## Conceptual Architecture Diagram

This document describes the Azure Landing Zone architecture aligned with Microsoft's Cloud Adoption Framework (CAF) design areas.

---

## Management Group Hierarchy

```
Tenant Root Group
│
└── [Organization Name]
    ├── Platform
    │   ├── Management
    │   │   └── Subscription: Management
    │   │       ├── Log Analytics Workspace
    │   │       ├── Azure Monitor
    │   │       ├── Recovery Services Vault
    │   │       └── Automation Account
    │   │
    │   ├── Connectivity
    │   │   └── Subscription: Connectivity
    │   │       ├── Hub Virtual Network
    │   │       │   ├── Azure Firewall
    │   │       │   ├── Azure Bastion
    │   │       │   ├── ExpressRoute Gateway
    │   │       │   └── VPN Gateway
    │   │       └── DNS (Optional)
    │   │
    │   └── Identity
    │       └── Subscription: Identity
    │           └── AD DS VMs / Entra Domain Services (Optional)
    │
    ├── Landing Zones
    │   ├── Corp
    │   │   └── Subscriptions: Corporate workloads
    │   │       └── Spoke Virtual Networks
    │   │           ├── Peered to Hub
    │   │           └── On-premises connectivity via hub
    │   │
    │   └── Online
    │       └── Subscriptions: Internet-facing workloads
    │           └── Spoke Virtual Networks
    │               ├── Peered to Hub
    │               └── Public-facing services
    │
    ├── Sandboxes
    │   └── Subscriptions: Development/Testing
    │       └── Isolated environments
    │
    └── Decommissioned
        └── Subscriptions: To be removed
```

---

## Network Topology: Hub-Spoke Architecture

### Hub Virtual Network (Connectivity Subscription)

```
Hub VNet: 10.100.0.0/16
├── AzureFirewallSubnet: 10.100.1.0/26
│   └── Azure Firewall (Zone-redundant)
│       ├── Public IP (Standard, Zone-redundant)
│       └── Firewall Rules & Policies
│
├── AzureBastionSubnet: 10.100.2.0/26
│   └── Azure Bastion (Standard tier)
│       └── Public IP (Standard, Zone-redundant)
│
├── GatewaySubnet: 10.100.3.0/27
│   ├── ExpressRoute Gateway (ErGw1AZ)
│   │   └── Connection to ExpressRoute Circuit
│   └── VPN Gateway (VpnGw1AZ)
│       └── Site-to-Site VPN Connection
│
├── ManagementSubnet: 10.100.4.0/24
│   └── Jump boxes, management VMs
│
└── SharedServicesSubnet: 10.100.5.0/24
    └── Shared infrastructure services
```

### Spoke Virtual Networks (Landing Zone Subscriptions)

#### Corp Spoke (Corporate Workloads)
```
Corp Spoke VNet: 10.110.0.0/16
├── ApplicationSubnet: 10.110.1.0/24
│   ├── NSG: Allow necessary traffic
│   └── UDR: Route to Azure Firewall
│
├── DataSubnet: 10.110.2.0/24
│   ├── NSG: Restrictive rules
│   ├── Service Endpoints
│   └── UDR: Route to Azure Firewall
│
├── PrivateEndpointsSubnet: 10.110.3.0/24
│   └── Private Endpoints for PaaS services
│
└── Peering to Hub VNet
    ├── Allow Virtual Network Access: Yes
    ├── Allow Forwarded Traffic: Yes
    ├── Use Remote Gateway: Yes
    └── Allow Gateway Transit: No
```

#### Online Spoke (Internet-Facing Workloads)
```
Online Spoke VNet: 10.120.0.0/16
├── WebTierSubnet: 10.120.1.0/24
│   ├── Application Gateway / Azure Front Door
│   └── Public-facing web applications
│
├── AppTierSubnet: 10.120.2.0/24
│   ├── Application logic tier
│   └── Internal load balancers
│
├── DataTierSubnet: 10.120.3.0/24
│   ├── Database services
│   └── Storage accounts
│
└── Peering to Hub VNet
```

---

## Design Areas Mapping

### Design Area A: Azure Billing and Tenant

**Components:**
- Single Azure AD (Entra ID) tenant
- Enterprise Agreement (EA) or Microsoft Customer Agreement (MCA)
- Subscription organization via management groups

**Implementation:**
- `modules/identity/entra-id.bicep` (configuration guidance)
- Manual tenant configuration

---

### Design Area B: Identity and Access Management

**Components:**
- **Entra ID (Azure AD):**
  - Conditional Access policies
  - Multi-Factor Authentication (MFA)
  - Privileged Identity Management (PIM)
  - Emergency access accounts

- **RBAC:**
  - Role assignments at management group level
  - Custom roles for specific scenarios
  - Service principals and managed identities

**Implementation:**
- `modules/identity/rbac.bicep`
- `modules/identity/managed-identities.bicep`
- Manual Entra ID policy configuration

---

### Design Area C: Resource Organization

**Components:**
1. **Management Groups:**
   - Hierarchical structure for policy and access
   - Separation of platform and landing zones

2. **Naming Conventions:**
   - Standard: `<type>-<workload>-<env>-<region>-<instance>`
   - Example: `vnet-finance-prod-eastus-001`

3. **Tagging Standards:**
   - Environment, CostCenter, BusinessOwner, TechnicalOwner
   - Criticality, DataClassification, Compliance

**Implementation:**
- `modules/management-groups/hierarchy.bicep`
- `modules/naming-conventions/standards.bicep`
- `modules/naming-conventions/tagging-standards.bicep`
- `policies/governance/tagging-policy.bicep`
- `policies/governance/naming-policy.bicep`

---

### Design Area E: Network Topology and Connectivity

**Components:**

1. **Hub-Spoke Topology:**
   - Centralized hub for shared services
   - Isolated spoke networks per workload
   - VNet peering for connectivity

2. **Hybrid Connectivity:**
   - **ExpressRoute:** Private, dedicated connection to on-premises
   - **VPN Gateway:** Site-to-Site IPsec VPN for branch offices
   - BGP routing for dynamic route updates

3. **Network Security:**
   - Azure Firewall for centralized traffic filtering
   - Network Security Groups (NSGs) at subnet level
   - User-Defined Routes (UDRs) to force traffic through firewall

4. **Network Services:**
   - Azure Bastion for secure RDP/SSH access
   - Azure DNS or custom DNS
   - Private Endpoints for PaaS services

**Implementation:**
- `modules/networking/hub-spoke/hub-vnet.bicep`
- `modules/networking/hub-spoke/spoke-vnet.bicep`
- `modules/networking/hub-spoke/peering.bicep`
- `modules/networking/expressroute.bicep`
- `modules/networking/vpn-gateway.bicep`
- `modules/networking/nsg.bicep`

---

### Design Area F: Security

**Components:**

1. **Microsoft Defender for Cloud:**
   - Defender for Servers (VMs)
   - Defender for Storage
   - Defender for SQL
   - Defender for Containers
   - Defender for Key Vault
   - Defender for Resource Manager
   - Defender for DNS

2. **Security Services:**
   - Azure Key Vault for secrets management
   - Customer-managed encryption keys
   - TLS 1.2 minimum for all services

3. **Security Policies:**
   - Azure Security Benchmark
   - CIS Microsoft Azure Foundations Benchmark
   - Encryption at rest and in transit enforcement

**Implementation:**
- `modules/security/defender.bicep`
- `modules/security/key-vault.bicep`
- `modules/security/security-baseline.bicep`
- `policies/security-baseline/azure-security-benchmark.bicep`

---

### Design Area G/H: Management and Governance

**Components:**

1. **Monitoring:**
   - Log Analytics Workspace (centralized logging)
   - Azure Monitor (metrics and alerts)
   - Application Insights
   - Network Watcher

2. **Management:**
   - Update Management
   - Change Tracking
   - Inventory
   - Automation Account

3. **Backup and Recovery:**
   - Recovery Services Vault
   - Geo-redundant backup storage
   - Cross-region restore enabled
   - Backup policies (daily, weekly, monthly, yearly)

4. **Governance:**
   - Azure Policy definitions and assignments
   - Policy initiatives (sets)
   - Compliance monitoring
   - Remediation tasks

**Implementation:**
- `modules/management/log-analytics.bicep`
- `modules/management/monitoring.bicep`
- `modules/management/backup.bicep`
- `policies/governance/` (various policies)

---

### Design Area I: Platform Automation and DevOps

**Components:**

1. **Infrastructure as Code:**
   - Bicep templates for all resources
   - Modular design for reusability
   - Parameter files for customer-specific configs

2. **Deployment Automation:**
   - PowerShell and Bash deployment scripts
   - Validation scripts
   - CI/CD pipeline ready

3. **Version Control:**
   - Git repository structure
   - Change tracking
   - Audit trail

**Implementation:**
- `main.bicep` (orchestration)
- `scripts/deploy.ps1` / `scripts/deploy.sh`
- `scripts/validate.ps1`
- Parameter files per customer

---

## Traffic Flows

### Inbound Internet Traffic

```
Internet
    ↓
Azure Front Door / Application Gateway (in spoke)
    ↓
Web Tier Subnet (spoke VNet)
    ↓
Application Tier Subnet (via internal LB)
    ↓
Data Tier Subnet
```

### On-Premises to Azure Traffic

```
On-Premises
    ↓
ExpressRoute Circuit / VPN Tunnel
    ↓
ExpressRoute Gateway / VPN Gateway (hub)
    ↓
Azure Firewall (hub) [if routing enforced]
    ↓
Spoke VNet (via peering)
    ↓
Application Resources
```

### Spoke-to-Spoke Traffic

```
Spoke VNet 1
    ↓
Hub VNet (via peering)
    ↓
Azure Firewall (hub) [traffic inspection]
    ↓
Hub VNet
    ↓
Spoke VNet 2 (via peering)
```

### Outbound Internet Traffic

```
Spoke VNet
    ↓
UDR routes to Azure Firewall
    ↓
Azure Firewall (hub) [NAT and filtering]
    ↓
Internet
```

---

## Multi-Regional Architecture

For customers requiring multi-regional deployments:

### Primary Region (e.g., East US)
- Complete hub-spoke deployment
- All platform services
- Active workloads

### Secondary Region (e.g., West US 2)
- Secondary hub VNet (different address space)
- Separate gateways for local on-premises connectivity
- Disaster recovery workloads
- Active-passive or active-active based on requirements

### Cross-Region Connectivity Options:
1. **VNet Peering** between hubs (for Azure-to-Azure traffic)
2. **ExpressRoute** with multiple peering locations
3. **Traffic Manager** or **Azure Front Door** for global load balancing

---

## Security Zones

### Zone 1: Platform Management
- Management subscription resources
- Log Analytics, monitoring, backup
- Highly restricted access

### Zone 2: Connectivity Hub
- Networking infrastructure
- Shared services
- Tightly controlled firewall rules

### Zone 3: Corporate Landing Zones
- Internal applications
- Connected to on-premises
- Private connectivity only

### Zone 4: Online Landing Zones
- Internet-facing applications
- Public endpoints via Application Gateway/Front Door
- Enhanced security monitoring

### Zone 5: Sandboxes
- Isolated development environments
- No production data
- Relaxed policies for experimentation

---

## Compliance and Audit Alignment

This architecture meets the following audit requirements:

✅ **Identity:** Entra ID with MFA and conditional access  
✅ **Networking:** Hub-spoke with ExpressRoute/VPN  
✅ **Resource Organization:** Management groups, tagging, naming  
✅ **Security:** Microsoft Defender, Azure Policy, Key Vault  
✅ **Management:** Centralized logging, monitoring, backup  
✅ **Governance:** Policy-driven compliance  
✅ **Automation:** Repeatable Bicep deployment  
✅ **Multi-Regional:** Zone-redundant resources, geo-redundant backup  

---

## Next Steps

1. Review and customize for your organization
2. Update parameter files with actual values
3. Deploy using provided scripts
4. Complete post-deployment configuration
5. Run Azure Landing Zone Review assessment
6. Document deployment for audit evidence

---

## References

- [Azure Landing Zone Conceptual Architecture](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-areas)
- [Hub-Spoke Network Topology](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Management Group Best Practices](https://learn.microsoft.com/en-us/azure/governance/management-groups/overview)
- [Azure Naming Conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
