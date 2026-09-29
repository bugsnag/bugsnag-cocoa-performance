#!/usr/bin/env bash

set -euo pipefail

bundle install

declare "${@}"

xcresult=$(date '+BugsnagTests-%Y-%m-%d-%H-%M-%S.xcresult')

die() {
	status=$?
	echo "^^^ +++"
	mkdir -p logs
	[[ -f xcodebuild.log ]] && mv xcodebuild.log logs/
	[[ -d $xcresult ]] && zip -qr "logs/$xcresult.zip" "$xcresult"
	exit $status
}

bundle install

echo "--- Analyze"

rm -rf DerivedData

make analyze "$@" || die

rm -rf DerivedData

echo "--- Test"

xcrun simctl shutdown all
xcrun simctl erase all

XCODEBUILD_EXTRA_ARGS=(-resultBundlePath "$xcresult")

if [[ ("$PLATFORM" = iOS || "$PLATFORM" = tvOS) && "$OS" == 9.* ]]; then
	# BugsnagNetworkRequestPlugin requires iOS/tvOS 10 or later
	XCODEBUILD_EXTRA_ARGS+=("-skip-testing:BugsnagNetworkRequestPlugin-${PLATFORM}Tests")
fi

if [[ "$PLATFORM" = iOS && ("$OS" == 14 || "$OS" == 14.*) ]]; then
	# Disk IOPS unit tests (PLAT-17309 / ROAD-2233) are not run on any iOS 14.x
	# simulator job. The test target is BugsnagPerformance-iOSTests; the four
	# classes live in DiskIOCollectorTests.mm, DiskIOMetricsTests.mm and
	# DiskIOSnapshotTests.mm.
	XCODEBUILD_EXTRA_ARGS+=("-skip-testing:BugsnagPerformance-iOSTests/DiskIOCollectorTests")
	XCODEBUILD_EXTRA_ARGS+=("-skip-testing:BugsnagPerformance-iOSTests/DiskIOLifecycleGatingTests")
	XCODEBUILD_EXTRA_ARGS+=("-skip-testing:BugsnagPerformance-iOSTests/DiskIOMetricsTests")
	XCODEBUILD_EXTRA_ARGS+=("-skip-testing:BugsnagPerformance-iOSTests/DiskIOSnapshotTests")
fi

make test "$@" XCODEBUILD_EXTRA_ARGS="${XCODEBUILD_EXTRA_ARGS[*]}" || die

rm -rf "$xcresult"
