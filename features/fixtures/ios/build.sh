#!/bin/bash

set -euxo pipefail

cd $(dirname "${BASH_SOURCE[0]}")

xcodebuild -destination generic/platform=iOS -archivePath Fixture.xcarchive -scheme Fixture archive -quiet

xcodebuild -destination generic/platform=iOS -archivePath Fixture.xcarchive -exportArchive -exportPath output -exportOptionsPlist ExportOptions.plist -quiet
