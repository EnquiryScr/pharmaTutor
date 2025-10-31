# Google Play Store Deployment Configuration

## Fastlane Configuration for Android

### Fastfile Configuration

```ruby
# mobile/fastlane/Fastfile

default_platform(:android)

platform :android do
  before_all do
    ENV["FASTLANE_HIDE_GITHUB_ISSUES"] = "1"
    setup_circle_ci if ENV['CI']
  end

  desc "Build and release Android app"
  lane :release do
    # Increment version code
    increment_version_code(
      gradle_file_path: "flutter_tutoring_app/android/app/build.gradle"
    )

    # Build APK
    gradle(
      task: "assemble",
      build_type: "Release",
      properties: {
        "android.injected.signing.store.file" => ENV["ANDROID_KEYSTORE_FILE"],
        "android.injected.signing.store.password" => ENV["ANDROID_KEYSTORE_PASSWORD"],
        "android.injected.signing.key.alias" => ENV["ANDROID_KEY_ALIAS"],
        "android.injected.signing.key.password" => ENV["ANDROID_KEY_PASSWORD"],
        "dart.build.mode" => "release",
        "dart.environment" => "production"
      }
    )

    # Upload to Play Store
    upload_to_play_store(
      track: "internal", # internal, alpha, beta, production
      aab: "../flutter_tutoring_app/build/app/outputs/bundle/release/app-release.aab",
      skip_upload_images: false,
      skip_upload_screenshots: false,
      release_status: "draft", # draft, in_progress, completed
      json_key_data: ENV["GOOGLE_PLAY_JSON_KEY"],
      package_name: "com.tutoring.platform.app"
    )

    # Create release notes
    send_slack_notification("Android app version #{get_version_name(
      gradle_file_path: "flutter_tutoring_app/android/app/build.gradle"
    )} has been released to Play Store!")
  end

  desc "Build and release internal testing"
  lane :internal do
    gradle(
      task: "bundle",
      build_type: "Release",
      properties: {
        "android.injected.signing.store.file" => ENV["ANDROID_KEYSTORE_FILE"],
        "android.injected.signing.store.password" => ENV["ANDROID_KEYSTORE_PASSWORD"],
        "android.injected.signing.key.alias" => ENV["ANDROID_KEY_ALIAS"],
        "android.injected.signing.key.password" => ENV["ANDROID_KEY_PASSWORD"]
      }
    )

    upload_to_play_store(
      track: "internal",
      aab: "../flutter_tutoring_app/build/app/outputs/bundle/release/app-release.aab",
      json_key_data: ENV["GOOGLE_PLAY_JSON_KEY"],
      package_name: "com.tutoring.platform.app"
    )
  end

  desc "Deploy to closed testing"
  lane :alpha do
    gradle(task: "bundle", build_type: "Release")

    upload_to_play_store(
      track: "alpha",
      aab: "../flutter_tutoring_app/build/app/outputs/bundle/release/app-release.aab",
      json_key_data: ENV["GOOGLE_PLAY_JSON_KEY"],
      package_name: "com.tutoring.platform.app",
      release_status: "draft"
    )
  end

  desc "Deploy to open testing"
  lane :beta do
    gradle(task: "bundle", build_type: "Release")

    upload_to_play_store(
      track: "beta",
      aab: "../flutter_tutoring_app/build/app/outputs/bundle/release/app-release.aab",
      json_key_data: ENV["GOOGLE_PLAY_JSON_KEY"],
      package_name: "com.tutoring.platform.app"
    )
  end

  desc "Deploy to production"
  lane :production do
    # Verify changelog and release notes
    ensure_play_store_credentials!

    gradle(task: "bundle", build_type: "Release")

    upload_to_play_store(
      track: "production",
      aab: "../flutter_tutoring_app/build/app/outputs/bundle/release/app-release.aab",
      json_key_data: ENV["GOOGLE_PLAY_JSON_KEY"],
      package_name: "com.tutoring.platform.app",
      skip_upload_images: false,
      skip_upload_screenshots: false,
      release_status: "completed"
    )

    # Send production notification
    send_slack_notification("🎉 Android app version #{get_version_name(
      gradle_file_path: "flutter_tutoring_app/android/app/build.gradle"
    )} is now live on Google Play Store!")
  end

  desc "Run tests"
  lane :test do
    gradle(
      task: "test",
      build_type: "Debug"
    )
  end

  desc "Upload screenshots and metadata"
  lane :metadata do
    upload_to_play_store(
      skip_upload_apk: true,
      skip_upload_aab: true,
      json_key_data: ENV["GOOGLE_PLAY_JSON_KEY"],
      package_name: "com.tutoring.platform.app"
    )
  end

  desc "Rollback to previous version"
  lane :rollback do
    upload_to_play_store(
      track: "production",
      json_key_data: ENV["GOOGLE_PLAY_JSON_KEY"],
      package_name: "com.tutoring.platform.app",
      release_status: "draft",
      version_code: ENV["PREVIOUS_VERSION_CODE"].to_i
    )
  end

  private_lane :send_slack_notification do |message|
    slack(
      slack_url: ENV["SLACK_WEBHOOK_URL"],
      message: message,
      channel: "#mobile-deployments",
      username: "Fastlane Bot",
      emoji: ":rocket:"
    ) if ENV["SLACK_WEBHOOK_URL"]
  end

  error do |exception|
    slack(
      slack_url: ENV["SLACK_WEBHOOK_URL"],
      message: "🚨 Android deployment failed: #{exception.message}",
      channel: "#mobile-deployments",
      username: "Fastlane Bot",
      emoji: ":warning:"
    )
  end
end
```

### Appfile Configuration

```ruby
# mobile/fastlane/Appfile

json_key_file(ENV["GOOGLE_PLAY_JSON_KEY"])
package_name("com.tutoring.platform.app")
```

### Metadata Configuration

```ruby
# mobile/fastlane/metadata/android/en-US/title.txt
Tutoring Platform - Learn & Teach

# mobile/fastlane/metadata/android/en-US/full_description.txt
Welcome to Tutoring Platform, the comprehensive mobile app designed to connect students with expert tutors worldwide. Whether you're struggling with homework, preparing for exams, or looking to expand your knowledge, our platform provides personalized tutoring experiences tailored to your needs.

## Key Features:

📚 **Expert Tutors**: Connect with verified, professional tutors across all subjects
📹 **Live Video Sessions**: High-quality video calls with screen sharing and interactive whiteboard
📝 **Assignment Help**: Get assistance with homework, projects, and academic writing
📊 **Progress Tracking**: Monitor your learning journey with detailed analytics
💬 **Messaging**: Communicate with tutors and students through secure messaging
📱 **Cross-Platform**: Seamless experience across all your devices

## Subjects We Cover:
- Mathematics (Algebra, Calculus, Statistics, etc.)
- Science (Physics, Chemistry, Biology)
- Languages (English, Spanish, French, etc.)
- Programming and Computer Science
- Business and Economics
- Test Preparation (SAT, ACT, GRE, etc.)
- And many more!

## For Tutors:
- Flexible scheduling
- Competitive earnings
- Student management tools
- Professional development resources
- Secure payment processing

Download Tutoring Platform today and start your learning journey with expert guidance!

# mobile/fastlane/metadata/android/en-US/short_description.txt
Connect with expert tutors worldwide for personalized learning experiences

# mobile/fastlane/metadata/android/en-US/changelogs.txt
Version 1.0.0:
- Initial release
- Live video tutoring sessions
- Assignment submission and grading
- Secure messaging between tutors and students
- Progress tracking and analytics
- Multiple subject support
- Cross-platform synchronization
```

## App Signing Configuration

### Android Keystore Generation

```bash
#!/bin/bash
# scripts/generate-android-keystore.sh

KEYSTORE_PATH="mobile/fastlane/tutoring-platform.keystore"
KEY_ALIAS="tutoring-platform-key"
KEY_PASSWORD=$(openssl rand -base64 32)
STORE_PASSWORD=$(openssl rand -base64 32)

echo "Generating Android keystore..."

keytool -genkeypair \
  -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$KEY_ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass "$STORE_PASSWORD" \
  -keypass "$KEY_PASSWORD" \
  -dname "CN=Tutoring Platform, OU=Development, O=Tutoring Platform, L=City, S=State, C=US"

echo "Keystore generated successfully!"
echo "KEYSTORE_PATH=$KEYSTORE_PATH" >> .env
echo "KEY_ALIAS=$KEY_ALIAS" >> .env
echo "KEY_PASSWORD=$KEY_PASSWORD" >> .env
echo "STORE_PASSWORD=$STORE_PASSWORD" >> .env
echo "Please securely store these credentials!"
```

### Gradle Configuration

```gradle
// flutter_tutoring_app/android/app/build.gradle

def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()

assert keystorePropertiesFile.exists()
keystoreProperties.load(new FileInputStream(keystorePropertiesFile))

android {
    compileSdkVersion 33
    ndkVersion "25.1.8937393"

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId "com.tutoring.platform.app"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
        
        multiDexEnabled true
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
        debug {
            storeFile file('../fastlane/tutoring-platform.keystore')
            storePassword 'android'
            keyAlias 'androiddebugkey'
            keyPassword 'android'
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            signingConfig signingConfigs.debug
            debuggable true
        }
    }

    flavorDimensions "environment"
    productFlavors {
        production {
            dimension "environment"
            applicationIdSuffix ""
            versionNameSuffix ""
            resValue "string", "app_name", "Tutoring Platform"
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            versionNameSuffix "-staging"
            resValue "string", "app_name", "Tutoring Platform Staging"
        }
        development {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
            resValue "string", "app_name", "Tutoring Platform Dev"
        }
    }
}
```

### ProGuard Rules

```proguard
# flutter_tutoring_app/android/app/proguard-rules.pro

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep model classes
-keep class com.tutoring.platform.models.** { *; }

# Keep Retrofit interfaces
-keep interface com.tutoring.platform.api.** { *; }

# Firebase/Firestore
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Video calling SDK (adjust based on SDK used)
-keep class com.agora.** { *; }

# WebRTC
-keep class org.webrtc.** { *; }

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**

# Flutter WebView
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}
```

## GitHub Actions for Google Play

```yaml
# .github/workflows/android-deploy.yml

name: Android Deploy

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'flutter_tutoring_app/**'
  workflow_dispatch:
    inputs:
      track:
        description: 'Deployment track'
        required: true
        default: 'internal'
        type: choice
        options:
          - internal
          - alpha
          - beta
          - production

env:
  JAVA_VERSION: '17'
  FLUTTER_VERSION: '3.16.0'

jobs:
  deploy-android:
    name: Deploy Android App
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Java
      uses: actions/setup-java@v4
      with:
        distribution: 'zulu'
        java-version: ${{ env.JAVA_VERSION }}
        
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: ${{ env.FLUTTER_VERSION }}
        channel: 'stable'
        
    - name: Get dependencies
      run: |
        cd flutter_tutoring_app
        flutter pub get
        
    - name: Setup Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.0'
        bundler-cache: true
        working-directory: mobile/fastlane
        
    - name: Install Fastlane
      run: |
        cd mobile/fastlane
        bundle install
        
    - name: Decrypt keystore
      run: |
        echo ${{ secrets.ANDROID_KEYSTORE }} | base64 -d > mobile/fastlane/tutoring-platform.keystore
        echo "ANDROID_KEYSTORE_FILE=mobile/fastlane/tutoring-platform.keystore" >> $GITHUB_ENV
        echo "ANDROID_KEY_ALIAS=tutoring-platform-key" >> $GITHUB_ENV
        echo "ANDROID_KEY_PASSWORD=${{ secrets.ANDROID_KEY_PASSWORD }}" >> $GITHUB_ENV
        echo "STORE_PASSWORD=${{ secrets.ANDROID_STORE_PASSWORD }}" >> $GITHUB_ENV
        echo "GOOGLE_PLAY_JSON_KEY=${{ secrets.GOOGLE_PLAY_JSON_KEY }}" >> $GITHUB_ENV
        
    - name: Build and Deploy
      run: |
        cd mobile/fastlane
        case "${{ github.event.inputs.track || 'internal' }}" in
          "internal")
            bundle exec fastlane android internal
            ;;
          "alpha")
            bundle exec fastlane android alpha
            ;;
          "beta")
            bundle exec fastlane android beta
            ;;
          "production")
            bundle exec fastlane android production
            ;;
        esac
      env:
        ANDROID_KEYSTORE_FILE: ${{ env.ANDROID_KEYSTORE_FILE }}
        ANDROID_KEY_ALIAS: ${{ env.ANDROID_KEY_ALIAS }}
        ANDROID_KEY_PASSWORD: ${{ env.ANDROID_KEY_PASSWORD }}
        STORE_PASSWORD: ${{ env.STORE_PASSWORD }}
        GOOGLE_PLAY_JSON_KEY: ${{ env.GOOGLE_PLAY_JSON_KEY }}
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

## Firebase App Distribution

```ruby
# Firebase App Distribution in Fastlane

desc "Deploy to Firebase App Distribution"
lane :firebase do
  # Build AAB
  gradle(task: "bundle", build_type: "Release")
  
  # Upload to Firebase
  firebase_app_distribution(
    app: ENV["FIREBASE_APP_ID_ANDROID"],
    groups: "qa-team,stakeholders",
    release_notes_file: "release-notes.txt",
    android_artifact_type: "AAB"
  )
end
```

## App Bundle Optimization

```gradle
# app/build.gradle (additional optimizations)

android {
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
}
```

This comprehensive Google Play Store configuration enables automated deployment, proper signing, and optimized builds for all deployment tracks.