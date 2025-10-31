# pharmäT - Pharmacy Tutoring Platform

<div align="center">

![pharmaT Banner](https://img.shields.io/badge/pharmaT-1.0.0-4B8BBE?style=for-the-badge&logo=flutter&logoColor=white)
[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=flat-square&logo=supabase&logoColor=white)](https://supabase.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

**Advanced Mobile Learning Platform for Pharmacy Education**

[Features](#-features) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Contributing](#-contributing) • [Support](#-support)

</div>

---

## 🎯 Overview

pharmaT is a comprehensive mobile tutoring platform specifically  designed for pharmacy students preparing for **NAPLEX** and **MPJE** examinations. Built with Flutter and powered by Supabase, it delivers personalized learning experiences with offline-first architecture, ensuring uninterrupted access to educational content.

## ✨ Features

### 🏥 Core Learning Features
- **🎥 Live 1-on-1 Video Tutoring** - Real-time WebRTC video sessions with tutors
- **📝 Interactive Whiteboard** - Screen sharing and collaborative drawing tools  
- **🧠 Adaptive Quiz System** - Auto-grading with personalized difficulty adjustment
- **📊 Progress Analytics** - Comprehensive performance tracking and insights
- **🌐 Multi-language Support** - 12+ languages with internationalization
- **♿ Accessibility Compliant** - WCAG 2.1 AA standards for inclusive learning

### 📱 Mobile-First Design
- **📱 Cross-Platform** - Single codebase for iOS, Android, Web, and Desktop
- **🔄 Offline-First Architecture** - Full functionality without internet connection
- **⚡ Cache-First Data Access** - Instant UI updates with background synchronization
- **📲 Progressive Web App** - Web deployment with native-like experience
- **🎨 Responsive Design** - Optimized for all screen sizes and orientations

### 🔧 Technical Excellence
- **🗄️ SQLite Local Cache** - Persistent data storage with intelligent caching
- **☁️ Supabase Backend** - Serverless database with real-time synchronization
- **🔐 Row Level Security** - Enterprise-grade data protection
- **📨 Real-time Messaging** - Instant notifications and chat functionality
- **📁 File Storage** - Secure cloud storage for course materials
- **🧪 Comprehensive Testing** - 90%+ code coverage with unit, widget, and integration tests

## 🚀 Quick Start

### Prerequisites
- **Flutter SDK** 3.22+ ([Install Guide](https://flutter.dev/docs/get-started/install))
- **Dart** 3.4+
- **Android Studio** or **VS Code**
- **Git**

### Installation

```bash
# Clone the repository
git clone https://github.com/EnquiryScr/pharmaT.git
cd pharmaT

# Navigate to Flutter app directory
cd app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build Commands

```bash
# Analyze code quality
flutter analyze

# Run tests
flutter test

# Build for production
flutter build apk --release     # Android
flutter build ios --release     # iOS  
flutter build web --release     # Web
flutter build windows --release # Windows
flutter build linux --release   # Linux
flutter build macos --release   # macOS
```

## 📁 Project Structure

```
pharmaT/
├── app/                    # Flutter mobile application
│   ├── lib/
│   │   ├── core/          # Core utilities and configuration
│   │   ├── data/          # Data layer (models, repositories)
│   │   ├── domain/        # Business logic and entities
│   │   ├── presentation/  # UI layer (pages, widgets, providers)
│   │   └── main.dart      # App entry point
│   ├── test/              # Comprehensive test suite
│   ├── assets/            # Images, fonts, and other assets
│   ├── pubspec.yaml       # Flutter dependencies and metadata
│   └── android/           # Android-specific configurations
├── docs/                  # Comprehensive documentation
│   ├── analysis/          # Technical analysis and reports
│   ├── guides/            # User and developer guides
│   └── research/          # Research documentation
├── deployment/            # Deployment configurations
│   ├── database/          # Database schemas and migrations
│   ├── cicd/             # CI/CD pipelines
│   └── environments/      # Environment configurations
└── backend/               # Legacy Node.js backend (archived)
```

## 🏗️ Architecture

### Clean Architecture Layers

```
┌─────────────────────┐
│   Presentation      │ ← UI, State Management, Navigation
├─────────────────────┤
│      Domain         │ ← Business Logic, Use Cases
├─────────────────────┤
│       Data          │ ← Repositories, Data Sources
├─────────────────────┤
│  Infrastructure     │ ← External APIs, Database, Network
└─────────────────────┘
```

### Data Flow

1. **User Action** → Widget/Page
2. **Provider/ViewModel** → Business Logic
3. **Repository** → Data Abstraction
4. **Data Sources** → SQLite Cache + Supabase
5. **Response** → Back through layers
6. **UI Update** → User Interface

### Offline-First Design

- **Cache-First Reads**: Instant UI updates from SQLite
- **Background Sync**: Non-blocking remote data updates  
- **Offline Queue**: Persistent write operations when offline
- **Auto-Sync**: Automatic queue processing on reconnection
- **Conflict Resolution**: Intelligent merge strategies

## 🧪 Testing

### Test Coverage
- **Unit Tests**: 90%+ coverage on business logic
- **Widget Tests**: Component and UI testing
- **Integration Tests**: End-to-end user workflows
- **Provider Tests**: State management validation
- **Repository Tests**: Data layer verification

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html

# Run specific test file
flutter test test/data/repositories/user_repository_test.dart
```

## 📋 Database Schema

### Core Tables
- **users** - User profiles and authentication
- **courses** - Course catalog and metadata
- **enrollments** - Student-course relationships  
- **sessions** - Tutoring session records
- **messages** - Chat and notification system
- **progress** - Learning progress tracking

### Supabase Features
- **Row Level Security** - Database-level access control
- **Real-time Subscriptions** - Live data updates
- **Edge Functions** - Server-side logic processing
- **Storage Buckets** - File and media storage
- **Authentication** - Multiple auth providers

## 🔧 Configuration

### Environment Setup

```dart
// lib/core/config/supabase_config.dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
  static const bool isDebugMode = false;
}
```

### Development vs Production

| Environment | URL | Features |
|-------------|-----|----------|
| **Development** | Local Supabase | Debug logs, test data |
| **Staging** | Staging Supabase | Production-like testing |
| **Production** | Live Supabase | Optimized, monitored |

## 📖 Documentation

### Complete Documentation Suite

- **[Architecture Guide](docs/guides/architecture.md)** - System design and patterns
- **[API Documentation](docs/guides/api.md)** - Endpoint specifications  
- **[Migration Guide](docs/guides/migration.md)** - Backend transition details
- **[Deployment Guide](docs/guides/deployment.md)** - Production setup
- **[Testing Guide](docs/analysis/PHASE_7_TESTING_GUIDE.md)** - Testing procedures
- **[Flutter Compilation Report](FLUTTER_COMPILATION_REPORT.md)** - Build instructions

### Migration Achievement

**✅ 100% Supabase Migration Complete**

| Phase | Status | Features |
|-------|--------|----------|
| Phase 1 | ✅ Complete | Supabase initialization |
| Phase 2 | ✅ Complete | Database schema (15 tables) |
| Phase 3 | ✅ Complete | Authentication service |
| Phase 4 | ✅ Complete | Remote data sources (6 files) |
| Phase 5 | ✅ Complete | SQLite local cache (7 files) |
| Phase 6 | ✅ Complete | Repository updates (6 files) |
| Phase 7 | ✅ Complete | Testing & validation (11 files) |

**Total Implementation**: 34 files, ~13,897 lines of code

## 🚀 Deployment

### Supported Platforms

| Platform | Status | Target Version |
|----------|--------|----------------|
| **Android** | ✅ Ready | API 21+ (Android 5.0) |
| **iOS** | ✅ Ready | iOS 11.0+ |
| **Web** | ✅ Ready | Progressive Web App |
| **Windows** | ✅ Ready | Windows 10+ |
| **macOS** | ✅ Ready | macOS 10.14+ |
| **Linux** | ✅ Ready | Ubuntu 18.04+ |

### Production Build

```bash
# Clean build
flutter clean && flutter pub get

# Platform-specific builds
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/
flutter build ios --release --obfuscate --split-debug-info=build/debug-info/
flutter build web --release --base-href="/pharmat/"

# Upload to stores
flutter appcenter upload --file build/app/outputs/flutter-apk/app-release.apk
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Workflow

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Code Standards

- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Write comprehensive tests for new features
- Update documentation for API changes
- Ensure all tests pass before submitting PR

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team** - For the amazing cross-platform framework
- **Supabase Team** - For the powerful backend-as-a-service
- **Open Source Community** - For the countless libraries and tools
- **Pharmacy Educators** - For domain expertise and feedback

## 📞 Support

- **📧 Email**: [support@pharmat.app](mailto:support@pharmat.app)
- **📱 Issues**: [GitHub Issues](https://github.com/EnquiryScr/pharmaT/issues)
- **📚 Documentation**: [docs.pharmat.app](https://docs.pharmat.app)
- **💬 Community**: [Discord Server](https://discord.gg/pharmat)

---

<div align="center">

**Made with ❤️ for Pharmacy Students Worldwide**

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](https://choosealicense.com/licenses/mit/)

</div>
