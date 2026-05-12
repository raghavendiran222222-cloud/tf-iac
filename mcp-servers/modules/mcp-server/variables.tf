variable "name" {
  description = "Name of the App Service (MCP server)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the pre-existing resource group."
  type        = string
}

variable "location" {
  description = "Azure region for the App Service."
  type        = string
}

variable "service_plan_id" {
  description = "Resource ID of the shared App Service Plan."
  type        = string
}

variable "docker_image" {
  description = "Docker image name (registry/image, without tag)."
  type        = string
}

variable "docker_image_tag" {
  description = "Docker image tag to deploy."
  type        = string
  default     = "latest"
}

variable "app_settings" {
  description = "Application settings (environment variables) for the MCP server."
  type        = map(string)
  default     = {}
}

variable "identity_type" {
  description = "Managed identity type. Use 'SystemAssigned' for Azure MCP, 'UserAssigned' for KV access, 'None' for no identity."
  type        = string
  default     = "None"
  validation {
    condition     = contains(["None", "SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "identity_type must be None, SystemAssigned, or UserAssigned."
  }
}

variable "user_assigned_identity_ids" {
  description = "List of user-assigned identity resource IDs. Required when identity_type is UserAssigned."
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace for diagnostic settings."
  type        = string
}

variable "enable_resource_lock" {
  description = "Enable CanNotDelete resource lock on the App Service."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
