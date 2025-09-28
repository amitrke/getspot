#!/bin/bash
set -euo pipefail

# Recreate GoogleService-Info.plist from the environment variable
echo "Recreating GoogleService-Info.plist from environment variable..."
PLIST_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../Runner/GoogleService-Info.plist"

if [ -z "$GOOGLE_SERVICE_INFO_PLIST_BASE64" ]; then
  echo "Error: GOOGLE_SERVICE_INFO_PLIST_BASE64 environment variable is not set."
  exit 1
fi

echo "$GOOGLE_SERVICE_INFO_PLIST_BASE64" | base64 --decode > "$PLIST_PATH"

if [ -f "$PLIST_PATH" ]; then
  echo "Successfully created GoogleService-Info.plist"
else
  echo "Error: Failed to create GoogleService-Info.plist"
  exit 1
fi
# --- End of GoogleService-Info.plist creation ---

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../pubspec.yaml" ]]; then
	REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
elif [[ -f "$SCRIPT_DIR/../../pubspec.yaml" ]]; then
	REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
else
	echo "Unable to locate Flutter project root" >&2
	exit 1
fi

cd "$REPO_ROOT"

echo "Setting up Flutter environment..."
FLUTTER_ROOT="$HOME/flutter"
if [[ ! -d "$FLUTTER_ROOT" ]]; then
	git clone --depth 1 https://github.com/flutter/flutter.git -b stable "$FLUTTER_ROOT"
fi
export PATH="$FLUTTER_ROOT/bin:$PATH"

flutter doctor -v
flutter pub get
flutter build ios --release --no-codesign

echo "Installing CocoaPods..."
pushd ios >/dev/null
pod install
popd >/dev/null
