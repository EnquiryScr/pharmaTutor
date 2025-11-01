# Flutter Setup Commands for GitHub Codespaces

## Step 1: Download and Extract Flutter
```bash
# Download Flutter (this may take 1-2 minutes)
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.3-stable.tar.xz

# Extract Flutter
tar xf flutter_linux_3.22.3-stable.tar.xz
```

## Step 2: Set PATH
```bash
# Add Flutter to PATH for current session
export PATH="$PATH:$PWD/flutter/bin"

# Make it permanent
echo 'export PATH="$PATH:$PWD/flutter/bin"' >> ~/.bashrc

# Reload the environment
source ~/.bashrc
```

## Step 3: Configure Flutter
```bash
# Disable analytics
flutter config --no-analytics

# Verify installation
flutter --version
```

## Step 4: Navigate to App Directory
```bash
cd app
```

## Step 5: Update Dependencies
```bash
# Open pubspec.yaml and add the missing dependencies from DEPENDENCIES_TO_ADD.md
# Then run:
flutter pub get
```

## Step 6: Analyze the Project
```bash
flutter analyze
```

---

## If Download Times Out (Alternative):
Try downloading in parts or use a mirror:
```bash
curl -L -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.3-stable.tar.xz
```

## Check Flutter Status:
```bash
flutter doctor
```