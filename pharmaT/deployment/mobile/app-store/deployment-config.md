# Apple App Store Deployment Configuration

## Fastlane Configuration for iOS

### Fastfile Configuration

```ruby
# mobile/fastlane/Fastfile

default_platform(:ios)

platform :ios do
  before_all do
    ENV["FASTLANE_HIDE_GITHUB_ISSUES"] = "1"
    setup_circle_ci if ENV['CI']
    
    # Verify certificates are available
    match(type: "appstore") unless ENV['FASTLANE_SKIP_CERTIFICATE_VERIFICATION'] == 'true'
  end

  desc "Build and release iOS app"
  lane :release do
    # Increment build number
    increment_build_number(
      build_number: ENV['CIRCLE_BUILD_NUM'] || Time.now.to_i.to_s
    )

    # Update provisioning profile settings
    update_project_provisioning(
      profile: ENV['sigh_com.tutoring.platform.app_appstore_profile-path'],
      target_filter: "Runner",
      build_configuration: "Release"
    )

    # Update project to use latest code signing
    update_project_team(
      team_id: ENV['sigh_com.tutoring.platform.app_appstore_team-id'],
      targets: ["Runner"]
    )

    # Build iOS app
    build_app(
      workspace: "flutter_tutoring_app/ios/Runner.xcworkspace",
      scheme: "Runner",
      configuration: "Release",
      export_method: "app-store",
      export_options: {
        method: "app-store",
        provisioningProfiles: {
          "com.tutoring.platform.app" => ENV['sigh_com.tutoring.platform.app_appstore_profile-name']
        }
      },
      clean: true
    )

    # Upload to App Store
    upload_to_app_store(
      ipa: "flutter_tutoring_app/build/ios/iphoneos/ios/Archive/Release-iphoneos.ipa",
      skip_screenshots: false,
      skip_metadata: false,
      submit_for_review: false,
      automatic_release: false,
      force: true,
      precheck_include_in_app_purchases: false,
      app_version: get_version_number(
        xcodeproj: "flutter_tutoring_app/ios/Runner.xcodeproj",
        target: "Runner"
      )
    )

    # Create changelog
    changelog = File.read("../changelog.txt") rescue "iOS app updated"
    
    # Send Slack notification
    send_slack_notification("🍎 iOS app version #{get_version_number(
      xcodeproj: "flutter_tutoring_app/ios/Runner.xcodeproj",
      target: "Runner"
    )} has been submitted to App Store!")
  end

  desc "Deploy to TestFlight (internal testing)"
  lane :beta do
    # Build for TestFlight
    build_app(
      workspace: "flutter_tutoring_app/ios/Runner.xcworkspace",
      scheme: "Runner",
      configuration: "Release",
      export_method: "app-store",
      export_options: {
        method: "app-store",
        provisioningProfiles: {
          "com.tutoring.platform.app" => ENV['sigh_com.tutoring.platform.app_appstore_profile-name']
        }
      },
      clean: true
    )

    # Upload to TestFlight
    upload_to_testflight(
      ipa: "flutter_tutoring_app/build/ios/iphoneos/ios/Archive/Release-iphoneos.ipa",
      skip_waiting_for_build_processing: false,
      app_version: get_version_number(
        xcodeproj: "flutter_tutoring_app/ios/Runner.xcodeproj",
        target: "Runner"
      )
    )

    send_slack_notification("🧪 iOS app version #{get_version_number(
      xcodeproj: "flutter_tutoring_app/ios/Runner.xcodeproj",
      target: "Runner"
    )} uploaded to TestFlight for beta testing!")
  end

  desc "Deploy to App Store Connect"
  lane :appstore do
    # Increment build number for App Store
    increment_build_number(
      build_number: ENV['CIRCLE_BUILD_NUM'] || Time.now.to_i.to_s
    )

    # Build the app
    build_app(
      workspace: "flutter_tutoring_app/ios/Runner.xcworkspace",
      scheme: "Runner",
      configuration: "Release",
      export_method: "app-store",
      clean: true
    )

    # Upload to App Store
    upload_to_app_store(
      ipa: "flutter_tutoring_app/build/ios/iphoneos/ios/Archive/Release-iphoneos.ipa",
      skip_screenshots: true,
      skip_metadata: false,
      submit_for_review: false,
      automatic_release: false
    )
  end

  desc "Deploy to production"
  lane :production do
    # Ensure we're on production branch
    ensure_git_branch(branch: "main") unless ENV['FASTLANE_SKIP_GIT_BRANCH_CHECK'] == 'true'
    
    # Verify changelog is updated
    ensure_changelog_updated! unless ENV['FASTLANE_SKIP_CHANGELOG_CHECK'] == 'true'

    # Build and upload
    build_app(
      workspace: "flutter_tutoring_app/ios/Runner.xcworkspace",
      scheme: "Runner",
      configuration: "Release",
      export_method: "app-store",
      clean: true
    )

    # Upload to App Store with production settings
    upload_to_app_store(
      ipa: "flutter_tutoring_app/build/ios/iphoneos/ios/Archive/Release-iphoneos.ipa",
      skip_screenshots: false,
      skip_metadata: false,
      submit_for_review: true,
      automatic_release: true,
      precheck_include_in_app_purchases: false
    )

    send_slack_notification("🎉 iOS app version #{get_version_number(
      xcodeproj: "flutter_tutoring_app/ios/Runner.xcodeproj",
      target: "Runner"
    )} is now live on App Store!")
  end

  desc "Generate screenshots"
  lane :screenshots do
    # Clean previous screenshots
    capture_screenshots(
      scheme: "RunnerUITests",
      devices: [
        "iPhone 14 Pro Max",
        "iPhone 14",
        "iPhone SE (3rd generation)",
        "iPad Pro (12.9-inch) (6th generation)"
      ],
      languages: ["en-US", "en-GB", "es-ES", "fr-FR"],
      clear_previous_screenshots: true,
      app_identifier: "com.tutoring.platform.app"
    )

    # Upload screenshots
    upload_to_app_store(
      skip_binary_upload: true,
      skip_metadata: true
    )
  end

  desc "Update app metadata"
  lane :metadata do
    upload_to_app_store(
      app_identifier: "com.tutoring.platform.app",
      skip_binary_upload: true,
      skip_screenshots: true,
      metadata_path: "metadata"
    )
  end

  desc "Precheck app before submission"
  lane :precheck do
    precheck(
      app_identifier: "com.tutoring.platform.app",
      include_in_app_purchases: false,
      online_capabilities: true,
      apple_connect: ENV['APPLE_CONNECT_USERNAME']
    )
  end

  desc "Rollback to previous version"
  lane :rollback do
    # Get previous version info
    version = get_version_number(
      xcodeproj: "flutter_tutoring_app/ios/Runner.xcodeproj",
      target: "Runner"
    )
    
    # This would require implementing custom rollback logic
    # as App Store Connect doesn't have a direct rollback API
    UI.message("Rollback for iOS requires manual intervention in App Store Connect")
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
      message: "🚨 iOS deployment failed: #{exception.message}",
      channel: "#mobile-deployments",
      username: "Fastlane Bot",
      emoji: ":warning:"
    )
  end
end
```

### Match Configuration

```ruby
# mobile/fastlane/Matchfile

git_url(ENV["GIT_REPO_URL"])
storage_mode("git")

type("appstore")
app_identifier(["com.tutoring.platform.app"])
username(ENV["APPLE_ID"])
team_id(ENV["APPLE_TEAM_ID"])
# For automated CI environments:
force_for_new_devices(ENV['MATCH_FORCE_NEW_DEVICES'] == 'true')
```

### Appfile Configuration

```ruby
# mobile/fastlane/Appfile

apple_id(ENV["APPLE_ID"])
itc_team_id(ENV["APPLE_CONNECT_TEAM_ID"])
team_id(ENV["APPLE_TEAM_ID"])
```

### Signing Configuration

```bash
# scripts/setup-ios-signing.sh

#!/bin/bash

# Install fastlane and dependencies
cd mobile/fastlane
bundle install

# Initialize match if not already done
if [ ! -f "../Matchfile" ]; then
  match init
fi

# Set up certificates and provisioning profiles
match appstore --app_identifier com.tutoring.platform.app

# Download existing certificates
match download --app_identifier com.tutoring.platform.app

echo "iOS signing setup completed!"
echo "Certificates and provisioning profiles are ready for use."
```

## App Store Metadata Configuration

### App Information

```ruby
# mobile/fastlane/metadata/en-US/name.txt
Tutoring Platform

# mobile/fastlane/metadata/en-US/subtitle.txt
Learn & Teach with Expert Tutors

# mobile/fastlane/metadata/en-US/description.txt
Welcome to Tutoring Platform, the premier mobile app connecting students with expert tutors worldwide. Whether you're struggling with homework, preparing for exams, or seeking to expand your knowledge, our platform provides personalized tutoring experiences tailored to your needs.

🎯 **Key Features:**
• Live 1-on-1 video tutoring sessions
• Expert tutors across all subjects
• Assignment submission and grading
• Secure messaging and collaboration
• Progress tracking and analytics
• Cross-platform synchronization
• Multiple language support

📚 **Subjects We Cover:**
Mathematics (Algebra, Calculus, Statistics)
Science (Physics, Chemistry, Biology)
Languages (English, Spanish, French, etc.)
Programming and Computer Science
Business and Economics
Test Preparation (SAT, ACT, GRE, etc.)

👨‍🏫 **For Tutors:**
• Flexible scheduling and earning opportunities
• Professional tutor profile and ratings
• Advanced tutoring tools and resources
• Secure payment processing
• Student management dashboard
• Continuing education resources

Download Tutoring Platform today and start your personalized learning journey!

# mobile/fastlane/metadata/en-US/keywords.txt
tutoring,education,learning,homework,exam prep,student,tutor,study,teaching,online learning,academic help,homework help,test prep,school,university

# mobile/fastlane/metadata/en-US/review_information.txt
First Name: Support
LastName: Team
Phone Number: +1-555-123-4567
Email Address: support@tutoring-platform.com
Demo User: testuser@tutoring-platform.com
Demo Password: DemoPassword123!
Notes: Please use the test account credentials to explore all features of the app. The app requires internet connection for full functionality.

# mobile/fastlane/metadata/en-US/promotional_text.txt
Connect with expert tutors worldwide for personalized learning experiences. Start your free trial today!

# mobile/fastlane/metadata/en-US/release_notes.txt
Version 1.0.0:
✨ Initial release of Tutoring Platform
🎥 Live video tutoring sessions with screen sharing
📝 Assignment submission and grading system
💬 Secure messaging between tutors and students
📊 Progress tracking and learning analytics
🌍 Support for multiple subjects and languages
🔒 Enhanced security and privacy features
📱 Optimized for all iOS devices
```

## iOS Project Configuration

### Info.plist Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>Tutoring Platform</string>
    <key>CFBundleIdentifier</key>
    <string>com.tutoring.platform.app</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
        <string>arm64</string>
    </array>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>tutoring-platform.com</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <false/>
                <key>NSExceptionMinimumTLSVersion</key>
                <string>TLSv1.2</string>
            </dict>
        </dict>
    </dict>
    <key>NSCameraUsageDescription</key>
    <string>This app requires access to camera for video tutoring sessions.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>This app requires access to microphone for video tutoring sessions.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app requires access to photo library for sharing photos and documents.</string>
    <key>NSFaceIDUsageDescription</key>
    <string>This app uses Face ID for secure authentication.</string>
</dict>
</plist>
```

### Xcode Project Configuration

```bash
#!/bin/bash
# scripts/update-xcode-project.sh

# Update build settings for App Store deployment

# Set development team
defaults write com.apple.dt.Xcode IDEDownloadedPropertyListsDownloaded -dict-add com.apple.dt.Xcode.DVTAppleIDDownloadedPropertyList.$(date +%s) "$(cat <<'EOF'
{
    "$(CODESIGNING_FOLDER_PATH)" = {
        DevelopmentTeam = "$(APPLE_TEAM_ID)";
        DevelopmentTeamName = "Your Organization Name";
        ProvisioningStyle = "Manual";
    };
}
EOF
)"

# Update Info.plist with bundle identifier
/usr/libexec/PlistBuddy -c "Set CFBundleIdentifier com.tutoring.platform.app" flutter_tutoring_app/ios/Runner/Info.plist

# Set version and build number
/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString 1.0.0" flutter_tutoring_app/ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set CFBundleVersion 1" flutter_tutoring_app/ios/Runner/Info.plist

echo "Xcode project configuration updated"
```

## GitHub Actions for App Store

```yaml
# .github/workflows/ios-deploy.yml

name: iOS Deploy

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
        default: 'beta'
        type: choice
        options:
          - beta
          - appstore
          - production

env:
  FLUTTER_VERSION: '3.16.0'

jobs:
  deploy-ios:
    name: Deploy iOS App
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
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
        
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
        
    - name: Setup signing certificates
      env:
        IOS_P12_PASSWORD: ${{ secrets.IOS_P12_PASSWORD }}
        MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
        SIGNING_MATCH_GIT_URL: ${{ secrets.SIGNING_MATCH_GIT_URL }}
        SIGNING_ASC_ISSUER: ${{ secrets.SIGNING_ASC_ISSUER }}
      run: |
        # Create Fastlane Matchfile
        cat > mobile/fastlane/Matchfile << EOF
git_url("${{ secrets.SIGNING_MATCH_GIT_URL }}")
storage_mode("git")
type("appstore")
app_identifier(["com.tutoring.platform.app"])
username("${{ secrets.APPLE_ID }}")
team_id("${{ secrets.APPLE_TEAM_ID }}")
EOF
        
        # Setup match
        cd mobile/fastlane
        bundle exec match appstore \
          --app_identifier com.tutoring.platform.app \
          --username "${{ secrets.APPLE_ID }}" \
          --team_id "${{ secrets.APPLE_TEAM_ID }}"
          
    - name: Install Apple Certificate
      env:
        CERTIFICATE_P12: ${{ secrets.IOS_CERTIFICATE_P12 }}
        CERTIFICATE_PASSWORD: ${{ secrets.IOS_CERTIFICATE_PASSWORD }}
        KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
      run: |
        # Create and unlock keychain
        security create-keychain -p "${{ secrets.KEYCHAIN_PASSWORD }}" build.keychain
        security set-keychain-settings -lut 21600 build.keychain
        security unlock-keychain -p "${{ secrets.KEYCHAIN_PASSWORD }}" build.keychain
        
        # Import certificate
        echo -n "${{ secrets.IOS_CERTIFICATE_P12 }}" | base64 --decode --output certificate.p12
        security import certificate.p12 -k build.keychain -P "${{ secrets.IOS_CERTIFICATE_PASSWORD }}" -A -T /usr/bin/codesign
        security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${{ secrets.KEYCHAIN_PASSWORD }}" build.keychain
        
    - name: Build and Deploy
      run: |
        cd mobile/fastlane
        case "${{ github.event.inputs.track || 'beta' }}" in
          "beta")
            bundle exec fastlane ios beta
            ;;
          "appstore")
            bundle exec fastlane ios appstore
            ;;
          "production")
            bundle exec fastlane ios production
            ;;
        esac
      env:
        APPLE_ID: ${{ secrets.APPLE_ID }}
        APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
        APPLE_CONNECT_TEAM_ID: ${{ secrets.APPLE_CONNECT_TEAM_ID }}
        APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
        APP_STORE_CONNECT_ISSUER_ID: ${{ secrets.APPLE_CONNECT_ISSUER_ID }}
        APP_STORE_CONNECT_PRIVATE_KEY: ${{ secrets.APP_STORE_CONNECT_PRIVATE_KEY }}
        MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
        FASTLANE_PASSWORD: ${{ secrets.FASTLANE_PASSWORD }}
```

## App Store Connect API Configuration

```ruby
# Connect API integration
lane :appstore_connect_info do
  # Get app information from App Store Connect
  app_info = app_store_connect_api.get_app(
    app_id: ENV['APP_STORE_CONNECT_APP_ID']
  )
  
  puts "App ID: #{app_info['id']}"
  puts "Bundle ID: #{app_info['attributes']['bundleId']}"
  puts "Name: #{app_info['attributes']['name']}"
  
  # Get latest version
  versions = app_store_connect_api.get_app_versions(
    app_id: app_info['id']
  )
  
  latest_version = versions['data'][0]
  puts "Latest version: #{latest_version['attributes']['versionString']}"
end
```

## Automated Testing Integration

```ruby
# Testing lane for CI/CD
lane :test do
  # Run unit tests
  run_tests(
    scheme: "Runner",
    configuration: "Debug",
    devices: ["iPhone 14 Pro"]
  )
  
  # Run UI tests
  run_tests(
    scheme: "RunnerUITests",
    configuration: "Debug",
    devices: ["iPhone 14 Pro"],
    only_testing: ["RunnerUITests"]
  )
  
  # Generate coverage report
  xcov(
    workspace: "flutter_tutoring_app/ios/Runner.xcworkspace",
    scheme: "Runner",
    output_directory: "coverage"
  )
end
```

This comprehensive iOS App Store deployment configuration ensures automated, secure, and efficient deployment of the mobile app to Apple's ecosystem.