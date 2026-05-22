#!/usr/bin/env bash
set -euo pipefail

# Detects root-level module directories with changes (for alz-modules branch).
# Only emits directories that contain a tests/ subdirectory.

base="${GITHUB_BASE_REF:-}"

if [[ -z "$base" ]]; then
  if git rev-parse HEAD^ >/dev/null 2>&1; then
    changed_dirs=$(git diff --name-only HEAD^ HEAD \
      | grep -v '^\.github/' \
      | awk -F/ '{print $1}' \
      | sort -u) || true
  else
    changed_dirs=$(find . -maxdepth 1 -mindepth 1 -type d \
      | grep -v '^\./\.' \
      | awk -F/ '{print $NF}' \
      | sort -u) || true
  fi
else
  git fetch origin "$base" --depth=1
  changed_dirs=$(git diff --name-only "origin/$base"...HEAD \
    | grep -v '^\.github/' \
    | awk -F/ '{print $1}' \
    | sort -u) || true
fi

filtered=()
while IFS= read -r dir; do
  [[ -z "$dir" ]] && continue
  if [[ -d "$dir/tests" ]]; then
    filtered+=("$dir")
  fi
done <<< "$changed_dirs"

if [[ ${#filtered[@]} -eq 0 ]]; then
  echo "changed=[]"
else
  json=$(printf '%s\n' "${filtered[@]}" | jq -R . | jq -s -c .)
  echo "changed=${json}"
fi
