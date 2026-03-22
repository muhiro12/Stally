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
  echo "MHUI adoption violation: $1" >&2
  failure_count=$((failure_count + 1))
}

if rg -n 'XCLocalSwiftPackageReference "MHUI"|relativePath = .*MHUI' \
  Stally.xcodeproj/project.pbxproj >/dev/null; then
  report_failure "local-path MHUI dependency found in Stally.xcodeproj."
fi

mhui_package_block=$(
  awk '/XCRemoteSwiftPackageReference "MHUI"/,/};/' \
    Stally.xcodeproj/project.pbxproj
)

if [[ -z "$mhui_package_block" ]]; then
  report_failure "MHUI remote package reference is missing from Stally.xcodeproj."
else
  if rg -n 'kind = branch|branch =|kind = revision' <<<"$mhui_package_block" >/dev/null; then
    report_failure "non-versioned MHUI dependency found in Stally.xcodeproj."
  fi

  if ! rg -n 'kind = upToNextMajorVersion' <<<"$mhui_package_block" >/dev/null; then
    report_failure "MHUI dependency is not configured as an up-to-next-major version range."
  fi

  if ! rg -n 'minimumVersion = 1\.0\.0;' <<<"$mhui_package_block" >/dev/null; then
    report_failure "MHUI dependency does not start from version 1.0.0."
  fi
fi

mhui_resolved_block=$(
  sed -n '/"identity" : "mhui"/,/}/p' \
    Stally.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
)

if [[ -z "$mhui_resolved_block" ]]; then
  report_failure "MHUI pin is missing from the Xcode Package.resolved."
else
  if rg -n '"branch"' <<<"$mhui_resolved_block" >/dev/null; then
    report_failure "floating MHUI resolution found in the Xcode Package.resolved."
  fi

  if ! rg -n '"version"' <<<"$mhui_resolved_block" >/dev/null; then
    report_failure "versioned MHUI resolution is missing from the Xcode Package.resolved."
  fi
fi

if [[ $failure_count -ne 0 ]]; then
  exit 1
fi

echo "MHUI adoption checks passed."
