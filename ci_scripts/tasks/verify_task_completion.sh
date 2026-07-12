#!/usr/bin/env bash
set -euo pipefail

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_directory/../lib/task_utils.sh"

ci_task_require_no_arguments "$@"
ci_task_enter_repository "${BASH_SOURCE[0]}"
repository_root=$CI_TASK_REPOSITORY_ROOT

bash "$repository_root/ci_scripts/tasks/check_repository_rules.sh"
bash "$repository_root/ci_scripts/tasks/test_stally_library.sh"
git diff --check
git diff --cached --check

echo "Task completion verification passed."
