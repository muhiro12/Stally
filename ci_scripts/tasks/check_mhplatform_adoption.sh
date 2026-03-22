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

if sed -n '/url: "https:\/\/github.com\/muhiro12\/MHPlatform.git"/,/)/p' \
  StallyLibrary/Package.swift | rg -n 'branch:' >/dev/null; then
  report_failure "branch-based MHPlatform dependency found in StallyLibrary/Package.swift."
fi

if sed -n '/url: "https:\/\/github.com\/muhiro12\/MHPlatform.git"/,/)/p' \
  StallyLibrary/Package.swift | rg -n 'path:' >/dev/null; then
  report_failure "local-path MHPlatform dependency found in StallyLibrary/Package.swift."
fi

if awk '/XCRemoteSwiftPackageReference "MHPlatform"/,/};/' \
  Stally.xcodeproj/project.pbxproj | rg -n 'kind = branch|branch =' >/dev/null; then
  report_failure "branch-based MHPlatform dependency found in Stally.xcodeproj."
fi

if sed -n '/"identity" : "mhplatform"/,/}/p' \
  StallyLibrary/Package.resolved | rg -n '"branch"' >/dev/null; then
  report_failure "floating MHPlatform resolution found in StallyLibrary/Package.resolved."
fi

if sed -n '/"identity" : "mhplatform"/,/}/p' \
  Stally.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved | \
  rg -n '"branch"' >/dev/null; then
  report_failure "floating MHPlatform resolution found in the Xcode Package.resolved."
fi

if rg -n '^(@testable )?import MHPlatform$' \
  StallyLibrary/Sources StallyLibrary/Tests >/dev/null; then
  report_failure "shared-library layer imports the MHPlatform umbrella."
fi

if rg -n '^import MHPlatform$' Stally/Sources >/dev/null; then
  report_failure "Stally app sources import the MHPlatform umbrella."
fi

if rg -n 'name: "MHPlatform"|name: "MHAppRuntime"|name: "MHReviewPolicy"' \
  StallyLibrary/Package.swift >/dev/null; then
  report_failure "StallyLibrary depends on an app-facing MHPlatform product."
fi

if rg -n 'productName = MHPlatform;' Stally.xcodeproj/project.pbxproj >/dev/null; then
  report_failure "Stally target depends on the full MHPlatform umbrella."
fi

if [[ $failure_count -ne 0 ]]; then
  exit 1
fi

echo "MHPlatform adoption checks passed."
