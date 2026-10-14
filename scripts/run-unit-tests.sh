#!/usr/bin/env bash
#
# Runs static analysis and unit tests for the Bugsnag Cocoa SDK.
#
# Usage:
#   ./run-unit-tests.sh [PLATFORM=iOS|tvOS|watchOS|macOS] [OS=latest|<version>] \
#                       [DEVICE=<simulator device name>] [DESTINATION=<xcodebuild destination>]
#
# Compatible with the macOS system Bash (3.2).

set -euo pipefail

# ---------------------------------------------------------------------------
# Argument parsing: allowlist only (replaces the unsafe `declare "${@}"`)
# ---------------------------------------------------------------------------
supplied_vars=()

for arg in "$@"; do
  case "$arg" in
    PLATFORM=*|OS=*|DEVICE=*|DESTINATION=*)
      name="${arg%%=*}"
      printf -v "$name" '%s' "${arg#*=}"
      case " ${supplied_vars[*]-} " in
        *" $name "*) ;;                    # already recorded
        *) supplied_vars+=("$name") ;;
      esac
      ;;
    *)
      echo "Unsupported argument: $arg" >&2
      echo "Allowed arguments: PLATFORM=, OS=, DEVICE=, DESTINATION=" >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
: "${PLATFORM:=iOS}"
: "${OS:=latest}"

case "$PLATFORM" in
  iOS)     : "${DEVICE:=iPhone 11}" ;;
  tvOS)    : "${DEVICE:=Apple TV}" ;;
  watchOS) : "${DEVICE:=Apple Watch Series 5 - 40mm}" ;;
esac

# ---------------------------------------------------------------------------
# Validation (also covers values inherited from the environment)
# ---------------------------------------------------------------------------
platform_re='^(iOS|tvOS|watchOS|macOS)$'
os_re='^(latest|[0-9]+(\.[0-9]+)*)$'
device_re='^[A-Za-z0-9 ().-]+$'
destination_re='^[A-Za-z0-9 =,.:_()-]+$'

if [[ ! "$PLATFORM" =~ $platform_re ]]; then
  echo "Invalid PLATFORM: $PLATFORM" >&2; exit 2
fi
if [[ ! "$OS" =~ $os_re ]]; then
  echo "Invalid OS: $OS" >&2; exit 2
fi
if [[ -n "${DEVICE:-}" && ! "$DEVICE" =~ $device_re ]]; then
  echo "Invalid DEVICE: $DEVICE" >&2; exit 2
fi
if [[ -n "${DESTINATION:-}" && ! "$DESTINATION" =~ $destination_re ]]; then
  echo "Invalid DESTINATION: $DESTINATION" >&2; exit 2
fi

# Validated user-supplied variables forwarded to make (DESTINATION handled separately)
make_vars=()
for name in "${supplied_vars[@]+"${supplied_vars[@]}"}"; do
  if [[ "$name" != DESTINATION ]]; then
    make_vars+=("$name=${!name}")
  fi
done

# ---------------------------------------------------------------------------
# Run-scoped state
# ---------------------------------------------------------------------------
xcresult=$(date '+BugsnagTests-%Y-%m-%d-%H-%M-%S.xcresult')
run_id="$(date +%Y%m%d-%H%M%S)-$$"
data_path="DerivedData-$run_id"
simulator_udid=""

# ---------------------------------------------------------------------------
# Cleanup / failure handling
# ---------------------------------------------------------------------------
cleanup_simulator() {
  if [[ -z "${simulator_udid:-}" ]]; then
    return 0
  fi
  xcrun simctl shutdown "$simulator_udid" >/dev/null 2>&1 || true
  xcrun simctl delete "$simulator_udid" >/dev/null 2>&1 || true
}

cleanup() {
  cleanup_simulator
  if [[ -n "${data_path:-}" ]]; then
    rm -rf "$data_path"
  fi
}
trap cleanup EXIT

die() {
  local status=$?
  echo "^^^ +++"
  mkdir -p logs
  if [[ -f xcodebuild.log ]]; then
    mv xcodebuild.log logs/
  fi
  if [[ -d "$xcresult" ]]; then
    # NOTE: xcresult bundles/logs may contain env values or test output.
    # Make sure CI does not publish logs/ publicly (e.g. on fork PR builds).
    zip -qr "logs/$xcresult.zip" "$xcresult"
  fi
  exit "$status"
}

# ---------------------------------------------------------------------------
# Dedicated simulator (only when a specific OS version is requested)
# ---------------------------------------------------------------------------
create_dedicated_simulator() {
  if [[ -n "${DESTINATION:-}" ]]; then return 0; fi
  if [[ "$PLATFORM" != iOS && "$PLATFORM" != tvOS && "$PLATFORM" != watchOS ]]; then return 0; fi
  if [[ "$OS" == "latest" ]]; then return 0; fi

  local runtime_name="$PLATFORM $OS"
  local device_type_id
  local runtime_id

  # Values are passed to Ruby via ENV (never interpolated into the Ruby code)
  device_type_id="$(
    xcrun simctl list devicetypes -j | DEVICE="${DEVICE:-}" ruby -rjson -e '
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

# ---------------------------------------------------------------------------
# Dependencies (locked to Gemfile.lock)
# ---------------------------------------------------------------------------
echo "--- Install dependencies"
BUNDLE_FROZEN=true bundle install

# ---------------------------------------------------------------------------
# Analyze
# ---------------------------------------------------------------------------
echo "--- Analyze"
rm -rf DerivedData

analyze_args=("${make_vars[@]+"${make_vars[@]}"}")
if [[ -n "${DESTINATION:-}" ]]; then
  analyze_args+=("DESTINATION=$DESTINATION")
fi

make analyze "${analyze_args[@]+"${analyze_args[@]}"}" || die
rm -rf DerivedData

# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------
echo "--- Test"
XCODEBUILD_EXTRA_ARGS=(-resultBundlePath "$xcresult")

if [[ ("$PLATFORM" = iOS || "$PLATFORM" = tvOS) && "$OS" == 9.* ]]; then
  # BugsnagNetworkRequestPlugin requires iOS/tvOS 10 or later
  XCODEBUILD_EXTRA_ARGS+=("-skip-testing:BugsnagNetworkRequestPlugin-${PLATFORM}Tests")
fi

create_dedicated_simulator

# NOTE: XCODEBUILD_EXTRA_ARGS is flattened into one string; the Makefile splits it on spaces.
# This is safe as long as none of the values contain spaces (true for the values above).
test_args=(
  "${make_vars[@]+"${make_vars[@]}"}"
  "DATA_PATH=$data_path"
  "XCODEBUILD_EXTRA_ARGS=${XCODEBUILD_EXTRA_ARGS[*]}"
)
if [[ -n "${DESTINATION:-}" ]]; then
  test_args+=("DESTINATION=$DESTINATION")
fi

make test "${test_args[@]}" || die

rm -rf "$xcresult"
# $data_path and the simulator are removed by the EXIT trap
