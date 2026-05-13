# non-prod/mvp-app

Root module for the BDT MVP application workload: VNet, App Service, MySQL Flexible Server,
and Azure Storage Account, using Azure Verified Modules (AVM).

## Architecture

```
VNet (10.30.0.0/16)
  ├── snet-bdt-app  → App Service Plan + Linux Web App (VNet Integration)
  └── snet-bdt-data → MySQL Flexible Server (Private DNS Zone)

Storage Account (LRS, StorageV2)
  ├── uploads container
  └── backups container
```

## Prerequisites

- Terraform >= 1.9
- Azure subscription with Contributor permissions on the target resource group
- HCP Terraform Cloud organisation and workspace `mvp-app` in project `alz-landingzones-infra-non-prod`
- MySQL admin password available via `TF_VAR_mysql_admin_password` or HashiCorp Vault

## Usage

```bash
# Copy and fill in your values
cp terraform.tfvars.example terraform.tfvars

terraform init
terraform plan
terraform apply
```

## HCP Terraform Cloud Backend

Organisation : `<organization-name>`
Workspace    : `mvp-app`
Project      : `alz-landingzones-infra-non-prod`

Set the following as **sensitive environment variables** in the HCP Terraform workspace:

| Variable                  | Description                        |
|---------------------------|------------------------------------|
| `ARM_CLIENT_ID`           | Azure SP client ID                 |
| `ARM_CLIENT_SECRET`       | Azure SP client secret             |
| `ARM_SUBSCRIPTION_ID`     | Target Azure subscription          |
| `ARM_TENANT_ID`           | Azure AD tenant                    |
| `TF_VAR_mysql_admin_password` | MySQL administrator password   |

## Inputs

See [variables.tf](variables.tf) for full descriptions and validations.

## Outputs

| Name                   | Description                              |
|------------------------|------------------------------------------|
| `vnet_id`              | Resource ID of the VNet                  |
| `app_service_hostname` | Default hostname of the App Service      |
| `mysql_server_name`    | MySQL Flexible Server name               |
| `mysql_server_fqdn`    | MySQL Flexible Server FQDN               |
| `storage_account_name` | Storage Account name                     |
| `storage_blob_endpoint`| Primary blob endpoint                    |
