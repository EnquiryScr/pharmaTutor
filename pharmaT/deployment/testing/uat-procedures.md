# Firebase App Distribution and User Acceptance Testing (UAT) Procedures

## Firebase App Distribution Configuration

### Fastlane Firebase Integration

```ruby
# mobile/fastlane/Fastfile (Firebase extension)

  desc "Deploy to Firebase App Distribution"
  lane :firebase_internal do
    # Build debug APK for Firebase
    gradle(
      task: "assemble",
      build_type: "Debug",
      properties: {
        "dart.build.mode" => "debug",
        "dart.environment" => "staging"
      }
    )

    # Upload to Firebase
    firebase_app_distribution(
      app: ENV["FIREBASE_APP_ID_ANDROID"],
      groups: "internal-testers",
      release_notes_file: "release-notes.txt",
      android_artifact_type: "APK",
      debug: true
    )

    send_slack_notification("📱 Android app version #{get_version_name(
      gradle_file_path: "flutter_tutoring_app/android/app/build.gradle"
    )} deployed to Firebase for internal testing!")
  end

  desc "Deploy to Firebase App Distribution - QA"
  lane :firebase_qa do
    # Build release APK for QA testing
    gradle(
      task: "assemble",
      build_type: "Release",
      properties: {
        "dart.build.mode" => "release",
        "dart.environment" => "staging"
      }
    )

    # Upload to Firebase
    firebase_app_distribution(
      app: ENV["FIREBASE_APP_ID_ANDROID"],
      groups: "qa-team,stakeholders",
      release_notes_file: "release-notes.txt",
      android_artifact_type: "APK"
    )

    send_slack_notification("🧪 Android app version #{get_version_name(
      gradle_file_path: "flutter_tutoring_app/android/app/build.gradle"
    )} deployed to Firebase for QA testing!")
  end

  desc "Deploy iOS to Firebase App Distribution"
  lane :firebase_ios do
    # Build iOS for Firebase
    build_app(
      workspace: "flutter_tutoring_app/ios/Runner.xcworkspace",
      scheme: "Runner",
      configuration: "Debug",
      export_method: "development",
      clean: true
    )

    # Upload to Firebase
    firebase_app_distribution(
      app: ENV["FIREBASE_APP_ID_IOS"],
      groups: "qa-team,stakeholders",
      release_notes_file: "release-notes.txt",
      ios_artifact_type: "IPA"
    )

    send_slack_notification("🍎 iOS app version #{get_version_number(
      xcodeproj: "flutter_tutoring_app/ios/Runner.xcodeproj",
      target: "Runner"
    )} deployed to Firebase for testing!")
  end

# Firebase Distribution Global Configuration
before_all do
  # Ensure Firebase CLI is installed
  sh "firebase --version" do |result|
    if !result.include?("Firebase CLI")
      UI.error("Firebase CLI not found. Please install it with: npm install -g firebase-tools")
      exit 1
    end
  end
end
```

### Firebase Configuration Files

```json
{
  "projects": {
    "default": "tutoring-platform-staging",
    "production": "tutoring-platform-production"
  },
  "targets": {
    "tutoring-platform-staging": {
      "android": {
        "app": {
          "name": "Tutoring Platform Staging",
          "bundleId": "com.tutoring.platform.app.staging"
        }
      },
      "ios": {
        "app": {
          "name": "Tutoring Platform Staging",
          "bundleId": "com.tutoring.platform.app.staging"
        }
      }
    },
    "tutoring-platform-production": {
      "android": {
        "app": {
          "name": "Tutoring Platform",
          "bundleId": "com.tutoring.platform.app"
        }
      },
      "ios": {
        "app": {
          "name": "Tutoring Platform",
          "bundleId": "com.tutoring.platform.app"
        }
      }
    }
  },
  "emulators": {
    "only": "firestore,auth,functions,hosting"
  }
}
```

### Release Notes Template

```markdown
# Release Notes Template

## Version {{version_name}} ({{build_number}})

### 🆕 New Features
- [Feature 1 description]
- [Feature 2 description]

### 🐛 Bug Fixes
- [Bug fix 1]
- [Bug fix 2]

### 🔧 Improvements
- [Improvement 1]
- [Improvement 2]

### 📝 Known Issues
- [Known issue 1]
- [Known issue 2]

### 🧪 Testing Instructions
1. [Test step 1]
2. [Test step 2]
3. [Test step 3]

### 📞 Feedback
Please report any issues to: qa@tutoring-platform.com

**Installation Instructions:**
- Download the app from Firebase App Distribution
- Install and test on your device
- Provide feedback through the app or email

---
Build Date: {{build_date}}
Branch: {{git_branch}}
Commit: {{git_commit}}
```

### Firebase Distribution Script

```bash
#!/bin/bash
# scripts/deploy-firebase.sh

set -euo pipefail

# Configuration
PROJECT_ID=${1:-tutoring-platform-staging}
PLATFORM=${2:-android}
ENVIRONMENT=${3:-staging}

echo "🚀 Deploying to Firebase App Distribution"
echo "Project: $PROJECT_ID"
echo "Platform: $PLATFORM"
echo "Environment: $ENVIRONMENT"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# Login to Firebase (interactive for first time)
firebase login --no-localhost

# Switch to Firebase project
firebase use "$PROJECT_ID"

# Generate release notes
RELEASE_NOTES_FILE="release-notes-$(date +%Y%m%d-%H%M%S).txt"
cat > "$RELEASE_NOTES_FILE" << EOF
## Version $APP_VERSION ($BUILD_NUMBER)

### 🚀 New Features
- [List new features here]

### 🐛 Bug Fixes
- [List bug fixes here]

### 🔧 Improvements
- [List improvements here]

### 🧪 Testing Focus
- [List areas to focus testing on]

Build Date: $(date)
Branch: ${GIT_BRANCH:-development}
Commit: ${GIT_COMMIT:-HEAD}
EOF

echo "📝 Release notes generated: $RELEASE_NOTES_FILE"

# Deploy based on platform
case $PLATFORM in
    "android")
        # Build Android APK
        cd flutter_tutoring_app
        flutter build apk --release --dart-define=ENV=$ENVIRONMENT
        
        # Deploy to Firebase
        firebase appdistribution:distribute \
          build/app/outputs/flutter-apk/app-release.apk \
          --app $FIREBASE_ANDROID_APP_ID \
          --groups "qa-team,stakeholders" \
          --release-notes-file "../$RELEASE_NOTES_FILE"
        ;;
        
    "ios")
        # Build iOS IPA
        cd flutter_tutoring_app
        flutter build ios --release --dart-define=ENV=$ENVIRONMENT
        
        cd ios
        xcodebuild -workspace Runner.xcworkspace -scheme Runner archive -archivePath Runner.xcarchive
        xcodebuild -exportArchive -archivePath Runner.xcarchive -exportPath . -exportOptionsPlist ExportOptions.plist
        
        # Deploy to Firebase
        firebase appdistribution:distribute \
          Runner.ipa \
          --app $FIREBASE_IOS_APP_ID \
          --groups "qa-team,stakeholders" \
          --release-notes-file "../$RELEASE_NOTES_FILE"
        ;;
        
    *)
        echo "❌ Invalid platform: $PLATFORM"
        echo "Supported platforms: android, ios"
        exit 1
        ;;
esac

echo "✅ Firebase deployment completed!"
echo "📱 Download links have been sent to the specified groups."
```

## User Acceptance Testing (UAT) Procedures

### UAT Environment Setup

```yaml
# docker-compose.uat.yml

version: '3.8'

services:
  # UAT API Backend
  api-uat:
    build:
      context: ../../code/nodejs_backend
      dockerfile: ../../deployment/backend/docker/Dockerfile
      target: production
    container_name: tutoring-api-uat
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=uat
      - PORT=3000
      - DATABASE_URL=postgresql://uat_user:uat_password@postgres-uat:5432/tutoring_uat
      - REDIS_URL=redis://redis-uat:6379
      - JWT_SECRET=uat-jwt-secret-key-for-testing
      - FIREBASE_PROJECT_ID=tutoring-platform-uat
      - STRIPE_SECRET_KEY=sk_test_uat_stripe_key
    volumes:
      - ../../code/nodejs_backend:/app
      - uploads_uat:/app/uploads
      - logs_uat:/app/logs
    depends_on:
      postgres-uat:
        condition: service_healthy
      redis-uat:
        condition: service_healthy
    networks:
      - tutoring-uat
    restart: unless-stopped

  # UAT Database
  postgres-uat:
    image: postgres:15
    container_name: tutoring-postgres-uat
    environment:
      - POSTGRES_DB=tutoring_uat
      - POSTGRES_USER=uat_user
      - POSTGRES_PASSWORD=uat_password
    volumes:
      - postgres_uat_data:/var/lib/postgresql/data
      - ./init-uat-scripts:/docker-entrypoint-initdb.d
    ports:
      - "5433:5432"
    networks:
      - tutoring-uat
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U uat_user -d tutoring_uat"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  # UAT Redis
  redis-uat:
    image: redis:7
    container_name: tutoring-redis-uat
    command: redis-server --appendonly yes --requirepass uat_redis_password
    volumes:
      - redis_uat_data:/data
    ports:
      - "6380:6379"
    networks:
      - tutoring-uat
    restart: unless-stopped

  # UAT Web Interface
  web-uat:
    image: nginx:alpine
    container_name: tutoring-web-uat
    ports:
      - "8080:80"
    volumes:
      - ./uat-nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - api-uat
    networks:
      - tutoring-uat
    restart: unless-stopped

  # Test Data Generator
  test-data-generator:
    build:
      context: .
      dockerfile: Dockerfile.test-data
    container_name: tutoring-test-data
    environment:
      - DATABASE_URL=postgresql://uat_user:uat_password@postgres-uat:5432/tutoring_uat
    depends_on:
      postgres-uat:
        condition: service_healthy
    networks:
      - tutoring-uat
    restart: "no"

volumes:
  postgres_uat_data:
  redis_uat_data:
  uploads_uat:
  logs_uat:

networks:
  tutoring-uat:
    driver: bridge
```

### UAT Test Data Generator

```javascript
// scripts/generate-uat-data.js

const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

class UATDataGenerator {
  constructor() {
    this.pool = new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5433,
      database: process.env.DB_NAME || 'tutoring_uat',
      user: process.env.DB_USER || 'uat_user',
      password: process.env.DB_PASSWORD || 'uat_password',
    });
  }

  async generateTestData() {
    console.log('🧪 Generating UAT test data...');

    await this.createTestUsers();
    await this.createTestSubjects();
    await this.createTestSessions();
    await this.createTestAssignments();
    await this.generateAnalyticsData();

    console.log('✅ UAT test data generated successfully');
  }

  async createTestUsers() {
    console.log('👥 Creating test users...');

    const students = [];
    const tutors = [];

    // Create test students
    for (let i = 1; i <= 20; i++) {
      const studentId = uuidv4();
      const hashedPassword = await bcrypt.hash('testpassword123', 10);

      students.push({
        id: studentId,
        email: `student${i}@uat.tutoring.com`,
        password_hash: hashedPassword,
        first_name: `Student${i}`,
        last_name: 'TestUser',
        user_type: 'student',
        is_active: true,
        email_verified: true,
      });
    }

    // Create test tutors
    for (let i = 1; i <= 10; i++) {
      const tutorId = uuidv4();
      const hashedPassword = await bcrypt.hash('testpassword123', 10);

      tutors.push({
        id: tutorId,
        email: `tutor${i}@uat.tutoring.com`,
        password_hash: hashedPassword,
        first_name: `Tutor${i}`,
        last_name: 'TestUser',
        user_type: 'tutor',
        is_active: true,
        email_verified: true,
        hourly_rate: 25.00 + (i * 5), // $25-75 per hour
        rating: 4.0 + (Math.random() * 1.0), // 4.0-5.0 rating
      });
    }

    // Insert students
    for (const student of students) {
      await this.pool.query(`
        INSERT INTO users (id, email, password_hash, first_name, last_name, user_type, is_active, email_verified)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        ON CONFLICT (email) DO NOTHING
      `, [student.id, student.email, student.password_hash, student.first_name, student.last_name, student.user_type, student.is_active, student.email_verified]);

      // Create profile
      await this.pool.query(`
        INSERT INTO user_profiles (user_id, bio, availability)
        VALUES ($1, $2, $3)
        ON CONFLICT (user_id) DO NOTHING
      `, [student.id, `Test student profile ${student.first_name}`, JSON.stringify({
        monday: ['09:00-17:00'],
        tuesday: ['09:00-17:00'],
        wednesday: ['09:00-17:00'],
        thursday: ['09:00-17:00'],
        friday: ['09:00-17:00'],
      })]);
    }

    // Insert tutors
    for (const tutor of tutors) {
      await this.pool.query(`
        INSERT INTO users (id, email, password_hash, first_name, last_name, user_type, is_active, email_verified)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        ON CONFLICT (email) DO NOTHING
      `, [tutor.id, tutor.email, tutor.password_hash, tutor.first_name, tutor.last_name, tutor.user_type, tutor.is_active, tutor.email_verified]);

      // Create tutor profile
      await this.pool.query(`
        INSERT INTO user_profiles (user_id, bio, education, experience, specializations, hourly_rate, rating, total_sessions)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        ON CONFLICT (user_id) DO NOTHING
      `, [
        tutor.id,
        `Test tutor profile for ${tutor.first_name}`,
        JSON.stringify([{ degree: 'BSc in Mathematics', institution: 'Test University', year: 2020 }]),
        JSON.stringify([{ position: 'Math Tutor', company: 'Test Company', duration: '2 years' }]),
        JSON.stringify(['Mathematics', 'Statistics', 'Algebra']),
        tutor.hourly_rate,
        tutor.rating,
        Math.floor(Math.random() * 100) + 20, // 20-120 sessions
      ]);
    }

    console.log(`✅ Created ${students.length} students and ${tutors.length} tutors`);
  }

  async createTestSubjects() {
    console.log('📚 Creating test subjects...');

    const subjects = [
      { name: 'Mathematics', description: 'Basic to advanced mathematics' },
      { name: 'Physics', description: 'Classical and modern physics' },
      { name: 'Chemistry', description: 'General and organic chemistry' },
      { name: 'Biology', description: 'Cell biology and genetics' },
      { name: 'English', description: 'Literature and composition' },
      { name: 'History', description: 'World history and civilizations' },
      { name: 'Computer Science', description: 'Programming and algorithms' },
      { name: 'Economics', description: 'Micro and macroeconomics' },
    ];

    for (const subject of subjects) {
      await this.pool.query(`
        INSERT INTO subjects (name, description)
        VALUES ($1, $2)
        ON CONFLICT DO NOTHING
      `, [subject.name, subject.description]);
    }

    console.log(`✅ Created ${subjects.length} subjects`);
  }

  async createTestSessions() {
    console.log('🎥 Creating test sessions...');

    // Get user IDs
    const studentsResult = await this.pool.query('SELECT id FROM users WHERE user_type = $1 LIMIT 10', ['student']);
    const tutorsResult = await this.pool.query('SELECT id FROM users WHERE user_type = $1 LIMIT 5', ['tutor']);
    const subjectsResult = await this.pool.query('SELECT id FROM subjects LIMIT 8');

    const students = studentsResult.rows;
    const tutors = tutorsResult.rows;
    const subjects = subjectsResult.rows;

    for (let i = 0; i < 50; i++) {
      const student = students[Math.floor(Math.random() * students.length)];
      const tutor = tutors[Math.floor(Math.random() * tutors.length)];
      const subject = subjects[Math.floor(Math.random() * subjects.length)];

      const scheduledStart = new Date();
      scheduledStart.setDate(scheduledStart.getDate() + Math.floor(Math.random() * 30));
      scheduledStart.setHours(9 + Math.floor(Math.random() * 8), 0, 0, 0);

      const scheduledEnd = new Date(scheduledStart);
      scheduledEnd.setHours(scheduledStart.getHours() + 1);

      const sessionId = uuidv4();

      await this.pool.query(`
        INSERT INTO tutoring_sessions (
          id, student_id, tutor_id, subject_id, title, description,
          scheduled_start, scheduled_end, status, hourly_rate, total_amount
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        ON CONFLICT (id) DO NOTHING
      `, [
        sessionId,
        student.id,
        tutor.id,
        subject.id,
        `Test Session ${i + 1}`,
        'UAT test session description',
        scheduledStart,
        scheduledEnd,
        'scheduled',
        30.00,
        30.00,
      ]);
    }

    console.log('✅ Created 50 test sessions');
  }

  async createTestAssignments() {
    console.log('📝 Creating test assignments...');

    // Get session IDs
    const sessionsResult = await this.pool.query('SELECT id FROM tutoring_sessions LIMIT 20');
    const sessions = sessionsResult.rows;

    for (let i = 0; i < 30; i++) {
      const session = sessions[Math.floor(Math.random() * sessions.length)];
      const assignmentId = uuidv4();

      await this.pool.query(`
        INSERT INTO assignments (
          id, session_id, title, description, assignment_type,
          due_date, status, grade, feedback
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ON CONFLICT (id) DO NOTHING
      `, [
        assignmentId,
        session.id,
        `Test Assignment ${i + 1}`,
        'UAT test assignment for testing purposes',
        'homework',
        new Date(Date.now() + Math.random() * 7 * 24 * 60 * 60 * 1000), // Random date within a week
        'pending',
        null,
        null,
      ]);
    }

    console.log('✅ Created 30 test assignments');
  }

  async generateAnalyticsData() {
    console.log('📊 Generating analytics data...');

    // Generate random analytics events
    const events = [
      'user_login',
      'session_started',
      'session_ended',
      'assignment_submitted',
      'assignment_graded',
      'message_sent',
      'payment_processed',
    ];

    for (let i = 0; i < 1000; i++) {
      const eventId = uuidv4();
      const userResult = await this.pool.query('SELECT id FROM users ORDER BY RANDOM() LIMIT 1');
      const userId = userResult.rows[0]?.id;

      if (userId) {
        await this.pool.query(`
          INSERT INTO analytics_events (id, user_id, event_type, event_data, created_at)
          VALUES ($1, $2, $3, $4, $5)
          ON CONFLICT (id) DO NOTHING
        `, [
          eventId,
          userId,
          events[Math.floor(Math.random() * events.length)],
          JSON.stringify({ test: true, value: Math.random() * 100 }),
          new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000), // Random date within last 30 days
        ]);
      }
    }

    console.log('✅ Generated analytics data');
  }

  async cleanup() {
    await this.pool.end();
  }
}

// Main execution
async function main() {
  const generator = new UATDataGenerator();
  
  try {
    await generator.generateTestData();
  } catch (error) {
    console.error('❌ Error generating UAT data:', error);
    process.exit(1);
  } finally {
    await generator.cleanup();
  }
}

if (require.main === module) {
  main();
}

module.exports = UATDataGenerator;
```

### UAT Test Suite

```javascript
// tests/uat/uat.test.js

const { spawn } = require('child_process');
const { Builder, By, until, Key } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');

class UATTestSuite {
  constructor() {
    this.driver = null;
    this.baseUrl = process.env.UAT_API_URL || 'http://localhost:3000';
  }

  async setup() {
    console.log('🚀 Setting up UAT test environment...');
    
    // Start UAT environment
    await this.startUATEnvironment();
    
    // Initialize WebDriver
    const options = new chrome.Options();
    options.addArguments(['--headless', '--no-sandbox', '--disable-dev-shm-usage']);
    
    this.driver = await new Builder()
      .forBrowser('chrome')
      .setChromeOptions(options)
      .build();
  }

  async startUATEnvironment() {
    return new Promise((resolve, reject) => {
      const dockerCompose = spawn('docker-compose', ['-f', 'docker-compose.uat.yml', 'up', '-d'], {
        cwd: __dirname,
        stdio: 'inherit'
      });

      dockerCompose.on('close', (code) => {
        if (code === 0) {
          console.log('✅ UAT environment started');
          setTimeout(resolve, 5000); // Wait for services to be ready
        } else {
          reject(new Error(`UAT environment failed to start with code ${code}`));
        }
      });
    });
  }

  async runUATTests() {
    console.log('🧪 Running UAT tests...');

    try {
      // Test 1: User Registration
      await this.testUserRegistration();

      // Test 2: User Login
      await this.testUserLogin();

      // Test 3: Tutoring Session Booking
      await this.testSessionBooking();

      // Test 4: Video Call Functionality
      await this.testVideoCall();

      // Test 5: Assignment Submission
      await this.testAssignmentSubmission();

      // Test 6: Payment Processing
      await this.testPaymentProcessing();

      // Test 7: Messaging System
      await this.testMessaging();

      // Test 8: Progress Tracking
      await this.testProgressTracking();

      console.log('✅ All UAT tests completed successfully');

    } catch (error) {
      console.error('❌ UAT tests failed:', error);
      throw error;
    }
  }

  async testUserRegistration() {
    console.log('📝 Testing user registration...');

    await this.driver.get(`${this.baseUrl}/register`);
    
    await this.driver.findElement(By.name('firstName')).sendKeys('Test');
    await this.driver.findElement(By.name('lastName')).sendKeys('User');
    await this.driver.findElement(By.name('email')).sendKeys('testuser@uat.tutoring.com');
    await this.driver.findElement(By.name('password')).sendKeys('TestPassword123!');
    await this.driver.findElement(By.name('userType')).sendKeys('student');
    
    await this.driver.findElement(By.css('button[type="submit"]')).click();
    
    // Wait for success message or redirect
    await this.driver.wait(until.urlContains('dashboard'), 10000);
    
    console.log('✅ User registration test passed');
  }

  async testUserLogin() {
    console.log('🔐 Testing user login...');

    await this.driver.get(`${this.baseUrl}/login`);
    
    await this.driver.findElement(By.name('email')).sendKeys('testuser@uat.tutoring.com');
    await this.driver.findElement(By.name('password')).sendKeys('TestPassword123!');
    
    await this.driver.findElement(By.css('button[type="submit"]')).click();
    
    await this.driver.wait(until.urlContains('dashboard'), 10000);
    
    console.log('✅ User login test passed');
  }

  async testSessionBooking() {
    console.log('📅 Testing session booking...');

    await this.driver.get(`${this.baseUrl}/sessions/book`);
    
    // Select subject
    await this.driver.findElement(By.name('subject')).sendKeys('Mathematics');
    
    // Select tutor
    await this.driver.findElement(By.name('tutor')).sendKeys('Tutor1');
    
    // Select date and time
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    await this.driver.findElement(By.name('date')).sendKeys(tomorrow.toISOString().split('T')[0]);
    
    // Book session
    await this.driver.findElement(By.css('button[type="submit"]')).click();
    
    // Wait for confirmation
    await this.driver.wait(until.elementLocated(By.css('.success-message')), 10000);
    
    console.log('✅ Session booking test passed');
  }

  async testVideoCall() {
    console.log('🎥 Testing video call functionality...');

    await this.driver.get(`${this.baseUrl}/sessions/active`);
    
    // Join video call
    await this.driver.findElement(By.css('.join-call-btn')).click();
    
    // Wait for video call interface
    await this.driver.wait(until.elementLocated(By.css('.video-container')), 10000);
    
    // Check if video elements are present
    const localVideo = await this.driver.findElement(By.css('.local-video'));
    const remoteVideo = await this.driver.findElement(By.css('.remote-video'));
    
    if (localVideo && remoteVideo) {
      console.log('✅ Video call test passed');
    } else {
      throw new Error('Video elements not found');
    }
  }

  async testAssignmentSubmission() {
    console.log('📝 Testing assignment submission...');

    await this.driver.get(`${this.baseUrl}/assignments`);
    
    // Click on an assignment
    await this.driver.findElement(By.css('.assignment-item')).click();
    
    // Upload file (assuming test file exists)
    const fileInput = await this.driver.findElement(By.css('input[type="file"]'));
    await fileInput.sendKeys('/path/to/test/assignment.pdf');
    
    // Submit assignment
    await this.driver.findElement(By.css('.submit-btn')).click();
    
    // Wait for success message
    await this.driver.wait(until.elementLocated(By.css('.success-message')), 10000);
    
    console.log('✅ Assignment submission test passed');
  }

  async testPaymentProcessing() {
    console.log('💳 Testing payment processing...');

    await this.driver.get(`${this.baseUrl}/payments`);
    
    // Enter payment details
    await this.driver.findElement(By.name('cardNumber')).sendKeys('4242424242424242');
    await this.driver.findElement(By.name('expiry')).sendKeys('12/25');
    await this.driver.findElement(By.name('cvc')).sendKeys('123');
    
    // Process payment
    await this.driver.findElement(By.css('.process-payment-btn')).click();
    
    // Wait for success
    await this.driver.wait(until.elementLocated(By.css('.payment-success')), 15000);
    
    console.log('✅ Payment processing test passed');
  }

  async testMessaging() {
    console.log('💬 Testing messaging system...');

    await this.driver.get(`${this.baseUrl}/messages`);
    
    // Send a message
    await this.driver.findElement(By.name('message')).sendKeys('Hello, this is a test message!');
    await this.driver.findElement(By.css('.send-btn')).click();
    
    // Wait for message to appear
    await this.driver.wait(until.elementLocated(By.css('.message-sent')), 10000);
    
    console.log('✅ Messaging test passed');
  }

  async testProgressTracking() {
    console.log('📊 Testing progress tracking...');

    await this.driver.get(`${this.baseUrl}/progress`);
    
    // Check if progress charts are loaded
    await this.driver.wait(until.elementLocated(By.css('.progress-chart')), 10000);
    
    // Check if statistics are displayed
    const statsElements = await this.driver.findElements(By.css('.stat-item'));
    
    if (statsElements.length > 0) {
      console.log('✅ Progress tracking test passed');
    } else {
      throw new Error('Progress statistics not found');
    }
  }

  async teardown() {
    console.log('🧹 Cleaning up...');
    
    if (this.driver) {
      await this.driver.quit();
    }
    
    // Stop UAT environment
    const dockerCompose = spawn('docker-compose', ['-f', 'docker-compose.uat.yml', 'down'], {
      cwd: __dirname,
      stdio: 'inherit'
    });

    return new Promise((resolve) => {
      dockerCompose.on('close', () => {
        console.log('✅ UAT environment cleaned up');
        resolve();
      });
    });
  }
}

// Main execution
async function main() {
  const uat = new UATTestSuite();
  
  try {
    await uat.setup();
    await uat.runUATTests();
    console.log('🎉 UAT completed successfully!');
  } catch (error) {
    console.error('❌ UAT failed:', error);
    process.exit(1);
  } finally {
    await uat.teardown();
  }
}

if (require.main === module) {
  main();
}

module.exports = UATTestSuite;
```

### UAT Report Generator

```javascript
// scripts/generate-uat-report.js

const fs = require('fs').promises;
const path = require('path');

class UATReportGenerator {
  constructor() {
    this.testResults = [];
    this.environment = {};
    this.metrics = {};
  }

  addTestResult(testName, status, duration, details = {}) {
    this.testResults.push({
      testName,
      status, // 'passed', 'failed', 'skipped'
      duration,
      timestamp: new Date().toISOString(),
      details
    });
  }

  addEnvironmentInfo(info) {
    this.environment = { ...this.environment, ...info };
  }

  addMetrics(metrics) {
    this.metrics = { ...this.metrics, ...metrics };
  }

  async generateHTMLReport() {
    const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <title>UAT Test Report</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f5f5f5; padding: 20px; border-radius: 5px; }
        .summary { display: flex; justify-content: space-around; margin: 20px 0; }
        .metric { text-align: center; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
        .test-result { margin: 10px 0; padding: 15px; border-radius: 5px; }
        .passed { background: #d4edda; border: 1px solid #c3e6cb; }
        .failed { background: #f8d7da; border: 1px solid #f5c6cb; }
        .skipped { background: #fff3cd; border: 1px solid #ffeaa7; }
        .timestamp { color: #666; font-size: 0.9em; }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>User Acceptance Test Report</h1>
        <p>Generated: ${new Date().toLocaleString()}</p>
      </div>

      <div class="summary">
        <div class="metric">
          <h3>${this.testResults.filter(t => t.status === 'passed').length}</h3>
          <p>Tests Passed</p>
        </div>
        <div class="metric">
          <h3>${this.testResults.filter(t => t.status === 'failed').length}</h3>
          <p>Tests Failed</p>
        </div>
        <div class="metric">
          <h3>${this.testResults.length}</h3>
          <p>Total Tests</p>
        </div>
      </div>

      <h2>Environment Information</h2>
      <pre>${JSON.stringify(this.environment, null, 2)}</pre>

      <h2>Test Results</h2>
      ${this.testResults.map(test => `
        <div class="test-result ${test.status}">
          <h3>${test.testName}</h3>
          <p><strong>Status:</strong> ${test.status.toUpperCase()}</p>
          <p><strong>Duration:</strong> ${test.duration}ms</p>
          <p class="timestamp">${test.timestamp}</p>
          ${Object.keys(test.details).length > 0 ? `<pre>${JSON.stringify(test.details, null, 2)}</pre>` : ''}
        </div>
      `).join('')}

      <h2>Metrics</h2>
      <pre>${JSON.stringify(this.metrics, null, 2)}</pre>
    </body>
    </html>
    `;

    const reportPath = path.join(__dirname, '..', 'reports', `uat-report-${Date.now()}.html`);
    await fs.mkdir(path.dirname(reportPath), { recursive: true });
    await fs.writeFile(reportPath, html);
    
    return reportPath;
  }

  async generateJSONReport() {
    const report = {
      generatedAt: new Date().toISOString(),
      environment: this.environment,
      metrics: this.metrics,
      testResults: this.testResults,
      summary: {
        total: this.testResults.length,
        passed: this.testResults.filter(t => t.status === 'passed').length,
        failed: this.testResults.filter(t => t.status === 'failed').length,
        skipped: this.testResults.filter(t => t.status === 'skipped').length,
        successRate: (this.testResults.filter(t => t.status === 'passed').length / this.testResults.length * 100).toFixed(2) + '%'
      }
    };

    const reportPath = path.join(__dirname, '..', 'reports', `uat-report-${Date.now()}.json`);
    await fs.mkdir(path.dirname(reportPath), { recursive: true });
    await fs.writeFile(reportPath, JSON.stringify(report, null, 2));
    
    return reportPath;
  }
}

module.exports = UATReportGenerator;
```

### UAT Pipeline Integration

```yaml
# .github/workflows/uat.yml

name: User Acceptance Testing

on:
  schedule:
    - cron: '0 6 * * 1'  # Weekly on Monday at 6 AM
  workflow_dispatch:
    inputs:
      environment:
        description: 'UAT Environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - uat
          - production

jobs:
  run-uat:
    name: Run UAT Tests
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        
    - name: Install dependencies
      run: |
        npm ci
        cd deployment/mobile/fastlane
        bundle install
        
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
        
    - name: Install Python dependencies
      run: |
        pip install selenium webdriver-manager
        
    - name: Setup Chrome
      run: |
        sudo apt-get update
        sudo apt-get install -y google-chrome-stable
        
    - name: Start UAT Environment
      run: |
        cd deployment/testing
        docker-compose -f docker-compose.uat.yml up -d
        sleep 30  # Wait for services to start
        
    - name: Generate Test Data
      run: |
        cd deployment/database
        node scripts/generate-uat-data.js
      env:
        DB_HOST: localhost
        DB_PORT: 5433
        DB_NAME: tutoring_uat
        DB_USER: uat_user
        DB_PASSWORD: uat_password
        
    - name: Run UAT Tests
      run: |
        cd deployment/testing
        node uat.test.js
      env:
        UAT_API_URL: http://localhost:3000
        CHROMEDRIVER_PATH: /usr/bin/chromedriver
        
    - name: Generate UAT Report
      run: |
        cd deployment/testing
        node scripts/generate-uat-report.js
        
    - name: Upload UAT Reports
      uses: actions/upload-artifact@v4
      with:
        name: uat-reports
        path: deployment/testing/reports/
        
    - name: Deploy to Firebase (if UAT passed)
      if: success()
      run: |
        cd deployment/mobile/fastlane
        bundle exec fastlane android firebase_qa
        bundle exec fastlane ios firebase_ios
      env:
        FIREBASE_APP_ID_ANDROID: ${{ secrets.FIREBASE_APP_ID_ANDROID }}
        FIREBASE_APP_ID_IOS: ${{ secrets.FIREBASE_APP_ID_IOS }}
        
    - name: Notify Slack
      if: always()
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        channel: '#uat-results'
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
        
    - name: Cleanup UAT Environment
      if: always()
      run: |
        cd deployment/testing
        docker-compose -f docker-compose.uat.yml down
```

This comprehensive Firebase App Distribution and UAT configuration ensures thorough testing and quality assurance before production releases.