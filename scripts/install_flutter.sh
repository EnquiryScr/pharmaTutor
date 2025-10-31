#!/bin/bash
# Flutter SDK Installation Script for pharmaT

echo "Installing Flutter SDK..."

# Download Flutter SDK
cd /workspace
wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.0-stable.tar.xz

# Extract Flutter SDK
tar xf flutter_linux_3.19.0-stable.tar.xz

# Add Flutter to PATH
export PATH="$PATH:/workspace/flutter/bin"

# Verify Flutter installation
echo "Flutter version:"
/workspace/flutter/bin/flutter --version

echo "Flutter installation completed!"
echo "PATH: /workspace/flutter/bin"
