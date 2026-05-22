# github-actions-workflows

Shared reusable GitHub Actions workflows and helpers for Terraform repositories.
Consumed by caller workflows via `btdmsd/github-actions-workflows/.github/workflows/<name>@main`.

## Workflows

### `fmt-validate.yaml` — Format & Validate
Fail-fast syntax gate: `terraform fmt`, `terraform init -backend=false`, `terraform validate`, and `tflint`.

```yaml
jobs:
  fmt-validate:
    uses: btdmsd/github-actions-workflows/.github/workflows/fmt-validate.yaml@main
    with:
      working-directory: non-prod/my-workload
    secrets: inherit
```

**Inputs**

| Input | Required | Description |
|---|---|---|
| `working-directory` | yes | Path to the Terraform root |

---

### `plan.yaml` — Terraform Plan
Authenticates via Azure OIDC, runs `terraform plan`, uploads the plan artifact, and posts a summary comment on PRs.

```yaml
jobs:
  plan:
    uses: btdmsd/github-actions-workflows/.github/workflows/plan.yaml@main
    with:
      working-directory: non-prod/my-workload
      environment: non-prod-plan
    secrets: inherit
```

**Inputs**

| Input | Required | Description |
|---|---|---|
| `working-directory` | yes | Path to the Terraform root |
| `environment` | yes | GitHub environment for OIDC credentials |

**Outputs**

| Output | Description |
|---|---|
| `artifact-name` | Name of the uploaded plan artifact — pass to `apply.yaml` |

---

### `checkov.yaml` — Checkov Security Scan
Downloads the plan artifact produced by `plan.yaml` and runs Checkov against `tfplan.json`. Uploads results as SARIF.

```yaml
jobs:
  checkov:
    needs: [plan]
    uses: btdmsd/github-actions-workflows/.github/workflows/checkov.yaml@main
    with:
      working-directory: non-prod/my-workload
    secrets: inherit
```

**Inputs**

| Input | Required | Default | Description |
|---|---|---|---|
| `working-directory` | yes | — | Path to the Terraform root |
| `plan-json` | no | `tfplan.json` | Plan JSON filename relative to working-directory |
| `soft-fail` | no | `false` | Exit 0 even on policy violations |

---

### `apply.yaml` — Terraform Apply
Downloads the plan artifact produced by `plan.yaml`, re-inits with apply credentials, and runs `terraform apply`. Raises a GitHub issue on failure.

```yaml
jobs:
  deploy:
    needs: [plan-post-merge]
    uses: btdmsd/github-actions-workflows/.github/workflows/apply.yaml@main
    with:
      working-directory: non-prod/my-workload
      environment: non-prod-my-workload
    secrets: inherit
```

**Inputs**

| Input | Required | Description |
|---|---|---|
| `working-directory` | yes | Path to the Terraform root |
| `environment` | yes | GitHub environment for apply credentials (configure required reviewers here for manual approval) |

---

### `tf-test.yaml` — Terraform Test
Runs plan-level pytest and `terraform test` (HCL) for apps, and optionally e2e tests for modules.

```yaml
jobs:
  tf-test:
    uses: btdmsd/github-actions-workflows/.github/workflows/tf-test.yaml@main
    with:
      working-directory: non-prod/my-workload
      repo-type: app      # app | module
      test-type: plan     # plan | e2e | all
      environment: non-prod-plan
    secrets: inherit
```

**Inputs**

| Input | Required | Default | Description |
|---|---|---|---|
| `working-directory` | yes | — | Path to the Terraform root or module |
| `repo-type` | no | `app` | `app` (workload) or `module` (reusable module) |
| `test-type` | no | `plan` | `plan` (no real infra), `e2e` (deploys real infra), or `all` |
| `environment` | no | `non-prod-plan` | GitHub environment for OIDC credentials |

---

## Helpers

### `helpers/detect-changes.sh`
Detects which directories changed and outputs a JSON array for use in a GitHub Actions matrix job.

Fetched at runtime from this branch via sparse checkout — not bundled in the caller repo.

**Environment variables**

| Variable | Required | Description |
|---|---|---|
| `PATTERN` | yes | grep regex applied to changed file paths (e.g. `^[^/]+-module/`) |
| `FIELD` | yes | awk field to extract as directory name (`1` = first path segment) |
| `PREFIX` | no | Directory prefix for existence check (e.g. `non-prod`) |
| `REQUIRE_TESTS` | no | Skip dirs without a `tests/` folder (`true`/`false`, default `false`) |

Detection modes (auto-selected):
- **PR** — diffs commits introduced by the PR against the base branch
- **Push** — diffs `HEAD^ → HEAD`
- **Initial commit** — falls back to `find` across all matching dirs

**Example usage in a workflow:**

```yaml
- name: Fetch shared helpers
  uses: actions/checkout@v4
  with:
    repository: ${{ github.repository }}
    ref: github-actions-workflows
    path: .shared
    sparse-checkout: helpers/

- id: detect
  env:
    PATTERN: '^[^/]+-module/'
    FIELD: "1"
    REQUIRE_TESTS: "true"
  run: bash .shared/helpers/detect-changes.sh >> "$GITHUB_OUTPUT"
```

---

## Required Secrets

| Secret | Purpose |
|---|---|
| `TFE_TOKEN` | Terraform Cloud API token |
| `AZURE_CLIENT_ID` | Azure service principal client ID (OIDC) |
| `AZURE_TENANT_ID` | Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `TF_CLOUD_ORGANIZATION` | Terraform Cloud organization name |

## Recommended Pipeline Pattern

```
PR Raised
  └── fmt-validate   ──► fail fast on syntax
        └── plan     ──► show diff, post PR comment
              └── checkov  ──► security gate on plan JSON
        └── tf-test  ──► plan-level unit tests (parallel with plan)

PR Merged to main
  └── plan-post-merge  ──► re-plan to catch drift
        └── deploy     ──► apply (manual approval via GitHub environment)

Manual (workflow_dispatch)
  └── destroy  ──► terraform destroy (manual approval via separate environment)
```
