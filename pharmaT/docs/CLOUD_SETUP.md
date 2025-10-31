# 🚀 Cloud Flutter Development Setup Guide

## Quick Start for GitHub Codespaces

1. **Open your repository in Codespaces:**
   - Visit: https://github.com/EnquiryScr/pharmaTutor
   - Click "Code" → "Codespaces" → "Create codespace"

2. **Run Flutter setup (copy each line):**
```bash
# Download Flutter (takes ~2 minutes)
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.3-stable.tar.xz

# Extract Flutter
tar xf flutter_linux_3.22.3-stable.tar.xz

# Add to PATH
export PATH="$PATH:$PWD/flutter/bin"
echo 'export PATH="$PATH:$PWD/flutter/bin"' >> ~/.bashrc

# Configure Flutter
flutter config --no-analytics
flutter config --enable-linux-desktop

# Accept Android licenses
echo "y" | flutter doctor --android-licenses

# Install app dependencies
cd app
flutter pub get

# Run the app
flutter run
```

## Alternative: Replit (No Setup Required)

1. Go to Replit.com
2. Create new Flutter project
3. Import from GitHub: https://github.com/EnquiryScr/pharmaTutor
4. Run directly in browser

## Development Commands

```bash
flutter doctor        # Check installation
flutter clean         # Clean project
flutter pub get       # Install dependencies
flutter run           # Run app
flutter build apk     # Build APK
```

## Cloud Deployment

Once working locally, deploy to:
- **Vercel:** Auto-deploy from GitHub
- **Netlify:** Connect repository
- **Firebase Hosting:** Firebase deploy