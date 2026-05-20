# github-actions-workflows

Shared reusable GitHub Actions workflows for Terraform repositories.

## Workflows

### `tf-apply.yml` — Terraform Apply
Runs `terraform init → plan → apply` with Azure OIDC authentication and Terraform Cloud backend.

```yaml
jobs:
  apply:
    uses: btdmsd/github-actions-workflows/.github/workflows/tf-apply.yml@main
    with:
      working-directory: non-prod/my-workload
      environment: non-prod-my-workload
    secrets: inherit
```

### `tf-validate.yml` — Terraform Validate
Full validation stack: format check, init, validate, tflint, tfsec, plan, Checkov, conftest, plan comment on PR.

```yaml
jobs:
  validate:
    uses: btdmsd/github-actions-workflows/.github/workflows/tf-validate.yml@main
    with:
      working-directory: non-prod/my-workload
      environment: non-prod-plan
    secrets: inherit
```

### `module-tests.yml` — Module Tests
Auto-discovers `*-module/` directories with `tests/` folders and runs plan-level pytest and optional e2e tests.

```yaml
jobs:
  test:
    uses: btdmsd/github-actions-workflows/.github/workflows/module-tests.yml@main
    with:
      test_type: plan   # plan | e2e | all
    secrets: inherit
```

## Required Secrets

| Secret | Purpose |
|--------|---------|
| `TFE_TOKEN` | Terraform Cloud API token |
| `AZURE_CLIENT_ID` | Azure service principal (OIDC) |
| `AZURE_TENANT_ID` | Azure tenant |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription |
| `TF_CLOUD_ORGANIZATION` | Terraform Cloud organization name |
