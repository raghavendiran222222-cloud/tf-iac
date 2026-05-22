#!/usr/bin/env bash
set -euo pipefail

# Detects changed non-prod/* environment directories (for alz-landingzones-infra branch).

base="${GITHUB_BASE_REF:-}"

if [[ -z "$base" ]]; then
  if git rev-parse HEAD^ >/dev/null 2>&1; then
    changed_dirs=$(git diff --name-only HEAD^ HEAD \
      | grep '^non-prod/' \
      | awk -F/ '{print $2}' \
      | sort -u) || true
  else
    changed_dirs=$(find non-prod -maxdepth 1 -mindepth 1 -type d \
      | awk -F/ '{print $NF}' \
      | sort -u) || true
  fi
else
  git fetch origin "$base" --depth=1
  changed_dirs=$(git diff --name-only "origin/$base"...HEAD \
    | grep '^non-prod/' \
    | awk -F/ '{print $2}' \
    | sort -u) || true
fi

if [[ -z "$changed_dirs" ]]; then
  echo "changed=[]"
else
  json=$(printf '%s\n' $changed_dirs | jq -R . | jq -s -c .)
  echo "changed=${json}"
fi
