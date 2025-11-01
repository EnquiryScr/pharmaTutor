# pharmaT Project Structure

This document describes the organization of the pharmaT pharmacy tutoring platform repository.

## 📁 Directory Structure

```
pharmaT/
├── README.md                      # Main project documentation
├── STRUCTURE.md                   # This file - project organization guide
├── .gitignore                     # Git ignore rules
│
├── app/                           # Flutter Mobile Application
│   ├── android/                   # Android platform code
│   ├── ios/                       # iOS platform code
│   ├── assets/                    # App assets (images, fonts, icons)
│   │   ├── fonts/                 # Custom fonts
│   │   ├── icons/                 # App icons
│   │   └── images/                # Image assets
│   ├── lib/                       # Flutter source code
│   │   ├── main.dart             # App entry point
│   │   ├── core/                  # Core utilities and configurations
│   │   ├── data/                  # Data layer (services, repositories)
│   │   ├── domain/                # Domain layer (models, use cases)
│   │   └── presentation/          # UI layer (screens, widgets)
│   ├── pubspec.yaml              # Flutter dependencies
│   └── README.md                 # App-specific documentation
│
├── backend/                       # Backend Services
│   └── nodejs_backend/           # Node.js API server
│       ├── src/                  # Source code
│       ├── logs/                 # Application logs
│       ├── uploads/              # File uploads
│       ├── package.json          # Node dependencies
│       └── README.md             # Backend documentation
│
├── docs/                          # Documentation Hub
│   ├── analysis/                 # Analysis & Status Reports
│   │   ├── TUTORING_PLATFORM_FEATURES_ANALYSIS.md
│   │   ├── RECOMMENDATION_ENGINE_DESIGN.md
│   │   ├── COMPREHENSIVE_ANALYSIS_AND_ROADMAP.md
│   │   ├── COMPILATION_REPORT.md
│   │   ├── FINAL_COMPILATION_STATUS.md
│   │   ├── FLUTTER_COMPILATION_VERIFICATION_RESULTS.md
│   │   ├── PROJECT_IMPLEMENTATION_SUMMARY.md
│   │   └── 3010compile.md
│   │
│   ├── deployment/               # Deployment Guides
│   │   ├── PHARMACY_TUTORING_PLATFORM_DEPLOYMENT_GUIDE.md
│   │   ├── QUICK_DEPLOYMENT_CHECKLIST.md
│   │   └── SECURITY_IMPLEMENTATION_README.md
│   │
│   ├── guides/                   # User & Technical Guides
│   │   ├── comprehensive_pharmacy_tutoring_platform_guide.md
│   │   ├── comprehensive_pharmacy_tutoring_platform_guide.pdf
│   │   ├── comprehensive_pharmacy_tutoring_platform_guide.docx
│   │   ├── phd_pharmacology_tutor_global_platform_roadmap.md
│   │   ├── phd_pharmacology_tutor_global_platform_roadmap.pdf
│   │   └── phd_pharmacology_tutor_global_platform_roadmap.docx
│   │
│   └── research/                 # Market & UX Research
│       ├── platform_analysis/    # Competitor platform analysis
│       ├── ux_research/          # User experience research
│       ├── pharmacy_research/    # Pharmacy education research
│       ├── global_market/        # Global market analysis
│       ├── monetization/         # Monetization strategies
│       ├── technical_analysis/   # Technical requirements
│       ├── platform_architecture/# Architecture research
│       ├── student_experience/   # Student experience research
│       ├── solo_practice_research/# Solo practice insights
│       └── expert_positioning/   # Expert positioning research
│
├── deployment/                    # Deployment Configurations
│   ├── backend/                  # Backend deployment configs
│   │   ├── docker/              # Docker configurations
│   │   ├── kubernetes/          # K8s manifests
│   │   └── cloud-deployment/    # Cloud-specific configs
│   ├── mobile/                   # Mobile app deployment
│   │   ├── google-play/         # Google Play configs
│   │   ├── app-store/           # Apple App Store configs
│   │   └── firebase-distribution/# Firebase App Distribution
│   ├── database/                 # Database migrations & seeds
│   ├── cicd/                     # CI/CD pipelines
│   │   ├── github-actions/      # GitHub Actions workflows
│   │   └── gitlab-ci/           # GitLab CI configurations
│   ├── monitoring/               # Monitoring & observability
│   │   ├── prometheus/          # Prometheus configs
│   │   ├── grafana/             # Grafana dashboards
│   │   ├── elk/                 # ELK stack configs
│   │   ├── cloudwatch/          # AWS CloudWatch
│   │   └── crashlytics/         # Firebase Crashlytics
│   ├── environments/             # Environment-specific configs
│   │   ├── dev/                 # Development
│   │   ├── staging/             # Staging
│   │   └── production/          # Production
│   ├── testing/                  # Testing configurations
│   ├── backup/                   # Backup & restore scripts
│   ├── ssl/                      # SSL certificate management
│   └── load-balancing/           # Load balancing configs
│
└── scripts/                       # Utility Scripts
    ├── build.sh                  # Build automation script
    ├── install_flutter.sh        # Flutter SDK installation
    ├── dependency_check.py       # Dependency verification
    ├── compile_fix_script.dart   # Compilation fixes
    └── quick_flutter_check.sh    # Quick Flutter validation
```

## 🎯 Key Components

### Mobile App (`/app`)
- **Architecture**: MVVM pattern with Provider state management
- **Platform**: Flutter 3.19.0+
- **Features**: Video calling, whiteboard, quizzes, analytics
- **Lines of Code**: 120,000+ (comprehensive implementation)

### Backend (`/backend`)
- **Platform**: Node.js
- **Integration**: Supabase (Database, Auth, Storage)
- **Services**: REST APIs, real-time subscriptions

### Documentation (`/docs`)
- **Analysis**: Platform features, recommendations, roadmaps
- **Deployment**: Complete deployment guides and checklists
- **Guides**: User manuals and technical documentation
- **Research**: Extensive market and UX research (1,700+ lines)

### Deployment (`/deployment`)
- **Environments**: Dev, Staging, Production configs
- **CI/CD**: GitHub Actions and GitLab CI pipelines
- **Monitoring**: Prometheus, Grafana, ELK, CloudWatch
- **Mobile**: Google Play and App Store deployment

## 🚀 Quick Start Guide

### 1. Local Development Setup

```bash
# Clone repository
git clone <repository-url>
cd pharmaT

# Setup Flutter app
cd app
flutter pub get
flutter run

# Setup backend (if needed)
cd ../backend/nodejs_backend
npm install
npm start
```

### 2. Testing

```bash
# Run Flutter tests
cd app
flutter test

# Run backend tests
cd backend/nodejs_backend
npm test
```

### 3. Building for Production

```bash
# Build Android APK
cd app
flutter build apk --release

# Build iOS
flutter build ios --release

# Build web
flutter build web --release
```

## 📊 Documentation Index

### For Developers
- **Quick Start**: `/app/README.md`
- **API Documentation**: `/backend/nodejs_backend/README.md`
- **Compilation Status**: `/docs/analysis/FINAL_COMPILATION_STATUS.md`
- **Technical Guide**: `/docs/guides/comprehensive_pharmacy_tutoring_platform_guide.md`

### For DevOps
- **Deployment Guide**: `/docs/deployment/PHARMACY_TUTORING_PLATFORM_DEPLOYMENT_GUIDE.md`
- **Quick Checklist**: `/docs/deployment/QUICK_DEPLOYMENT_CHECKLIST.md`
- **Security Guide**: `/docs/deployment/SECURITY_IMPLEMENTATION_README.md`
- **CI/CD Configs**: `/deployment/cicd/`

### For Product/Business
- **Feature Analysis**: `/docs/analysis/TUTORING_PLATFORM_FEATURES_ANALYSIS.md`
- **Roadmap**: `/docs/analysis/COMPREHENSIVE_ANALYSIS_AND_ROADMAP.md`
- **Recommendation Engine**: `/docs/analysis/RECOMMENDATION_ENGINE_DESIGN.md`
- **Market Research**: `/docs/research/`

## 🔧 Development Workflow

1. **Feature Development**
   - Create feature branch from `develop`
   - Implement feature in `/app/lib/`
   - Write tests
   - Update documentation
   - Create pull request

2. **Backend Changes**
   - Update `/backend/nodejs_backend/src/`
   - Update API documentation
   - Test with Postman/curl
   - Deploy to staging first

3. **Documentation Updates**
   - Update relevant files in `/docs/`
   - Keep README.md current
   - Update STRUCTURE.md if structure changes

## 📦 Deployment Process

1. **Development** → Push to `develop` branch
2. **Staging** → Merge to `staging` branch → Auto-deploy
3. **Production** → Merge to `main` branch → Manual approval → Deploy

See `/docs/deployment/` for detailed deployment procedures.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

For questions or issues:
- Create GitHub issue
- Check `/docs/guides/` for documentation
- Review `/docs/analysis/` for implementation details

---

**Last Updated**: 2025-10-30
**Version**: 1.0.0
**Status**: Ready for GitHub Codespaces
