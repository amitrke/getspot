#!/bin/bash
set -euo pipefail

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
