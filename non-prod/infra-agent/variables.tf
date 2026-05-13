variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus2"
}

variable "project" {
  description = "Project name used as a naming prefix"
  type        = string
  default     = "mcp"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod"
  }
}

variable "tags" {
  description = "Additional tags applied to all resources"
  type        = map(string)
  default     = {}
}

# ── HCP ────────────────────────────────────────────────────────────────────────

variable "hcp_project_id" {
  description = "HCP project ID (visible in HCP Portal → Settings → General)"
  type        = string
}

variable "hcp_vault_app_name" {
  description = "HCP Vault Secrets application name that holds github-pat and hcp-terraform-token"
  type        = string
  default     = "mcp-servers"
}

variable "hcp_terraform_org" {
  description = "HCP Terraform organisation name (injected into the Terraform MCP server as TFC_ORG)"
  type        = string
}

# ── Networking ─────────────────────────────────────────────────────────────────

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "container_apps_subnet_cidr" {
  description = "CIDR for Container Apps Environment subnet (delegated, min /27)"
  type        = string
  default     = "10.0.0.0/23"
}

variable "apim_subnet_cidr" {
  description = "CIDR for API Management subnet (min /28 for Stv2)"
  type        = string
  default     = "10.0.4.0/28"
}

# ── API Management ─────────────────────────────────────────────────────────────

variable "apim_publisher_name" {
  description = "APIM publisher display name"
  type        = string
}

variable "apim_publisher_email" {
  description = "APIM publisher email address"
  type        = string
}

variable "apim_sku_name" {
  description = "APIM SKU (Developer_1 for dev/test; Premium_1 for prod HA + SLA)"
  type        = string
  default     = "Developer_1"
}

# ── Copilot Studio OAuth ───────────────────────────────────────────────────────

variable "copilot_studio_tenant_id" {
  description = "Azure AD tenant where Copilot Studio is registered — used for JWT validation"
  type        = string
}
