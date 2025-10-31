#!/bin/bash

echo "🚀 Setting up Flutter in GitHub Codespaces..."
echo "=========================================="

# Update system packages
echo "📦 Updating system packages..."
sudo apt-get update -y

# Install required dependencies
echo "🔧 Installing required dependencies..."
sudo apt-get install -y \
    wget \
    unzip \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-11-jdk-headless \
    libc6-dev

# Download and install Flutter SDK
echo "⬇️ Downloading Flutter SDK..."
cd /tmp
wget -O flutter_linux_3.22.3-stable.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.3-stable.tar.xz

echo "📁 Extracting Flutter SDK..."
tar xf flutter_linux_3.22.3-stable.tar.xz

echo "🌍 Setting up Flutter path..."
sudo mv flutter /opt/
export PATH="$PATH:/opt/flutter/bin"
echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc

# Configure Flutter
echo "⚙️ Configuring Flutter..."
/opt/flutter/bin/flutter config --no-analytics
/opt/flutter/bin/flutter config --enable-linux-desktop

# Add environment variables for Android development
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/emulator' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/tools' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/tools/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.bashrc

# Install Android SDK command line tools
echo "📱 Installing Android SDK..."
mkdir -p $HOME/Android/Sdk/cmdline-tools
cd $HOME/Android/Sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-11076708_latest.zip
mv cmdline-tools latest
mkdir cmdline-tools
mv latest cmdline-tools/

# Set up Android licenses
echo "📋 Accepting Android licenses..."
yes | /opt/flutter/bin/flutter doctor --android-licenses || true

# Install Android SDK platform
echo "📲 Installing Android SDK platform..."
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "platforms;android-33" "build-tools;33.0.2"

# Verify installation
echo "✅ Verifying Flutter installation..."
source ~/.bashrc
/opt/flutter/bin/flutter doctor --verbose

echo "🎉 Flutter setup complete!"
echo "💡 To use Flutter, either:"
echo "   1. Run: source ~/.bashrc"
echo "   2. Or restart the terminal"
echo ""
echo "🧪 Test with: flutter --version"