#!/usr/bin/env bash

set -euo pipefail

# Parse KEY=VALUE positional args into environment variables
for arg in "$@"; do
  case "$arg" in
    PLATFORM=*|OS=*|DEVICE=*)
      export "${arg?}"
      ;;
  esac
done

# Set defaults
PLATFORM="${PLATFORM:-iOS}"
OS="${OS:-26.1}"
DEVICE="${DEVICE:-iPhone 17}"

# Build MAKE_ARGS excluding KEY=VALUE env overrides
MAKE_ARGS=()
for arg in "$@"; do
  case "$arg" in
    PLATFORM=*|OS=*|DEVICE=*) ;;
    *) MAKE_ARGS+=("$arg") ;;
  esac
done
MAKE_ARGS=("${MAKE_ARGS[@]+"${MAKE_ARGS[@]}"}")

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

make analyze ${MAKE_ARGS[@]+"${MAKE_ARGS[@]}"} || die

rm -rf DerivedData

echo "--- Test"

# Clean up lingering CoreSimulator processes from previous agent runs
echo "--- Resetting CoreSimulator environment"
echo "  Killing lingering CoreSimulator daemons..."
killall -9 com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null || true
killall -9 launchd_sim 2>/dev/null || true
echo "  Shutting down all simulators..."
xcrun simctl shutdown all 2>/dev/null || true
echo "  Erasing all simulators..."
xcrun simctl erase all
echo "  CoreSimulator reset complete."

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

  # Countdown so CI log shows progress — avoids "stuck" appearance
  echo "Waiting 30s for LaunchServices app registration to settle on iOS $OS..."
  for i in 30 25 20 15 10 5; do
    echo "  ... ${i}s remaining"
    sleep 5
  done
  echo "  LaunchServices settle wait complete."
fi

# Use extended timeouts for iOS 14 to handle slow app registration
if [[ "$PLATFORM" == "iOS" && "$OS" == 14.* ]]; then
  XCODEBUILD_EXTRA_ARGS=(
    -resultBundlePath "$xcresult"
    -test-timeouts-enabled YES
    -parallel-testing-enabled NO
    -default-test-execution-time-allowance 600
    -maximum-test-execution-time-allowance 600
  )
else
  XCODEBUILD_EXTRA_ARGS=(
    -resultBundlePath "$xcresult"
    -test-timeouts-enabled YES
    -parallel-testing-enabled NO
  )
fi

if [[ ("$PLATFORM" = iOS || "$PLATFORM" = tvOS) && "$OS" == 9.* ]]; then
  XCODEBUILD_EXTRA_ARGS+=("-skip-testing:BugsnagNetworkRequestPlugin-${PLATFORM}Tests")
fi

XCODEBUILD_EXTRA_ARGS_STR="${XCODEBUILD_EXTRA_ARGS[*]}"

# Run tests with scoped retry for known simulator-launch attach flakes
max_attempts=2
attempt=1

until make test ${MAKE_ARGS[@]+"${MAKE_ARGS[@]}"} XCODEBUILD_EXTRA_ARGS="$XCODEBUILD_EXTRA_ARGS_STR"; do
  if [[ -f xcodebuild.log ]] \
    && grep -qE "Test runner never began executing tests after launching|FBSApplicationLibrary|Early unexpected exit" xcodebuild.log \
    && [[ $attempt -lt $max_attempts ]]; then
    attempt=$((attempt + 1))
    echo "--- Simulator launch flake detected, retrying tests (attempt $attempt/$max_attempts)"
    killall -9 com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null || true
    xcrun simctl shutdown all || true
    if [[ -n "${simulator_udid:-}" ]]; then
      xcrun simctl boot "$simulator_udid" 2>/dev/null || true
      xcrun simctl bootstatus "$simulator_udid" -b || true
      echo "Waiting 30s for LaunchServices to settle before retry..."
      for i in 30 25 20 15 10 5; do
        echo "  ... ${i}s remaining"
        sleep 5
      done
    fi
    continue
  fi
  die
done

rm -rf "$xcresult"
