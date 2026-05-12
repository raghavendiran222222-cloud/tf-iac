locals {
  region_abbr = {
    eastus2     = "eus2"
    centralus   = "cus"
    eastus      = "eus"
    westus2     = "wus2"
    westeurope  = "weu"
    northeurope = "neu"
  }
  abbr = local.region_abbr[var.location]

  # Resource names
  asp_name               = "asp-bdt-mcp-${var.environment}-${local.abbr}-001"
  kv_name                = "kv-bdt-mcp-${var.environment}-${local.abbr}-001"
  law_name               = "law-bdt-mcp-${var.environment}-${local.abbr}-001"
  github_mcp_app_name    = "app-bdt-mcp-github-${var.environment}-${local.abbr}-001"
  terraform_mcp_app_name = "app-bdt-mcp-terraform-${var.environment}-${local.abbr}-001"
  azure_mcp_app_name     = "app-bdt-mcp-azure-${var.environment}-${local.abbr}-001"

  common_tags = merge(var.tags, {
    ManagedBy    = "Terraform"
    CreationDate = formatdate("MMDDYYYY", timestamp())
  })
}
