#!/usr/bin/env bash
set -euo pipefail

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_directory/../lib/task_utils.sh"

ci_task_require_no_arguments "$@"
ci_task_enter_repository "${BASH_SOURCE[0]}"

if ! ci_task_should_skip_environment_check; then
  bash "$CI_TASK_REPOSITORY_ROOT/ci_scripts/tasks/check_environment.sh" --profile tests
fi

destination=${CI_IOS_SIMULATOR_DESTINATION:?Select a discovered dedicated iOS 27 Simulator destination}
derived_data_path=${CI_DERIVED_DATA_PATH:-.build/stally-system-tests}

xcodebuild \
  -project Stally.xcodeproj \
  -scheme StallySystemTests \
  -destination "$destination" \
  -parallel-testing-enabled NO \
  -derivedDataPath "$derived_data_path" \
  test
