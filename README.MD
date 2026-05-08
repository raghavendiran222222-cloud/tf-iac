# GitHub Repository Setup

Commands to create, initialize, and protect all Terraform module repositories under the `bdtmsd` org.

---

## 1. Create Repositories

```bash
gh repo create bdtmsd/tf-iac-vnet-module --private --description "Terraform module: tf-iac-vnet-module"
gh repo create bdtmsd/tf-iac-nsg-module --private --description "Terraform module: tf-iac-nsg-module"
gh repo create bdtmsd/tf-iac-app-service-module --private --description "Terraform module: tf-iac-app-service-module"
gh repo create bdtmsd/tf-iac-mysql-module --private --description "Terraform module: tf-iac-mysql-module"
gh repo create bdtmsd/tf-iac-storage-module --private --description "Terraform module: tf-iac-storage-module"
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
      { "context": "HCP Terraform Speculative Plan" },
      { "context": "TF-test" }
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
      { "context": "HCP Terraform Speculative Plan" },
      { "context": "TF-test" }
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
      { "context": "HCP Terraform Speculative Plan" },
      { "context": "TF-test" }
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
      { "context": "HCP Terraform Speculative Plan" },
      { "context": "TF-test" }
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
      { "context": "HCP Terraform Speculative Plan" },
      { "context": "TF-test" }
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
