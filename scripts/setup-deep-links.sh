#!/bin/bash

# Setup script for Universal Links / App Links
# This script copies the .well-known files to the web build directory

set -e

echo "🔗 Setting up Universal Links / App Links..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if build/web exists
if [ ! -d "build/web" ]; then
    echo -e "${YELLOW}⚠️  build/web directory not found. Running flutter build web...${NC}"
    flutter build web
fi

# Create .well-known directory
echo "📁 Creating .well-known directory..."
mkdir -p build/web/.well-known

# Copy Apple App Site Association
echo "🍎 Copying apple-app-site-association..."
if [ -f "docs/hosting/apple-app-site-association" ]; then
    cp docs/hosting/apple-app-site-association build/web/.well-known/
    echo -e "${GREEN}✓ Copied apple-app-site-association${NC}"
else
    echo -e "${RED}✗ docs/hosting/apple-app-site-association not found!${NC}"
    exit 1
fi

# Copy Android Asset Links
echo "🤖 Copying assetlinks.json..."
if [ -f "docs/hosting/assetlinks.json" ]; then
    cp docs/hosting/assetlinks.json build/web/.well-known/
    echo -e "${GREEN}✓ Copied assetlinks.json${NC}"
else
    echo -e "${RED}✗ docs/hosting/assetlinks.json not found!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Deep link setup complete!${NC}"
echo ""
echo "📋 Next steps:"
echo "   1. Edit build/web/.well-known/apple-app-site-association"
echo "      - Replace TEAM_ID with your Apple Developer Team ID"
echo ""
echo "   2. Edit build/web/.well-known/assetlinks.json"
echo "      - Replace SHA-256 fingerprint with your release key fingerprint"
echo ""
echo "   3. Deploy to Firebase Hosting:"
echo "      firebase deploy --only hosting"
echo ""
echo "   4. Test the links:"
echo "      https://getspot.org/.well-known/apple-app-site-association"
echo "      https://getspot.org/.well-known/assetlinks.json"
echo ""
