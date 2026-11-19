# 🛠️ Terraform CLI Commands Reference Guide

A practical command-line reference for Entry-Level DevOps Engineers, Junior Cloud Engineers, and DevOps Consultants working with Terraform and Microsoft Azure.

---

## 📋 Table of Contents

1. [Core Workflow Overview](#1-core-workflow-overview)
2. [Initialization (`terraform init`)](#2-initialization-terraform-init)
3. [Formatting and Linting (`terraform fmt`)](#3-formatting-and-linting-terraform-fmt)
4. [Syntax Validation (`terraform validate`)](#4-syntax-validation-terraform-validate)
5. [Execution Planning (`terraform plan`)](#5-execution-planning-terraform-plan)
6. [Applying Changes (`terraform apply`)](#6-applying-changes-terraform-apply)
7. [Importing Existing Infrastructure (`terraform import`)](#7-importing-existing-infrastructure-terraform-import)
8. [Inspecting State (`terraform state`)](#8-inspecting-state-terraform-state)
9. [Safely Destroying Infrastructure (`terraform destroy`)](#9-safely-destroying-infrastructure-terraform-destroy)
10. [Junior Engineer Pro-Tips](#10-junior-engineer-pro-tips)

---

## 1. Core Workflow Overview

The standard Terraform lifecycle follows four repeatable steps:

```
+------------------+      +--------------------+      +------------------+      +-------------------+
|  terraform init  | ---> | terraform validate | ---> |  terraform plan  | ---> |  terraform apply  |
|  (Download deps) |      | (Check syntax/fmt) |      | (Preview diffs)  |      | (Execute changes) |
+------------------+      +--------------------+      +------------------+      +-------------------+
```

---

## 2. Initialization (`terraform init`)

Prepares your working directory by downloading required provider plugins (`azurerm`) and configuring the backend state storage.

### Offline / Local Initialization (No Cloud Credentials Needed)
Useful for local syntax checking, unit testing, and GitHub Actions PR validation:
```bash
terraform init -backend=false
```

### Initializing with Remote Azure Blob Backend
Connects state storage to an Azure Storage Account container:
```bash
terraform init \
  -backend-config="resource_group_name=rg-terraform-state-dev-eastus" \
  -backend-config="storage_account_name=sttfstatedeveastus01" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev.landingzone.terraform.tfstate"
```

### Upgrading Provider Plugins
Forces Terraform to query the registry and update provider versions within constraints:
```bash
terraform init -upgrade
```

---

## 3. Formatting and Linting (`terraform fmt`)

Standardizes HCL formatting to canonical HashiCorp conventions (2-space indents, alignment of `=` signs).

### Automatically Format All Files in Current Directory and Subdirectories
```bash
terraform fmt -recursive
```

### Check Formatting Without Modifying Files (Used in CI/CD Gates)
Returns exit code `0` if formatted, exit code `3` if any file violates formatting:
```bash
terraform fmt -check -diff -recursive
```

---

## 4. Syntax Validation (`terraform validate`)

Validates whether configuration files are syntactically valid and internally consistent (verifies attribute names, argument types, and module inputs).

```bash
terraform validate
```

**Expected Successful Output:**
```text
Success! The configuration is valid.
```

---

## 5. Execution Planning (`terraform plan`)

Calculates the difference between the desired state (code) and current cloud state without making any modifications.

### Standard Plan with Custom Variable File
```bash
terraform plan -var-file="terraform.tfvars"
```

### Saving an Immutable Plan File for Automated CI/CD
Saving the plan to a binary file guarantees that `apply` executes the exact reviewed actions:
```bash
terraform plan -var-file="terraform.tfvars" -out="tfplan"
```

### Inspecting a Saved Plan File in Plain Text
```bash
terraform show -no-color tfplan > plan-summary.txt
```

### Detailed Exit Code Mode (Used in Automated Pipelines)
- `0`: Succeeded with empty diff (no changes)
- `1`: Error encountered
- `2`: Succeeded with non-empty diff (infrastructure changes pending)
```bash
terraform plan -detailed-exitcode -out="tfplan"
```

---

## 6. Applying Changes (`terraform apply`)

Provisions or updates cloud infrastructure according to the execution plan.

### Applying a Pre-Generated Binary Plan (Recommended Best Practice)
Never re-calculate plans directly on production servers. Apply the approved binary artifact:
```bash
terraform apply "tfplan"
```

### Interactive Direct Apply (Development Only)
Prompts for manual `yes` confirmation before executing:
```bash
terraform apply -var-file="terraform.tfvars"
```

### Automated Apply for Scripted Non-Interactive Pipelines
```bash
terraform apply -auto-approve "tfplan"
```

---

## 7. Importing Existing Infrastructure (`terraform import`)

Brings pre-existing Azure cloud resources under Terraform management without recreating them.

### Step-by-Step Practical Example: Importing an Existing Resource Group

1. **Step 1: Write the resource block in your `.tf` file:**
   ```hcl
   resource "azurerm_resource_group" "imported_rg" {
     name     = "rg-legacy-workload-eastus"
     location = "eastus"
   }
   ```

2. **Step 2: Obtain the Azure Resource ID from the portal or Azure CLI:**
   ```text
   /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-legacy-workload-eastus
   ```

3. **Step 3: Run the import command:**
   ```bash
   terraform import \
     azurerm_resource_group.imported_rg \
     /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-legacy-workload-eastus
   ```

4. **Step 4: Run `terraform plan` to reconcile any configuration drift:**
   ```bash
   terraform plan
   ```
   If Terraform detects differences (such as missing tags), update your code until `terraform plan` shows:
   ```text
   No changes. Your infrastructure matches the configuration.
   ```

---

## 8. Inspecting State (`terraform state`)

Commands for safely inspecting and modifying state metadata without manual JSON editing.

### List All Managed Resources in the State File
```bash
terraform state list
```
*Sample Output:*
```text
module.hub_rg.azurerm_resource_group.rg
module.hub_vnet.azurerm_virtual_network.vnet
module.hub_gateway_subnet.azurerm_subnet.subnet
module.spoke_vnet.azurerm_virtual_network.vnet
module.key_vault.azurerm_key_vault.kv
```

### Show Attributes of a Specific Resource
```bash
terraform state show module.hub_vnet.azurerm_virtual_network.vnet
```

### Remove a Resource from State Management (Without Deleting from Cloud)
Useful when decommissioning code or moving resources across modules:
```bash
terraform state rm module.spoke_rg.azurerm_resource_group.rg
```

---

## 9. Safely Destroying Infrastructure (`terraform destroy`)

Tears down all resources managed by the current Terraform workspace.

### Preview Resources That Will Be Destroyed
```bash
terraform plan -destroy -var-file="terraform.tfvars"
```

### Execute Destruction with Confirmation
```bash
terraform destroy -var-file="terraform.tfvars"
```

---

## 10. Junior Engineer Pro-Tips

| Tip | Principle | Why It Matters |
| :--- | :--- | :--- |
| **Never edit `.tfstate` by hand** | State Integrity | Direct state edits often lead to checksum mismatch and state corruption. Use `terraform state` commands. |
| **Always save `-out=tfplan` in CI** | Determinism | Applying without a saved plan causes a race condition where cloud changes made between plan and apply could be overwritten. |
| **Use `.gitignore` relentlessly** | Credential Security | State files can contain unencrypted database passwords, private keys, and service principal secrets. |
| **Pin provider versions** | Stability | Avoid unconstrained `azurerm` versions (`~> 3.0` vs bare `azurerm`) to prevent surprise breaking schema changes during pipelines. |
| **Leverage `terraform fmt -check`** | Clean PRs | Running format checks in pre-commit hooks eliminates trivial formatting debate during code reviews. |
