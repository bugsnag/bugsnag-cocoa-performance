#!/usr/bin/env bash
# Source this from Xcode 27 steps (macos-26-2, "developer-machine" queue).

hostname -s | grep -q '^macos-26-2' || { echo "ERROR: expected macos-26-2, got $(hostname -s)"; exit 1; }
xcodebuild -version | grep -q '^Xcode 27' || { echo "ERROR: active Xcode is not Xcode 27"; xcodebuild -version; exit 1; }

# CI-only overrides applied by xcodebuild to every target; nothing is committed to the repo.
export XCODE_XCCONFIG_FILE="/tmp/xcode27-overrides-${BUILDKITE_JOB_ID}.xcconfig"
printf 'IPHONEOS_DEPLOYMENT_TARGET = 15.0\nOTHER_CFLAGS = $(inherited) -Wno-error=deprecated-declarations\n' > "$XCODE_XCCONFIG_FILE"
echo "Using CI-only Xcode 27 overrides from $XCODE_XCCONFIG_FILE:" && cat "$XCODE_XCCONFIG_FILE"
