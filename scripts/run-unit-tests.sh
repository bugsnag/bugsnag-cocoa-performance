#!/bin/sh
#
# Runs static analysis and unit tests for the Bugsnag Cocoa SDK.
# Usage: ./scripts/run-unit-tests.sh [PLATFORM=..] [OS=..] [DEVICE=..] [DESTINATION=..]

set -eu
(set -o pipefail) 2>/dev/null && set -o pipefail

# --- Arguments: allowlist only -------------------------------------------
for arg in "$@"; do
  case "$arg" in
    PLATFORM=*|OS=*|DEVICE=*|DESTINATION=*)
      name=${arg%%=*}
      value=${arg#*=}
      export "$name=$value"
      ;;
    *)
      echo "Unsupported argument: $arg" >&2
      echo "Allowed: PLATFORM=, OS=, DEVICE=, DESTINATION=" >&2
      exit 2
      ;;
  esac
done

# --- Defaults --------------------------------------------------------------
: "${PLATFORM:=iOS}"
: "${OS:=latest}"

case "$PLATFORM" in
  iOS)     : "${DEVICE:=iPhone 11}" ;;
  tvOS)    : "${DEVICE:=Apple TV}" ;;
  watchOS) : "${DEVICE:=Apple Watch Series 5 - 40mm}" ;;
esac

# --- Validation ------------------------------------------------------------
invalid() {
  echo "Invalid $1: $2" >&2
  exit 2
}

case "$PLATFORM" in
  iOS|tvOS|watchOS|macOS) ;;
  *) invalid PLATFORM "$PLATFORM" ;;
esac

case "$OS" in
  latest) ;;
  ''|*[!0-9.]*|.*|*.) invalid OS "$OS" ;;
esac

if [ -n "${DEVICE:-}" ]; then
  case "$DEVICE" in
    *[!A-Za-z0-9\ \(\).-]*) invalid DEVICE "$DEVICE" ;;
  esac
fi

if [ -n "${DESTINATION:-}" ]; then
  case "$DESTINATION" in
    *[!A-Za-z0-9\ =,.:_\(\)-]*) invalid DESTINATION "$DESTINATION" ;;
  esac
fi

# --- Run-scoped state ------------------------------------------------------
xcresult=$(date '+BugsnagTests-%Y-%m-%d-%H-%M-%S.xcresult')
run_id="$(date +%Y%m%d-%H%M%S)-$$"
data_path="DerivedData-$run_id"
simulator_udid=""

# --- Cleanup / failure handling --------------------------------------------
cleanup() {
  if [ -n "${simulator_udid:-}" ]; then
    xcrun simctl shutdown "$simulator_udid" >/dev/null 2>&1 || true
    xcrun simctl delete "$simulator_udid" >/dev/null 2>&1 || true
  fi
  rm -rf "$data_path"
}
trap cleanup EXIT

die() {
  status=$?
  echo "^^^ +++"
  mkdir -p logs
  if [ -f xcodebuild.log ]; then
    mv xcodebuild.log logs/
  fi
  if [ -d "$xcresult" ]; then
    zip -qr "logs/$xcresult.zip" "$xcresult"
  fi
  exit "$status"
}

# --- Dedicated simulator ---------------------------------------------------
create_dedicated_simulator() {
  if [ -n "${DESTINATION:-}" ]; then return 0; fi
  case "$PLATFORM" in
    iOS|tvOS|watchOS) ;;
    *) return 0 ;;
  esac
  if [ "$OS" = "latest" ]; then return 0; fi

  runtime_name="$PLATFORM $OS"

  device_type_id="$(
    xcrun simctl list devicetypes -j | DEVICE="$DEVICE" ruby -rjson -e '
      device_name = ENV.fetch("DEVICE")
      device_type = JSON.parse(STDIN.read).fetch("devicetypes").find { |item| item["name"] == device_name }
      abort("Unable to find simulator device type: #{device_name}") unless device_type
      puts device_type.fetch("identifier")
    '
  )"

  runtime_id="$(
    xcrun simctl list runtimes -j | RUNTIME_NAME="$runtime_name" ruby -rjson -e '
      runtime_name = ENV.fetch("RUNTIME_NAME")
      runtime = JSON.parse(STDIN.read).fetch("runtimes").find do |item|
        item["name"] == runtime_name && item.fetch("isAvailable", item["availability"] == "(available)")
      end
      abort("Unable to find available simulator runtime: #{runtime_name}") unless runtime
      puts runtime.fetch("identifier")
    '
  )"

  simulator_udid="$(xcrun simctl create "Bugsnag-UnitTests-$run_id" "$device_type_id" "$runtime_id")"
  echo "Using dedicated simulator: $simulator_udid"

  xcrun simctl boot "$simulator_udid"
  xcrun simctl bootstatus "$simulator_udid" -b

  DESTINATION="platform=$PLATFORM Simulator,id=$simulator_udid"
}

# --- Dependencies ----------------------------------------------------------
echo "--- Install dependencies"
bundle install

# --- Analyze ---------------------------------------------------------------
echo "--- Analyze"
rm -rf DerivedData
make analyze "$@" || die
rm -rf DerivedData

# --- Test ------------------------------------------------------------------
echo "--- Test"
XCODEBUILD_EXTRA_ARGS="-resultBundlePath $xcresult"

if { [ "$PLATFORM" = "iOS" ] || [ "$PLATFORM" = "tvOS" ]; } && [ "${OS#9.}" != "$OS" ]; then
  # BugsnagNetworkRequestPlugin requires iOS/tvOS 10 or later
  XCODEBUILD_EXTRA_ARGS="$XCODEBUILD_EXTRA_ARGS -skip-testing:BugsnagNetworkRequestPlugin-${PLATFORM}Tests"
fi

create_dedicated_simulator

if [ -n "${DESTINATION:-}" ]; then
  make test "$@" "DATA_PATH=$data_path" "XCODEBUILD_EXTRA_ARGS=$XCODEBUILD_EXTRA_ARGS" "DESTINATION=$DESTINATION" || die
else
  make test "$@" "DATA_PATH=$data_path" "XCODEBUILD_EXTRA_ARGS=$XCODEBUILD_EXTRA_ARGS" || die
fi

rm -rf "$xcresult"
# $data_path and the simulator are removed by the EXIT trap
