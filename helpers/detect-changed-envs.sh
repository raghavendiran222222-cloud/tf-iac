#!/usr/bin/env bash
set -euo pipefail

# Detects which non-prod/<app> directories have changed.
# Outputs a JSON array of app names, e.g. ["infra-agent","mvp-app"].
# Only changed apps are returned — other apps are never included.

base="${GITHUB_BASE_REF:-}"

if [[ -n "$base" ]]; then
  # PR context: diff only the commits introduced by this PR against the target branch.
  # fetch-depth 50 is enough to reliably find the merge-base even for older branches.
  git fetch origin "$base" --depth=50
  merge_base=$(git merge-base "origin/$base" HEAD)
  changed_dirs=$(git diff --name-only "$merge_base"...HEAD \
    | grep '^non-prod/' \
    | awk -F/ '{print $2}' \
    | sort -u) || true

elif git rev-parse HEAD^ >/dev/null 2>&1; then
  # Push to main: only the files in the landed commit(s).
  changed_dirs=$(git diff --name-only HEAD^ HEAD \
    | grep '^non-prod/' \
    | awk -F/ '{print $2}' \
    | sort -u) || true

else
  # Initial commit — treat every workload as changed.
  changed_dirs=$(find non-prod -maxdepth 1 -mindepth 1 -type d \
    | awk -F/ '{print $NF}' \
    | sort -u) || true
fi

# Filter to directories that actually exist (guards against deleted apps)
filtered=()
while IFS= read -r dir; do
  [[ -z "$dir" ]] && continue
  [[ -d "non-prod/$dir" ]] && filtered+=("$dir")
done <<< "$changed_dirs"

if [[ ${#filtered[@]} -eq 0 ]]; then
  echo "changed=[]"
else
  json=$(printf '%s\n' "${filtered[@]}" | jq -R . | jq -s -c .)
  echo "changed=${json}"
fi
