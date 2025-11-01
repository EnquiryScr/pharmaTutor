# pharmaT Database Architecture Strategy

**Date**: 2025-10-31  
**Status**: Architecture Review & Migration Plan

---

## Current Architecture Analysis

### 🏗️ Backend Status

**Current Implementation:**
- **Backend Type**: Node.js + PostgreSQL + Redis
- **Location**: `/workspace/pharmaT/backend/nodejs_backend/`
- **Database Schema**: 406 lines of SQL (comprehensive tables)
- **Authentication**: Custom JWT implementation
- **API**: RESTful endpoints with Socket.IO for real-time features

**Key Tables (PostgreSQL):**
- `users` - User accounts with roles (student/tutor/admin)
- `assignments` - Assignment management with rubrics
- `queries` - Support ticket system
- `messages` - Chat/messaging
- `articles` - Content library
- `appointments` - Scheduling system
- `payments` - Payment processing
- `analytics_events` - User tracking

**Supabase Status:**
- ❌ **NOT currently integrated**
- ⚠️ Configuration placeholders exist in `.env.example` (lines 52-55)
- ⚠️ Documentation mentions Supabase but it's not implemented
- ⚠️ No Supabase packages in Flutter app

### 📱 Flutter App Status

**Current Implementation:**
- **Lines of Code**: Only 31 Dart files (minimal implementation)
- **HTTP Client**: Dio (makes REST calls to Node.js backend)
- **Local Storage**:
  - ✅ **Hive**: Initialized in main.dart (NoSQL key-value storage)
  - ❌ **SQLite**: Declared in pubspec.yaml but NOT implemented
  - ✅ **SecureStorage**: For encrypted credentials

**Data Models** (Ready but no database integration):
- UserModel (562 lines)
- CourseModel (826 lines)
- SessionModel (601 lines)
- PaymentModel (683 lines)
- MessageModel (319 lines)
- NotificationModel (493 lines)

**Current Data Flow:**
```
Flutter App → Dio HTTP → Node.js Backend → PostgreSQL
     ↓
  Hive (local cache)
```

---

## Proposed Architecture: Supabase-First

### 🎯 New Data Flow

```
Flutter App ↔ Supabase Client SDK ↔ Supabase Cloud
     ↓                                    ↓
SQLite (offline cache)          PostgreSQL (production DB)
                                         ↓
                              Auth, Storage, Edge Functions
```

### 📊 Database Strategy

#### **Supabase (Backend) - PRIMARY STORAGE**

**Tables to Create:**
1. **Authentication** (Supabase Auth built-in)
   - User profiles
   - Sessions management
   - Role-based access control (RLS policies)

2. **Core Tables** (migrate from Node.js backend)
   - `users` - Extended user profiles
   - `courses` - Course catalog
   - `course_content` - Learning materials
   - `enrollments` - Student-course relationships
   - `sessions` - Tutoring sessions
   - `session_feedback` - Reviews and ratings
   - `payments` - Transaction records
   - `messages` - Chat history
   - `conversations` - Chat threads
   - `notifications` - Push notifications
   - `assignments` - Assignment submissions
   - `queries` - Support tickets

3. **Real-time Features** (Supabase Realtime)
   - Chat messages (live updates)
   - Session status changes
   - Notifications

4. **File Storage** (Supabase Storage)
   - Profile images
   - Course materials
   - Assignment submissions
   - Chat attachments

#### **SQLite (Frontend) - LOCAL CACHE ONLY**

**Purpose**: Offline functionality and performance optimization

**Tables to Create:**
1. **User Session Cache**
   - `cached_user` - Current user profile
   - `cached_preferences` - App preferences

2. **Offline Data Cache**
   - `cached_courses` - Recently viewed courses
   - `cached_messages` - Recent chat history
   - `cached_notifications` - Unread notifications

3. **Draft Data** (pending sync)
   - `draft_messages` - Messages sent offline
   - `draft_feedback` - Feedback pending submission

**Sync Strategy:**
- On app start: Sync SQLite ↔ Supabase
- On network change: Resume sync if connection restored
- Background sync: Every 5 minutes for active users

#### **Hive (Frontend) - SIMPLE KEY-VALUE STORAGE**

**Keep for:**
- App settings (theme, language)
- Onboarding status
- Feature flags
- Temporary UI state

---

## Migration Plan

### Phase 1: Supabase Setup ✅

**Tasks:**
1. ✅ Create Supabase project
2. ✅ Get Supabase credentials (URL, anon key, service role key)
3. ✅ Add Supabase packages to Flutter app:
   ```yaml
   dependencies:
     supabase_flutter: ^2.0.0
   ```

### Phase 2: Database Schema Migration

**Tasks:**
1. **Migrate PostgreSQL schema to Supabase**
   - Use Supabase SQL Editor
   - Copy tables from `backend/nodejs_backend/src/schema/database.sql`
   - Adapt to Supabase conventions (use RLS policies)

2. **Create Row Level Security (RLS) policies**
   - Users can only read their own data
   - Tutors can read assigned students
   - Admins have full access

3. **Design Flutter data models alignment**
   - Ensure UserModel matches `users` table
   - Ensure CourseModel matches `courses` table
   - Map all 6 models to Supabase tables

### Phase 3: Authentication Migration

**Replace:**
- ❌ Custom JWT auth (Node.js)
- ❌ `AuthApiClient` with Dio

**With:**
- ✅ Supabase Auth
- ✅ Email/password authentication
- ✅ OAuth providers (Google, Apple)
- ✅ Magic link authentication

**Implementation:**
```dart
// Initialize Supabase
await Supabase.initialize(
  url: SUPABASE_URL,
  anonKey: SUPABASE_ANON_KEY,
);

// Sign in
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
```

### Phase 4: Data Layer Migration

**Create:**
1. `lib/core/database/supabase_client.dart` - Supabase client wrapper
2. `lib/core/database/database_helper.dart` - SQLite helper (local cache)
3. `lib/data/datasources/supabase/` - Supabase data sources
   - `user_supabase_datasource.dart`
   - `course_supabase_datasource.dart`
   - `session_supabase_datasource.dart`
   - `payment_supabase_datasource.dart`
   - `message_supabase_datasource.dart`
   - `notification_supabase_datasource.dart`

**Update:**
1. `lib/data/repositories/` - Add Supabase + SQLite sync logic
2. Remove `AuthApiClient` (Dio-based)

### Phase 5: SQLite Local Cache Implementation

**Create:**
1. SQLite schema for cache tables
2. Sync service for Supabase ↔ SQLite
3. Offline mode detection
4. Background sync worker

### Phase 6: Testing & Validation

**Test:**
1. ✅ Authentication flow (signup, login, logout)
2. ✅ Data CRUD operations
3. ✅ Offline mode functionality
4. ✅ Real-time updates (chat, notifications)
5. ✅ File upload/download
6. ✅ RLS policy enforcement

### Phase 7: Backend Decommissioning

**Decision Point:**
- **Option A**: Keep Node.js backend for custom business logic
- **Option B**: Migrate all logic to Supabase Edge Functions

---

## Key Decisions Required

### 🤔 Questions for You:

1. **Node.js Backend Fate:**
   - ❓ **Keep Node.js backend** for custom logic (analytics, payments)?
   - ❓ **Fully migrate to Supabase** and use Edge Functions?
   - ❓ **Hybrid approach** (Supabase for data, Node.js for complex logic)?

2. **SQLite Local Cache Scope:**
   - ❓ Which data should be cached offline?
   - ❓ Do you need full offline mode (create courses offline)?
   - ❓ Or just read-only cache (view courses offline)?

3. **Migration Timeline:**
   - ❓ Migrate existing data from PostgreSQL → Supabase?
   - ❓ Fresh start with clean Supabase database?

4. **Real-time Features:**
   - ❓ Which features need real-time updates? (chat, sessions, notifications?)

---

## Recommendations

### ✅ Recommended Approach

**Architecture:**
```
Supabase (Backend)
├── PostgreSQL Database (production data)
├── Supabase Auth (authentication)
├── Supabase Storage (file uploads)
├── Supabase Realtime (live updates)
└── Supabase Edge Functions (custom logic)

Flutter App (Frontend)
├── Supabase Client SDK (primary data access)
├── SQLite (offline cache - read-only)
├── Hive (app settings)
└── SecureStorage (tokens, credentials)
```

**Benefits:**
- ✅ Simplified backend (no Node.js server management)
- ✅ Built-in authentication & authorization (RLS)
- ✅ Real-time subscriptions out-of-box
- ✅ Automatic API generation
- ✅ Built-in file storage
- ✅ Scales automatically

**SQLite Usage:**
- ✅ Cache recently viewed data (courses, messages)
- ✅ Store draft content (pending sync)
- ✅ Enable basic offline viewing
- ❌ NOT a full offline-first database
- ❌ NOT for creating new records offline

---

## Next Steps

**Immediate Actions:**

1. **Get Supabase Credentials** (if you have a project)
   - Project URL
   - Anon key
   - Service role key

2. **Clarify Architecture Vision**
   - Answer decision questions above

3. **Design Supabase Schema**
   - Based on existing PostgreSQL schema
   - Add RLS policies
   - Map to Flutter models

4. **Implement Step-by-Step**
   - Start with Supabase auth
   - Migrate one entity at a time (users → courses → sessions → payments)
   - Test thoroughly at each step

---

**Status**: Awaiting user decisions before proceeding with implementation.
