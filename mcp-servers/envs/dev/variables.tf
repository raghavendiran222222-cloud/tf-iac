variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID (used by the Azure MCP server)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the pre-existing resource group for MCP servers."
  type        = string
}

variable "location" {
  description = "Azure region for all MCP server resources."
  type        = string
  default     = "eastus2"
  validation {
    condition     = contains(["eastus2", "centralus", "eastus", "westus2", "westeurope", "northeurope"], var.location)
    error_message = "Location must be one of the approved Azure regions."
  }
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["sandbox", "dev", "test", "stage", "qa", "uat", "sit", "prod", "nonprod"], var.environment)
    error_message = "Environment must be a valid BDT environment name."
  }
}

variable "github_pat" {
  description = "GitHub Personal Access Token for the GitHub MCP server. Set via TF_VAR_github_pat."
  type        = string
  sensitive   = true
}

variable "tfc_token" {
  description = "HCP Terraform Cloud API token for the Terraform MCP server. Set via TF_VAR_tfc_token."
  type        = string
  sensitive   = true
}

variable "tfc_organization" {
  description = "HCP Terraform Cloud organization name."
  type        = string
  default     = "bdtmsd"
}

variable "tags" {
  description = "Resource tags applied to all MCP server resources."
  type = object({
    Application         = string
    DevOwner            = string
    BusinessOwner       = string
    Environment         = string
    DataClassification  = string
    BusinessCriticality = string
    IACRepository       = string
    CostCenter          = optional(string, "")
  })
}
