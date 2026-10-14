#!/bin/sh

set -eu
(set -o pipefail) 2>/dev/null && set -o pipefail

bundle install

for arg in "$@"; do
  case "$arg" in
    *=*)
      name=${arg%%=*}
      value=${arg#*=}
      export "$name=$value"
      ;;
    *)
      echo "Unsupported argument: $arg" >&2
      exit 1
      ;;
  esac
done

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
  [ -z "${simulator_udid:-}" ] && return
  xcrun simctl shutdown "$simulator_udid" >/dev/null 2>&1 || true
  xcrun simctl delete "$simulator_udid" >/dev/null 2>&1 || true
}

trap cleanup_simulator EXIT

die() {
  status=$?
  echo "^^^ +++"
  mkdir -p logs
  [ -f xcodebuild.log ] && mv xcodebuild.log logs/
  [ -d "$xcresult" ] && zip -qr "logs/$xcresult.zip" "$xcresult"
  exit $status
}

create_dedicated_simulator() {
  [ -n "${DESTINATION:-}" ] && return
  case "$PLATFORM" in
    iOS|tvOS|watchOS)
      ;;
    *)
      return
      ;;
  esac
  [ "$OS" = "latest" ] && return

  runtime_name="$PLATFORM $OS"

  device_type_id="$(
    xcrun simctl list devicetypes -j | ruby -rjson -e '
      device_name = ENV.fetch("DEVICE")
      device_type = JSON.parse(STDIN.read).fetch("devicetypes").find { |item| item["name"] == device_name }
      abort("Unable to find simulator device type: #{device_name}") unless device_type
      puts device_type.fetch("identifier")
    '
  )"

  runtime_id="$(
    RUNTIME_NAME="$runtime_name" xcrun simctl list runtimes -j | ruby -rjson -e '
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

rm -rf "$xcresult" "$data_path"
 
