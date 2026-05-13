# Alz-modules

This repository contains custom Terraform modules used across landing zones and infrastructure deployments.

## Structure

Each subdirectory is a self-contained child module, versioned via git tags and consumable by root configurations in other repositories.

## Modules

| Module | Description |
|--------|-------------|
| `storage-module` | Azure Storage Account module for ALZ landing zones |

## Usage

Reference a module from this repo using a git source:

```hcl
module "storage" {
  source = "git::https://github.com/<org>/tf-iac.git//storage-module?ref=storage-module/v1.0.0"
}
```
