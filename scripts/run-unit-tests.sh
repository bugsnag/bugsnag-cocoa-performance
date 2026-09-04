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

# Xcode 14 can try to install the XCTest runner before an erased iOS 14
# simulator has finished registering applications with SpringBoard. Resolve
# the requested simulator unambiguously and wait for it to finish booting.
if [[ "$PLATFORM" = iOS && "$OS" == 14.* ]]; then
if [[ -z "${DEVICE:-}" ]]; then
echo "DEVICE must be specified when running iOS 14 simulator tests"
false
fi

simulator_udid=$(
xcrun simctl list devices "iOS $OS" |
awk -v device="$DEVICE" '
{
line = $0
sub(/^[[:space:]]*/, "", line)
}
index(line, device " (") == 1 && line !~ /unavailable/ {
sub(/^[^(]*\(/, "", line)
sub(/\).*/, "", line)
print line
exit
}
'
)

if [[ -z "$simulator_udid" ]]; then
echo "Could not find an available $DEVICE simulator running iOS $OS"
false
fi

echo "Waiting for $DEVICE ($simulator_udid) to finish booting"
xcrun simctl bootstatus "$simulator_udid" -b
fi

XCODEBUILD_EXTRA_ARGS=(-resultBundlePath "$xcresult")

if [[ ("$PLATFORM" = iOS || "$PLATFORM" = tvOS) && "$OS" == 9.* ]]; then
	# BugsnagNetworkRequestPlugin requires iOS/tvOS 10 or later
	XCODEBUILD_EXTRA_ARGS+=("-skip-testing:BugsnagNetworkRequestPlugin-${PLATFORM}Tests")
fi

make test "$@" XCODEBUILD_EXTRA_ARGS="${XCODEBUILD_EXTRA_ARGS[*]}" || die

rm -rf "$xcresult"
