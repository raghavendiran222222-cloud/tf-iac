terraform {
  required_version = ">= 1.9, < 2.0"

  # ── HCP Terraform Cloud backend ────────────────────────────────────────────
  # Set TF_CLOUD_ORGANIZATION and TF_WORKSPACE env vars, or replace the
  # placeholders below with your actual org / workspace names.
  cloud {
    organization = "REPLACE_WITH_YOUR_HCP_ORG"

    workspaces {
      # Use a separate workspace per environment, e.g. mcp-servers-dev
      name = "REPLACE_WITH_YOUR_WORKSPACE"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.72"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.111"
    }
  }
}
