# Database Architecture Analysis - pharmaT App

## Current State (Before Migration)

### Backend Architecture
- **Type**: Node.js + PostgreSQL + Redis
- **Location**: `/workspace/pharmaT/backend/nodejs_backend/`
- **Authentication**: JWT-based (custom implementation)
- **Database**: PostgreSQL with 406 lines of SQL schema
- **Tables**: users, assignments, queries, messages, articles, appointments, payments, analytics_events

### Flutter App Architecture
- **Location**: `/workspace/pharmaT/app/`
- **HTTP Client**: Dio (for REST API calls to Node.js backend)
- **Local Storage**: 
  - Hive (initialized, for NoSQL key-value storage)
  - SQLite (declared in pubspec.yaml but NOT implemented)
  - SecureStorage (for encrypted credential storage)
- **Auth Implementation**: Custom JWT auth via `AuthApiClient` → Node.js backend

### Data Models (Flutter)
- UserModel (562 lines)
- CourseModel (826 lines) 
- SessionModel (601 lines)
- PaymentModel (683 lines)
- MessageModel (319 lines)
- NotificationModel (493 lines)

**Total: Only 31 Dart files in entire app (minimally implemented)**

### Current Data Flow
```
Flutter App → Dio HTTP → Node.js Backend → PostgreSQL Database
                ↓
          Hive (local cache)
```

## User's New Requirement

**Switch to Supabase-First Architecture:**
- Replace Node.js + PostgreSQL with Supabase
- All authentication via Supabase Auth
- All backend database operations via Supabase
- SQLite only for frontend local caching

## Questions to Resolve

1. **Supabase Integration Status**: 
   - README.md and STRUCTURE.md mention "Supabase" integration
   - But NO Supabase packages in pubspec.yaml
   - Backend uses PostgreSQL + Redis (NOT Supabase)
   - **Status**: Documentation is outdated/aspirational

2. **SQLite Usage Strategy**:
   - What data needs local caching?
   - Offline-first features?
   - Sync strategy with Supabase?

3. **Migration Path**:
   - Keep Node.js backend OR fully migrate to Supabase?
   - Migrate existing PostgreSQL schema to Supabase?

## Next Steps
1. Ask user to clarify architecture vision
2. Determine SQLite local caching requirements
3. Design Supabase schema based on existing PostgreSQL schema + Flutter models
4. Plan migration strategy
