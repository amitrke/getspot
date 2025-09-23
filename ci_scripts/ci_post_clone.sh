#!/bin/bash
set -e

echo "Setting up Flutter environment..."
export FLUTTER_ROOT=/Users/runner/flutter
export PATH=$FLUTTER_ROOT/bin:$PATH

flutter pub get
flutter build ios --release --no-codesign

echo "Installing CocoaPods..."
cd ios
pod install
cd ..
