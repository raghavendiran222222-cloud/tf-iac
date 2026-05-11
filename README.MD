# GitHub Repository Setup

Commands to create, initialize, protect, and configure all Terraform module repositories under the `bdtmsd` org.

---

## 1. Create Repositories

```bash
gh repo create bdtmsd/tf-iac-vnet-module --private --description "Terraform module: tf-iac-vnet-module"
gh repo create bdtmsd/tf-iac-nsg-module --private --description "Terraform module: tf-iac-nsg-module"
gh repo create bdtmsd/tf-iac-app-service-module --private --description "Terraform module: tf-iac-app-service-module"
gh repo create bdtmsd/tf-iac-mysql-module --private --description "Terraform module: tf-iac-mysql-module"
gh repo create bdtmsd/tf-iac-storage-module --private --description "Terraform module: tf-iac-storage-module"
gh repo create bdtmsd/tf-iac --private --description "BDT MVP root workloads module"
```

---

## 2. Initialize Main Branch

```bash
git commit --allow-empty -m "chore: initialize main branch"
git branch -M main
git push -u origin main
```

---

## 3. Apply Branch Protection

### tf-iac-vnet-module

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/bdtmsd/tf-iac-vnet-module/branches/main/protection" \
  --input - << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "Lint" },
      { "context": "Security Scan" },
      { "context": "TF-test" },
      { "context": "HCP Terraform Speculative Plan" }
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_last_push_approval": true,
    "dismissal_restrictions": {}
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

### tf-iac-nsg-module

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/bdtmsd/tf-iac-nsg-module/branches/main/protection" \
  --input - << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "Lint" },
      { "context": "Security Scan" },
      { "context": "TF-test" },
      { "context": "HCP Terraform Speculative Plan" }
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_last_push_approval": true,
    "dismissal_restrictions": {}
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

### tf-iac-app-service-module

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/bdtmsd/tf-iac-app-service-module/branches/main/protection" \
  --input - << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "Lint" },
      { "context": "Security Scan" },
      { "context": "TF-test" },
      { "context": "HCP Terraform Speculative Plan" }
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_last_push_approval": true,
    "dismissal_restrictions": {}
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

### tf-iac-mysql-module

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/bdtmsd/tf-iac-mysql-module/branches/main/protection" \
  --input - << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "Lint" },
      { "context": "Security Scan" },
      { "context": "TF-test" },
      { "context": "HCP Terraform Speculative Plan" }
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_last_push_approval": true,
    "dismissal_restrictions": {}
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

### tf-iac-storage-module

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/bdtmsd/tf-iac-storage-module/branches/main/protection" \
  --input - << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "Lint" },
      { "context": "Security Scan" },
      { "context": "TF-test" },
      { "context": "HCP Terraform Speculative Plan" }
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_last_push_approval": true,
    "dismissal_restrictions": {}
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

### tf-iac (root repo)

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/bdtmsd/tf-iac/branches/main/protection" \
  --input - << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "Lint" },
      { "context": "Security Scan" },
      { "context": "Plan (dev)" },
      { "context": "Plan (prod)" },
      { "context": "HCP Terraform Speculative Plan" }
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_last_push_approval": true,
    "dismissal_restrictions": {}
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

---

## 4. Create GitHub Environments (tf-iac root repo only)

### dev environment (auto-deploy — no reviewers)

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/bdtmsd/tf-iac/environments/dev"
```

### prod environment (requires approval)

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/bdtmsd/tf-iac/environments/prod" \
  --input - << 'EOF'
{
  "reviewers": [
    { "type": "User", "id": "<raghavendiran-github-user-id>" },
    { "type": "User", "id": "<sakthivel-github-user-id>" }
  ],
  "deployment_branch_policy": {
    "protected_branches": true,
    "custom_branch_policies": false
  }
}
EOF
```

> Replace `<raghavendiran-github-user-id>` and `<sakthivel-github-user-id>` with actual GitHub numeric user IDs (`gh api /users/<username> --jq .id`).

---

## 5. Add GitHub Secrets

### Child module repos (run for each of the 5 module repos)

```bash
for REPO in tf-iac-vnet-module tf-iac-nsg-module tf-iac-app-service-module tf-iac-mysql-module tf-iac-storage-module; do
  gh secret set TF_TOKEN_APP_TERRAFORM_IO   --repo bdtmsd/$REPO --body "<hcp-terraform-token>"
  gh secret set ARM_SUBSCRIPTION_ID         --repo bdtmsd/$REPO --body "<subscription-id>"
  gh secret set ARM_CLIENT_ID               --repo bdtmsd/$REPO --body "<client-id>"
  gh secret set ARM_TENANT_ID               --repo bdtmsd/$REPO --body "<tenant-id>"
  gh secret set ARM_CLIENT_SECRET           --repo bdtmsd/$REPO --body "<client-secret>"
done
```

### Root repo (tf-iac)

```bash
gh secret set TF_TOKEN_APP_TERRAFORM_IO   --repo bdtmsd/tf-iac --body "<hcp-terraform-token>"
gh secret set ARM_SUBSCRIPTION_ID         --repo bdtmsd/tf-iac --body "<subscription-id>"
gh secret set ARM_CLIENT_ID               --repo bdtmsd/tf-iac --body "<client-id>"
gh secret set ARM_TENANT_ID               --repo bdtmsd/tf-iac --body "<tenant-id>"
gh secret set ARM_CLIENT_SECRET           --repo bdtmsd/tf-iac --body "<client-secret>"
gh secret set TF_VAR_MYSQL_ADMIN_PASSWORD --repo bdtmsd/tf-iac --body "<mysql-admin-password>"
```

> Secrets sourced from HashiCorp Vault or Azure Key Vault per FDD requirement. Never hardcode values.

---

## 6. HCP Terraform Workspace Setup (VCS-driven)

Run these steps in the HCP Terraform UI for each workspace. This enables the native `HCP Terraform Speculative Plan` status check on pull requests.

### Create VCS-driven workspaces

| Workspace | Repo | Branch | Working Directory |
|-----------|------|--------|------------------|
| `mvp-workload-dev` | `bdtmsd/tf-iac` | `main` | `envs/dev` |
| `mvp-workload-prod` | `bdtmsd/tf-iac` | `main` | `envs/prod` |

### Configure workspace variables

For each workspace, set the following in **Variables → + Add variable**:

**Terraform Variables:**

| Key | Value | Sensitive |
|-----|-------|-----------|
| `environment` | `dev` or `prod` | No |
| `location` | `eastus2` | No |
| `app_sku` | `B1` / `P1v3` | No |
| `mysql_sku` | `B_Standard_B1ms` / `GP_Standard_D2ds_v4` | No |
| `storage_replication` | `LRS` / `GRS` | No |
| `enable_resource_lock` | `false` / `true` | No |
| `mysql_admin_password` | `<value>` | **Yes** |

**Environment Variables:**

| Key | Value | Sensitive |
|-----|-------|-----------|
| `ARM_SUBSCRIPTION_ID` | `<value>` | **Yes** |
| `ARM_CLIENT_ID` | `<value>` | **Yes** |
| `ARM_TENANT_ID` | `<value>` | **Yes** |
| `ARM_CLIENT_SECRET` | `<value>` | **Yes** |

### Configure path-based run triggers

Under workspace **Settings → Version Control → Trigger runs**:
- Select: **Only trigger runs when files in specified paths change**
- `mvp-workload-dev`: add path `envs/dev/**`
- `mvp-workload-prod`: add path `envs/prod/**`

### Enable speculative plans on PRs

Under workspace **Settings → Pull Requests**:
- Enable: **Plan on pull requests from forks** (or "Plan on pull requests")
- This posts the `HCP Terraform Speculative Plan` check on every PR automatically
