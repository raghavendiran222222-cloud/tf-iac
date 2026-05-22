variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group used for GHA workflow testing."
  default     = "rg-gha-test"
}

variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "eastus"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource."
  default = {
    environment = "test"
    managed-by  = "terraform"
    purpose     = "github-actions-testing"
  }
}
