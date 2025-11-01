# Tutoring Platform Backend API

A comprehensive Node.js monolithic backend API for a global tutoring platform with real-time communication, assignment management, payment processing, and analytics.

## 🚀 Features

- **User Management**: Authentication, authorization, profile management, role-based access control
- **Assignment Management**: CRUD operations, file uploads, grading system, rubrics
- **Query/Ticket System**: Support tickets with comments, priorities, assignment handling
- **Real-time Chat/Messaging**: WebSocket-based messaging, rooms, file sharing
- **Article Library**: Content management, search, categorization, likes/bookmarks
- **Scheduling System**: Appointment booking, availability management, calendar integration
- **Payment Processing**: Stripe integration, revenue sharing, refunds, payouts
- **File Uploads**: Multi-format support, security scanning, CDN ready
- **Analytics**: User engagement, revenue tracking, performance metrics
- **Security**: JWT authentication, rate limiting, input validation, CORS, helmet
- **Database**: PostgreSQL with Redis caching, connection pooling
- **Real-time Features**: Socket.IO integration for live updates
- **API Documentation**: Comprehensive endpoint documentation

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    API Gateway & Load Balancer               │
├─────────────────────────────────────────────────────────────┤
│  Express.js Server with Middleware Stack                    │
│  ├── Authentication & Authorization                         │
│  ├── Rate Limiting & Security                              │
│  ├── Input Validation & Sanitization                       │
│  ├── Error Handling & Logging                              │
│  └── Real-time WebSocket Support                           │
├─────────────────────────────────────────────────────────────┤
│                    Service Layer                            │
│  ├── Authentication Service                                │
│  ├── User Management Service                               │
│  ├── Assignment Management Service                         │
│  ├── Chat/Messaging Service                                │
│  ├── Payment Processing Service                            │
│  ├── File Upload Service                                   │
│  └── Analytics Service                                     │
├─────────────────────────────────────────────────────────────┤
│                    Data Layer                               │
│  ├── PostgreSQL (Primary Database)                        │
│  ├── Redis (Caching & Sessions)                           │
│  ├── File System (Uploads)                                │
│  └── External APIs (Stripe, Firebase, etc.)               │
└─────────────────────────────────────────────────────────────┘
```

## 📦 Installation

### Prerequisites

- Node.js 18+ 
- PostgreSQL 12+
- Redis 6+
- Stripe account (for payments)
- Firebase project (for push notifications)
- Supabase project (optional, for additional services)

### Setup

1. **Clone and install dependencies**
```bash
git clone <repository-url>
cd code/nodejs_backend
npm install
```

2. **Configure environment**
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Setup database**
```bash
# Create PostgreSQL database
createdb tutoring_platform

# Run schema migrations
psql tutoring_platform < src/schema/database.sql
psql tutoring_platform < src/schema/indexes.sql
```

4. **Start Redis server**
```bash
redis-server
```

5. **Start the server**
```bash
# Development
npm run dev

# Production
npm start
```

## 🔧 Configuration

### Environment Variables

Key configuration options in `.env`:

- **Database**: `POSTGRES_HOST`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
- **Redis**: `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`
- **JWT**: `JWT_SECRET`, `JWT_REFRESH_SECRET`, `JWT_EXPIRE`
- **Stripe**: `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`
- **File Upload**: `UPLOAD_DIR`, `MAX_FILE_SIZE`, `ALLOWED_FILE_TYPES`
- **Security**: `BCRYPT_ROUNDS`, `RATE_LIMIT_MAX_REQUESTS`
- **CORS**: `ALLOWED_ORIGINS`

### Database Schema

The application uses PostgreSQL with the following main tables:

- **users**: User accounts and profiles
- **assignments**: Assignment management
- **queries**: Support tickets
- **messages**: Chat messages
- **articles**: Content library
- **appointments**: Scheduling
- **payments**: Payment processing
- **analytics_events**: User activity tracking

## 📚 API Documentation

### Authentication Endpoints

#### Register User
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "firstName": "John",
  "lastName": "Doe",
  "role": "student"
}
```

#### Login
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "rememberMe": false
}
```

#### Refresh Token
```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refreshToken": "your_refresh_token_here"
}
```

### User Management

#### Get Profile
```http
GET /api/v1/users/profile
Authorization: Bearer <token>
```

#### Update Profile
```http
PUT /api/v1/users/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+1234567890",
  "bio": "Experienced tutor",
  "subjects": ["Mathematics", "Physics"],
  "timezone": "America/New_York"
}
```

#### Change Password
```http
PUT /api/v1/users/change-password
Authorization: Bearer <token>
Content-Type: application/json

{
  "currentPassword": "OldPassword123!",
  "newPassword": "NewPassword123!",
  "confirmPassword": "NewPassword123!"
}
```

### Assignment Management

#### Create Assignment
```http
POST /api/v1/assignments
Authorization: Bearer <token>
Content-Type: multipart/form-data

title: "Math Assignment 1"
description: "Solve the following equations..."
subject: "Mathematics"
gradeLevel: "high"
deadline: "2024-12-31T23:59:59Z"
instructions: "Show all work"
attachments: [file1, file2]
```

#### Get Assignments
```http
GET /api/v1/assignments?page=1&limit=20&subject=Mathematics&status=published
Authorization: Bearer <token>
```

#### Submit Assignment
```http
POST /api/v1/assignments/:id/submit
Authorization: Bearer <token>
Content-Type: multipart/form-data

content: "My solution to the assignment..."
attachments: [submission_file1]
```

#### Grade Assignment
```http
POST /api/v1/assignments/:id/grade
Authorization: Bearer <token>
Content-Type: application/json

{
  "grade": 95.5,
  "feedback": "Excellent work! Well done.",
  "rubricScores": {
    "problem_solving": 95,
    "presentation": 96
  }
}
```

### Query/Ticket System

#### Create Query
```http
POST /api/v1/queries
Authorization: Bearer <token>
Content-Type: multipart/form-data

subject: "Assignment Not Graded"
description: "My assignment was submitted 3 days ago but hasn't been graded yet."
priority: "high"
category: "Technical Support"
attachments: [screenshot]
```

#### Get Queries
```http
GET /api/v1/queries?page=1&limit=10&status=open
Authorization: Bearer <token>
```

#### Add Comment
```http
POST /api/v1/queries/:id/comments
Authorization: Bearer <token>
Content-Type: application/json

{
  "comment": "I've checked your submission and will grade it today.",
  "isInternal": false
}
```

### Chat/Messaging

#### Send Message
```http
POST /api/v1/chat/message
Authorization: Bearer <token>
Content-Type: application/json

{
  "recipientId": "uuid-of-recipient",
  "message": "Hello! How are you?",
  "messageType": "text",
  "attachments": []
}
```

#### Get Conversation
```http
GET /api/v1/chat/conversation/:userId?page=1&limit=50
Authorization: Bearer <token>
```

#### Create Chat Room
```http
POST /api/v1/chat/room
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Study Group Math",
  "type": "group",
  "participants": ["uuid1", "uuid2", "uuid3"]
}
```

### Article Library

#### Create Article
```http
POST /api/v1/articles
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Introduction to Calculus",
  "content": "Calculus is a branch of mathematics...",
  "summary": "A beginner's guide to calculus concepts",
  "tags": ["mathematics", "calculus", "beginner"],
  "category": "Mathematics",
  "difficultyLevel": "beginner",
  "estimatedReadTime": 15,
  "isPublished": true
}
```

#### Search Articles
```http
GET /api/v1/articles?search=calculus&category=Mathematics&page=1&limit=10
```

#### Like Article
```http
POST /api/v1/articles/:id/like
Authorization: Bearer <token>
```

### Scheduling

#### Create Appointment
```http
POST /api/v1/schedule/appointment
Authorization: Bearer <token>
Content-Type: application/json

{
  "tutorId": "uuid-of-tutor",
  "startTime": "2024-12-31T14:00:00Z",
  "endTime": "2024-12-31T15:00:00Z",
  "subject": "Mathematics",
  "notes": "Need help with calculus",
  "meetingLink": "https://zoom.us/j/123456789"
}
```

#### Get Appointments
```http
GET /api/v1/schedule/appointments?page=1&limit=20
Authorization: Bearer <token>
```

#### Update Availability
```http
POST /api/v1/schedule/tutor/availability
Authorization: Bearer <token>
Content-Type: application/json

{
  "date": "2024-12-31",
  "timeSlots": [
    {
      "start": "09:00",
      "end": "10:00",
      "isAvailable": true
    },
    {
      "start": "10:00", 
      "end": "11:00",
      "isAvailable": false
    }
  ]
}
```

### Payment Processing

#### Create Payment Intent
```http
POST /api/v1/payments/create-intent
Authorization: Bearer <token>
Content-Type: application/json

{
  "amount": 5000, // $50.00 in cents
  "currency": "usd",
  "description": "Mathematics tutoring session",
  "appointmentId": "uuid-of-appointment",
  "metadata": {
    "sessionType": "individual"
  }
}
```

#### Confirm Payment
```http
POST /api/v1/payments/confirm/:paymentId
Authorization: Bearer <token>
Content-Type: application/json

{
  "paymentIntentId": "pi_1234567890"
}
```

#### Payment History
```http
GET /api/v1/payments/history?page=1&limit=20
Authorization: Bearer <token>
```

### File Uploads

#### Single File Upload
```http
POST /api/v1/uploads/single
Authorization: Bearer <token>
Content-Type: multipart/form-data

file: [file]
purpose: "assignment"
entityId: "uuid-of-assignment"
```

#### Multiple File Upload
```http
POST /api/v1/uploads/multiple
Authorization: Bearer <token>
Content-Type: multipart/form-data

files: [file1, file2, file3]
purpose: "profile"
```

#### Download File
```http
GET /api/v1/uploads/:fileId/download
Authorization: Bearer <token>
```

### Analytics

#### Platform Overview (Admin)
```http
GET /api/v1/analytics/overview
Authorization: Bearer <admin-token>
```

#### User Engagement (Admin)
```http
GET /api/v1/analytics/engagement?period=30d&userType=all
Authorization: Bearer <admin-token>
```

#### Revenue Analytics (Admin)
```http
GET /api/v1/analytics/revenue?period=30d&groupBy=day
Authorization: Bearer <admin-token>
```

#### Track Event
```http
POST /api/v1/analytics/track
Authorization: Bearer <token>
Content-Type: application/json

{
  "eventType": "assignment_viewed",
  "eventData": {
    "assignmentId": "uuid",
    "duration": 300
  },
  "sessionId": "session-uuid"
}
```

## 🔐 Authentication & Authorization

### JWT Token Structure

```json
{
  "userId": "uuid",
  "email": "user@example.com",
  "role": "student|tutor|admin",
  "permissions": ["read_own_assignments", "submit_assignments"],
  "iat": 1234567890,
  "exp": 1234567890
}
```

### Role-Based Access Control

- **Student**: Can view/submit assignments, chat, book appointments
- **Tutor**: Can create/grade assignments, manage schedule, chat
- **Admin**: Full access to all features and user management

### Security Features

- JWT tokens with refresh mechanism
- Password hashing with bcrypt (12 rounds)
- Rate limiting (100 requests per 15 minutes)
- Input validation and sanitization
- CORS protection
- Helmet security headers
- SQL injection prevention
- XSS protection

## 🔧 Middleware Stack

```javascript
// Request Flow
Request → Rate Limiter → CORS → Security Headers → Body Parser → 
Authentication → Authorization → Validation → Route Handler → 
Response → Logging
```

### Custom Middleware

- **Authentication**: JWT token verification
- **Authorization**: Role-based access control
- **Validation**: Input validation and sanitization
- **Error Handling**: Centralized error management
- **Logging**: Request/response logging
- **Security**: Rate limiting, CORS, headers

## 📊 Database Schema

### Core Tables

- **users**: User accounts and profiles
- **assignments**: Assignment management
- **queries**: Support tickets
- **messages**: Chat messaging
- **articles**: Content library
- **appointments**: Scheduling
- **payments**: Payment processing
- **analytics_events**: User tracking

### Indexes

- Performance indexes for frequently queried columns
- Full-text search indexes for content
- Composite indexes for complex queries
- Partial indexes for filtered data

## 🚀 Real-time Features

### WebSocket Events

- **Chat**: `send_message`, `typing_start`, `typing_stop`
- **Video Calls**: `join_call`, `webrtc_offer`, `webrtc_answer`
- **Notifications**: `assignment_update`, `grade_submitted`
- **Collaborative**: `whiteboard_draw`, `screen_share_start`

### Socket.IO Integration

```javascript
// Client connection
const socket = io('http://localhost:5000', {
  auth: {
    token: 'jwt_token_here'
  }
});

// Join call
socket.emit('join_call', {
  callId: 'call-uuid',
  participants: ['user1', 'user2'],
  isVideo: true
});

// Send message
socket.emit('send_message', {
  recipientId: 'user-uuid',
  message: 'Hello!',
  messageType: 'text'
});
```

## 📈 Monitoring & Logging

### Logging Levels

- **ERROR**: System errors and exceptions
- **WARN**: Security events and warnings
- **INFO**: User actions and business events
- **DEBUG**: Detailed debugging information

### Log Files

- `logs/combined.log`: All log entries
- `logs/error.log`: Error-level logs only
- `logs/security.log`: Security events
- `logs/performance.log`: Performance metrics
- `logs/api.log`: API request/response logs

### Health Checks

```bash
# Check server health
curl http://localhost:5000/health

# Response
{
  "status": "OK",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "uptime": 3600,
  "environment": "development",
  "version": "1.0.0"
}
```

## 🧪 Testing

### Running Tests

```bash
# Unit tests
npm test

# Watch mode
npm run test:watch

# With coverage
npm run test:coverage
```

### Test Structure

```
src/tests/
├── unit/
│   ├── auth.test.js
│   ├── users.test.js
│   └── assignments.test.js
├── integration/
│   ├── api.test.js
│   └── database.test.js
└── fixtures/
    └── test-data.js
```

## 🚀 Deployment

### Production Setup

1. **Environment Configuration**
   - Set `NODE_ENV=production`
   - Configure production database
   - Set secure JWT secrets
   - Enable HTTPS

2. **Process Management**
   ```bash
   # Using PM2
   npm install -g pm2
   pm2 start src/server.js --name tutoring-api
   ```

3. **Database Migration**
   ```bash
   psql production_db < src/schema/database.sql
   psql production_db < src/schema/indexes.sql
   ```

4. **Nginx Configuration**
   ```nginx
   server {
       listen 443 ssl;
       server_name api.tutoringplatform.com;
       
       location / {
           proxy_pass http://localhost:5000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

### Docker Deployment

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      - NODE_ENV=production
    depends_on:
      - postgres
      - redis
  
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: tutoring_platform
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## 📋 API Response Format

### Success Response

```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {
    // Response data
  },
  "pagination": {
    "page": 1,
    "limit": 20,
    "totalCount": 100,
    "totalPages": 5,
    "hasNext": true,
    "hasPrev": false
  }
}
```

### Error Response

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message",
  "code": "ERROR_CODE",
  "validationErrors": [
    {
      "field": "email",
      "message": "Invalid email format",
      "value": "invalid-email"
    }
  ]
}
```

## 🔧 Development

### Code Structure

```
src/
├── server.js              # Main server file
├── middleware/            # Custom middleware
│   ├── auth.js           # Authentication
│   ├── errorHandler.js   # Error handling
│   ├── validation.js     # Input validation
│   └── logger.js         # Logging
├── routes/               # API routes
│   ├── auth.js          # Authentication
│   ├── users.js         # User management
│   ├── assignments.js   # Assignment CRUD
│   ├── queries.js       # Support tickets
│   ├── chat.js          # Messaging
│   ├── articles.js      # Content
│   ├── schedule.js      # Appointments
│   ├── payments.js      # Payments
│   ├── uploads.js       # File uploads
│   └── analytics.js     # Analytics
├── services/            # Business logic
│   ├── databaseService.js
│   ├── socketService.js
│   ├── loggingService.js
│   └── redisService.js
├── schema/              # Database schema
│   ├── database.sql     # Table definitions
│   └── indexes.sql      # Performance indexes
├── utils/               # Utility functions
├── config/              # Configuration
└── tests/               # Test files
```

### Adding New Features

1. **Create Route Handler**
   ```javascript
   // routes/feature.js
   router.post('/feature', authMiddleware, async (req, res, next) => {
     // Implementation
   });
   ```

2. **Add Database Query**
   ```javascript
   // services/databaseService.js
   const queries = {
     feature: {
       create: 'INSERT INTO features ... RETURNING *',
       findById: 'SELECT * FROM features WHERE id = $1'
     }
   };
   ```

3. **Update Validation**
   ```javascript
   // middleware/validation.js
   const featureValidations = {
     create: [
       body('name').isLength({ min: 1 }).withMessage('Name required')
     ]
   };
   ```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Code Standards

- ESLint configuration for code style
- Jest for unit testing
- Prettier for code formatting
- Conventional commits for git messages

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:

- Email: support@tutoringplatform.com
- Documentation: https://docs.tutoringplatform.com
- Issues: GitHub Issues page

## 🔄 Changelog

### v1.0.0
- Initial release
- Core API features
- Authentication & authorization
- Assignment management
- Real-time messaging
- Payment processing
- File uploads
- Analytics tracking

---

**Built with ❤️ for the global tutoring community**