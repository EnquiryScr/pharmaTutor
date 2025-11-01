#!/bin/bash

echo "🚀 Quick Flutter Setup for Codespaces"
echo "=================================="

# Download Flutter
echo "⬇️ Downloading Flutter..."
wget -q -O flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.3-stable.tar.xz

# Extract Flutter
echo "📦 Extracting Flutter..."
tar xf flutter.tar.xz

# Add to PATH
echo "🔧 Setting up PATH..."
export PATH="$PATH:$PWD/flutter/bin"
echo "export PATH=\"\$PATH:\$PWD/flutter/bin\"" >> ~/.bashrc

# Quick setup
echo "⚙️ Configuring Flutter..."
flutter config --no-analytics
flutter config --enable-linux-desktop

# Test installation
echo "✅ Testing installation..."
flutter --version

# Accept Android licenses (if prompted)
echo "📋 Setting up Android..."
echo "y" | flutter doctor --android-licenses 2>/dev/null || true

# Navigate to app and get dependencies
echo "📱 Setting up app dependencies..."
cd app
flutter pub get

echo ""
echo "🎉 Setup complete!"
echo "💡 If flutter command not found, run: source ~/.bashrc"
echo ""
echo "🧪 Test your app:"
echo "   flutter run"
echo "   flutter build apk"