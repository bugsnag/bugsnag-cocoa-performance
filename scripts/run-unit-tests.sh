#!/usr/bin/env bash

set -euo pipefail

bundle install

for arg in "$@"; do
    if [[ "${arg#*=}" != "$arg" ]]; then
        name=${arg%%=*}
        value=${arg#*=}
        export "$name=$value"
    else
        echo "Unsupported argument: $arg" >&2
        exit 1
    fi
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
current_xcresult="$xcresult"
run_id="$(date +%Y%m%d-%H%M%S)-$$"
data_path="DerivedData-$run_id"
cleanup_xcresults="$xcresult"
cleanup_data_paths="$data_path"
simulator_udid=""

cleanup_simulator() {
    [[ -z "${simulator_udid:-}" ]] && return
    xcrun simctl shutdown "$simulator_udid" >/dev/null 2>&1 || true
    xcrun simctl delete "$simulator_udid" >/dev/null 2>&1 || true
    simulator_udid=""
    DESTINATION=""
}

trap cleanup_simulator EXIT

die() {
    local status=$?
    echo "^^^ +++"
    mkdir -p logs
    [[ -f xcodebuild.log ]] && mv xcodebuild.log logs/
    [[ -d "$current_xcresult" ]] && zip -qr "logs/$current_xcresult.zip" "$current_xcresult"
    exit $status
}

run_make_test() {
    local test_xcresult=$1
    local test_selector=$2
    shift 2

    current_xcresult="$test_xcresult"
    local test_xcodebuild_args="${XCODEBUILD_EXTRA_ARGS:-}"
    test_xcodebuild_args="${test_xcodebuild_args:+$test_xcodebuild_args }-resultBundlePath $test_xcresult"
    [[ -n "$test_selector" ]] && test_xcodebuild_args="$test_xcodebuild_args $test_selector"
    local test_data_path="$data_path"
    cleanup_xcresults="$cleanup_xcresults $test_xcresult"

    if [[ "$PLATFORM" == "iOS" ]]; then
        cleanup_simulator
        create_dedicated_simulator
        test_data_path="${data_path}-${test_xcresult%.xcresult}"
        cleanup_data_paths="$cleanup_data_paths $test_data_path"
    fi

    if [[ -n "${DESTINATION:-}" ]]; then
        make test "$@" "DATA_PATH=$test_data_path" "XCODEBUILD_EXTRA_ARGS=$test_xcodebuild_args" "DESTINATION=$DESTINATION" || die
    else
        make test "$@" "DATA_PATH=$test_data_path" "XCODEBUILD_EXTRA_ARGS=$test_xcodebuild_args" || die
    fi
}

create_dedicated_simulator() {
    [[ -n "${DESTINATION:-}" ]] && return

    case "$PLATFORM" in
        iOS|tvOS|watchOS)
            ;;
        *)
            return
            ;;
    esac

    [[ "$OS" == "latest" ]] && return

    local runtime_name="$PLATFORM $OS"

    local device_type_id
    device_type_id="$(
        xcrun simctl list devicetypes -j | ruby -rjson -e '
            device_name = ENV.fetch("DEVICE")
            device_type = JSON.parse(STDIN.read).fetch("devicetypes").find { |item| item["name"] == device_name }
            abort("Unable to find simulator device type: #{device_name}") unless device_type
            puts device_type.fetch("identifier")
        '
    )"

    local runtime_id
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

echo "--- Analyze"

rm -rf DerivedData

make analyze "$@" || die

rm -rf DerivedData

echo "--- Test"

XCODEBUILD_EXTRA_ARGS="${XCODEBUILD_EXTRA_ARGS:+$XCODEBUILD_EXTRA_ARGS }-parallel-testing-enabled NO -maximum-parallel-testing-workers 1"

if [[ ("$PLATFORM" == "iOS" || "$PLATFORM" == "tvOS") && "${OS#9.}" != "$OS" ]]; then
    # BugsnagNetworkRequestPlugin requires iOS/tvOS 10 or later
    XCODEBUILD_EXTRA_ARGS="$XCODEBUILD_EXTRA_ARGS -skip-testing:BugsnagNetworkRequestPlugin-${PLATFORM}Tests"
fi

if [[ "$PLATFORM" == "iOS" ]]; then
    run_make_test "${xcresult%.xcresult}-swift.xcresult" "-only-testing:BugsnagPerformance-iOSTestsSwift" "$@"
    run_make_test "${xcresult%.xcresult}-objc.xcresult" "-only-testing:BugsnagPerformance-iOSTests" "$@"
    run_make_test "${xcresult%.xcresult}-named-spans.xcresult" "-only-testing:BugsnagPerformanceNamedSpansTests" "$@"
else
    create_dedicated_simulator
    run_make_test "$xcresult" "" "$@"
fi

for path in $cleanup_xcresults $cleanup_data_paths; do
    rm -rf "$path"
done
