# 🚀 Cloud Flutter Setup Guide

## Option 1: Quick Manual Installation (Recommended for Codespaces)

Run these commands in your Codespaces terminal:

```bash
# Download Flutter
wget -O flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.3-stable.tar.xz

# Extract Flutter
tar xf flutter.tar.xz

# Add Flutter to PATH
export PATH="$PATH:$PWD/flutter/bin"
echo 'export PATH="$PATH:$PWD/flutter/bin"' >> ~/.bashrc

# Verify installation
flutter --version

# Setup Android (required for mobile development)
flutter doctor --android-licenses

# Install dependencies for your app
cd app
flutter pub get

# Run the app
flutter run
```

## Option 2: Using the Pre-configured DevContainer

1. **Rebuild Codespaces:**
   - Go to your GitHub repo: https://github.com/EnquiryScr/pharmaTutor
   - Click "Code" → "Codespaces" 
   - Click the three dots (...) → "Rebuild Container"

2. **The devcontainer.json file will automatically:**
   - Install Flutter 3.22
   - Set up Android SDK
   - Install VS Code extensions
   - Run `flutter pub get` automatically

## Option 3: Quick Alternative - Replit (No Setup Required)

1. **Go to Replit.com**
2. **Click "Create Repl"**
3. **Choose "Flutter" template**
4. **Import from GitHub:**
   - URL: `https://github.com/EnquiryScr/pharmaTutor`
   - Import the `app` folder only

## ✅ Expected Results

After setup, you should be able to run:

```bash
flutter doctor          # Check Flutter installation
flutter pub get         # Install dependencies  
flutter run            # Run the app
flutter build apk      # Build Android APK
```

## 🔧 Troubleshooting

**If Flutter command not found:**
```bash
source ~/.bashrc
# OR restart terminal
```

**If Android issues:**
```bash
flutter doctor --android-licenses
```

**If dependencies fail:**
```bash
flutter clean
flutter pub get
```

## 📱 Platform Targets

- **Web:** `flutter run -d chrome`
- **Android:** `flutter run -d android` (emulator)
- **Desktop:** `flutter run -d linux` (Linux desktop)

## 🌐 Cloud Deployment Options

Once your app works locally, deploy to:

- **Vercel:** Auto-deploy from GitHub
- **Netlify:** Connect repo for instant deployment  
- **Firebase Hosting:** `firebase deploy`

Choose the option that works best for you!