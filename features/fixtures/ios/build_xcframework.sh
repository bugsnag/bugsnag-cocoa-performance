#!/usr/bin/env bash

xcodebuild -version | awk 'NR==1{x=$0}END{print x" "$NF}'
echo "$(sw_vers -productName) $(sw_vers -productVersion) $(sw_vers -buildVersion) $(uname -m)"

set -euxo pipefail

disable_swizzling_key=''
disable_swizzling_value=''
swizzling_premain_key=''
swizzling_premain_value=''

fixture_name='FixtureXcFramework'
for ((i=1;i<=$#;i++));
do
    if [ ${!i} = '--fixtureName' ]
    then ((i++))
        fixture_name=${!i};
    fi
    if [ ${!i} = '--disableSwizzling' ]
    then
        disable_swizzling_key='<key>disableSwizzling</key>'
        disable_swizzling_value='<true/>\t\t\t\t\t\t\t\t\t\t';
    fi
    if [ ${!i} = '--swizzlingPremain' ]
    then
        swizzling_premain_key='<key>swizzleViewLoadPreMain</key>'
        swizzling_premain_value='<true/>\t\t\t\t\t\t\t\t\t'
    fi
done;

unzip -q BugsnagPerformance.xcframework.zip
unzip -q BugsnagPerformanceSwift.xcframework.zip

cp $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.template.plist $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist

sed -i '' -e 's|DISABLE_SWIZZLING_KEY|'$disable_swizzling_key'|' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist
sed -i '' -e 's|DISABLE_SWIZZLING_VALUE|'$disable_swizzling_value'|' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist
sed -i '' -e 's|SWIZZLING_PREMAIN_KEY|'$swizzling_premain_key'|' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist
sed -i '' -e 's|SWIZZLING_PREMAIN_VALUE|'$swizzling_premain_value'|' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist

sed -i '' -e 's|FIXTURENAME-Swift.h|FixtureXcFramework-Swift.h|' $(dirname "${BASH_SOURCE[0]}")/Fixture/ErrorGenerator.m


cd $(dirname "${BASH_SOURCE[0]}")

echo "--- FixtureXcFramework: xcodebuild archive"

#
# Using CLANG_ENABLE_MODULES=NO to surface build errors
# https://github.com/bugsnag/bugsnag-cocoa/pull/1284
#

xcrun xcodebuild \
  -scheme FixtureXcFramework \
  -project FixtureXcFramework.xcodeproj \
  -destination generic/platform=iOS \
  -configuration Release \
  -archivePath archive/FixtureXcFramework.xcarchive \
  -allowProvisioningUpdates \
  -quiet \
  archive

echo "--- FixtureXcFramework: xcodebuild -exportArchive"

xcrun xcodebuild \
  -exportArchive \
  -archivePath archive/FixtureXcFramework.xcarchive \
  -destination generic/platform=iOS \
  -exportPath output/ \
  -quiet \
  -exportOptionsPlist exportOptions.plist

mv ./output/FixtureXcFramework.ipa ./output/$fixture_name.ipa
