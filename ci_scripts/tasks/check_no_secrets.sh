#!/usr/bin/env bash
set -euo pipefail

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_directory/../lib/task_utils.sh"

ci_task_require_no_arguments "$@"
ci_task_enter_repository "${BASH_SOURCE[0]}"

declare -a repository_paths=()
while IFS= read -r -d '' path; do
  repository_paths+=("$path")
done < <(git ls-files -z --cached --others --exclude-standard)

if [[ ${#repository_paths[@]} -eq 0 ]]; then
  echo "No tracked or unignored files to scan."
  exit 0
fi

declare -a blocked_paths=()
declare -a existing_repository_paths=()
repository_path=""
for repository_path in "${repository_paths[@]}"; do
  if [[ ! -f "$repository_path" ]]; then
    continue
  fi

  existing_repository_paths+=("$repository_path")

  case "$repository_path" in
    Secret.swift|*/Secret.swift \
    |Configuration.storekit|*/Configuration.storekit \
    |StoreKitTestCertificate.cer|*/StoreKitTestCertificate.cer \
    |GoogleService-Info.plist|*/GoogleService-Info.plist \
    |.env|.env.*|*/.env|*/.env.* \
    |.netrc|*/.netrc \
    |*.p8|*.p12|*.mobileprovision)
      blocked_paths+=("$repository_path")
      ;;
    esac
done

if [[ ${#existing_repository_paths[@]} -eq 0 ]]; then
  echo "No existing tracked or unignored files to scan."
  exit 0
fi

if [[ ${#blocked_paths[@]} -gt 0 ]]; then
  echo "Blocked local-only files are present in the repository view:" >&2
  printf '  - %s\n' "${blocked_paths[@]}" >&2
  echo "Move them out of git or extend ignore rules before publishing." >&2
  exit 1
fi

declare -a content_patterns=(
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'github_pat_[A-Za-z0-9_]{20,}'
  'gh[pousr]_[A-Za-z0-9]{20,}'
  'AKIA[0-9A-Z]{16}'
  'AIza[0-9A-Za-z_-]{35}'
  'sk_live_[0-9A-Za-z]{16,}'
  'rk_live_[0-9A-Za-z]{16,}'
  'SG\\.[A-Za-z0-9_-]{16,}\\.[A-Za-z0-9_-]{16,}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  'ya29\\.[0-9A-Za-z_-]+'
)

declare -a rg_arguments=(
  -n
  -I
  --color=never
)
pattern=""
for pattern in "${content_patterns[@]}"; do
  rg_arguments+=(-e "$pattern")
done
rg_arguments+=(--)
rg_arguments+=("${existing_repository_paths[@]}")

content_matches=$(rg "${rg_arguments[@]}" || true)
if [[ -n "$content_matches" ]]; then
  echo "Potential secret-like content found in repository files:" >&2
  printf '%s\n' "$content_matches" >&2
  echo "Review the matches before pushing this repository to GitHub." >&2
  exit 1
fi

echo "Secret scan passed."
