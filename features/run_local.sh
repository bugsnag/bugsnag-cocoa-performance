#!/bin/bash

set -euxo pipefail

ideviceinstaller --uninstall com.bugsnag.Fixture

bundle exec maze-runner --os=ios --farm=local --app=features/fixtures/ios/output/Fixture.ipa --apple-team-id=7W9PZ27Y5F --udid=$(idevice_id -l) "$@"
