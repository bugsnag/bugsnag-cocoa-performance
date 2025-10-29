#!/bin/bash

xcodebuild -version | awk 'NR==1{x=$0}END{print x" "$NF}'
echo "$(sw_vers -productName) $(sw_vers -productVersion) $(sw_vers -buildVersion) $(uname -m)"

set -euxo pipefail


fixture_name='Fixture'
for ((i=1;i<=$#;i++));
do
    if [ ${!i} = '--fixtureName' ]
    then ((i++))
        fixture_name=${!i};
    fi
done;

cd $(dirname "${BASH_SOURCE[0]}")

xcodebuild -destination generic/platform=iOS -archivePath Fixture.xcarchive -scheme Fixture -project Fixture.xcodeproj archive -allowProvisioningUpdates -quiet

xcodebuild -destination generic/platform=iOS -archivePath Fixture.xcarchive -exportArchive -exportPath output -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates -quiet

mv ./output/Fixture.ipa ./output/$fixture_name.ipa

#rm ./Fixture/Info.plist
