# 📖 Terraform Infrastructure as Code (IaC) Guide

A beginner-friendly technical guide to mastering HashiCorp Terraform and Infrastructure as Code for Microsoft Azure.

---

## 📋 Table of Contents

1. [What is Infrastructure as Code?](#1-what-is-infrastructure-as-code)
2. [Anatomy of Terraform Configuration Files](#2-anatomy-of-terraform-configuration-files)
3. [Terraform Providers](#3-terraform-providers)
4. [Input Variables & Validation Rules](#4-input-variables--validation-rules)
5. [Local Values (locals)](#5-local-values-locals)
6. [Data Sources](#6-data-sources)
7. [Resources & Dynamic Blocks](#7-resources--dynamic-blocks)
8. [Reusable Child Modules](#8-reusable-child-modules)
9. [Outputs](#9-outputs)
10. [State Management & Azure Remote Backend](#10-state-management--azure-remote-backend)
11. [Multi-Environment Structuring: Directories vs Workspaces](#11-multi-environment-structuring-directories-vs-workspaces)

---

## 1. What is Infrastructure as Code?

Infrastructure as Code (IaC) is the management and provisioning of cloud infrastructure through machine-readable definition files rather than manual physical hardware configuration or interactive configuration tools (like the Azure Portal GUI).

### Key Benefits for DevOps Teams:
* **Repeatability:** Spin up identical dev, test, and prod environments in minutes.
* **Version Control:** Track every infrastructure modification through Git commits and pull requests.
* **Auditability & Compliance:** Peer review changes before they reach cloud environments.
* **Zero Configuration Drift:** Detect unapproved manual portal changes during `terraform plan`.

---

## 2. Anatomy of Terraform Configuration Files

In standard enterprise projects, Terraform files are organized logically by function:

| File Name | Purpose | Example Contents |
| :--- | :--- | :--- |
| `main.tf` | Primary resource declarations and module calls. | `module "hub_vnet" { ... }` |
| `variables.tf` | Parameter definitions, type constraints, and descriptions. | `variable "environment" { type = string }` |
| `outputs.tf` | Values returned after execution to consumers or pipelines. | `output "vnet_id" { value = ... }` |
| `locals.tf` | Reusable local calculations and tag dictionaries. | `locals { naming_prefix = ... }` |
| `providers.tf` | Required provider plugins and version constraints. | `provider "azurerm" { ... }` |
| `backend.tf` | Remote state storage configuration. | `backend "azurerm" { ... }` |
| `terraform.tfvars`| Actual input variable values assigned per environment. | `environment = "dev"` |

---

## 3. Terraform Providers

Providers are plugins that implement resource types and interact with upstream cloud APIs.

```hcl
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}
```

* **Version Pinning:** `~> 3.0` or `>= 3.0.0, < 5.0.0` prevents surprise breaking changes when upstream providers update.
* **Features Block:** The `azurerm` provider requires an explicit `features {}` block to configure cloud-specific behaviors (such as soft-delete handling for Key Vaults).

---

## 4. Input Variables & Validation Rules

Variables parameterize modules so the same code can deploy development, testing, and production environments.

```hcl
variable "vnet_address_space" {
  description = "The address space in CIDR format."
  type        = list(string)
  default     = ["10.10.0.0/16"]

  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "At least one CIDR address space must be supplied."
  }
}
```

---

## 5. Local Values (locals)

Locals assign a name to an expression, preventing repetitive code and simplifying complex calculations:

```hcl
locals {
  naming_prefix = "${var.project_name}-${var.environment}-${var.location_short}"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  )
}
```

---

## 6. Data Sources

Data sources allow Terraform to query information about existing cloud resources outside the current configuration or read tenant runtime metadata:

```hcl
# Read current Azure client / tenant context dynamically
data "azurerm_client_config" "current" {}

# Use client config inside resources
output "current_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}
```

---

## 7. Resources & Dynamic Blocks

Resources represent physical or logical infrastructure components managed by Terraform.

### Dynamic Blocks
Dynamic blocks avoid repeating similar nested configuration blocks:

```hcl
resource "azurerm_network_security_group" "nsg" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  # Dynamically generate security_rule blocks from an input list of rule objects
  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      destination_port_range     = lookup(security_rule.value, "destination_port_range", null)
      source_address_prefix      = lookup(security_rule.value, "source_address_prefix", null)
      destination_address_prefix = lookup(security_rule.value, "destination_address_prefix", null)
    }
  }
}
```

---

## 8. Reusable Child Modules

Modules are self-contained packages of Terraform configurations. This project encapsulates:
* `modules/resource_group`
* `modules/virtual_network`
* `modules/subnet`
* `modules/network_security_group`
* `modules/key_vault`

### Calling a Child Module from Environment `main.tf`:
```hcl
module "spoke_vnet" {
  source              = "../../modules/virtual_network"
  vnet_name           = "vnet-spoke-alz-dev-eus"
  resource_group_name = module.spoke_rg.name
  location            = module.spoke_rg.location
  address_space       = var.spoke_vnet_address_space
  tags                = local.common_tags
}
```

---

## 9. Outputs

Outputs export values from child modules to parent modules, or display useful attributes after `terraform apply`:

```hcl
output "vnet_id" {
  description = "The Resource ID of the provisioned Virtual Network."
  value       = azurerm_virtual_network.vnet.id
}
```

---

## 10. State Management & Azure Remote Backend

### What is the State File (`terraform.tfstate`)?
Terraform stores state about managed infrastructure and configuration in a state file. It acts as the single source of truth mapping your code definitions to real Azure Resource IDs.

### Why Local State is Dangerous for Teams:
1. **No Concurrency Control:** Multiple engineers applying changes simultaneously will corrupt the state.
2. **Security Vulnerability:** State contains plain text resource attributes, which may include database connection strings or secrets.
3. **Loss of History:** If the local laptop drive fails, the state is permanently lost.

### Enterprise Solution: Azure Blob Storage Remote Backend
```
+------------------+         +------------------+
|  Engineer A      |         |  Engineer B      |
+------------------+         +------------------+
         \                          /
          \                        /
           v                      v
+-------------------------------------------------------+
|  AZURE BLOB STORAGE CONTAINER (tfstate)              |
|  - Encrypted at rest (Microsoft-managed or CMK)       |
|  - Blob Lease Locking: Prevents simultaneous writes   |
|  - RBAC: Access restricted to CI/CD Service Principal |
+-------------------------------------------------------+
```

#### How Blob Lease Locking Works:
When an engineer or CI/CD pipeline runs `terraform plan` or `apply`, Terraform acquires an exclusive lease lock on the state blob. If another pipeline attempts to run concurrently, it receives an error:
```text
Error: Error acquiring the state lock: Storage lease already present.
```

---

## 11. Multi-Environment Structuring: Directories vs Workspaces

| Approach | Architecture | Best Use Case | Recommendation in Enterprise |
| :--- | :--- | :--- | :--- |
| **Directory-Based Separation** (Used in this project) | Distinct folders (`environments/dev`, `environments/test`, `environments/prod`) with dedicated variable files and state keys. | Strict environment isolation, different access controls per subscription, different resource topologies. | **Industry standard for production landing zones.** |
| **Terraform Workspaces** | Single code directory with switching via `terraform workspace select <env>`. | Transient staging testing or deploying identical ephemeral copies of single services. | Not recommended for multi-tier landing zones due to shared state backend risk. |
