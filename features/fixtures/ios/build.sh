#!/bin/bash

xcodebuild -version | awk 'NR==1{x=$0}END{print x" "$NF}'
echo "$(sw_vers -productName) $(sw_vers -productVersion) $(sw_vers -buildVersion) $(uname -m)"

set -euxo pipefail

if [ [ $@ == *"--disableSwizzling"* ] ]; then
    sed -i '' -e 's/DISABLE_SWIZZLING/<key>disableSwizzling</key>\n\t\t\t<true/>/' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist
else
    sed -i '' -e 's/DISABLE_SWIZZLING//' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist
fi

if [ [ $@ == *"--swizzlingPremain"* ] ]; then
    sed -i '' -e 's/SWIZZLING_PREMAIN/<key>disableSwizzling</key>\n\t\t\t<true/>/' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist
else
    sed -i '' -e 's/SWIZZLING_PREMAIN//' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist
fi

cd $(dirname "${BASH_SOURCE[0]}")

xcodebuild -destination generic/platform=iOS -archivePath Fixture.xcarchive -scheme Fixture archive -allowProvisioningUpdates -quiet

xcodebuild -destination generic/platform=iOS -archivePath Fixture.xcarchive -exportArchive -exportPath output -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates -quiet
