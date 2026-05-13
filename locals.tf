locals {
  name_prefix = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  })

  # ── MCP server definitions ────────────────────────────────────────────────────
  # Each entry drives one call to the AVM Container App module in main.tf.

  mcp_github = {
    name         = "${local.name_prefix}-github-mcp"
    image        = "ghcr.io/github/github-mcp-server:latest"
    port         = 8080
    cpu          = 0.5
    memory       = "1Gi"
    min_replicas = 1
    max_replicas = 3
    command      = ["github-mcp-server"]
    args         = ["--transport", "sse"]
    env = [
      { name = "GITHUB_TOOLSETS", value = "all", secret_name = null },
      { name = "GITHUB_PERSONAL_ACCESS_TOKEN", value = null, secret_name = "github-pat" },
    ]
    kv_secret_refs = { "github-pat" = "github-pat" }
  }

  mcp_azure = {
    name         = "${local.name_prefix}-azure-mcp"
    image        = "mcr.microsoft.com/azure-mcp-server:latest"
    port         = 3000
    cpu          = 0.5
    memory       = "1Gi"
    min_replicas = 1
    max_replicas = 3
    command      = []
    args         = []
    env = [
      { name = "AZURE_SUBSCRIPTION_ID", value = var.subscription_id, secret_name = null },
      { name = "AZURE_TENANT_ID", value = var.tenant_id, secret_name = null },
    ]
    kv_secret_refs = {}
  }

  mcp_terraform = {
    name         = "${local.name_prefix}-terraform-mcp"
    image        = "hashicorp/terraform-mcp-server:latest"
    port         = 8080
    cpu          = 0.5
    memory       = "1Gi"
    min_replicas = 1
    max_replicas = 3
    command      = []
    args         = []
    env = [
      { name = "TFC_TOKEN", value = null, secret_name = "hcp-terraform-token" },
      { name = "TFC_ORG", value = var.hcp_terraform_org, secret_name = null },
    ]
    kv_secret_refs = { "hcp-terraform-token" = "hcp-terraform-token" }
  }
}
