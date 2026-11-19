# 🛡️ Azure Governance, Security & Compliance

A deep-dive technical reference on cloud governance, security baselines, and identity controls implemented across the **Azure Landing Zone** architecture.

---

## 📋 Table of Contents

1. [Management Group Hierarchy & Inheritance](#1-management-group-hierarchy--inheritance)
2. [Azure Role-Based Access Control (RBAC)](#2-azure-role-based-access-control-rbac)
3. [Azure Policy & Compliance Guardrails](#3-azure-policy--compliance-guardrails)
4. [Managed Identities for Azure Resources](#4-managed-identities-for-azure-resources)
5. [Azure Key Vault Security Architecture](#5-azure-key-vault-security-architecture)
6. [Resource Locks](#6-resource-locks)
7. [Secure Terraform State Storage](#7-secure-terraform-state-storage)
8. [Governance Checklist for DevOps Teams](#8-governance-checklist-for-devops-teams)

---

## 1. Management Group Hierarchy & Inheritance

Governance in Azure operates hierarchically. Policies, role assignments, and budgets assigned at higher scopes are inherited by child scopes without exception:

```
Tenant Root Management Group
  ├── Platform Management Group
  │     ├── Connectivity (Hub VNet, Firewall)
  │     ├── Management (Log Analytics, Automation)
  │     └── Identity (AD DS, Domain Controllers)
  └── Landing Zones Management Group
        ├── Corp (Private internal workloads)
        └── Online (Internet-exposed workloads)
              ├── Dev Subscription
              ├── Test Subscription
              └── Prod Subscription
```

### Inheritance Rules:
* **Cannot Override Deny:** If an Azure Policy at the Tenant Root Group evaluates to `Deny`, a child subscription cannot bypass or disable it.
* **Cumulative Permissions:** RBAC permissions granted at a higher scope accumulate at lower scopes.

---

## 2. Azure Role-Based Access Control (RBAC)

Azure RBAC segregates duties and ensures the **Principle of Least Privilege**: engineers and automation agents are granted only the permissions essential to perform their duties.

### Core Built-in Roles:

| Built-In Role | Permitted Actions | Recommended Assignment |
| :--- | :--- | :--- |
| **Reader** | View all resources, configurations, and logs. Cannot create or edit. | Junior team members, security auditors, billing reviewers. |
| **Contributor** | Create and manage all Azure resources. Cannot grant access to others. | Workload DevOps engineers within their application resource group. |
| **Owner** | Full management access, including granting access and managing locks. | Restricted strictly to Subscription Leads / Platform Admins. |
| **Key Vault Secrets Officer** | Read and write secrets inside Azure Key Vault (data-plane). | CI/CD deployment service principal for application secrets. |
| **Network Contributor** | Manage virtual networks, subnets, and peering. Cannot modify compute. | Cloud Network Operations team. |

### Custom Role Definition Example:
When built-in roles grant too much privilege, custom roles define explicit action lists:

```json
{
  "Name": "Landing Zone Network Operator",
  "IsCustom": true,
  "Description": "Grants permissions to restart and inspect networks without creating new VNets.",
  "Actions": [
    "Microsoft.Network/virtualNetworks/read",
    "Microsoft.Network/networkSecurityGroups/read",
    "Microsoft.Network/networkSecurityGroups/join/action"
  ],
  "NotActions": [
    "Microsoft.Network/virtualNetworks/delete",
    "Microsoft.Network/virtualNetworks/write"
  ],
  "AssignableScopes": [
    "/subscriptions/00000000-0000-0000-0000-000000000000"
  ]
}
```

---

## 3. Azure Policy & Compliance Guardrails

Azure Policy enforces organizational standards and assesses compliance at scale.

```
+---------------------------------------------------------------------------------------+
|  POLICY ENFORCEMENT ENGINE                                                            |
|  Evaluates ARM / Bicep / Terraform template payloads BEFORE resource creation          |
+---------------------------------------------------------------------------------------+
        |                                       |
        v (Matches Rule)                        v (Complies)
[ Action: DENY / AUDIT ]                 [ Resource Created ]
```

### Key CAF Baseline Policies:

1. **Allowed Locations Policy:**
   - **Effect:** `Deny`
   - **Rule:** Rejects any resource deployment outside approved corporate cloud regions (`eastus`, `centralus`).
   - **Benefit:** Prevents unexpected cross-region data transfer latency and ensures data sovereignty compliance.

2. **Mandatory Resource Tagging:**
   - **Effect:** `Deny` or `Modify`
   - **Rule:** Blocks creation of resources missing `Environment`, `CostCenter`, or `Owner` tags.

3. **Disallow Unencrypted Storage Accounts:**
   - **Effect:** `Deny`
   - **Rule:** Blocks storage accounts with HTTP traffic enabled or minimum TLS version lower than `TLS 1.2`.

4. **Deny Public Network Exposure on PaaS:**
   - **Effect:** `Deny`
   - **Rule:** Prevents Key Vaults or SQL Databases from enabling unrestricted `0.0.0.0/0` public internet endpoints.

---

## 4. Managed Identities for Azure Resources

Managed Identities eliminate the need for developers to manage credentials in configuration files.

```
+-------------------------+      1. Request Token      +-------------------------+
|  Azure Virtual Machine  | -------------------------> |  Microsoft Entra ID     |
|  or Azure Pipeline      | <------------------------- |  (Instance Metadata)   |
+-------------------------+     2. Returns OAuth Token +-------------------------+
             |
             | 3. Access with Token
             v
+-------------------------+
|  Azure Key Vault        |
|  (kv-alz-dev-eus-01)    |
+-------------------------+
```

* **System-Assigned Identity:** Tied directly to the lifecycle of the Azure resource. When the resource is deleted, Azure automatically cleans up the identity in Entra ID.
* **User-Assigned Identity:** Created as an independent Azure resource and shared across multiple workloads (e.g., a pool of CI/CD build agents).

---

## 5. Azure Key Vault Security Architecture

Azure Key Vault provides secure storage for tokens, passwords, certificates, and API keys.

### Security Configurations in This Project:
* **Azure RBAC Authorization (`enable_rbac_authorization = true`):**
  Replaces legacy, coarse-grained Key Vault Access Policies with granular Azure RBAC roles (`Key Vault Secrets Officer`, `Key Vault Reader`).
* **Soft Delete (`soft_delete_retention_days = 7` to `90`):**
  Ensures that accidentally deleted secrets or vaults remain recoverable for a retention window.
* **Purge Protection (`purge_protection_enabled = true` in Prod):**
  Enforces a mandatory retention window during which no administrator can permanently destroy a soft-deleted vault, protecting against malicious insider deletion and ransomware.
* **Network ACLs:**
  Restricts incoming traffic to authorized virtual networks and approved corporate IP ranges.

---

## 6. Resource Locks

Resource locks protect critical landing zone components against accidental deletion or unauthorized modification:

| Lock Type | Behavior | Best Use Case |
| :--- | :--- | :--- |
| **CanNotDelete** | Authorized users can read and modify a resource, but cannot delete it. | Hub Virtual Network, ExpressRoute Gateway, Key Vault, Production Subnets. |
| **ReadOnly** | Authorized users can read resources, but cannot update or delete them. | Baseline governance policies, audit storage logs. |

---

## 7. Secure Terraform State Storage

To ensure state files are safeguarded:
1. **Azure Blob Storage at Rest:** Encrypted with 256-bit AES encryption.
2. **Access Control:** Storage account access keys are disabled. Only Entra ID OAuth / Service Principals with `Storage Blob Data Contributor` can access state blobs.
3. **Blob Lease State Locking:** Prevents two concurrent CI/CD pipelines from modifying state simultaneously.
4. **Network Restrictions:** State storage accounts are locked down with firewall rules to allow access strictly from Azure DevOps build agent subnets.

---

## 8. Governance Checklist for DevOps Teams

- [x] Hierarchical Management Group structure defined
- [x] Standard CAF naming convention applied across all modules
- [x] Mandatory tags (`Environment`, `Project`, `Owner`, `CostCenter`, `ManagedBy`) merged into all resources
- [x] Subnet segmentation isolates Frontend, Backend, and Database tiers
- [x] Key Vault deployed with RBAC authorization and soft-delete retention
- [x] Hub-and-Spoke connectivity established via native VNet Peering
- [x] Multi-stage pipeline gates execution behind manual review and automated linting
