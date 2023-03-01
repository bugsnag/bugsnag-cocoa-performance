#!/bin/bash

xcodebuild -version | awk 'NR==1{x=$0}END{print x" "$NF}'
echo "$(sw_vers -productName) $(sw_vers -productVersion) $(sw_vers -buildVersion) $(uname -m)"

set -euxo pipefail

cd $(dirname "${BASH_SOURCE[0]}")

xcodebuild -destination generic/platform=iOS -archivePath Fixture.xcarchive -scheme Fixture archive -quiet

xcodebuild -destination generic/platform=iOS -archivePath Fixture.xcarchive -exportArchive -exportPath output -exportOptionsPlist ExportOptions.plist -quiet
