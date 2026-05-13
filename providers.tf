provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azuread" {
  tenant_id = var.tenant_id
}

# ── HCP Provider ───────────────────────────────────────────────────────────────
# Authentication via HCP_CLIENT_ID and HCP_CLIENT_SECRET environment variables
# (set these as sensitive workspace variables in HCP Terraform, not in code).
# When running in HCP Terraform, workload identity (OIDC) is also supported:
# https://developer.hashicorp.com/hcp/docs/hcp-terraform/workload-identity
provider "hcp" {
  project_id = var.hcp_project_id
}
