#!/usr/bin/env bash
set -euo pipefail

argument_count=$#
if [[ $argument_count -ne 0 ]]; then
  echo "This script does not accept arguments." >&2
  exit 2
fi

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repository_root=$(cd "$script_directory/../.." && pwd)
cd "$repository_root"

failure_count=0

report_failure() {
  echo "MHPlatform adoption violation: $1" >&2
  failure_count=$((failure_count + 1))
}

if rg -n 'XCLocalSwiftPackageReference "MHPlatform"|relativePath = .*MHPlatform' \
  Stally.xcodeproj/project.pbxproj >/dev/null; then
  report_failure "local-path MHPlatform dependency found in Stally.xcodeproj."
fi

mhplatform_package_block=$(
  sed -n '/url: "https:\/\/github.com\/muhiro12\/MHPlatform.git"/,/)/p' \
    StallyLibrary/Package.swift
)

if [[ -z "$mhplatform_package_block" ]]; then
  report_failure "MHPlatform dependency is missing from StallyLibrary/Package.swift."
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

  if ! rg -n 'exact:\s*"1\.1\.0"' <<<"$mhplatform_package_block" >/dev/null; then
    report_failure "MHPlatform dependency in StallyLibrary/Package.swift must use exact: \"1.1.0\"."
  fi
fi

mhplatform_project_block=$(
  awk '/XCRemoteSwiftPackageReference "MHPlatform"/,/};/' \
    Stally.xcodeproj/project.pbxproj
)

if [[ -z "$mhplatform_project_block" ]]; then
  report_failure "MHPlatform remote package reference is missing from Stally.xcodeproj."
else
  if rg -n 'kind = branch|branch =' <<<"$mhplatform_project_block" >/dev/null; then
    report_failure "branch-based MHPlatform dependency found in Stally.xcodeproj."
  fi

  if rg -n 'kind = revision|revision =' <<<"$mhplatform_project_block" >/dev/null; then
    report_failure "revision-pinned MHPlatform dependency found in Stally.xcodeproj."
  fi

  if ! rg -n 'kind = exactVersion' <<<"$mhplatform_project_block" >/dev/null; then
    report_failure "MHPlatform dependency must be configured as an exact version."
  fi

  if ! rg -n 'version = 1\.1\.0;' <<<"$mhplatform_project_block" >/dev/null; then
    report_failure "MHPlatform dependency must pin version 1.1.0."
  fi
fi

mhplatform_library_resolved_block=$(
  sed -n '/"identity" : "mhplatform"/,/}/p' \
    StallyLibrary/Package.resolved
)

if [[ -z "$mhplatform_library_resolved_block" ]]; then
  report_failure "MHPlatform pin is missing from StallyLibrary/Package.resolved."
else
  if rg -n '"branch"' <<<"$mhplatform_library_resolved_block" >/dev/null; then
    report_failure "floating MHPlatform resolution found in StallyLibrary/Package.resolved."
  fi

  if ! rg -n '"version"\s*:\s*"1\.1\.0"' <<<"$mhplatform_library_resolved_block" >/dev/null; then
    report_failure "StallyLibrary/Package.resolved must pin MHPlatform 1.1.0."
  fi
fi

mhplatform_xcode_resolved_block=$(
  sed -n '/"identity" : "mhplatform"/,/}/p' \
    Stally.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
)

if [[ -z "$mhplatform_xcode_resolved_block" ]]; then
  report_failure "MHPlatform pin is missing from the Xcode Package.resolved."
else
  if rg -n '"branch"' <<<"$mhplatform_xcode_resolved_block" >/dev/null; then
    report_failure "floating MHPlatform resolution found in the Xcode Package.resolved."
  fi

  if ! rg -n '"version"\s*:\s*"1\.1\.0"' <<<"$mhplatform_xcode_resolved_block" >/dev/null; then
    report_failure "The Xcode Package.resolved must pin MHPlatform 1.1.0."
  fi
fi

if ! rg -n '^(@testable )?import MHPlatformCore$' \
  StallyLibrary/Sources StallyLibrary/Tests >/dev/null; then
  report_failure "shared-library layer must import MHPlatformCore."
fi

if rg -n '^(@testable )?import MHPlatform$' \
  StallyLibrary/Sources StallyLibrary/Tests >/dev/null; then
  report_failure "shared-library layer must not import the MHPlatform umbrella."
fi

if rg -n '^(@testable )?import MH(DeepLinking|Logging|Preferences|RouteExecution|NotificationPlans|NotificationPayloads|AppRuntimeCore|AppRuntime|ReviewPolicy)$' \
  StallyLibrary/Sources StallyLibrary/Tests >/dev/null; then
  report_failure "shared-library layer must use MHPlatformCore instead of direct MHPlatform module imports."
fi

if ! rg -n '^import MHPlatform$' \
  Stally/Sources StallyTests >/dev/null; then
  report_failure "Stally app and tests must import MHPlatform."
fi

if rg -n '^import MH(AppRuntimeCore|AppRuntime|PlatformCore|DeepLinking|Logging|Preferences|RouteExecution|AppRuntimeDefaults|AppRuntimeAds|AppRuntimeLicenses|ReviewPolicy)$' \
  Stally/Sources StallyTests >/dev/null; then
  report_failure "Stally app and tests must use MHPlatform instead of direct MHPlatform module imports."
fi

if ! rg -n 'name: "MHPlatformCore"' \
  StallyLibrary/Package.swift >/dev/null; then
  report_failure "StallyLibrary must depend on the MHPlatformCore product."
fi

if rg -n 'name: "MHPlatform"|name: "MHAppRuntime"|name: "MHReviewPolicy"|name: "MHDeepLinking"|name: "MHLogging"|name: "MHPreferences"|name: "MHRouteExecution"' \
  StallyLibrary/Package.swift >/dev/null; then
  report_failure "StallyLibrary must not depend on app-facing or granular MHPlatform products."
fi

if ! rg -n 'productName = MHPlatform;' \
  Stally.xcodeproj/project.pbxproj >/dev/null; then
  report_failure "Stally target must depend on the MHPlatform umbrella."
fi

if rg -n 'productName = MH(AppRuntimeCore|DeepLinking|Logging|Preferences|RouteExecution|AppRuntimeDefaults|AppRuntimeAds|AppRuntimeLicenses);' \
  Stally.xcodeproj/project.pbxproj >/dev/null; then
  report_failure "Stally target must not depend on direct MHPlatform core/runtime products."
fi

if [[ $failure_count -ne 0 ]]; then
  exit 1
fi

echo "MHPlatform adoption checks passed."
