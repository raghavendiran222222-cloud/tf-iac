# GitHub Actions CI/CD Setup

This document describes the two-workflow shape implemented in `.github/workflows/` and how to configure the required environments and status checks.

---

## Workflow Overview

### Entry-point workflows (two only)

| File | Trigger | What it does |
|---|---|---|
| `pr.yml` | PR → `main` | Detects changed envs → runs `tf-validate.yml` in parallel per changed workload |
| `deploy.yml` | Push → `main`, `workflow_dispatch` | Detects changed envs → runs `tf-apply.yml` in parallel per changed workload |

### Reusable workflows (called by the entry points)

| File | Called by | What it does |
|---|---|---|
| `tf-validate.yml` | `pr.yml` | `fmt -check`, `validate`, `tfsec`, `plan`, formatted PR comment |
| `tf-apply.yml` | `deploy.yml` | `init`, `plan -out`, `apply`, failure issue on error |

### Utility workflows

| File | Trigger | What it does |
|---|---|---|
| `break-glass.yml` | `workflow_dispatch` | Manual plan / apply / destroy with audit log; gated by `break-glass` environment |
| `tftest.yml` | PR → `main` (test paths) | pytest + native `terraform test` |

---

## How changed-environment detection works

`scripts/detect-changed-envs.sh` runs `git diff` against the base branch (on PR) or `HEAD^` (on push/dispatch) and emits a JSON array of the workload names that changed under `non-prod/`, e.g. `["infra-agent"]`. The entry-point workflow expands this into a matrix — untouched workloads are never planned or applied.

---

## Azure OIDC Setup via App Registration

The workflows authenticate to Azure using **OIDC (Workload Identity Federation)** — no long-lived client secrets required. Follow these steps once per environment.

### Step 1 — Create an App Registration

```bash
APP_NAME="github-actions-terraform"
TENANT_ID="<your-tenant-id>"
SUBSCRIPTION_ID="<your-subscription-id>"

az ad app create --display-name "$APP_NAME"
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
az ad sp create --id "$APP_ID"
SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)
```

### Step 2 — Add Federated Credentials (OIDC)

**For Pull Requests:**
```bash
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters '{
    "name": "github-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<your-org>/<your-repo>:pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

**For Push to main (deploy workflow):**
```bash
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters '{
    "name": "github-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<your-org>/<your-repo>:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Step 3 — Assign RBAC Role

```bash
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

### Step 4 — Store Values in GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

| Secret Name | Value |
|---|---|
| `AZURE_CLIENT_ID` | `$APP_ID` from Step 1 |
| `AZURE_TENANT_ID` | Your Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID |
| `TF_CLOUD_ORGANIZATION` | Your HCP Terraform organisation name |
| `TFE_TOKEN` | Your HCP Terraform API token |

```bash
gh secret set AZURE_CLIENT_ID         --body "$APP_ID"
gh secret set AZURE_TENANT_ID         --body "$TENANT_ID"
gh secret set AZURE_SUBSCRIPTION_ID   --body "$SUBSCRIPTION_ID"
gh secret set TF_CLOUD_ORGANIZATION   --body "<your-tfc-org>"
gh secret set TFE_TOKEN               --body "<your-tfe-token>"
```

---

## GitHub Environments

Four environments must be created. The workflows reference them as follows:

| Environment | Used by | Purpose |
|---|---|---|
| `non-prod-plan` | `tf-validate.yml` (via `pr.yml`) | OIDC scope for speculative plans on PRs |
| `non-prod-infra-agent` | `tf-apply.yml` (via `deploy.yml`) | Approval gate + OIDC for infra-agent apply |
| `non-prod-mvp-app` | `tf-apply.yml` (via `deploy.yml`) | Approval gate + OIDC for mvp-app apply |
| `break-glass` | `break-glass.yml` | 2-reviewer gate for manual operations |

### Create environments (GitHub CLI)

```bash
REPO="your-org/your-repo"
REVIEWER_ID="<numeric-github-user-id>"  # gh api /users/<username> --jq .id

for ENV in non-prod-plan non-prod-infra-agent non-prod-mvp-app break-glass; do
  gh api --method PUT /repos/${REPO}/environments/${ENV} \
    --input - <<EOF
{
  "reviewers": [
    { "type": "User", "id": ${REVIEWER_ID} }
  ],
  "deployment_branch_policy": null
}
EOF
done
```

The `break-glass` environment should require at least **2 reviewers**. The `non-prod-plan` environment needs no reviewers (plans are read-only).

---

## Terraform Apply — Approval Gate

When a commit merges to `main`, the `deploy.yml` workflow detects which workloads changed and calls `tf-apply.yml` for each. Because each call runs in a named GitHub Environment (`non-prod-infra-agent` / `non-prod-mvp-app`), GitHub pauses execution until a required reviewer approves.

The reviewer sees:
```
This workflow is waiting for your review to deploy to non-prod-infra-agent
[ Review deployments ]
```

`terraform apply` only runs after approval.

---

## Break Glass Workflow

Use the break-glass workflow for emergency manual operations (import, targeted destroy, etc.) that cannot wait for a normal PR cycle.

1. Go to **Actions → Break Glass → Run workflow**
2. Select: target workload, action (plan / apply / destroy), tier
3. Two reviewers from the `break-glass` environment must approve
4. Every invocation automatically creates a GitHub Issue with actor, action, and run link as an audit trail

---

## PR Plan Comments

`tf-validate.yml` posts a formatted comment on every PR:

```
## Terraform Plan — `non-prod/infra-agent`

**+3 to add** · **~1 to change** · **⚠️ -1 to destroy**

<details><summary>Full plan output</summary>

```hcl
...full terraform plan...
```

</details>
```

- Previous plan comments for the same workload are deleted before posting (no stale comment spam).
- Destructive changes (`to destroy`) are highlighted with ⚠️.
- The plan artifact (`tfplan`) is uploaded as a workflow artifact (7-day retention).

---

## Security Scan Results

`tfsec` findings are uploaded to the **GitHub Security** tab via SARIF. Review at:

```
https://github.com/<org>/<repo>/security/code-scanning
```

Categories: `tfsec-non-prod/infra-agent`, `tfsec-non-prod/mvp-app`.

---

## Required Status Checks (Branch Protection)

After the new workflows have run at least once, add these checks to the `main` branch protection rule:

| Check name | Workflow |
|---|---|
| `validate (non-prod/infra-agent)` | `tf-validate.yml` via `pr.yml` |
| `validate (non-prod/mvp-app)` | `tf-validate.yml` via `pr.yml` |
| `tftest (non-prod/infra-agent)` | `tftest.yml` |
| `tftest (non-prod/mvp-app)` | `tftest.yml` |

```bash
REPO="your-org/your-repo"

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/${REPO}/branches/main/protection \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "validate (non-prod/infra-agent)",
      "validate (non-prod/mvp-app)",
      "tftest (non-prod/infra-agent)",
      "tftest (non-prod/mvp-app)"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1
  },
  "restrictions": null
}
EOF
```
