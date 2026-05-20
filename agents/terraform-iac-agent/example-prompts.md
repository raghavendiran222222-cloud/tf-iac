# Terraform IaC Agent — Example Test Prompts

Use these prompts to validate the agent in Copilot Studio. Each prompt covers a distinct mode and scenario.

---

## Module Creation (alz-modules branch)

### Prompt 1 — New module, basic
```
Create a Key Vault module for the alz-modules branch. It should support RBAC authorization,
optional soft-delete configuration, and network ACLs to restrict access to a specific subnet.
```
**Expected behavior:**
- Creates branch `keyvault-module` off `alz-modules`
- Generates `keyvault-module/` folder with: `main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `versions.tf`, `CHANGELOG.md`, `README.md`, `examples/basic/main.tf`
- Uses `Azure/avm-res-keyvault-vault/azurerm` v0.10.2
- Opens PR to `alz-modules`

### Prompt 2 — New module, advanced feature
```
Create a storage module that supports lifecycle management policies in addition to
the existing basic storage account and blob container features.
Target the alz-modules branch.
```
**Expected behavior:**
- Creates branch `storage-module-lifecycle` or new module branch off `alz-modules`
- Adds `azurerm_storage_management_policy` resource, optional lifecycle variable
- Follows existing storage-module pattern exactly (naming, tags, try/null outputs)

### Prompt 3 — New networking module
```
Build a networking module for alz-modules that provisions a VNet with configurable subnets,
an NSG per subnet, and subnet-NSG association. Each subnet should support optional delegations.
```
**Expected behavior:**
- Creates branch `networking-module` off `alz-modules`
- Uses `Azure/avm-res-network-virtualnetwork/azurerm` v0.17.1 and `Azure/avm-res-network-networksecuritygroup/azurerm` v0.5.1
- Subnets as variable list of objects with optional delegation

---

## Application Creation (alz-landingzones-infra branch, non-prod)

### Prompt 4 — New non-prod app, standard 3-tier
```
Create a new app called payments-api for the dev environment. It needs a VNet,
App Service Plan (Linux, B2 SKU), App Service, MySQL Flexible Server, and
a Storage Account with a "receipts" blob container.
```
**Expected behavior:**
- Creates branch `payments-api-dev` off `alz-landingzones-infra`
- Generates `non-prod/payments-api/` with all 10 files
- Naming: `vnet-bdt-payments-api-dev-eus2-001`, etc.
- Backend workspace: `alz-landingzones-payments-api`, tags `["non-prod"]`
- Opens PR to `alz-landingzones-infra`

### Prompt 5 — New non-prod app, Container Apps runtime
```
Create a qa environment for the auth-service application. It should use
Azure Container Apps with a managed environment, Key Vault for secrets,
and Log Analytics for diagnostics.
```
**Expected behavior:**
- Creates branch `auth-service-qa` off `alz-landingzones-infra`
- Generates `non-prod/auth-service/` with all 10 files
- Uses `Azure/avm-res-app-managedenvironment/azurerm` v0.3.0 and `Azure/avm-res-app-containerapp/azurerm` v0.8.0
- Includes `Azure/avm-res-keyvault-vault/azurerm` and `Azure/avm-res-operationalinsights-workspace/azurerm`

---

## Application Creation (prod tier)

### Prompt 6 — New prod app
```
Create a prod landing zone for the reporting-app. Resources needed: Storage Account
with GRS replication, Log Analytics Workspace, and resource locks enabled.
```
**Expected behavior:**
- Creates branch `reporting-app-prod` off `alz-landingzones-infra`
- Generates `prod/reporting-app/` with all 10 files
- Backend workspace tags: `["prod"]`
- `enable_resource_lock = true` variable with `CanNotDelete` lock applied
- Opens PR to `alz-landingzones-infra`

---

## Modify Existing (ModifyExisting mode)

### Prompt 7 — Add variable to existing app
```
Add a variable to the mvp-app for enabling private endpoints on the Storage Account.
The variable should be a boolean with a default of false.
```
**Expected behavior:**
- Reads current `non-prod/mvp-app/variables.tf` from `alz-landingzones-infra`
- Adds `enable_storage_private_endpoint` boolean variable with `default = false`
- Creates branch `update-mvp-app-storage-private-endpoint`
- Commits only the modified `variables.tf`
- Opens PR to `alz-landingzones-infra`

### Prompt 8 — Add feature to existing module
```
Update the storage-module on alz-modules to support enabling blob soft delete
with a configurable retention period in days.
```
**Expected behavior:**
- Reads current `storage-module/variables.tf` and `storage-module/main.tf` from `alz-modules`
- Adds `soft_delete_retention_days` optional variable (default null = disabled)
- Updates `azurerm_storage_account` with `blob_properties { delete_retention_policy { days = ... } }` block gated on null check
- Creates branch `update-storage-module-soft-delete`
- Commits only modified files
- Opens PR to `alz-modules`

---

## Explain Code (ExplainCode mode — no PR)

### Prompt 9 — Explain a module file
```
Explain how the storage-module locals.tf works. I'm new to Terraform and
don't understand the region_abbr_map or the merged_tags pattern.
```
**Expected behavior:**
- Reads `storage-module/locals.tf` from `alz-modules`
- Explains `_region_abbr_map`, `lookup()`, `merged_tags = merge(...)` in plain English
- Explains why `Environment` is overridden in the merge
- No branch or PR created

### Prompt 10 — Explain an app design decision
```
Walk me through what the mvp-app backend.tf does and why it uses
HCP Terraform Cloud instead of a local backend or Azure Blob backend.
```
**Expected behavior:**
- Reads `non-prod/mvp-app/backend.tf` from `alz-landingzones-infra`
- Explains HCP Terraform Cloud remote state: workspace, organization, tags
- Explains the trade-offs vs azurerm backend (state locking, UI, run history)
- No branch or PR created
