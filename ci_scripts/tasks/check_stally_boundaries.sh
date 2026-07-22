#!/usr/bin/env bash
set -euo pipefail

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_directory/../lib/task_utils.sh"

ci_task_require_no_arguments "$@"
ci_task_enter_repository "${BASH_SOURCE[0]}"
repository_root=$CI_TASK_REPOSITORY_ROOT

app_sources=(
  "$repository_root/Stally/Sources"
)

library_sources=(
  "$repository_root/StallyLibrary/Sources"
)

failures=()

record_failure() {
  failures+=("$1")
}

search_swift_sources() {
  local rg_pattern=$1
  local grep_pattern=$2
  shift 2

  if command -v rg >/dev/null 2>&1; then
    rg \
      --line-number \
      "$rg_pattern" \
      "$@" \
      -g '*.swift' || true
    return 0
  fi

  find "$@" -type f -name '*.swift' -print0 |
    xargs -0 grep -nE "$grep_pattern" 2>/dev/null || true
}

missing_operations=$(
  test -f "$repository_root/StallyLibrary/Sources/Item/ItemOperations.swift" || printf '%s\n' "StallyLibrary/Sources/Item/ItemOperations.swift"
)

if [[ -n "$missing_operations" ]]; then
  record_failure "Missing library Operations entrypoint: $missing_operations"
fi

app_model_declarations=$(
  search_swift_sources \
    "@Model" \
    "@Model" \
    "${app_sources[@]}"
)

if [[ -n "$app_model_declarations" ]]; then
  record_failure "SwiftData model declarations belong in StallyLibrary, not app sources:
$app_model_declarations"
fi

app_direct_model_mutations=$(
  search_swift_sources \
    "\bitem\.(addMark|removeMark|historySnapshot|isMarked)\(" \
    '(^|[^[:alnum:]_])item\.(addMark|removeMark|historySnapshot|isMarked)\(' \
    "${app_sources[@]}"
)

if [[ -n "$app_direct_model_mutations" ]]; then
  record_failure "App views should call ItemOperations instead of item business helpers:
$app_direct_model_mutations"
fi

app_direct_item_creation=$(
  search_swift_sources \
    "\bItem\(" \
    '(^|[^[:alnum:]_])Item\(' \
    "${app_sources[@]}"
)

if [[ -n "$app_direct_item_creation" ]]; then
  record_failure "App views should create items through ItemOperations:
$app_direct_item_creation"
fi

public_business_helpers=$(
  search_swift_sources \
    "^[[:space:]]*public[[:space:]]+func[[:space:]]+(historySnapshot|mark|isMarked|addMark|removeMark)\\b" \
    '^[[:space:]]*public[[:space:]]+func[[:space:]]+(historySnapshot|mark|isMarked|addMark|removeMark)([^[:alnum:]_]|$)' \
    "${library_sources[@]}"
)

if [[ -n "$public_business_helpers" ]]; then
  record_failure "Business helper methods should stay behind public ItemOperations:
$public_business_helpers"
fi

if [[ ${#failures[@]} -ne 0 ]]; then
  echo "Stally boundary check failed." >&2

  for failure in "${failures[@]}"; do
    printf -- '- %s\n' "$failure" >&2
  done

  exit 1
fi

echo "Stally boundary check passed."
