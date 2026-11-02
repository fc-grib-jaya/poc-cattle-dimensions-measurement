#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift test
xcodebuild -project SapiMeasure.xcodeproj -scheme SapiMeasure -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
