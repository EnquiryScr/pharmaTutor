# PharmaTutor - Pharmacy Education Platform

A comprehensive Flutter-based tutoring platform for pharmacy education, featuring personalized learning, interactive quizzes, and expert guidance.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.22.3 or later
- GitHub Codespaces (recommended for cloud development)
- Supabase account for backend services

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/EnquiryScr/pharmaTutor.git
   cd pharmaTutor
   ```

2. **Set up development environment**
   - **Option A: GitHub Codespaces (Recommended)**
     - Open repository in GitHub Codespaces
     - Flutter SDK is automatically configured
   
   - **Option B: Local Development**
     ```bash
     cd app
     ./setup_flutter_now.sh
     ```

3. **Install dependencies**
   ```bash
   cd app
   flutter pub get
   ```

4. **Configure environment**
   - Copy environment template: `cp .env.example .env`
   - Fill in your Supabase credentials
   - Add Google Maps API key (if using location features)

5. **Run the application**
   ```bash
   flutter run
   ```

## 📱 Features

- **🎓 Personalized Learning**: AI-powered tutoring adapted to student needs
- **📚 Comprehensive Content**: Pharmacy curriculum across all major topics
- **🎯 Interactive Quizzes**: Engage with knowledge through gamified assessments
- **👨‍🏫 Expert Guidance**: Connect with experienced pharmacy professionals
- **📊 Progress Tracking**: Monitor learning progress and achievements
- **🔒 Secure Authentication**: Biometric login and secure data storage
- **☁️ Cloud Sync**: Synchronized learning across all devices

## 🏗️ Architecture

The application follows clean architecture principles with clear separation between:

- **Presentation Layer**: UI components and state management
- **Domain Layer**: Business logic and use cases
- **Data Layer**: Repository patterns and data sources

### Tech Stack

- **Frontend**: Flutter 3.22.3
- **Backend**: Supabase (Database, Auth, Storage, Edge Functions)
- **State Management**: Riverpod/Provider
- **Database**: PostgreSQL (via Supabase)
- **Authentication**: Supabase Auth + Biometric
- **HTTP Client**: Dio with Retrofit

## 📂 Project Structure

```
pharmaTutor/
├── .github/              # CI/CD workflows and templates
├── app/                  # Flutter application
│   ├── lib/             # Source code
│   ├── assets/          # Images, fonts, icons
│   ├── android/         # Android build files
│   ├── ios/             # iOS build files
│   └── pubspec.yaml     # Dependencies
├── backend/             # Node.js backend services
├── deployment/          # Deployment configurations
├── docs/               # Project documentation
├── scripts/            # Build and utility scripts
└── README.md
```

## 🔧 Development

### Prerequisites for Development

- Flutter 3.22.3 or later
- Dart 3.0 or later
- VS Code or Android Studio
- Git

### Running Tests

```bash
cd app
flutter test
```

### Code Analysis

```bash
flutter analyze
```

### Building

**Debug APK:**
```bash
cd app
flutter build apk --debug
```

**Release APK:**
```bash
cd app
flutter build apk --release
```

**iOS App Store:**
```bash
cd app
flutter build ios --release
```

## 🚀 Deployment

Detailed deployment guides available in:
- [Deployment Guide](docs/deployment/) - Cloud and mobile app deployment
- [CI/CD Setup](.github/workflows/) - Automated deployment workflows

## 📚 Documentation

- [Architecture Overview](docs/architecture/)
- [API Documentation](docs/api/)
- [Deployment Guide](docs/deployment/)
- [Development Guidelines](docs/development/)

## 🤝 Contributing

Please read our [Contributing Guide](docs/CONTRIBUTING.md) for development guidelines and code standards.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/EnquiryScr/pharmaTutor/issues)
- **Discussions**: [GitHub Discussions](https://github.com/EnquiryScr/pharmaTutor/discussions)
- **Email**: enquiryscr@gmail.com

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for backend infrastructure
- Pharmacy education community for requirements and feedback

---

**Built with ❤️ by the PharmaTutor Team**