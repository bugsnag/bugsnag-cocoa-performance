#!/bin/bash

set -euxo pipefail

cd $(dirname "${BASH_SOURCE[0]}")

repo=${BUILDKITE_REPO:-file://$(git rev-parse --show-toplevel)}
commit=${BUILDKITE_COMMIT:-$(git rev-parse HEAD)}
echo "git \"$repo\" \"$commit\"" > Cartfile
carthage update --platform iOS --use-xcframeworks

xcodebuild -destination generic/platform=iOS -archivePath Fixture.xcarchive -scheme Fixture archive -quiet
