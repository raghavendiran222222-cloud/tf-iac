# non-prod/infra-agent

Root module for the MCP Server infrastructure: GitHub MCP, Azure MCP, and Terraform MCP servers
hosted on Azure Container Apps, fronted by API Management, with secrets sourced from HCP Vault Secrets.

## Architecture

```
Internet → APIM (External VNet) → Container Apps Env (Internal VNet)
                                      ├── GitHub MCP Container App
                                      ├── Azure MCP Container App
                                      └── Terraform MCP Container App
HCP Vault Secrets → Azure Key Vault ← Container Apps (UAMI pull at runtime)
```

## Prerequisites

- Terraform >= 1.9
- Azure subscription with Contributor + User Access Administrator permissions
- HCP Terraform Cloud organisation and workspace `infra-agent` in project `alz-landingzones-infra-non-prod`
- HCP Vault Secrets app containing `github-pat` and `hcp-terraform-token` secrets

## Usage

```hcl
# Copy terraform.tfvars.example to terraform.tfvars and fill in values.
# Never commit terraform.tfvars.
terraform init
terraform plan
terraform apply
```

## HCP Terraform Cloud Backend

Organisation : `<organization-name>`
Workspace    : `infra-agent`
Project      : `alz-landingzones-infra-non-prod`

Set the following as **sensitive environment variables** in the HCP Terraform workspace:

| Variable             | Description                          |
|----------------------|--------------------------------------|
| `HCP_CLIENT_ID`      | HCP service principal client ID      |
| `HCP_CLIENT_SECRET`  | HCP service principal client secret  |
| `ARM_CLIENT_ID`      | Azure SP client ID (from Key Vault)  |
| `ARM_CLIENT_SECRET`  | Azure SP client secret               |
| `ARM_SUBSCRIPTION_ID`| Target Azure subscription            |
| `ARM_TENANT_ID`      | Azure AD tenant                      |

## Inputs

See [variables.tf](variables.tf) for full descriptions and validations.

## Outputs

| Name                          | Description                                    |
|-------------------------------|------------------------------------------------|
| `apim_gateway_url`            | Base URL for Copilot Studio custom connectors  |
| `mcp_api_endpoints`           | Per-server APIM endpoints                      |
| `copilot_studio_app_client_id`| OAuth2 App Registration client ID             |
| `copilot_studio_oauth_token_url` | OAuth2 token endpoint                       |
| `key_vault_uri`               | Key Vault URI for manual rotation              |
