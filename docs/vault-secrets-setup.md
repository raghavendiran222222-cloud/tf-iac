# HCP Vault Dedicated — Secrets & GitHub Actions Setup

All Azure credentials and Terraform tokens are stored in HCP Vault Dedicated and
fetched at runtime via `hashicorp/vault-action`. This document covers:

1. [Prerequisites](#1-prerequisites)
2. [Enable the KV v2 secrets engine](#2-enable-the-kv-v2-secrets-engine)
3. [Store secrets in Vault](#3-store-secrets-in-vault)
4. [Create a Vault policy](#4-create-a-vault-policy)
5. [Configure JWT auth for GitHub Actions](#5-configure-jwt-auth-for-github-actions)
6. [Create a Vault role](#6-create-a-vault-role)
7. [Add GitHub repository secrets](#7-add-github-repository-secrets)
8. [Secret paths reference](#8-secret-paths-reference)

---

## 1. Prerequisites

| Requirement | Notes |
|-------------|-------|
| HCP Vault Dedicated cluster | Tier: Plus or above (JWT auth requires network access) |
| `vault` CLI | `brew install vault` |
| Admin Vault token | From the HCP portal → Vault cluster → **Generate token** |
| Azure Service Principal | With OIDC federated credential for GitHub Actions |
| HCP Terraform (TFE) token | From app.terraform.io → User Settings → **Tokens** |

Set your shell environment before running any `vault` commands:

```bash
export VAULT_ADDR="https://<cluster-name>.vault.<region>.hashicorp.cloud:8200"
export VAULT_NAMESPACE="admin"          # HCP Vault always uses a namespace
export VAULT_TOKEN="<your-admin-token>"
```

Verify connectivity:

```bash
vault status
```

---

## 2. Enable the KV v2 secrets engine

```bash
vault secrets enable -path=kv kv-v2
```

If `kv` is already enabled you will see `Error enabling: ... path is already in use`.
That is fine — skip this step.

---

## 3. Store secrets in Vault

### 3a. Azure credentials

```bash
vault kv put kv/azure \
  client_id="<azure-sp-client-id>" \
  tenant_id="<azure-tenant-id>" \
  subscription_id="<azure-subscription-id>"
```

Verify:

```bash
vault kv get kv/azure
```

### 3b. Terraform / HCP Terraform credentials

```bash
vault kv put kv/terraform \
  organization="<hcp-terraform-org-name>" \
  tfe_token="<hcp-terraform-api-token>"
```

Verify:

```bash
vault kv get kv/terraform
```

### Updating a single field without overwriting others

KV v2 `put` replaces the entire secret. Use `patch` to update one key:

```bash
vault kv patch kv/azure client_id="<new-client-id>"
vault kv patch kv/terraform tfe_token="<new-token>"
```

### Rotating a secret

```bash
# Write the new value
vault kv patch kv/azure client_id="<rotated-client-id>"

# Confirm the new version is active
vault kv metadata get kv/azure
```

---

## 4. Create a Vault policy

Save the following as `github-actions-policy.hcl`:

```hcl
# github-actions-policy.hcl

path "kv/data/azure" {
  capabilities = ["read"]
}

path "kv/data/terraform" {
  capabilities = ["read"]
}
```

Apply the policy:

```bash
vault policy write github-actions github-actions-policy.hcl
```

---

## 5. Configure JWT auth for GitHub Actions

GitHub Actions exposes an OIDC token per workflow run. Vault's JWT auth method
validates this token without storing any long-lived credentials.

### Enable JWT auth

```bash
vault auth enable jwt
```

### Configure the JWT auth method

```bash
vault write auth/jwt/config \
  oidc_discovery_url="https://token.actions.githubusercontent.com" \
  bound_issuer="https://token.actions.githubusercontent.com"
```

---

## 6. Create a Vault role

The role restricts which GitHub repositories and refs are allowed to authenticate.

```bash
vault write auth/jwt/role/github-actions \
  role_type="jwt" \
  bound_audiences="https://vault.hashicorp.com" \
  user_claim="sub" \
  bound_claims_type="glob" \
  bound_claims='{
    "sub": "repo:<github-org>/<repo-name>:*"
  }' \
  policies="github-actions" \
  ttl="15m"
```

Replace `<github-org>/<repo-name>` with your actual values, e.g.
`myorg/tf-iac`.

The `sub` glob `repo:<org>/<repo>:*` allows all branches and workflows in that
repository. To restrict to a specific branch:

```bash
bound_claims='{"sub":"repo:<github-org>/<repo-name>:ref:refs/heads/main"}'
```

Verify the role was created:

```bash
vault read auth/jwt/role/github-actions
```

---

## 7. Add GitHub repository secrets

Only two secrets need to be set in GitHub — everything else comes from Vault.

Navigate to **GitHub repo → Settings → Secrets and variables → Actions → New repository secret**.

| Secret name | Value |
|-------------|-------|
| `VAULT_ADDR` | `https://<cluster-name>.vault.<region>.hashicorp.cloud:8200` |
| `VAULT_ROLE` | `github-actions` |

Using the GitHub CLI:

```bash
gh secret set VAULT_ADDR --body "https://<cluster-name>.vault.<region>.hashicorp.cloud:8200"
gh secret set VAULT_ROLE --body "github-actions"
```

---

## 8. Secret paths reference

The following paths match exactly what the workflows read via `vault-action`:

| Vault path | Key | Consumed as env var |
|------------|-----|---------------------|
| `kv/data/azure` | `client_id` | `AZURE_CLIENT_ID` |
| `kv/data/azure` | `tenant_id` | `AZURE_TENANT_ID` |
| `kv/data/azure` | `subscription_id` | `AZURE_SUBSCRIPTION_ID` |
| `kv/data/terraform` | `organization` | `TF_CLOUD_ORGANIZATION` |
| `kv/data/terraform` | `tfe_token` | `TFE_TOKEN` |

> **Note:** KV v2 stores secrets under `kv/data/<path>` but you read/write them
> with the CLI using `kv/<path>` (without `data/`). The `data/` segment is added
> automatically by the CLI and by `vault-action`.
