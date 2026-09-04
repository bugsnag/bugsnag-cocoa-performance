#!/usr/bin/env bash

set -euo pipefail

# Safely handle parameters without declare "${@}"
PLATFORM="${PLATFORM:-iOS}"
OS="${OS:-14.5}"
DEVICE="${DEVICE:-iPhone 12}"

MAKE_ARGS=("$@")

bundle install

xcresult=$(date '+BugsnagTests-%Y-%m-%d-%H-%M-%S.xcresult')

die() {
  status=$?
  echo "^^^ +++"
  mkdir -p logs
  [[ -f xcodebuild.log ]] && mv xcodebuild.log logs/
  [[ -d "$xcresult" ]] && zip -qr "logs/$xcresult.zip" "$xcresult"
  exit $status
}

echo "--- Analyze"

rm -rf DerivedData

make analyze "${MAKE_ARGS[@]}" || die

rm -rf DerivedData

echo "--- Test"

xcrun simctl shutdown all
xcrun simctl erase all

# Pre-boot target simulator to allow iOS 13/14 SpringBoard & Data Migrations to settle
simulator_udid=""

if [[ "$PLATFORM" == "iOS" && ( "$OS" == 14.* || "$OS" == 13.* ) ]]; then
  if [[ -z "${DEVICE:-}" ]]; then
    echo "DEVICE must be specified when running iOS $OS simulator tests"
    exit 1
  fi

  simulator_udid=$(
    xcrun simctl list devices "iOS $OS" 2>/dev/null |
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
    exit 1
  fi

  echo "Booting $DEVICE ($simulator_udid) and waiting for iOS $OS initialization..."
  xcrun simctl boot "$simulator_udid" 2>/dev/null || true
  xcrun simctl bootstatus "$simulator_udid" -b || true
fi

XCODEBUILD_EXTRA_ARGS=(-resultBundlePath "$xcresult")

if [[ ("$PLATFORM" = iOS || "$PLATFORM" = tvOS) && "$OS" == 9.* ]]; then
  # BugsnagNetworkRequestPlugin requires iOS/tvOS 10 or later
  XCODEBUILD_EXTRA_ARGS+=("-skip-testing:BugsnagNetworkRequestPlugin-${PLATFORM}Tests")
fi

XCODEBUILD_EXTRA_ARGS_STR="${XCODEBUILD_EXTRA_ARGS[*]}"

# Run tests with scoped retry for the known simulator-launch attach flake
max_attempts=2
attempt=1

until make test "${MAKE_ARGS[@]}" XCODEBUILD_EXTRA_ARGS="$XCODEBUILD_EXTRA_ARGS_STR"; do
  if [[ -f xcodebuild.log ]] \
    && grep -q "Test runner never began executing tests after launching" xcodebuild.log \
    && [[ $attempt -lt $max_attempts ]]; then
    attempt=$((attempt + 1))
    echo "--- Simulator launch flake detected, retrying tests (attempt $attempt/$max_attempts)"
    xcrun simctl shutdown all || true
    if [[ -n "${simulator_udid:-}" ]]; then
      xcrun simctl boot "$simulator_udid" 2>/dev/null || true
      xcrun simctl bootstatus "$simulator_udid" -b || true
    fi
    continue
  fi
  die
done

rm -rf "$xcresult"
