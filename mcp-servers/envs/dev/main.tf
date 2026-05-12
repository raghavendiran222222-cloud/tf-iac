provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

data "azurerm_client_config" "current" {}

# ── Observability ────────────────────────────────────────────────────────────

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.law_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

# ── Key Vault (stores MCP server API tokens) ─────────────────────────────────

resource "azurerm_key_vault" "this" {
  name                          = local.kv_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  enable_rbac_authorization     = true
  public_network_access_enabled = true
  tags                          = local.common_tags
}

# Grant the Terraform deployer Key Vault Secrets Officer so it can write secrets
resource "azurerm_role_assignment" "kv_deployer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# MCP server tokens stored as Key Vault secrets
resource "azurerm_key_vault_secret" "github_pat" {
  name         = "github-pat"
  value        = var.github_pat
  key_vault_id = azurerm_key_vault.this.id
  tags         = local.common_tags

  depends_on = [azurerm_role_assignment.kv_deployer]
}

resource "azurerm_key_vault_secret" "tfc_token" {
  name         = "tfc-token"
  value        = var.tfc_token
  key_vault_id = azurerm_key_vault.this.id
  tags         = local.common_tags

  depends_on = [azurerm_role_assignment.kv_deployer]
}

# ── App Service Plan (shared across all 3 MCP servers) ───────────────────────

resource "azurerm_service_plan" "this" {
  name                = local.asp_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B2"
  tags                = local.common_tags
}

# ── User-assigned identity (shared by GitHub + Terraform MCP for KV access) ──

resource "azurerm_user_assigned_identity" "mcp_kv_reader" {
  name                = "id-bdt-mcp-kv-${var.environment}-${local.abbr}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "mcp_kv_reader" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.mcp_kv_reader.principal_id
}

# ── MCP Server: GitHub ────────────────────────────────────────────────────────

module "github_mcp" {
  source = "../../modules/mcp-server"

  name                       = local.github_mcp_app_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  service_plan_id            = azurerm_service_plan.this.id
  docker_image               = "ghcr.io/github/github-mcp-server"
  docker_image_tag           = "latest"
  identity_type              = "UserAssigned"
  user_assigned_identity_ids = [azurerm_user_assigned_identity.mcp_kv_reader.id]
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  app_settings = {
    GITHUB_PERSONAL_ACCESS_TOKEN                   = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.github_pat.versionless_id})"
    WEBSITES_PORT                                  = "8080"
    AZURE_CLIENT_ID                                = azurerm_user_assigned_identity.mcp_kv_reader.client_id
  }

  tags = local.common_tags

  depends_on = [azurerm_role_assignment.mcp_kv_reader]
}

# ── MCP Server: HCP Terraform ────────────────────────────────────────────────

module "terraform_mcp" {
  source = "../../modules/mcp-server"

  name                       = local.terraform_mcp_app_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  service_plan_id            = azurerm_service_plan.this.id
  docker_image               = "hashicorp/terraform-mcp-server"
  docker_image_tag           = "latest"
  identity_type              = "UserAssigned"
  user_assigned_identity_ids = [azurerm_user_assigned_identity.mcp_kv_reader.id]
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  app_settings = {
    TFC_TOKEN                                      = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.tfc_token.versionless_id})"
    TFC_ORGANIZATION                               = var.tfc_organization
    WEBSITES_PORT                                  = "8080"
    AZURE_CLIENT_ID                                = azurerm_user_assigned_identity.mcp_kv_reader.client_id
  }

  tags = local.common_tags

  depends_on = [azurerm_role_assignment.mcp_kv_reader]
}

# ── MCP Server: Azure ─────────────────────────────────────────────────────────

module "azure_mcp" {
  source = "../../modules/mcp-server"

  name                       = local.azure_mcp_app_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  service_plan_id            = azurerm_service_plan.this.id
  docker_image               = "mcr.microsoft.com/azure-mcp-server"
  docker_image_tag           = "latest"
  identity_type              = "SystemAssigned"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  app_settings = {
    AZURE_SUBSCRIPTION_ID = var.subscription_id
    AZURE_TENANT_ID       = var.tenant_id
    WEBSITES_PORT         = "8080"
  }

  tags = local.common_tags
}

# Grant Azure MCP's system identity Reader on the subscription so it can query Azure resources
resource "azurerm_role_assignment" "azure_mcp_reader" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Reader"
  principal_id         = module.azure_mcp.identity_principal_id
}
