#!/bin/bash

xcodebuild -version | awk 'NR==1{x=$0}END{print x" "$NF}'
echo "$(sw_vers -productName) $(sw_vers -productVersion) $(sw_vers -buildVersion) $(uname -m)"

set -euxo pipefail

cd $(dirname "${BASH_SOURCE[0]}")

repo="file://$(git rev-parse --show-toplevel)"
commit=${BUILDKITE_COMMIT:-$(git rev-parse HEAD)}
echo "git \"$repo\" \"$commit\"" > Cartfile

# Attempt to work around Carthage checkout errors
rm -rf ~/Library/Caches/org.carthage.CarthageKit/dependencies/bugsnag-cocoa-performance

carthage update --platform iOS --use-xcframeworks

xcodebuild -destination generic/platform=iOS -archivePath Fixture.xcarchive -scheme Fixture archive -quiet
