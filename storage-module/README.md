# storage-module

Child module wrapping `Azure/avm-res-storage-storageaccount/azurerm` with opinionated defaults
for BDT MVP environments.

## Usage

```hcl
module "storage" {
  source = "git::https://github.com/raghavendiran222222-cloud/tf-iac.git//storage-module?ref=storage-module-v0.1.0"

  subscription_id      = var.subscription_id
  resource_group_name  = var.resource_group_name
  storage_account_name = local.storage_name
  location             = var.location

  blob_containers = {
    "uploads" = { access_type = "private" }
    "backups"  = { access_type = "private" }
  }

  tags = {
    Application  = "BDT MVP"
    Owner        = "team@bdtmsd.com"
    Environment  = var.environment
    CostCenter   = ""
  }
}
```

## Inputs

See [variables.tf](variables.tf).

## Outputs

| Name                  | Description                      |
|-----------------------|----------------------------------|
| `storage_account_id`  | Resource ID of the Storage Account |
| `storage_account_name`| Name of the Storage Account      |
| `primary_blob_endpoint` | Primary blob endpoint FQDN     |
| `container_ids`       | Map of container name → resource ID |

## Versioning

Released via git tags on the `alz-modules` branch.
Current stable: `storage-module-v0.1.0`
