#!/bin/bash

echo "🚀 Setting up Flutter SDK..."

# Download Flutter (if not exists)
if [ ! -f "flutter_linux_3.22.3-stable.tar.xz" ]; then
    echo "📥 Downloading Flutter SDK..."
    wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.3-stable.tar.xz
fi

# Extract Flutter (if not exists)
if [ ! -d "flutter" ]; then
    echo "📦 Extracting Flutter SDK..."
    tar xf flutter_linux_3.22.3-stable.tar.xz
fi

# Add to PATH
export PATH="$PATH:$PWD/flutter/bin"
echo "PATH=$PATH" > flutter_path.conf

# Configure Flutter
echo "⚙️ Configuring Flutter..."
./flutter/bin/flutter config --no-analytics

echo "✅ Flutter setup complete!"
echo "🔧 To use Flutter in this session, run:"
echo "export PATH=\"\$PATH:$PWD/flutter/bin\""
echo ""
echo "📋 Current directory: $(pwd)"
echo "🔍 Flutter version:"
./flutter/bin/flutter --version