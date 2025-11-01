#!/bin/bash
# Quick Flutter SDK Download and Setup Script

echo "🔧 Quick Flutter SDK Setup for pharmaT"
echo "======================================"

# Create flutter directory
mkdir -p /workspace/flutter_download

# Navigate to flutter directory
cd /workspace/flutter_download

# Download Flutter SDK (attempting with timeout)
echo "📥 Downloading Flutter SDK..."
wget --timeout=30 --tries=2 https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.0-stable.tar.xz -O flutter.tar.xz

# Check if download was successful
if [ $? -eq 0 ] && [ -f flutter.tar.xz ]; then
    echo "✅ Flutter SDK downloaded successfully"
    
    # Extract
    echo "📦 Extracting Flutter SDK..."
    tar -xf flutter.tar.xz
    
    # Move to final location
    mv flutter /workspace/
    
    # Set up PATH
    export PATH="$PATH:/workspace/flutter/bin"
    
    # Test Flutter
    echo "🧪 Testing Flutter installation..."
    /workspace/flutter/bin/flutter --version
    
    if [ $? -eq 0 ]; then
        echo "🎉 Flutter SDK installed successfully!"
        echo "📍 Location: /workspace/flutter/bin"
        echo "🔧 Next steps:"
        echo "  1. cd /workspace/code/flutter_tutoring_app"
        echo "  2. export PATH=\"\$PATH:/workspace/flutter/bin\""
        echo "  3. flutter pub get"
        echo "  4. flutter analyze"
        echo "  5. flutter build apk --debug"
    else
        echo "⚠️  Flutter downloaded but test failed"
    fi
else
    echo "❌ Flutter SDK download failed"
    echo "💡 Manual installation required:"
    echo "  1. Download from: https://flutter.dev/docs/get-started/install/linux"
    echo "  2. Extract to /workspace/flutter"
    echo "  3. Add to PATH: export PATH=\"\$PATH:/workspace/flutter/bin\""
    echo "  4. Run flutter doctor to check setup"
fi

echo "🔍 Current directory contents:"
ls -la /workspace/
