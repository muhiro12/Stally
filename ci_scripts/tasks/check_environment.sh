#!/usr/bin/env bash
set -euo pipefail

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_directory/../lib/task_utils.sh"

usage() {
  cat <<'EOF' >&2
Usage: bash ci_scripts/tasks/check_environment.sh --profile <swiftlint|rules|tests>
EOF
}

argument_count=$#
if [[ $argument_count -ne 2 || "${1:-}" != "--profile" ]]; then
  usage
  exit 2
fi

profile=$2
case "$profile" in
  swiftlint | rules | tests)
    ;;
  *)
    usage
    exit 2
    ;;
esac

ci_task_enter_repository "${BASH_SOURCE[0]}"
repository_root=$CI_TASK_REPOSITORY_ROOT

failures=()
next_steps=()

record_failure() {
  failures+=("$1")
}

record_next_step() {
  local message=$1
  local existing_message

  if [[ ${#next_steps[@]} -gt 0 ]]; then
    for existing_message in "${next_steps[@]}"; do
      if [[ "$existing_message" == "$message" ]]; then
        return 0
      fi
    done
  fi

  next_steps+=("$message")
}

ensure_command() {
  local command_name=$1
  local install_hint=$2

  if command -v "$command_name" >/dev/null 2>&1; then
    return 0
  fi

  record_failure "Missing command: $command_name"
  record_next_step "$install_hint"
}

check_swiftlint_environment() {
  local project_directory="Stally.xcodeproj"
  local project_file
  local project_configuration
  local candidate
  local -a project_files=()

  ensure_command "xcodebuild" "Install Xcode and ensure xcodebuild is available from the command line."
  ensure_command "plutil" "Install the macOS command-line tools so project configurations can be inspected."

  for candidate in "$project_directory/project.pbxproj" "$project_directory/"*.xcproj; do
    if [[ -f "$candidate" ]]; then
      project_files+=("$candidate")
    fi
  done

  if [[ ${#project_files[@]} -eq 0 ]]; then
    record_failure "Missing project configuration in $project_directory."
    record_next_step "Restore a project.pbxproj or JSON .xcproj configuration so the repository-managed SwiftLint package can be resolved."
    return 0
  fi

  if [[ ${#project_files[@]} -ne 1 ]]; then
    record_failure "Multiple project configurations in $project_directory."
    record_next_step "Keep one authoritative project.pbxproj or JSON .xcproj configuration before resolving SwiftLint."
    return 0
  fi

  project_file=${project_files[0]}
  if ! project_configuration=$(plutil -p "$project_file" 2>/dev/null); then
    record_failure "Unreadable project configuration: $project_file"
    record_next_step "Restore a valid project configuration before resolving SwiftLint."
    return 0
  fi

  if [[ "$project_configuration" != *"https://github.com/SimplyDanny/SwiftLintPlugins"* ]]; then
    record_failure "Stally.xcodeproj is missing the SwiftLintPlugins package dependency."
    record_next_step "Add https://github.com/SimplyDanny/SwiftLintPlugins to Stally.xcodeproj."
  fi
}

check_tests_environment() {
  ensure_command "xcodebuild" "Install Xcode and ensure xcodebuild is available from the command line."

  if [[ ! -f "StallyLibrary/Package.swift" ]]; then
    record_failure "Missing file: StallyLibrary/Package.swift"
    record_next_step "Restore StallyLibrary/Package.swift so library tests can run."
  fi
}

check_rules_environment() {
  check_swiftlint_environment
  ensure_command "rg" "Repository rules require a working source search; report verification incomplete until it is available."
}

case "$profile" in
  swiftlint)
    check_swiftlint_environment
    ;;
  rules)
    check_rules_environment
    ;;
  tests)
    check_tests_environment
    ;;
esac

if [[ ${#failures[@]} -ne 0 ]]; then
  echo "Environment check failed for profile '$profile'." >&2
  echo "Missing prerequisites:" >&2

  for failure in "${failures[@]}"; do
    printf -- '- %s\n' "$failure" >&2
  done

  if [[ ${#next_steps[@]} -ne 0 ]]; then
    echo "Next actions:" >&2
    for next_step in "${next_steps[@]}"; do
      printf -- '- %s\n' "$next_step" >&2
    done
  fi

  exit 1
fi

echo "Environment check passed for profile '$profile'."
