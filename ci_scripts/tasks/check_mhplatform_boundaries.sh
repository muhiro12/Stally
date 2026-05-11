#!/usr/bin/env bash
set -euo pipefail

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_directory/../lib/task_utils.sh"

ci_task_require_no_arguments "$@"
ci_task_enter_repository "${BASH_SOURCE[0]}"
repository_root=$CI_TASK_REPOSITORY_ROOT

expected_mhplatform_remote="https://github.com/muhiro12/MHPlatform.git"

failure_count=0

report_failure() {
  echo "MHPlatform boundary violation: $1" >&2
  failure_count=$((failure_count + 1))
}

if rg -n 'XCLocalSwiftPackageReference "MHPlatform"|relativePath = .*MHPlatform' \
  "$repository_root/Stally.xcodeproj/project.pbxproj" >/dev/null; then
  report_failure "local-path MHPlatform dependency found in Stally.xcodeproj."
fi

mhplatform_package_block=$(
  awk -v remote="$expected_mhplatform_remote" '
    index($0, "url: \"" remote "\"") { capture = 1 }
    capture { print }
    capture && $0 ~ /^[[:space:]]*\),?$/ { exit }
  ' "$repository_root/StallyLibrary/Package.swift"
)

if [[ -z "$mhplatform_package_block" ]]; then
  report_failure "StallyLibrary/Package.swift must reference the canonical MHPlatform remote."
else
  if rg -n 'branch:' <<<"$mhplatform_package_block" >/dev/null; then
    report_failure "branch-based MHPlatform dependency found in StallyLibrary/Package.swift."
  fi

  if rg -n 'path:' <<<"$mhplatform_package_block" >/dev/null; then
    report_failure "local-path MHPlatform dependency found in StallyLibrary/Package.swift."
  fi

  if rg -n 'revision:' <<<"$mhplatform_package_block" >/dev/null; then
    report_failure "revision-pinned MHPlatform dependency found in StallyLibrary/Package.swift."
  fi

  if ! rg -n '"1\.0\.0"\.\.<"2\.0\.0"' <<<"$mhplatform_package_block" >/dev/null; then
    report_failure "MHPlatform dependency in StallyLibrary/Package.swift must use \"1.0.0\"..<\"2.0.0\"."
  fi
fi

mhplatform_project_block=$(
  awk '/XCRemoteSwiftPackageReference "MHPlatform"/,/};/' \
    "$repository_root/Stally.xcodeproj/project.pbxproj"
)

if [[ -z "$mhplatform_project_block" ]]; then
  report_failure "MHPlatform remote package reference is missing from Stally.xcodeproj."
else
  if ! grep -q --fixed-strings "repositoryURL = \"$expected_mhplatform_remote\";" <<<"$mhplatform_project_block"; then
    report_failure "Stally.xcodeproj must reference the canonical MHPlatform remote."
  fi

  if rg -n 'kind = branch|branch =' <<<"$mhplatform_project_block" >/dev/null; then
    report_failure "branch-based MHPlatform dependency found in Stally.xcodeproj."
  fi

  if rg -n 'kind = revision|revision =' <<<"$mhplatform_project_block" >/dev/null; then
    report_failure "revision-pinned MHPlatform dependency found in Stally.xcodeproj."
  fi

  if ! rg -n 'kind = upToNextMajorVersion' <<<"$mhplatform_project_block" >/dev/null; then
    report_failure "MHPlatform dependency must use upToNextMajorVersion."
  fi

  if ! rg -n 'minimumVersion = 1\.0\.0;' <<<"$mhplatform_project_block" >/dev/null; then
    report_failure "MHPlatform dependency must use minimumVersion 1.0.0."
  fi
fi

mhplatform_library_resolved_block=$(
  awk -v remote="$expected_mhplatform_remote" '
    index($0, "\"location\" : \"" remote "\"") { capture = 1 }
    capture { print }
    capture && $0 ~ /^    },?$/ { exit }
  ' "$repository_root/StallyLibrary/Package.resolved"
)

if [[ -z "$mhplatform_library_resolved_block" ]]; then
  report_failure "MHPlatform canonical pin is missing from StallyLibrary/Package.resolved."
else
  if rg -n '"branch"' <<<"$mhplatform_library_resolved_block" >/dev/null; then
    report_failure "floating MHPlatform resolution found in StallyLibrary/Package.resolved."
  fi

  if ! rg -n '"version"\s*:' <<<"$mhplatform_library_resolved_block" >/dev/null; then
    report_failure "StallyLibrary/Package.resolved must contain a versioned MHPlatform pin."
  fi
fi

mhplatform_xcode_resolved_block=$(
  awk -v remote="$expected_mhplatform_remote" '
    index($0, "\"location\" : \"" remote "\"") { capture = 1 }
    capture { print }
    capture && $0 ~ /^    },?$/ { exit }
  ' "$repository_root/Stally.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
)

if [[ -z "$mhplatform_xcode_resolved_block" ]]; then
  report_failure "MHPlatform canonical pin is missing from the Xcode Package.resolved."
else
  if rg -n '"branch"' <<<"$mhplatform_xcode_resolved_block" >/dev/null; then
    report_failure "floating MHPlatform resolution found in the Xcode Package.resolved."
  fi

  if ! rg -n '"version"\s*:' <<<"$mhplatform_xcode_resolved_block" >/dev/null; then
    report_failure "The Xcode Package.resolved must contain a versioned MHPlatform pin."
  fi
fi

if ! rg -n '^(@testable )?import MHPlatformCore$' \
  "$repository_root/StallyLibrary/Sources" \
  "$repository_root/StallyLibrary/Tests" >/dev/null; then
  report_failure "shared-library layer must import MHPlatformCore."
fi

if rg -n '^(@testable )?import MHPlatform$' \
  "$repository_root/StallyLibrary/Sources" \
  "$repository_root/StallyLibrary/Tests" >/dev/null; then
  report_failure "shared-library layer must not import the MHPlatform umbrella."
fi

if rg -n '^(@testable )?import MH(DeepLinking|Logging|Preferences|RouteExecution|NotificationPlans|NotificationPayloads|AppRuntime|ReviewPolicy)$' \
  "$repository_root/StallyLibrary/Sources" \
  "$repository_root/StallyLibrary/Tests" >/dev/null; then
  report_failure "shared-library layer must use MHPlatformCore instead of direct MHPlatform module imports."
fi

if ! rg -n '^import MHPlatform$' \
  "$repository_root/Stally/Sources" >/dev/null; then
  report_failure "Stally app must import MHPlatform."
fi

if rg -n '^import MH(AppRuntime|PlatformCore|DeepLinking|Logging|Preferences|RouteExecution|AppRuntimeDefaults|AppRuntimeAds|AppRuntimeLicenses|ReviewPolicy)$' \
  "$repository_root/Stally/Sources" >/dev/null; then
  report_failure "Stally app must use MHPlatform instead of direct MHPlatform module imports."
fi

if ! rg -n 'name: "MHPlatformCore"' \
  "$repository_root/StallyLibrary/Package.swift" >/dev/null; then
  report_failure "StallyLibrary must depend on the MHPlatformCore product."
fi

if rg -n 'name: "MHPlatform"|name: "MHAppRuntime"|name: "MHReviewPolicy"|name: "MHDeepLinking"|name: "MHLogging"|name: "MHPreferences"|name: "MHRouteExecution"' \
  "$repository_root/StallyLibrary/Package.swift" >/dev/null; then
  report_failure "StallyLibrary must not depend on app-facing or granular MHPlatform products."
fi

if ! rg -n 'productName = MHPlatform;' \
  "$repository_root/Stally.xcodeproj/project.pbxproj" >/dev/null; then
  report_failure "Stally target must depend on the MHPlatform umbrella."
fi

if rg -n 'productName = MH(DeepLinking|Logging|Preferences|RouteExecution|AppRuntimeDefaults|AppRuntimeAds|AppRuntimeLicenses);' \
  "$repository_root/Stally.xcodeproj/project.pbxproj" >/dev/null; then
  report_failure "Stally target must not depend on direct MHPlatform core/runtime products."
fi

if [[ $failure_count -ne 0 ]]; then
  exit 1
fi

echo "MHPlatform boundary checks passed."
