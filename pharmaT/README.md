# pharmaT - Pharmacy Tutoring Platform

A comprehensive mobile tutoring platform designed specifically for pharmacy students preparing for NAPLEX and MPJE examinations.

## 🎯 Project Overview

pharmaT is a Flutter-based mobile application with Node.js backend services, providing personalized learning experiences for pharmacy students through:

- **Live 1-on-1 Video Tutoring** with WebRTC integration
- **Interactive Whiteboard** and screen sharing capabilities
- **Adaptive Quiz System** with auto-grading
- **Progress Analytics** and performance tracking
- **Multi-language Support** (12+ languages)
- **WCAG 2.1 AA Accessibility** compliance

## 📁 Project Structure

```
pharmaT/
├── app/                    # Flutter mobile application
├── backend/                # Node.js backend services
├── docs/                   # Documentation and research
│   ├── analysis/          # Platform analysis reports
│   ├── research/          # Market and UX research
│   ├── deployment/        # Deployment guides
│   └── guides/            # User and technical guides
├── deployment/            # Deployment configurations
└── scripts/               # Build and utility scripts
```

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.19.0+
- Android Studio / Xcode
- Node.js 18+
- Supabase account (for backend services)

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd pharmaT
   ```

2. **Set up Flutter app**
   ```bash
   cd app
   flutter pub get
   flutter run
   ```

3. **Set up backend** (if using separate Node.js server)
   ```bash
   cd backend
   npm install
   npm start
   ```

For detailed setup instructions, see [docs/deployment/DEPLOYMENT-GUIDE.md](docs/deployment/DEPLOYMENT-GUIDE.md)

## 📊 Key Features Status

See [docs/analysis/FEATURES_ANALYSIS.md](docs/analysis/TUTORING_PLATFORM_FEATURES_ANALYSIS.md) for complete feature comparison and implementation status.

## 🔧 Technology Stack

- **Frontend**: Flutter 3.19.0, Provider, MVVM Architecture
- **Backend**: Node.js, Supabase (Database, Auth, Storage)
- **Real-time**: WebRTC, WebSockets
- **State Management**: Provider pattern
- **Testing**: Flutter Test, Integration Tests

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- 🚧 Web (Progressive)

## 🤝 Contributing

Please read our contributing guidelines before submitting pull requests.

## 📄 License

[Add your license here]

## 📞 Contact

[Add contact information]

---

**Built with ❤️ for pharmacy students worldwide**
