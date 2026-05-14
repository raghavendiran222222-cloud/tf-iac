# GitHub Actions CI/CD Setup

This document describes the workflows in `.github/workflows/` and how to configure required status checks on the `main` branch.

---

## Workflow Overview

| Workflow File | Trigger | What it does |
|---|---|---|
| `terraform-fmt-validate.yml` | Push (non-main), PR → main | `terraform fmt -check` + `terraform validate` |
| `terraform-security.yml` | Push (non-main), PR → main | `tfsec` static security analysis, results in GitHub Security tab |
| `terraform-plan.yml` | PR → main | Speculative `terraform plan`, posts output as PR comment |
| `terraform-apply.yml` | Push → main | `terraform apply` with manual approval gate per environment |

All workflows run a matrix over both modules:
- `non-prod/infra-agent`
- `non-prod/mvp-app`

---

## Azure OIDC Setup via App Registration

The workflows authenticate to Azure using **OIDC (Workload Identity Federation)** — no long-lived client secrets required. Follow these steps once per environment.

### Step 1 — Create an App Registration

```bash
# Set variables
APP_NAME="github-actions-terraform"
TENANT_ID="<your-tenant-id>"
SUBSCRIPTION_ID="<your-subscription-id>"

# Create the app registration
az ad app create --display-name "$APP_NAME"

# Note the appId from the output — this is your CLIENT_ID
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)

# Create a service principal for the app
az ad sp create --id "$APP_ID"
SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)
```

### Step 2 — Add Federated Credentials (OIDC)

Add one federated credential per trigger type you need.

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

**For Push to main (apply workflow):**
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

> Replace `<your-org>/<your-repo>` with your actual GitHub repository (e.g. `Sakthi/BDT-Terraform-MVP`).

### Step 3 — Assign RBAC Role

Grant the service principal access to your Azure subscription (or resource group for least-privilege):

```bash
# Contributor on subscription (use resource group scope if preferred)
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Also grant Key Vault Secrets User so it can read KV secrets at runtime
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/<your-rg>/providers/Microsoft.KeyVault/vaults/<your-kv>"
```

### Step 4 — Store Values in GitHub Secrets

Go to your repository → **Settings → Secrets and variables → Actions** and add:

| Secret Name | Where to get it |
|---|---|
| `AZURE_CLIENT_ID` | `$APP_ID` from Step 1 |
| `AZURE_TENANT_ID` | Your Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID |
| `KEY_VAULT_NAME` | Name of your Azure Key Vault |
| `TF_CLOUD_ORGANIZATION` | Your HCP Terraform organisation name |

```bash
# Quick way using gh CLI
gh secret set AZURE_CLIENT_ID     --body "$APP_ID"
gh secret set AZURE_TENANT_ID     --body "$TENANT_ID"
gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
gh secret set KEY_VAULT_NAME      --body "<your-kv-name>"
gh secret set TF_CLOUD_ORGANIZATION --body "<your-tfc-org>"
```

The Key Vault must contain the following secrets (fetched at runtime by the workflows):
- `arm-client-id`, `arm-client-secret`, `arm-subscription-id`, `arm-tenant-id`
- `tfe-token`

### How OIDC Works in the Workflows

The workflows use `azure/login@v2` with the `client-id`, `tenant-id`, and `subscription-id` inputs (no `client-secret`). GitHub's OIDC provider issues a short-lived token that Azure exchanges for an access token, validated against the federated credential subject you configured above.

```yaml
- uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

No secrets are stored in the workflow files — all sensitive values are pulled from Key Vault at runtime.

---

## Terraform Apply — Manual Approval Gate

The `terraform-apply.yml` workflow uses [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) to pause execution and wait for a human to approve before `terraform apply` runs. Two environments are referenced:

| Environment name | Module |
|---|---|
| `non-prod-infra-agent` | `non-prod/infra-agent` |
| `non-prod-mvp-app` | `non-prod/mvp-app` |

You must create these environments and configure required reviewers — otherwise the apply job runs immediately with no approval.

### Option A — GitHub UI

Repeat for each environment (`non-prod-infra-agent` and `non-prod-mvp-app`):

1. Go to your repository → **Settings** → **Environments**
2. Click **New environment**, enter the name (e.g. `non-prod-infra-agent`), click **Configure environment**
3. Under **Deployment protection rules**, enable **Required reviewers**
4. Add the GitHub users or teams who must approve (e.g. your team lead or `@infra-team`)
5. Optionally set **Wait timer** (e.g. 5 minutes) to allow cancellation before approval
6. Click **Save protection rules**

When a push to `main` triggers the workflow, GitHub will pause the apply job and send a notification to the required reviewers. They must click **Review deployments → Approve** before Terraform runs.

### Option B — GitHub CLI (`gh`)

```bash
REPO="your-org/your-repo"   # e.g. Sakthi/BDT-Terraform-MVP
REVIEWER_ID="<github-user-id>"   # numeric user ID — get with: gh api /users/<username> --jq .id

for ENV in non-prod-infra-agent non-prod-mvp-app; do
  # Create the environment
  gh api --method PUT /repos/${REPO}/environments/${ENV}

  # Add required reviewer (user)
  gh api --method PUT /repos/${REPO}/environments/${ENV} \
    --input - <<EOF
{
  "reviewers": [
    { "type": "User", "id": ${REVIEWER_ID} }
  ],
  "deployment_branch_policy": null
}
EOF

  echo "Environment ${ENV} configured."
done
```

To add a **team** as reviewer instead of a user, replace the reviewers block:
```json
{ "type": "Team", "id": <team-id> }
```
Get a team's ID with:
```bash
gh api /orgs/<your-org>/teams/<team-slug> --jq .id
```

### What the approver sees

When a push to `main` triggers the apply workflow, the required reviewer receives a GitHub notification and sees this on the Actions run page:

```
This workflow is waiting for your review to deploy to non-prod-infra-agent
[ Review deployments ]
```

They can review the pending deployment and either **Approve and deploy** or **Reject**. The `terraform apply` step only executes after approval.

---

## Enable Status Check Requirements (Branch Protection)

These steps enforce that the **Speculative Plan** and **TF-test** checks must pass before a PR can be merged into `main`.

### Option A — GitHub UI

1. Go to your repository → **Settings** → **Branches**
2. Click **Add branch protection rule** (or edit the existing `main` rule)
3. Set **Branch name pattern** to `main`
4. Enable **Require status checks to pass before merging**
5. Enable **Require branches to be up to date before merging**
6. In the search box, add each required check:
   - `plan (non-prod/infra-agent)`
   - `plan (non-prod/mvp-app)`
   - `tftest (non-prod/infra-agent)`
   - `tftest (non-prod/mvp-app)`
   - `fmt-validate (non-prod/infra-agent)` *(optional but recommended)*
   - `fmt-validate (non-prod/mvp-app)` *(optional but recommended)*
   - `security (non-prod/infra-agent)` *(optional but recommended)*
   - `security (non-prod/mvp-app)` *(optional but recommended)*
7. Click **Save changes**

> **Note:** Status check names only appear in the search box after the workflow has run at least once on a PR.

---

### Option B — GitHub CLI (`gh`)

Run the following command once your workflows have executed at least once (so GitHub recognises the check names):

```bash
REPO="your-org/your-repo"   # e.g. Sakthi/BDT-Terraform-MVP

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/${REPO}/branches/main/protection \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "plan (non-prod/infra-agent)",
      "plan (non-prod/mvp-app)",
      "tftest (non-prod/infra-agent)",
      "tftest (non-prod/mvp-app)",
      "fmt-validate (non-prod/infra-agent)",
      "fmt-validate (non-prod/mvp-app)",
      "security (non-prod/infra-agent)",
      "security (non-prod/mvp-app)"
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

Replace `your-org/your-repo` with your actual repository path. Adjust `required_approving_review_count` or remove `required_pull_request_reviews` if not needed.

---

## How PR Comments Work

When a PR is opened or updated targeting `main`, the `terraform-plan` workflow:
1. Runs `terraform plan` for each module
2. Posts the plan output directly on the PR as a comment
3. Truncates at 65,000 characters if the plan is very large

This allows reviewers to see infrastructure changes without running Terraform locally.

---

## Security Scan Results

`tfsec` findings are uploaded to the **GitHub Security** tab (Code Scanning Alerts) via SARIF upload. You can review findings at:

```
https://github.com/<org>/<repo>/security/code-scanning
```

Findings are categorised per module (`tfsec-non-prod/infra-agent`, `tfsec-non-prod/mvp-app`).
