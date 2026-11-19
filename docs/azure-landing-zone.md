# 🌐 Azure Landing Zone & Cloud Adoption Framework (CAF) Deep Dive

This comprehensive guide breaks down the core concepts, design areas, and best practices behind **Azure Landing Zones** as defined by the **Microsoft Cloud Adoption Framework (CAF)**.

---

## 🎯 What is an Azure Landing Zone?

An **Azure Landing Zone** is an environment for hosting workloads, pre-provisioned through code, that takes into account:
* Security boundaries and identity federation
* Network routing, hybrid connectivity, and internet egress
* Centralized governance, logging, and policy compliance
* Scalable multi-subscription resource architecture

Rather than deploying cloud resources ad-hoc, a Landing Zone establishes an automated, standardized "foundation" ensuring every application team adheres to corporate compliance and security requirements from day one.

---

## 🏛️ The 8 CAF Core Design Areas

The Microsoft Cloud Adoption Framework categorizes enterprise cloud architecture into eight critical design areas:

```
+---------------------------------------------------------------------------------------+
|                       CAF 8 CRITICAL DESIGN AREAS                                     |
+---------------------------------------------------------------------------------------+
|  1. Azure Billing & Entra ID Tenant   |  5. Security, Governance & Compliance          |
|  2. Identity & Access Management (IAM)|  6. Operations Baseline & Central Logging     |
|  3. Management Group & Subscriptions  |  7. Business Continuity & Disaster Recovery   |
|  4. Network Topology & Connectivity   |  8. Deployment Options & IaC Automation       |
+---------------------------------------------------------------------------------------+
```

---

### 1. Azure Billing & Microsoft Entra ID Tenant
* **Single Tenant Model:** Enterprise workloads reside within a single Microsoft Entra ID (formerly Azure AD) tenant, ensuring unified identity management across users, groups, and service principals.
* **Enrollment Account / Billing Hierarchy:** Departmental chargeback models map to Management Groups and Subscription tags for billing transparency.

---

### 2. Identity and Access Management (IAM)
* **Principle of Least Privilege:** Users and CI/CD service principals are granted the minimum permissions needed to fulfill their role.
* **Role-Based Access Control (RBAC):** Native Azure roles (`Reader`, `Contributor`, `Key Vault Secrets Officer`) replace monolithic administrative access.
* **Managed Identities:** Eliminates hardcoded secrets by assigning system-assigned or user-assigned identities to Azure resources (VMs, App Services, Pipeline runners).

---

### 3. Resource Organization & Management Groups
Management Groups organize subscriptions hierarchically:
* **Tenant Root Group:** Enforces universal baselines (e.g., disallowing unencrypted storage).
* **Platform Management Group:** Contains dedicated subscriptions for `Connectivity` (Hub VNet, Firewalls), `Management` (Log Analytics, Automation), and `Identity` (Domain Controllers).
* **Landing Zones Management Group:** Segregates application subscriptions into `Corp` (internal-only private IPs) and `Online` (workloads with public internet endpoints).
* **Decommissioned / Sandbox:** Isolates experimental or retired workloads to prevent accidental production traffic interference.

---

### 4. Network Topology and Connectivity
The project implements the canonical **Hub-and-Spoke** network pattern:

```
[ On-Premises Office / VPN Users ]
               | (IPsec / ExpressRoute)
               v
+-------------------------------------------------------------------+
|  HUB VNET (Platform Landing Zone)                                 |
|  - GatewaySubnet: Terminates VPN & ExpressRoute                   |
|  - AzureBastionSubnet: RDP/SSH without public IPs                 |
|  - AzureFirewallSubnet: Central inspection & egress filtering     |
|  - SharedServicesSubnet: Core DNS, Monitoring, CI runners         |
+-------------------------------------------------------------------+
               |                    |
        (VNet Peering)        (VNet Peering)
               v                    v
+-------------------------------+  +-------------------------------+
|  SPOKE 1: Dev Workload VNet   |  |  SPOKE 2: Prod Workload VNet  |
|  - Frontend Subnet            |  |  - Frontend Subnet            |
|  - Backend Subnet             |  |  - Backend Subnet             |
|  - Database Subnet            |  |  - Database Subnet            |
+-------------------------------+  +-------------------------------+
```

#### Core Network Components Explained:
* **Azure Virtual Network (VNet):** Primary building block for private networks in Azure. Enables Azure resources to securely communicate with each other, the internet, and on-premises networks.
* **Subnets:** Logical subdivisions of a VNet address space enabling network segmentation and granular security enforcement.
* **VNet Peering:** High-throughput, low-latency private connectivity linking two VNets over Microsoft's backbone network. Traffic does not traverse the public internet.
* **Network Security Groups (NSGs):** Stateful packet-filtering firewalls containing 5-tuple security rules (Source, Destination, Port, Protocol, Direction) applied at subnet or network interface levels.
* **Azure Firewall (Conceptual):** Cloud-native, fully stateful firewall-as-a-service with built-in high availability and unrestricted cloud scalability. Centrally inspects and logs east-west and north-south traffic.
* **Azure Bastion (Conceptual):** Fully platform-managed PaaS service deployed inside `AzureBastionSubnet` providing secure RDP/SSH access directly in the Azure portal via TLS, eliminating public IP requirements for jump boxes.
* **Azure VPN Gateway (Conceptual):** Encrypted cross-premises tunnel between Azure VNets and corporate on-premises datacenters over the public internet.
* **Azure Private DNS (Conceptual):** Resolves private IP addresses inside VNets without exposing internal hostname records to public DNS servers.

---

### 5. Security, Governance & Compliance
* **Azure Policy:** Enforces compliance rules across resources (e.g., restricting deployment regions to `eastus`, enforcing mandatory tags, auditing unencrypted disks).
* **Azure Key Vault:** Centralized, hardware-backed vault for managing cryptographic keys, certificates, and application secrets with RBAC authorization and soft-delete retention.
* **Resource Locks:** Prevents inadvertent deletion (`CanNotDelete`) or unauthorized alteration (`ReadOnly`) of critical platform resources.

---

### 6. Standardized Naming Conventions

This project adheres strictly to Microsoft CAF naming recommendations:
`<resource-type>-<workload>-<environment>-<region>-<instance>`

| Resource Type | Recommended Prefix | Example in This Project |
| :--- | :--- | :--- |
| **Resource Group** | `rg-` | `rg-hub-alz-dev-eus` / `rg-spoke-alz-dev-eus` |
| **Virtual Network** | `vnet-` | `vnet-hub-alz-dev-eus` / `vnet-spoke-alz-dev-eus` |
| **Subnet** | `snet-` | `snet-frontend-alz-dev-eus` |
| **Network Security Group** | `nsg-` | `nsg-backend-alz-dev-eus` |
| **Key Vault** | `kv-` | `kv-alz-dev-eus-01` |
| **Storage Account** | `st` | `sttfstatedeveastus01` |

---

### 7. Resource Tagging Strategy

Every resource deployed through this project inherits standard governance metadata:

```hcl
common_tags = {
  Environment      = "dev"                        # dev | test | prod
  Project          = "alz"                        # Workload acronym
  ManagedBy        = "Terraform"                  # IaC engine
  Owner            = "aishwaryabelekar-devops"    # Technical owner
  CostCenter       = "devops-lab-101"             # Accounting code
  CreatedAt        = "2026-11-19"                 # Audit timestamp
  Repo             = "azure-landing-zone-deployment" # Source repository
}
```

#### Why Tagging Matters in DevOps:
1. **Cost Allocation & FinOps:** Enables finance and cloud engineers to split Azure bills by project, team, or environment.
2. **Operations & Incident Response:** Pinpoints who owns a failing resource during an outage.
3. **Automated Lifecycle Management:** Allows runbooks to automatically shut down development resources outside business hours based on `Environment = dev`.

---

## 🔄 How the Components Work Together in Practice

1. **Governance & Guardrails:** Azure Policy and Management Groups define the boundaries within which subscriptions operate.
2. **Network Plumbing:** Terraform provisions the Hub VNet in the Platform subscription and the Spoke VNet in the Workload subscription.
3. **Secure Backbone:** Bi-directional VNet Peering joins the two networks, allowing private traffic routing between tiers.
4. **Perimeter Defense:** NSG rules on individual subnets isolate tiers:
   - External traffic reaches only the Frontend subnet.
   - The Frontend tier communicates with the Backend API subnet.
   - The Database tier communicates strictly with the Backend subnet.
5. **Secret Protection:** Application microservices authenticate to Azure Key Vault over private endpoints or subnet service endpoints using Managed Identities, eliminating passwords stored in code or configuration files.
