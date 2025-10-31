#!/bin/bash

# pharmaT Build Script
# Run this script in your Flutter development environment

set -e

echo "🏗️ Starting pharmaT Build Process..."
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check Flutter installation
echo -e "${BLUE}🔍 Checking Flutter installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    echo "Please install Flutter SDK from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -n 1)
echo -e "${GREEN}✅ Flutter found: $FLUTTER_VERSION${NC}"

# Navigate to project directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ pubspec.yaml not found. Please run this script from the app/ directory${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Installing dependencies...${NC}"
flutter pub get

echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
flutter clean

echo -e "${BLUE}📦 Getting dependencies again...${NC}"
flutter pub get

echo -e "${BLUE}🔍 Analyzing code...${NC}"
flutter analyze

echo -e "${BLUE}🧪 Running tests...${NC}"
flutter test

echo -e "${BLUE}📋 Running doctor check...${NC}"
flutter doctor -v

echo ""
echo -e "${GREEN}✅ Build preparation completed!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "${BLUE}1. Run 'flutter run' to start development server${NC}"
echo -e "${BLUE}2. Connect a device or start an emulator${NC}"
echo -e "${BLUE}3. For production builds:${NC}"
echo -e "${BLUE}   - Android: flutter build apk --release${NC}"
echo -e "${BLUE}   - iOS: flutter build ios --release${NC}"
echo ""
echo -e "${GREEN}🎉 Happy coding with pharmaT!${NC}"
