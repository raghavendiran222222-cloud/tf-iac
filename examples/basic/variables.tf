variable "subscription_id" {
  type        = string
  sensitive   = true
  default     = "00000000-0000-0000-0000-000000000000"
  description = "Azure Subscription ID."
}

variable "resource_group_name" {
  type        = string
  default     = "rg-myapp-dev-eus2-001"
  description = "Name of the pre-existing Resource Group."
}

variable "server_name" {
  type        = string
  default     = "mysql-myapp-dev-eus2-001"
  description = "Name of the MySQL Flexible Server."
}

variable "location" {
  type        = string
  default     = "eastus2"
  description = "Azure region."
}

variable "administrator_password" {
  type        = string
  sensitive   = true
  default     = "P@ssw0rd1234!"
  description = "MySQL administrator password. Use a real secret in non-test environments."
}
