#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodegen >/dev/null 2>&1; then
  echo 'XcodeGen is required. Install it on your Mac (for example: brew install xcodegen), then retry.' >&2
  exit 1
fi
if [[ ! -f FieldBriefAI/Configuration/GoogleService-Info.plist ]]; then
  echo 'NOTE: Firebase config is missing. On-device generation can run if Apple Intelligence is available.'
  echo 'For Gemini cloud fallback, add GoogleService-Info.plist privately and rerun this script.'
fi
xcodegen generate
open FieldBriefAI.xcodeproj
echo 'Opened FieldBriefAI.xcodeproj. Configure signing, App Check, and test.'
