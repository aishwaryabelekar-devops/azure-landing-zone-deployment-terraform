# 🔧 DevOps Troubleshooting & FAQ Guide

A practical troubleshooting manual for Entry-Level DevOps Engineers encountering real-world errors in Terraform and Azure DevOps CI/CD pipelines.

---

## 📋 Table of Contents

1. [Terraform Common Errors & Resolutions](#1-terraform-common-errors--resolutions)
   - [Error 1: Provider Download / Registry Connection Failure](#error-1-provider-download--registry-connection-failure)
   - [Error 2: Storage Lease State Lock Error](#error-2-storage-lease-state-lock-error)
   - [Error 3: Subnet CIDR Overlap](#error-3-subnet-cidr-overlap)
   - [Error 4: Globally Unique Key Vault Name Conflict](#error-4-globally-unique-key-vault-name-conflict)
   - [Error 5: Resource Already Exists in Azure](#error-5-resource-already-exists-in-azure)
   - [Error 6: Cyclic Dependency Detected](#error-6-cyclic-dependency-detected)
2. [Azure DevOps YAML Pipeline Errors & Resolutions](#2-azure-devops-yaml-pipeline-errors--resolutions)
   - [Error 7: Invalid or Missing Service Connection](#error-7-invalid-or-missing-service-connection)
   - [Error 8: Pipeline Blocked at Environment Approval Gate](#error-8-pipeline-blocked-at-environment-approval-gate)
   - [Error 9: Terraform fmt -check Fails Build in CI](#error-9-terraform-fmt--check-fails-build-in-ci)
   - [Error 10: Missing Artifact in Downstream Apply Stage](#error-10-missing-artifact-in-downstream-apply-stage)
3. [General Debugging Checklist](#3-general-debugging-checklist)

---

## 1. Terraform Common Errors & Resolutions

### Error 1: Provider Download / Registry Connection Failure

#### Symptom:
```text
Error: Failed to query available provider packages
Could not retrieve the list of available versions for provider hashicorp/azurerm:
could not connect to registry.terraform.io: dial tcp: lookup registry.terraform.io: no such host
```

#### Root Cause:
The environment running Terraform cannot resolve or connect to the public internet (common in corporate proxies, firewalled runners, or offline sandboxes).

#### Step-by-Step Fix:
1. For local syntax checks and offline validation without internet, run:
   ```bash
   terraform init -backend=false
   ```
2. If working behind a corporate proxy, set standard proxy environment variables:
   ```bash
   export HTTP_PROXY="http://proxy.corp.internal:8080"
   export HTTPS_PROXY="http://proxy.corp.internal:8080"
   ```
3. Use a pre-cached provider plugin directory:
   ```bash
   terraform init -plugin-dir="/path/to/cached/providers"
   ```

---

### Error 2: Storage Lease State Lock Error

#### Symptom:
```text
Error: Error acquiring the state lock
Error message: storage: service returned error: StatusCode=409,
ErrorCode=LeaseAlreadyPresent, ErrorMessage=There is already a lease present.
Lock Info:
  ID:        17486249-1a42-4521-87ab-18c7e2b19213
  Who:       runner@azure-devops-build-agent
```

#### Root Cause:
A prior `terraform plan` or `apply` command was abruptly terminated, killed, or cancelled mid-execution, leaving the Azure Blob Storage lease locked.

#### Step-by-Step Fix:
1. Confirm that no other engineer or pipeline is currently applying changes.
2. Force-unlock the state using the Lock ID reported in the error message:
   ```bash
   terraform force-unlock 17486249-1a42-4521-87ab-18c7e2b19213
   ```
3. Alternatively, break the blob lease in the Azure Portal:
   - Navigate to **Storage Account** > **Containers** > `tfstate` > select your `.tfstate` blob.
   - Click **Break Lease** in the toolbar.

---

### Error 3: Subnet CIDR Overlap

#### Symptom:
```text
Error: creating Subnet: (Name "snet-backend" / Virtual Network "vnet-spoke"):
network.SubnetsClient#CreateOrUpdate: Failure sending request:
StatusCode=400 -- Subnet 'snet-backend' address prefix 10.11.1.0/24 overlaps with
existing subnet 'snet-frontend' (10.11.1.0/24).
```

#### Root Cause:
Two subnets within the same Virtual Network have been assigned identical or overlapping IP address ranges.

#### Step-by-Step Fix:
1. Check your `variables.tf` and `terraform.tfvars` subnet allocations.
2. Ensure every subnet possesses a non-overlapping CIDR block within the VNet address space:
   ```hcl
   # Correct non-overlapping CIDR plan:
   spoke_frontend_subnet_prefix = ["10.11.1.0/24"] # 10.11.1.0 - 10.11.1.255
   spoke_backend_subnet_prefix  = ["10.11.2.0/24"] # 10.11.2.0 - 10.11.2.255
   spoke_database_subnet_prefix = ["10.11.3.0/24"] # 10.11.3.0 - 10.11.3.255
   ```

---

### Error 4: Globally Unique Key Vault Name Conflict

#### Symptom:
```text
Error: creating Key Vault: (Name "kv-alz-dev-eus-01"):
vaults.VaultsClient#CreateOrUpdate: Failure sending request:
StatusCode=409 -- The name 'kv-alz-dev-eus-01' is already in use.
```

#### Root Cause:
Azure Key Vault names are **globally unique across all Azure subscriptions worldwide** and share a public DNS namespace (`<name>.vault.azure.net`). A soft-deleted vault with that name may also still occupy the name reservation.

#### Step-by-Step Fix:
1. Append an organization-specific or randomized identifier to your Key Vault variable:
   ```hcl
   name = "kv-alz-dev-eus-${random_string.suffix.result}"
   ```
2. If the vault was deleted recently, purge the soft-deleted vault:
   ```bash
   az keyvault purge --name "kv-alz-dev-eus-01" --location "eastus"
   ```

---

### Error 5: Resource Already Exists in Azure

#### Symptom:
```text
Error: A resource with the ID "/subscriptions/.../resourceGroups/rg-hub-dev" already exists
and is not managed by Terraform.
```

#### Root Cause:
A resource was manually created in the Azure portal or CLI with the same name prior to running Terraform.

#### Step-by-Step Fix:
* **Option A (Import into State):** If the resource should be managed by Terraform:
  ```bash
  terraform import module.hub_rg.azurerm_resource_group.rg /subscriptions/.../resourceGroups/rg-hub-dev
  ```
* **Option B (Rename in Code):** If it represents a different workload, change the name in `terraform.tfvars`.

---

### Error 6: Cyclic Dependency Detected

#### Symptom:
```text
Error: Cycle: module.hub_vnet, module.spoke_vnet, azurerm_virtual_network_peering.hub_to_spoke
```

#### Root Cause:
Resource A references Resource B, while Resource B simultaneously references Resource A, creating an unresolvable graph loop.

#### Step-by-Step Fix:
1. Break the circular reference by separating peering into standalone resources (`azurerm_virtual_network_peering`) outside the VNet child modules.
2. Pass specific attributes (such as `module.spoke_vnet.id`) rather than the entire module object.

---

## 2. Azure DevOps YAML Pipeline Errors & Resolutions

### Error 7: Invalid or Missing Service Connection

#### Symptom:
```text
##[error]Could not find a service connection named 'sc-azure-landing-zone-service-connection'.
Ensure the service connection exists and has been authorized for this pipeline.
```

#### Root Cause:
The ARM Service Connection placeholder defined in YAML has not been created or authorized in Azure DevOps Project Settings.

#### Step-by-Step Fix:
1. Open your Azure DevOps project.
2. Go to **Project Settings** > **Service connections** > **New service connection** > **Azure Resource Manager**.
3. Select **Workload Identity Federation (recommended)** or **Service Principal (automatic)**.
4. Name the connection `sc-azure-landing-zone-service-connection`.
5. Under security options, check **Grant access permission to all pipelines**.

---

### Error 8: Pipeline Blocked at Environment Approval Gate

#### Symptom:
The pipeline stays in "Waiting" or "Job is pending approval" indefinitely at Stage 3.

#### Root Cause:
The Azure DevOps Environment targeted by the deployment job has an **Approvals and checks** policy configured, waiting for designated reviewers to click "Approve".

#### Step-by-Step Fix:
1. Navigate to **Pipelines** > **Environments** > `landing-zone-dev-approval`.
2. Review the pending check notification at the top of the pipeline run.
3. Inspect the published plan artifact summary and click **Approve** with reviewer notes.

---

### Error 9: Terraform fmt -check Fails Build in CI

#### Symptom:
```text
##[error]Bash exited with code '3'.
main.tf
variables.tf
##[error]Terraform format check failed! Code is not formatted according to canonical style.
```

#### Root Cause:
Code was committed locally without running `terraform fmt`, resulting in inconsistent whitespace or indentation.

#### Step-by-Step Fix:
1. Run format locally before staging git commits:
   ```bash
   terraform fmt -recursive
   ```
2. Check git diff to confirm indentation was corrected:
   ```bash
   git diff
   ```
3. Commit and push the clean files.

---

### Error 10: Missing Artifact in Downstream Apply Stage

#### Symptom:
```text
##[error]Artifact 'terraform-plan-dev' was not found for build '20261119.1'.
```

#### Root Cause:
The `Plan` stage did not successfully publish the artifact, or the `Apply` stage referenced a mismatched artifact name.

#### Step-by-Step Fix:
1. Check the `publishLocation` and `artifact` parameters in `templates/terraform-plan.yml`.
2. Verify that the artifact name matches exactly in `templates/terraform-apply.yml`:
   ```yaml
   inputs:
     artifactName: 'terraform-plan-${{ parameters.environment }}'
   ```
3. Ensure the upstream Plan stage succeeded before the Apply stage triggers (`dependsOn: Plan`).

---

## 3. General Debugging Checklist

When encountering any unexpected Terraform or CI/CD behavior:

- [ ] Enable verbose Terraform debugging:
  ```bash
  export TF_LOG="DEBUG"
  export TF_LOG_PATH="terraform-debug.log"
  ```
- [ ] Run `terraform fmt -check` and `terraform validate` locally.
- [ ] Verify variable types in `variables.tf` match the data in `terraform.tfvars`.
- [ ] Ensure subscription quotas (e.g., maximum VNets per region) are not exceeded.
- [ ] Inspect Azure Activity Log in the portal for detailed Azure Resource Manager REST API failure responses.
