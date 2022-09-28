#!/bin/bash

set -euxo pipefail

cd $(dirname "${BASH_SOURCE[0]}")

xcodebuild -destination generic/platform=iOS -scheme Example
