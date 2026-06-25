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

missing_operations=$(
  test -f "$repository_root/StallyLibrary/Sources/Item/ItemOperations.swift" || printf '%s\n' "StallyLibrary/Sources/Item/ItemOperations.swift"
)

if [[ -n "$missing_operations" ]]; then
  record_failure "Missing library Operations entrypoint: $missing_operations"
fi

app_model_declarations=$(
  rg \
    --line-number \
    "@Model" \
    "${app_sources[@]}" \
    -g '*.swift' || true
)

if [[ -n "$app_model_declarations" ]]; then
  record_failure "SwiftData model declarations belong in StallyLibrary, not app sources:
$app_model_declarations"
fi

app_direct_model_mutations=$(
  rg \
    --line-number \
    "\bitem\.(addMark|removeMark|historySnapshot|isMarked)\(" \
    "${app_sources[@]}" \
    -g '*.swift' || true
)

if [[ -n "$app_direct_model_mutations" ]]; then
  record_failure "App views should call ItemOperations instead of item business helpers:
$app_direct_model_mutations"
fi

app_direct_item_creation=$(
  rg \
    --line-number \
    "\bItem\(" \
    "${app_sources[@]}" \
    -g '*.swift' || true
)

if [[ -n "$app_direct_item_creation" ]]; then
  record_failure "App views should create items through ItemOperations:
$app_direct_item_creation"
fi

public_business_helpers=$(
  rg \
    --line-number \
    "^[[:space:]]*public[[:space:]]+func[[:space:]]+(historySnapshot|mark|isMarked|addMark|removeMark)\\b" \
    "${library_sources[@]}" \
    -g '*.swift' || true
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
