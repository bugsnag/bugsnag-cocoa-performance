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
failures=()

cleanup_simulator() {
    [[ -z "${simulator_udid:-}" ]] && return
    xcrun simctl shutdown "$simulator_udid" >/dev/null 2>&1 || true
    xcrun simctl delete "$simulator_udid" >/dev/null 2>&1 || true
    simulator_udid=""
    DESTINATION=""
}

# Delete dedicated simulators left behind by earlier runs that were killed
# (e.g. Buildkite timeout/cancel). Only removes simulators whose owning
# script PID (last part of the name) is no longer running, so concurrent
# jobs on the same agent are not affected.
cleanup_stale_simulators() {
    local udid
    xcrun simctl list devices -j | ruby -rjson -e '
        JSON.parse(STDIN.read).fetch("devices").values.flatten.each do |d|
            next unless d["name"] =~ /\ABugsnag-UnitTests-\d{8}-\d{6}-(\d+)\z/
            begin
                Process.kill(0, $1.to_i)   # owner still running -> keep
            rescue Errno::ESRCH
                puts d["udid"]             # owner gone -> delete
            rescue Errno::EPERM
                # owner exists under another user -> keep
            end
        end
    ' | while read -r udid; do
        [[ -z "$udid" ]] && continue
        echo "Deleting stale simulator: $udid"
        xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
        xcrun simctl delete "$udid" >/dev/null 2>&1 || true
    done
}

# INT/TERM exit through the EXIT trap so the simulator is cleaned up exactly once.
trap cleanup_simulator EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cleanup_stale_simulators || true

die() {
    local status=$?
    echo "^^^ +++"
    mkdir -p logs
    [[ -f xcodebuild.log ]] && mv xcodebuild.log logs/
    [[ -d "$current_xcresult" ]] && zip -qr "logs/$current_xcresult.zip" "$current_xcresult"
    exit $status
}

# Save logs for one failed bundle without stopping the script.
archive_failure() {
    local test_xcresult=$1
    echo "^^^ +++"
    mkdir -p logs
    if [[ -f xcodebuild.log ]]; then
        mv xcodebuild.log "logs/xcodebuild-${test_xcresult%.xcresult}.log"
    fi
    if [[ -d "$test_xcresult" ]]; then
        zip -qr "logs/$test_xcresult.zip" "$test_xcresult"
    fi
}

run_make_test() {
    local test_xcresult=$1
    local test_selector=$2
    shift 2

    current_xcresult="$test_xcresult"
    local test_xcodebuild_args="${XCODEBUILD_EXTRA_ARGS:-}"
    test_xcodebuild_args="${test_xcodebuild_args:+$test_xcodebuild_args }-resultBundlePath $test_xcresult"
    [[ -n "$test_selector" ]] && test_xcodebuild_args="$test_xcodebuild_args $test_selector"
    cleanup_xcresults="$cleanup_xcresults $test_xcresult"

    if [[ "$PLATFORM" == "iOS" ]]; then
        # Fresh simulator per bundle (this is what fixed the iOS 14 runner hang).
        cleanup_simulator
        if ! create_dedicated_simulator; then
            echo "Failed to create dedicated simulator for $test_xcresult" >&2
            archive_failure "$test_xcresult"
            return 1
        fi
    fi

    # All bundles share one DerivedData path so only the first bundle does a
    # full build; later bundles reuse the build products.
    if [[ -n "${DESTINATION:-}" ]]; then
        if ! make test "$@" "DATA_PATH=$data_path" "XCODEBUILD_EXTRA_ARGS=$test_xcodebuild_args" "DESTINATION=$DESTINATION"; then
            archive_failure "$test_xcresult"
            return 1
        fi
    else
        if ! make test "$@" "DATA_PATH=$data_path" "XCODEBUILD_EXTRA_ARGS=$test_xcodebuild_args"; then
            archive_failure "$test_xcresult"
            return 1
        fi
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

    # Intentional: CI always passes an explicit OS. OS=latest is only used for
    # local runs, where the default simulator from the Makefile is fine.
    [[ "$OS" == "latest" ]] && return

    local runtime_name="$PLATFORM $OS"

    # Explicit "|| return 1": this function may be called from an "||" context
    # where set -e is disabled.
    local device_type_id
    device_type_id="$(
        xcrun simctl list devicetypes -j | ruby -rjson -e '
            device_name = ENV.fetch("DEVICE")
            device_type = JSON.parse(STDIN.read).fetch("devicetypes").find { |item| item["name"] == device_name }
            abort("Unable to find simulator device type: #{device_name}") unless device_type
            puts device_type.fetch("identifier")
        '
    )" || return 1

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
    )" || return 1

    simulator_udid="$(xcrun simctl create "Bugsnag-UnitTests-$run_id" "$device_type_id" "$runtime_id")" || return 1

    echo "Using dedicated simulator: $simulator_udid"
    xcrun simctl boot "$simulator_udid" || return 1
    xcrun simctl bootstatus "$simulator_udid" -b || return 1

    DESTINATION="platform=$PLATFORM Simulator,id=$simulator_udid"
}

echo "--- Analyze"

rm -rf DerivedData

make analyze "$@" || die

rm -rf DerivedData

echo "--- Test"

# Parallel testing clones the simulator; on CI agents the clones intermittently
# fail to launch ("Test runner never began executing tests"), so tests run
# serially on all platforms. (-maximum-parallel-testing-workers is a no-op
# once parallel testing is disabled, so it is not passed.)
XCODEBUILD_EXTRA_ARGS="${XCODEBUILD_EXTRA_ARGS:+$XCODEBUILD_EXTRA_ARGS }-parallel-testing-enabled NO"

if [[ ("$PLATFORM" == "iOS" || "$PLATFORM" == "tvOS") && "${OS#9.}" != "$OS" ]]; then
    # BugsnagNetworkRequestPlugin requires iOS/tvOS 10 or later
    XCODEBUILD_EXTRA_ARGS="$XCODEBUILD_EXTRA_ARGS -skip-testing:BugsnagNetworkRequestPlugin-${PLATFORM}Tests"
fi

if [[ "$PLATFORM" == "iOS" ]]; then
    # Keep in sync with the Testables in the BugsnagPerformance-iOS scheme.
    # All bundles run even if one fails; the job fails at the end.
    run_make_test "${xcresult%.xcresult}-swift.xcresult" "-only-testing:BugsnagPerformance-iOSTestsSwift" "$@" \
        || failures+=("BugsnagPerformance-iOSTestsSwift")
    run_make_test "${xcresult%.xcresult}-objc.xcresult" "-only-testing:BugsnagPerformance-iOSTests" "$@" \
        || failures+=("BugsnagPerformance-iOSTests")
    run_make_test "${xcresult%.xcresult}-named-spans.xcresult" "-only-testing:BugsnagPerformanceNamedSpansTests" "$@" \
        || failures+=("BugsnagPerformanceNamedSpansTests")
else
    create_dedicated_simulator
    run_make_test "$xcresult" "" "$@" || failures+=("$PLATFORM tests")
fi

if (( ${#failures[@]} > 0 )); then
    # Same as before: on failure, leave xcresult/DerivedData in place (already zipped to logs/).
    echo "Failed test bundles: ${failures[*]}" >&2
    exit 1
fi

for path in $cleanup_xcresults $cleanup_data_paths; do
    rm -rf "$path"
done
