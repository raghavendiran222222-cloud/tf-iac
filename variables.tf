variable "root_management_group_id" {
  type        = string
  description = "The name/ID for the top-level management group created under the Tenant Root Group (e.g. 'bdt'). Used as prefix for all child management groups."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{2,90}$", var.root_management_group_id))
    error_message = "root_management_group_id must be 2-90 characters, alphanumeric and hyphens only."
  }
}

variable "root_management_group_display_name" {
  type        = string
  description = "The display name for the top-level management group (e.g. 'BDT')."
}

variable "subscription_id_management" {
  type        = string
  description = "Subscription ID for the Management platform subscription. Placed under the <prefix>-management management group."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id_management))
    error_message = "subscription_id_management must be a valid UUID."
  }
}

variable "subscription_id_connectivity" {
  type        = string
  description = "Subscription ID for the Connectivity platform subscription. Placed under the <prefix>-connectivity management group."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id_connectivity))
    error_message = "subscription_id_connectivity must be a valid UUID."
  }
}

variable "subscription_id_identity" {
  type        = string
  description = "Subscription ID for the Identity platform subscription. Placed under the <prefix>-identity management group."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id_identity))
    error_message = "subscription_id_identity must be a valid UUID."
  }
}

variable "location" {
  type        = string
  default     = "eastus2"
  description = "Azure region for policy remediation resources. Per FDD, East US 2 is the primary region."
}

variable "parent_management_group_id" {
  type        = string
  default     = ""
  description = "ID of the parent management group under which the root ALZ management group is created. Leave empty to default to the Tenant Root Group."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Enable AVM telemetry. Set to false to opt out of Microsoft usage data collection."
}

variable "default_tags" {
  type        = map(string)
  default     = {}
  description = "Default tags applied to all resources. Recommended FDD tags: Application, CreationDate, DevOwner, BusinessOwner, Environment, CostCenter, DataClassification, BusinessCriticality, Compliance."
}
