data "azurerm_client_config" "current" {}

# ── HCP Vault Secrets ──────────────────────────────────────────────────────────
# Single source of truth for all secrets.
# The HCP provider authenticates via HCP_CLIENT_ID + HCP_CLIENT_SECRET workspace
# variables (set as sensitive in HCP Terraform — never in code or tfvars).
# Terraform reads the values here and writes them into Azure Key Vault once,
# so Container Apps pull them from Azure Key Vault at runtime via Managed Identity.

data "hcp_vault_secrets_secret" "github_pat" {
  app_name    = var.hcp_vault_app_name
  secret_name = "github-pat"
}

data "hcp_vault_secrets_secret" "hcp_terraform_token" {
  app_name    = var.hcp_vault_app_name
  secret_name = "hcp-terraform-token"
}

# ── Resource Group ─────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.tags
}

# ── User Assigned Managed Identity ─────────────────────────────────────────────
# AVM: Azure/avm-res-managedidentity-userassignedidentity/azurerm 0.1.0
# All three Container Apps share this identity.
# Azure MCP uses it for Azure SDK authentication.
# KV grants it Secrets User role so containers can pull secrets at runtime.

module "uami" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.1.0"

  name                = "${local.name_prefix}-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  enable_telemetry    = false
  tags                = local.tags
}

# ── Virtual Network ────────────────────────────────────────────────────────────
# AVM: Azure/avm-res-network-virtualnetwork/azurerm 0.17.1
# Two subnets:
#   snet-container-apps — delegated to Microsoft.App/environments (internal CAE)
#   snet-apim           — for APIM Developer/Premium VNet integration

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  name                = "${local.name_prefix}-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = var.vnet_address_space
  enable_telemetry    = false
  tags                = local.tags

  subnets = {
    container_apps = {
      name             = "snet-container-apps"
      address_prefixes = [var.container_apps_subnet_cidr]
      # Service endpoint lets containers reach Key Vault without a public IP
      service_endpoints = ["Microsoft.KeyVault"]

      delegation = [{
        name = "Microsoft.App-environments"
        service_delegation = {
          name    = "Microsoft.App/environments"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }]

      network_security_group = {
        id = azurerm_network_security_group.container_apps.id
      }
    }

    apim = {
      name             = "snet-apim"
      address_prefixes = [var.apim_subnet_cidr]

      network_security_group = {
        id = azurerm_network_security_group.apim.id
      }
    }
  }
}

# ── NSG: Container Apps (allow only APIM inbound) ─────────────────────────────

resource "azurerm_network_security_group" "container_apps" {
  name                = "${local.name_prefix}-nsg-container-apps"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags

  security_rule {
    name                       = "Allow-APIM-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = var.apim_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Other-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ── NSG: APIM (per Microsoft requirements for Stv2) ───────────────────────────

resource "azurerm_network_security_group" "apim" {
  name                = "${local.name_prefix}-nsg-apim"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags

  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Allow-APIM-Management"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3443"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Allow-Backend-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Allow-AzureAD-Outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureActiveDirectory"
  }
}

# ── Log Analytics Workspace ────────────────────────────────────────────────────
# AVM: Azure/avm-res-operationalinsights-workspace/azurerm 0.4.2

module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.4.2"

  name                = "${local.name_prefix}-law"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  enable_telemetry    = false
  tags                = local.tags
}

# ── Key Vault ──────────────────────────────────────────────────────────────────
# AVM: Azure/avm-res-keyvault-vault/azurerm 0.10.2
# RBAC-only (no legacy access policies). Network ACL restricts to VNet subnet.

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  name                          = "${local.name_prefix}-kv"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  enable_rbac_authorization     = true
  public_network_access_enabled = false
  enable_telemetry              = false
  tags                          = local.tags

  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    virtual_network_subnet_ids = [module.vnet.subnets["container_apps"].resource_id]
    ip_rules                   = []
  }

  role_assignments = {
    deployer = {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = data.azurerm_client_config.current.object_id
      description                = "Terraform deployer — manages secrets"
    }
    mcp_reader = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.uami.principal_id
      description                = "MCP shared identity — reads secrets at runtime"
    }
  }
}

# ── Key Vault Secrets ─────────────────────────────────────────────────────────
# Native resources so we can use ignore_changes and prevent Terraform from
# overwriting secrets that were rotated manually or by a pipeline.

# ── Azure Key Vault Secrets (values sourced from HCP Vault Secrets) ────────────
# HCP Vault Secrets is the single source of truth.
# Azure Key Vault is the runtime store — Container Apps pull from it at startup.
# ignore_changes prevents Terraform from overwriting values rotated in HCP Vault
# after the initial bootstrap. Run `terraform apply -refresh-only` to pick up
# new values from HCP Vault and propagate them to Azure Key Vault.

resource "azurerm_key_vault_secret" "github_pat" {
  name         = "github-pat"
  value        = data.hcp_vault_secrets_secret.github_pat.secret_value
  key_vault_id = module.key_vault.resource_id

  lifecycle {
    ignore_changes = [value]
  }

  depends_on = [module.key_vault]
}

resource "azurerm_key_vault_secret" "hcp_terraform_token" {
  name         = "hcp-terraform-token"
  value        = data.hcp_vault_secrets_secret.hcp_terraform_token.secret_value
  key_vault_id = module.key_vault.resource_id

  lifecycle {
    ignore_changes = [value]
  }

  depends_on = [module.key_vault]
}

# ── Container Apps Environment (internal, VNet-integrated) ─────────────────────
# AVM: Azure/avm-res-app-managedenvironment/azurerm 0.3.0
# internal_load_balancer_enabled = true → no public ingress on any app.
# All traffic must enter via APIM.

module "container_apps_environment" {
  source  = "Azure/avm-res-app-managedenvironment/azurerm"
  version = "0.3.0"

  name                = "${local.name_prefix}-cae"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  log_analytics_workspace_resource_id = module.log_analytics.resource_id
  infrastructure_subnet_id            = module.vnet.subnets["container_apps"].resource_id
  internal_load_balancer_enabled      = true

  workload_profiles = [
    {
      name                  = "Consumption"
      workload_profile_type = "Consumption"
      minimum_count         = 0
      maximum_count         = 0
    }
  ]

  enable_telemetry = false
  tags             = local.tags
}

# ── GitHub MCP Container App ───────────────────────────────────────────────────
# AVM: Azure/avm-res-app-containerapp/azurerm 0.8.0

module "mcp_github" {
  source  = "Azure/avm-res-app-containerapp/azurerm"
  version = "0.8.0"

  name                                  = local.mcp_github.name
  resource_group_name                   = azurerm_resource_group.main.name
  container_app_environment_resource_id = module.container_apps_environment.resource_id
  revision_mode                         = "Single"
  enable_telemetry                      = false

  managed_identities = {
    user_assigned_resource_ids = [module.uami.resource_id]
  }

  ingress = {
    allow_insecure_connections = false
    external_enabled           = false
    target_port                = local.mcp_github.port
    transport                  = "auto"
    traffic_weight = [{
      latest_revision = true
      percentage      = 100
    }]
  }

  secrets = {
    "github-pat" = {
      key_vault_secret_id = azurerm_key_vault_secret.github_pat.versionless_id
      identity            = module.uami.resource_id
    }
  }

  template = {
    min_replicas = local.mcp_github.min_replicas
    max_replicas = local.mcp_github.max_replicas

    containers = [
      {
        name    = "github-mcp"
        image   = local.mcp_github.image
        cpu     = local.mcp_github.cpu
        memory  = local.mcp_github.memory
        command = local.mcp_github.command
        args    = local.mcp_github.args

        env = local.mcp_github.env

        liveness_probe = {
          path             = "/health"
          port             = local.mcp_github.port
          transport        = "HTTP"
          initial_delay    = 10
          interval_seconds = 30
          failure_count_threshold = 3
        }

        readiness_probe = {
          path             = "/health"
          port             = local.mcp_github.port
          transport        = "HTTP"
          interval_seconds = 10
          failure_count_threshold = 3
        }
      }
    ]

    http_scale_rules = [{
      name                = "http-scaling"
      concurrent_requests = 10
    }]
  }

  tags = merge(local.tags, { mcp_server = "github" })
}

# ── Azure MCP Container App ────────────────────────────────────────────────────
# AVM: Azure/avm-res-app-containerapp/azurerm 0.8.0
# Uses Managed Identity for Azure SDK auth — no token secret needed.

module "mcp_azure" {
  source  = "Azure/avm-res-app-containerapp/azurerm"
  version = "0.8.0"

  name                                  = local.mcp_azure.name
  resource_group_name                   = azurerm_resource_group.main.name
  container_app_environment_resource_id = module.container_apps_environment.resource_id
  revision_mode                         = "Single"
  enable_telemetry                      = false

  managed_identities = {
    user_assigned_resource_ids = [module.uami.resource_id]
  }

  ingress = {
    allow_insecure_connections = false
    external_enabled           = false
    target_port                = local.mcp_azure.port
    transport                  = "auto"
    traffic_weight = [{
      latest_revision = true
      percentage      = 100
    }]
  }

  secrets = {}

  template = {
    min_replicas = local.mcp_azure.min_replicas
    max_replicas = local.mcp_azure.max_replicas

    containers = [
      {
        name   = "azure-mcp"
        image  = local.mcp_azure.image
        cpu    = local.mcp_azure.cpu
        memory = local.mcp_azure.memory

        env = concat(local.mcp_azure.env, [
          { name = "AZURE_CLIENT_ID", value = module.uami.client_id, secret_name = null }
        ])

        liveness_probe = {
          path             = "/health"
          port             = local.mcp_azure.port
          transport        = "HTTP"
          initial_delay    = 10
          interval_seconds = 30
          failure_count_threshold = 3
        }

        readiness_probe = {
          path             = "/health"
          port             = local.mcp_azure.port
          transport        = "HTTP"
          interval_seconds = 10
          failure_count_threshold = 3
        }
      }
    ]

    http_scale_rules = [{
      name                = "http-scaling"
      concurrent_requests = 10
    }]
  }

  tags = merge(local.tags, { mcp_server = "azure" })
}

# ── Terraform MCP Container App ────────────────────────────────────────────────
# AVM: Azure/avm-res-app-containerapp/azurerm 0.8.0

module "mcp_terraform" {
  source  = "Azure/avm-res-app-containerapp/azurerm"
  version = "0.8.0"

  name                                  = local.mcp_terraform.name
  resource_group_name                   = azurerm_resource_group.main.name
  container_app_environment_resource_id = module.container_apps_environment.resource_id
  revision_mode                         = "Single"
  enable_telemetry                      = false

  managed_identities = {
    user_assigned_resource_ids = [module.uami.resource_id]
  }

  ingress = {
    allow_insecure_connections = false
    external_enabled           = false
    target_port                = local.mcp_terraform.port
    transport                  = "auto"
    traffic_weight = [{
      latest_revision = true
      percentage      = 100
    }]
  }

  secrets = {
    "hcp-terraform-token" = {
      key_vault_secret_id = azurerm_key_vault_secret.hcp_terraform_token.versionless_id
      identity            = module.uami.resource_id
    }
  }

  template = {
    min_replicas = local.mcp_terraform.min_replicas
    max_replicas = local.mcp_terraform.max_replicas

    containers = [
      {
        name   = "terraform-mcp"
        image  = local.mcp_terraform.image
        cpu    = local.mcp_terraform.cpu
        memory = local.mcp_terraform.memory

        env = local.mcp_terraform.env

        liveness_probe = {
          path             = "/health"
          port             = local.mcp_terraform.port
          transport        = "HTTP"
          initial_delay    = 10
          interval_seconds = 30
          failure_count_threshold = 3
        }

        readiness_probe = {
          path             = "/health"
          port             = local.mcp_terraform.port
          transport        = "HTTP"
          interval_seconds = 10
          failure_count_threshold = 3
        }
      }
    ]

    http_scale_rules = [{
      name                = "http-scaling"
      concurrent_requests = 10
    }]
  }

  tags = merge(local.tags, { mcp_server = "terraform" })
}

# ── Azure Role Assignment — Azure MCP needs read access to subscriptions ───────

resource "azurerm_role_assignment" "azure_mcp_reader" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Reader"
  principal_id         = module.uami.principal_id
}

# ── Azure AD App Registration for Copilot Studio OAuth2 ────────────────────────
# Copilot Studio custom connectors authenticate to this App to obtain a JWT.
# APIM validates the JWT on every inbound request.

resource "azuread_application" "copilot_studio" {
  display_name = "${local.name_prefix}-copilot-studio"

  api {
    requested_access_token_version = 2

    oauth2_permission_scope {
      admin_consent_description  = "Call MCP servers via APIM on behalf of a user"
      admin_consent_display_name = "MCP.Call"
      enabled                    = true
      id                         = "00000000-0000-0000-0000-000000000001"
      type                       = "Admin"
      value                      = "MCP.Call"
    }
  }
}

resource "azuread_service_principal" "copilot_studio" {
  client_id = azuread_application.copilot_studio.client_id
}

# ── API Management ─────────────────────────────────────────────────────────────
# AVM: Azure/avm-res-apimanagement-service/azurerm 0.0.7
# External VNet mode: public HTTPS gateway, backends reach the internal CAE VNet.

module "apim" {
  source  = "Azure/avm-res-apimanagement-service/azurerm"
  version = "0.0.7"

  name                = "${local.name_prefix}-apim"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = var.apim_sku_name
  enable_telemetry    = false

  virtual_network_type = "External"
  virtual_network_configuration = {
    subnet_id = module.vnet.subnets["apim"].resource_id
  }

  tags = local.tags
}

# ── APIM Diagnostics ───────────────────────────────────────────────────────────

resource "azurerm_monitor_diagnostic_setting" "apim" {
  name                       = "apim-diag"
  target_resource_id         = module.apim.resource_id
  log_analytics_workspace_id = module.log_analytics.resource_id

  enabled_log { category = "GatewayLogs" }
  metric { category = "AllMetrics"; enabled = true }
}

# ── APIM Global Policy — JWT validation + security headers ────────────────────
# Applied to every API in this APIM instance.

resource "azurerm_api_management_policy" "global" {
  api_management_id = module.apim.resource_id

  xml_content = <<-XML
    <policies>
      <inbound>
        <validate-jwt header-name="Authorization"
                      failed-validation-httpcode="401"
                      failed-validation-error-message="Unauthorized: valid Azure AD JWT required">
          <openid-config url="https://login.microsoftonline.com/${var.copilot_studio_tenant_id}/v2.0/.well-known/openid-configuration" />
          <audiences>
            <audience>${azuread_application.copilot_studio.client_id}</audience>
          </audiences>
          <issuers>
            <issuer>https://login.microsoftonline.com/${var.copilot_studio_tenant_id}/v2.0</issuer>
          </issuers>
          <required-claims>
            <claim name="scp" match="any">
              <value>MCP.Call</value>
            </claim>
          </required-claims>
        </validate-jwt>
        <rate-limit calls="60" renewal-period="60" />
        <cors allow-credentials="true">
          <allowed-origins>
            <origin>https://copilotstudio.microsoft.com</origin>
          </allowed-origins>
          <allowed-methods preflight-result-max-age="86400">
            <method>GET</method>
            <method>POST</method>
            <method>OPTIONS</method>
          </allowed-methods>
          <allowed-headers>
            <header>Authorization</header>
            <header>Content-Type</header>
          </allowed-headers>
        </cors>
      </inbound>
      <backend>
        <forward-request timeout="30" />
      </backend>
      <outbound>
        <set-header name="X-Content-Type-Options" exists-action="override"><value>nosniff</value></set-header>
        <set-header name="X-Frame-Options" exists-action="override"><value>DENY</value></set-header>
        <set-header name="Strict-Transport-Security" exists-action="override">
          <value>max-age=31536000; includeSubDomains</value>
        </set-header>
      </outbound>
      <on-error>
        <return-response>
          <set-status code="@(context.Response.StatusCode)" reason="@(context.Response.StatusReason)" />
          <set-header name="Content-Type" exists-action="override"><value>application/json</value></set-header>
          <set-body>{"error":"@(context.LastError.Message)"}</set-body>
        </return-response>
      </on-error>
    </policies>
  XML
}

# ── APIM Backends — one per MCP server ────────────────────────────────────────

resource "azurerm_api_management_backend" "github" {
  name                = "github-mcp"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = module.apim.resource.name
  protocol            = "http"
  url                 = "https://${module.mcp_github.resource.ingress[0].fqdn}"
  tls {
    validate_certificate_chain = true
    validate_certificate_name  = true
  }
}

resource "azurerm_api_management_backend" "azure" {
  name                = "azure-mcp"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = module.apim.resource.name
  protocol            = "http"
  url                 = "https://${module.mcp_azure.resource.ingress[0].fqdn}"
  tls {
    validate_certificate_chain = true
    validate_certificate_name  = true
  }
}

resource "azurerm_api_management_backend" "terraform" {
  name                = "terraform-mcp"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = module.apim.resource.name
  protocol            = "http"
  url                 = "https://${module.mcp_terraform.resource.ingress[0].fqdn}"
  tls {
    validate_certificate_chain = true
    validate_certificate_name  = true
  }
}

# ── APIM APIs — one per MCP server ────────────────────────────────────────────

locals {
  apim_apis = {
    github = {
      name         = "github-mcp"
      display_name = "GitHub MCP Server"
      path         = "github"
      backend_id   = azurerm_api_management_backend.github.name
    }
    azure = {
      name         = "azure-mcp"
      display_name = "Azure MCP Server"
      path         = "azure"
      backend_id   = azurerm_api_management_backend.azure.name
    }
    terraform = {
      name         = "terraform-mcp"
      display_name = "Terraform MCP Server"
      path         = "terraform"
      backend_id   = azurerm_api_management_backend.terraform.name
    }
  }
}

resource "azurerm_api_management_api" "mcp" {
  for_each = local.apim_apis

  name                  = each.value.name
  resource_group_name   = azurerm_resource_group.main.name
  api_management_name   = module.apim.resource.name
  revision              = "1"
  display_name          = each.value.display_name
  path                  = each.value.path
  protocols             = ["https"]
  subscription_required = false

  import {
    content_format = "openapi"
    content_value  = <<-YAML
      openapi: "3.0.1"
      info:
        title: "${each.value.display_name}"
        version: "1.0"
      paths:
        /sse:
          get:
            operationId: "connect-sse"
            summary: "Open SSE stream (MCP transport)"
            responses:
              "200":
                description: "Server-Sent Events stream"
        /message:
          post:
            operationId: "send-message"
            summary: "Send MCP JSON-RPC message"
            requestBody:
              required: true
              content:
                application/json:
                  schema:
                    type: object
            responses:
              "200":
                description: "MCP JSON-RPC response"
                content:
                  application/json:
                    schema:
                      type: object
    YAML
  }
}

resource "azurerm_api_management_api_policy" "mcp" {
  for_each = local.apim_apis

  api_name            = azurerm_api_management_api.mcp[each.key].name
  api_management_name = module.apim.resource.name
  resource_group_name = azurerm_resource_group.main.name

  xml_content = <<-XML
    <policies>
      <inbound>
        <base />
        <set-backend-service backend-id="${each.value.backend_id}" />
        <!-- Strip caller JWT before forwarding — backend authenticates via Managed Identity -->
        <set-header name="Authorization" exists-action="delete" />
        <set-header name="X-MCP-Server" exists-action="override">
          <value>${each.value.name}</value>
        </set-header>
      </inbound>
      <backend><base /></backend>
      <outbound><base /></outbound>
      <on-error><base /></on-error>
    </policies>
  XML
}

# ── APIM Product — bundles all three MCP APIs for Copilot Studio ───────────────

resource "azurerm_api_management_product" "mcp" {
  product_id            = "mcp-servers"
  api_management_name   = module.apim.resource.name
  resource_group_name   = azurerm_resource_group.main.name
  display_name          = "MCP Servers"
  description           = "GitHub, Azure, and Terraform MCP servers for Copilot Studio"
  subscription_required = false
  published             = true
}

resource "azurerm_api_management_product_api" "mcp" {
  for_each = local.apim_apis

  api_name            = azurerm_api_management_api.mcp[each.key].name
  product_id          = azurerm_api_management_product.mcp.product_id
  api_management_name = module.apim.resource.name
  resource_group_name = azurerm_resource_group.main.name
}
