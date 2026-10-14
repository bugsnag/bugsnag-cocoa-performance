#!/usr/bin/env bash

set -euo pipefail

bundle install

declare "${@}"

: "${PLATFORM:=iOS}"
: "${OS:=latest}"

case "$PLATFORM" in
  iOS)
    : "${DEVICE:=iPhone 11}"
    ;;
  tvOS)
    : "${DEVICE:=Apple TV}"
    ;;
  watchOS)
    : "${DEVICE:=Apple Watch Series 5 - 40mm}"
    ;;
esac

xcresult=$(date '+BugsnagTests-%Y-%m-%d-%H-%M-%S.xcresult')
run_id="$(date +%Y%m%d-%H%M%S)-$$"
data_path="DerivedData-$run_id"
simulator_udid=""

cleanup_simulator() {
  [[ -z "${simulator_udid:-}" ]] && return
  xcrun simctl shutdown "$simulator_udid" >/dev/null 2>&1 || true
  xcrun simctl delete "$simulator_udid" >/dev/null 2>&1 || true
}

trap cleanup_simulator EXIT

die() {
  status=$?
  echo "^^^ +++"
  mkdir -p logs
  [[ -f xcodebuild.log ]] && mv xcodebuild.log logs/
  [[ -d $xcresult ]] && zip -qr "logs/$xcresult.zip" "$xcresult"
  exit $status
}

create_dedicated_simulator() {
  [[ -n "${DESTINATION:-}" ]] && return
  [[ "$PLATFORM" != iOS && "$PLATFORM" != tvOS && "$PLATFORM" != watchOS ]] && return
  [[ "$OS" == "latest" ]] && return

  local runtime_name="$PLATFORM $OS"
  local device_type_id
  local runtime_id

  device_type_id="$(
    xcrun simctl list devicetypes -j | ruby -rjson -e '
      device_name = ENV.fetch("DEVICE")
      device_type = JSON.parse(STDIN.read).fetch("devicetypes").find { |item| item["name"] == device_name }
      abort("Unable to find simulator device type: #{device_name}") unless device_type
      puts device_type.fetch("identifier")
    '
  )"

  runtime_id="$(
    xcrun simctl list runtimes -j | ruby -rjson -e '
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

bundle install

echo "--- Analyze"

rm -rf DerivedData

make analyze "$@" || die

rm -rf DerivedData

echo "--- Test"

XCODEBUILD_EXTRA_ARGS=(-resultBundlePath "$xcresult")

if [[ ("$PLATFORM" = iOS || "$PLATFORM" = tvOS) && "$OS" == 9.* ]]; then
  # BugsnagNetworkRequestPlugin requires iOS/tvOS 10 or later
  XCODEBUILD_EXTRA_ARGS+=("-skip-testing:BugsnagNetworkRequestPlugin-${PLATFORM}Tests")
fi

create_dedicated_simulator

make_args=("$@" "DATA_PATH=$data_path" "XCODEBUILD_EXTRA_ARGS=${XCODEBUILD_EXTRA_ARGS[*]}")
[[ -n "${DESTINATION:-}" ]] && make_args+=("DESTINATION=$DESTINATION")

make test "${make_args[@]}" || die

rm -rf "$xcresult" "$data_path"
 
