# Comprehensive Deployment Infrastructure Setup Guide

## Overview

This guide provides step-by-step instructions for setting up the complete deployment infrastructure for the Tutoring Platform. The infrastructure supports multiple environments (development, staging, production) with automated CI/CD pipelines, monitoring, and comprehensive testing procedures.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Infrastructure Setup](#infrastructure-setup)
3. [CI/CD Pipeline Configuration](#cicd-pipeline-configuration)
4. [Environment Configuration](#environment-configuration)
5. [Mobile App Deployment](#mobile-app-deployment)
6. [Backend Deployment](#backend-deployment)
7. [Monitoring and Observability](#monitoring-and-observability)
8. [Security Configuration](#security-configuration)
9. [Testing and Quality Assurance](#testing-and-quality-assurance)
10. [Operations and Maintenance](#operations-and-maintenance)

## Prerequisites

### Required Tools and Software

```bash
# Core tools
- Docker 20.10+
- Docker Compose 2.0+
- Node.js 18+
- Flutter 3.16+
- Python 3.9+
- Ruby 3.0+
- Git

# Cloud CLI tools
- AWS CLI v2
- Firebase CLI
- Google Cloud SDK

# Development tools
- kubectl
- terraform
- helm
- fastlane
```

### Required Accounts and Services

```bash
# Cloud Services
- AWS Account with appropriate permissions
- Google Cloud Platform account
- Firebase project
- CloudFlare account
- GitHub or GitLab account

# Third-party services
- Stripe account (payment processing)
- SendGrid account (email delivery)
- Twilio account (SMS/voice)
- Agora or similar video SDK
- SSL certificate provider

# Monitoring services
- DataDog, New Relic, or similar APM
- Sentry (error tracking)
- PagerDuty (incident management)
```

## Infrastructure Setup

### 1. AWS Infrastructure Setup

#### Terraform Configuration

```bash
# Clone infrastructure repository
git clone <infrastructure-repo>
cd tutoring-platform-infrastructure

# Initialize Terraform
terraform init

# Create workspace for each environment
terraform workspace new development
terraform workspace new staging
terraform workspace new production

# Apply infrastructure configuration
terraform plan -var-file="environments/production.tfvars"
terraform apply -var-file="environments/production.tfvars"
```

#### Core Infrastructure Components

```yaml
# infrastructure/main.tf
# VPC and Networking
- VPC with public and private subnets
- Internet Gateway
- NAT Gateway for private subnets
- Route tables

# Load Balancing
- Application Load Balancer with SSL termination
- Target groups for backend services
- Health checks and auto-scaling groups

# Database
- RDS PostgreSQL with Multi-AZ
- Read replicas for read scaling
- ElastiCache Redis cluster
- Automated backups and snapshots

# Container Orchestration
- ECS cluster with Fargate
- ECR repositories for Docker images
- Application Auto Scaling policies

# Security
- Security groups
- IAM roles and policies
- KMS encryption keys
- Secrets Manager

# Monitoring
- CloudWatch metrics and alarms
- AWS X-Ray for distributed tracing
- CloudTrail for audit logging
```

### 2. Kubernetes Setup (Alternative)

```bash
# Install kubectl and configure cluster access
aws eks update-kubeconfig --region us-east-1 --name tutoring-platform-prod

# Apply namespace
kubectl apply -f deployment/backend/kubernetes/01-namespace-and-secrets.yaml

# Apply configurations
kubectl apply -f deployment/backend/kubernetes/02-configmaps.yaml
kubectl apply -f deployment/backend/kubernetes/03-services.yaml
kubectl apply -f deployment/backend/kubernetes/04-deployments.yaml
kubectl apply -f deployment/backend/kubernetes/05-ingress.yaml

# Verify deployment
kubectl get pods -n tutoring-platform
kubectl get services -n tutoring-platform
```

## CI/CD Pipeline Configuration

### 1. GitHub Actions Setup

#### Repository Secrets Configuration

```bash
# Go to GitHub Repository Settings > Secrets and Variables > Actions
# Add the following secrets:

# Database
DB_HOST=your-production-db-host
DB_PASSWORD=your-secure-password

# Redis
REDIS_PASSWORD=your-redis-password

# Firebase
FIREBASE_PRIVATE_KEY=your-firebase-private-key
FIREBASE_PROJECT_ID=your-project-id

# AWS
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Google Play
GOOGLE_PLAY_JSON_KEY=your-service-account-json

# App Store
APP_STORE_CONNECT_API_KEY=your-api-key
APP_STORE_CONNECT_ISSUER_ID=your-issuer-id
APP_STORE_CONNECT_PRIVATE_KEY=your-private-key

# Notifications
SLACK_WEBHOOK_URL=your-webhook-url

# Certificates
IOS_CERTIFICATE_P12=base64-encoded-certificate
IOS_CERTIFICATE_PASSWORD=certificate-password
ANDROID_KEYSTORE=base64-encoded-keystore
ANDROID_KEY_PASSWORD=keystore-password
ANDROID_STORE_PASSWORD=store-password
```

#### Workflow Files

```bash
# Copy workflow files to your repository
cp deployment/cicd/github-actions/*.yml .github/workflows/

# Create directories if they don't exist
mkdir -p .github/workflows
mkdir -p mobile/fastlane
mkdir -p deployment/testing/postman
```

### 2. GitLab CI Configuration

```bash
# Copy GitLab CI configuration
cp deployment/cicd/gitlab-ci/.gitlab-ci.yml .gitlab-ci.yml

# Configure GitLab CI/CD variables in project settings
# Settings > CI/CD > Variables
```

### 3. Fastlane Setup

```bash
# Initialize Fastlane for both platforms
cd mobile/fastlane

# Android setup
fastlane init android
fastlane add_plugin firebase_app_distribution

# iOS setup (requires Mac)
fastlane init ios

# Install dependencies
bundle install

# Configure signing (iOS)
fastlane match appstore

# Configure Play Store (Android)
fastlane supply init
```

## Environment Configuration

### 1. Development Environment

```bash
# Copy environment template
cp deployment/environments/dev/.env.example .env

# Configure local development
# Edit .env with local database URLs, development keys, etc.

# Start local development environment
cd deployment/backend/docker
docker-compose -f docker-compose.yml up -d

# Start Flutter development server
cd ../../flutter_tutoring_app
flutter run
```

### 2. Staging Environment

```bash
# Set up staging environment on cloud provider
terraform workspace select staging
terraform apply

# Configure environment variables
cp deployment/environments/staging/.env.example .env.staging
# Edit with staging-specific values

# Deploy to staging
# (This will be automated via CI/CD)
```

### 3. Production Environment

```bash
# Set up production environment
terraform workspace select production
terraform apply

# Configure production environment variables
cp deployment/environments/production/.env.example .env.production
# Edit with production-specific values (use secure methods for secrets)

# Deploy to production
# (This will be automated via CI/CD with manual approval)
```

## Mobile App Deployment

### 1. Android Deployment

#### Prerequisites

```bash
# Install Android SDK and tools
# Generate signing keystore
./scripts/generate-android-keystore.sh

# Configure Google Play Console
# - Create application
# - Set up app signing
# - Configure testing tracks
```

#### Deployment Process

```bash
# Automated via CI/CD
# Manual deployment:
cd mobile/fastlane
bundle exec fastlane android production

# To deploy to specific track:
bundle exec fastlane android internal    # Internal testing
bundle exec fastlane android alpha       # Closed testing
bundle exec fastlane android beta        # Open testing
bundle exec fastlane android production  # Production
```

### 2. iOS Deployment

#### Prerequisites

```bash
# Set up Apple Developer account
# Create App Store Connect application
# Configure code signing certificates
# Generate provisioning profiles

# Install certificates (CI/CD will handle this)
# Manual installation:
security create-keychain -p "password" build.keychain
security import certificate.p12 -k build.keychain -P "password" -A -T /usr/bin/codesign
```

#### Deployment Process

```bash
# Automated via CI/CD
# Manual deployment:
cd mobile/fastlane
bundle exec fastlane ios production

# To deploy to TestFlight:
bundle exec fastlane ios beta
```

### 3. Firebase App Distribution

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize project
firebase init

# Deploy to Firebase App Distribution
./scripts/deploy-firebase.sh tutoring-platform-staging android staging
```

## Backend Deployment

### 1. Docker Deployment

```bash
# Build and push Docker images
cd deployment/backend/docker
docker build -t tutoring-platform/api:latest .
docker push tutoring-platform/api:latest

# Deploy with Docker Compose
docker-compose -f docker-compose.yml up -d
```

### 2. Kubernetes Deployment

```bash
# Update image tags in Kubernetes manifests
sed -i "s/image: .*/image: tutoring-platform\/api:$GIT_COMMIT/" deployment/backend/kubernetes/04-deployments.yaml

# Apply manifests
kubectl apply -f deployment/backend/kubernetes/

# Check deployment status
kubectl rollout status deployment/tutoring-api -n tutoring-platform
```

### 3. AWS ECS Deployment

```bash
# Update ECS service
aws ecs update-service \
  --cluster tutoring-platform-prod \
  --service tutoring-backend-prod \
  --force-new-deployment \
  --task-definition tutoring-backend-prod-task
```

## Monitoring and Observability

### 1. Prometheus Configuration

```bash
# Deploy Prometheus
kubectl apply -f deployment/monitoring/prometheus/

# Configure alert rules
kubectl apply -f deployment/monitoring/alertmanager/

# Verify monitoring setup
kubectl get pods -n monitoring
```

### 2. Grafana Configuration

```bash
# Deploy Grafana
kubectl apply -f deployment/monitoring/grafana/

# Import dashboards
# (Import JSON files from deployment/monitoring/grafana/dashboards/)
```

### 3. ELK Stack Setup

```bash
# Deploy Elasticsearch, Logstash, Kibana
kubectl apply -f deployment/monitoring/elk/

# Configure log shipping
# (Configure Filebeat or Fluentd for log collection)
```

### 4. Application Monitoring

```bash
# Deploy Jaeger for distributed tracing
kubectl apply -f deployment/monitoring/jaeger/

# Deploy Sentry for error tracking
# (Configure via Sentry SaaS or self-hosted)
```

## Security Configuration

### 1. SSL/TLS Certificates

```bash
# Install certbot for Let's Encrypt
sudo apt install certbot

# Generate certificates
sudo certbot certonly --standalone -d api.tutoring-platform.com
sudo certbot certonly --standalone -d app.tutoring-platform.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 2. Security Scanning

```bash
# Container vulnerability scanning
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image tutoring-platform/api:latest

# Dependency scanning
npm audit
npm install -g audit-ci
audit-ci
```

### 3. Access Control

```bash
# Configure AWS IAM roles and policies
# Set up VPN access for production
# Configure Bastion hosts
# Implement network segmentation
```

## Testing and Quality Assurance

### 1. Unit and Integration Testing

```bash
# Backend tests
cd code/nodejs_backend
npm test
npm run test:integration

# Frontend tests
cd flutter_tutoring_app
flutter test
flutter test integration_test/
```

### 2. End-to-End Testing

```bash
# Run E2E tests
cd deployment/testing
npm install
npm test

# Performance testing
npm run test:load
```

### 3. User Acceptance Testing

```bash
# Start UAT environment
cd deployment/testing
docker-compose -f docker-compose.uat.yml up -d

# Generate test data
node scripts/generate-uat-data.js

# Run UAT tests
node uat.test.js
```

### 4. Automated Testing Pipeline

```bash
# GitHub Actions automatically runs:
# - Unit tests
# - Integration tests
# - Security scans
# - Build verification
# - UAT tests (scheduled)
```

## Operations and Maintenance

### 1. Backup and Recovery

```bash
# Configure automated backups
# Database backups (RDS automated snapshots)
# File uploads (S3 versioning)
# Configuration backups (encrypted S3)

# Manual backup procedures
./deployment/backup/backup-restore.sh full
./deployment/backup/backup-restore.sh verify
```

### 2. Monitoring and Alerting

```bash
# Configure alerting rules
# Slack notifications for critical issues
# PagerDuty integration for on-call
# Email notifications for warnings

# Monitor key metrics:
# - API response times
# - Error rates
# - Database performance
# - Resource utilization
# - Business metrics (active users, sessions)
```

### 3. Logging and Audit

```bash
# Centralized logging with ELK stack
# Security audit logs with CloudTrail
# Application performance monitoring
# Error tracking with Sentry
```

### 4. Disaster Recovery

```bash
# Disaster recovery procedures documented in:
# - RTO (Recovery Time Objective): 4 hours
# - RPO (Recovery Point Objective): 15 minutes

# DR testing schedule:
# - Monthly tabletop exercises
# - Quarterly full DR tests
# - Annual comprehensive DR test
```

## Deployment Checklist

### Pre-Deployment

```bash
□ All tests passing (unit, integration, e2e)
□ Security scan results reviewed
□ Database migrations tested
□ Environment variables configured
□ Monitoring and alerting setup
□ Backup procedures tested
□ Rollback plan prepared
□ Documentation updated
□ Stakeholders notified
```

### Deployment

```bash
□ Deploy to staging environment
□ Run smoke tests
□ Verify monitoring alerts
□ Check error rates
□ Validate performance metrics
□ Confirm database connectivity
□ Test critical user journeys
□ Monitor for 2 hours minimum
```

### Post-Deployment

```bash
□ Update documentation
□ Notify stakeholders
□ Monitor error rates for 24 hours
□ Review performance metrics
□ Update release notes
□ Archive deployment artifacts
□ Schedule post-mortem if needed
```

## Rollback Procedures

### Automated Rollback

```bash
# Triggered by:
# - Error rate > 5%
# - Response time > 10 seconds
# - Health check failures
# - Manual intervention

# Rollback steps:
1. Stop new deployment
2. Revert to previous version
3. Clear cache if needed
4. Verify service restoration
5. Investigate issues
```

### Manual Rollback

```bash
# AWS ECS rollback
aws ecs update-service \
  --cluster tutoring-platform-prod \
  --service tutoring-backend-prod \
  --task-definition tutoring-backend-prod-task-previous \
  --force-new-deployment

# Kubernetes rollback
kubectl rollout undo deployment/tutoring-api -n tutoring-platform

# Database rollback
./deployment/database/migrate.js rollback <version>
```

## Support and Maintenance

### On-Call Procedures

```bash
# Incident response workflow:
1. Alert triggered
2. PagerDuty notification
3. On-call engineer responds
4. Incident assessment
5. Fix or rollback decision
6. Communication updates
7. Post-incident review
```

### Regular Maintenance

```bash
# Weekly:
- Review error rates and performance metrics
- Check backup completion
- Update dependency vulnerabilities
- Monitor SSL certificate expiration

# Monthly:
- Security patch updates
- Performance optimization review
- Capacity planning assessment
- DR testing exercises

# Quarterly:
- Security audit
- Cost optimization review
- Technology stack updates
- Disaster recovery tests
```

## Troubleshooting Guide

### Common Issues

#### High Error Rates

```bash
# Check:
1. Application logs: kubectl logs -f deployment/tutoring-api
2. Database connectivity: pg_isready
3. Redis connectivity: redis-cli ping
4. Load balancer health: aws elbv2 describe-target-health
```

#### Performance Issues

```bash
# Investigate:
1. Response time metrics in Grafana
2. Database query performance
3. Cache hit rates
4. Resource utilization
5. Network latency
```

#### Build Failures

```bash
# Debug:
1. Check CI/CD logs
2. Verify environment variables
3. Test locally with same configuration
4. Check external service availability
5. Review security credentials
```

## Contact Information

- **DevOps Team**: devops@tutoring-platform.com
- **Security Team**: security@tutoring-platform.com
- **On-Call**: Available via PagerDuty
- **Documentation**: https://wiki.tutoring-platform.com

---

This setup guide provides a comprehensive foundation for deploying and maintaining the Tutoring Platform. Regular reviews and updates of these procedures ensure continued reliability and security of the deployment infrastructure.