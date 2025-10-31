#!/bin/bash

# Flutter Quick Setup Script for GitHub Codespaces
# Run this script in your GitHub Codespaces terminal

echo "🚀 Setting up Flutter in GitHub Codespaces..."

# Check if we're in the right directory
if [ ! -f "flutter_linux_3.22.3-stable.tar.xz" ]; then
    echo "❌ Flutter SDK not found. Please make sure you're in the app directory."
    exit 1
fi

# Step 1: Extract Flutter (if not already extracted)
if [ ! -d "flutter" ]; then
    echo "📦 Extracting Flutter SDK..."
    tar xf flutter_linux_3.22.3-stable.tar.xz
    echo "✅ Flutter extracted successfully!"
else
    echo "✅ Flutter already extracted!"
fi

# Step 2: Set PATH
echo "🔧 Setting up PATH..."
export PATH="$PATH:$PWD/flutter/bin"
echo 'export PATH="$PATH:$PWD/flutter/bin"' >> ~/.bashrc
echo "✅ PATH configured!"

# Step 3: Verify Flutter installation
echo "🔍 Verifying Flutter installation..."
flutter --version

# Step 4: Configure Flutter
echo "⚙️ Configuring Flutter..."
flutter config --no-analytics

# Step 5: Check dependencies
echo "📋 Checking Flutter doctor..."
flutter doctor

# Step 6: Navigate to app and get dependencies
echo "📦 Getting dependencies..."
flutter pub get

echo ""
echo "🎉 Setup complete!"
echo "📝 Next steps:"
echo "1. Check FLUTTER_SETUP_COMPLETE.md for detailed instructions"
echo "2. Review DEPENDENCIES_TO_ADD.md to update pubspec.yaml"
echo "3. Run 'flutter analyze' to check project status"
echo ""
echo "🔍 Run 'flutter doctor' anytime to check Flutter setup status"