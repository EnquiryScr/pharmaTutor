require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const session = require('express-session');
const redis = require('redis');
const connectRedis = require('connect-redis');
const { createServer } = require('http');
const { Server } = require('socket.io');

// Import middleware
const { errorHandler, notFound } = require('./middleware/errorHandler');
const { requestLogger } = require('./middleware/logger');
const { validateRequest } = require('./middleware/validation');

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const assignmentRoutes = require('./routes/assignments');
const queryRoutes = require('./routes/queries');
const chatRoutes = require('./routes/chat');
const articleRoutes = require('./routes/articles');
const scheduleRoutes = require('./routes/schedule');
const paymentRoutes = require('./routes/payments');
const uploadRoutes = require('./routes/uploads');
const analyticsRoutes = require('./routes/analytics');

// Import services
const SocketService = require('./services/socketService');
const DatabaseService = require('./services/databaseService');
const RedisService = require('./services/redisService');
const LoggingService = require('./services/loggingService');

const app = express();
const server = createServer(app);

// Initialize services
const databaseService = new DatabaseService();
const loggingService = new LoggingService();
const socketService = new SocketService(server);

// Initialize Redis
const redisClient = redis.createClient({
  host: process.env.REDIS_HOST || 'localhost',
  port: process.env.REDIS_PORT || 6379,
  password: process.env.REDIS_PASSWORD
});

// Trust proxy for accurate IP addresses behind load balancers
app.set('trust proxy', 1);

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "ws:", "wss:"]
    }
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

// CORS configuration
app.use(cors({
  origin: function (origin, callback) {
    const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [
      'http://localhost:3000',
      'http://localhost:3001'
    ];
    
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'production' ? 100 : 1000, // limit each IP
  message: {
    error: 'Too many requests from this IP, please try again later.',
    retryAfter: '15 minutes'
  },
  standardHeaders: true,
  legacyHeaders: false
});

const speedLimiter = slowDown({
  windowMs: 15 * 60 * 1000, // 15 minutes
  delayAfter: 50, // allow 50 requests per windowMs without delay
  delayMs: 500 // add 500ms delay per request after delayAfter
});

// Apply rate limiting
app.use(limiter);
app.use(speedLimiter);

// Redis session store
const RedisStore = connectRedis(session);
app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET || 'your-secret-key',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000, // 24 hours
    sameSite: 'strict'
  },
  name: 'tutoring.sid'
}));

// Body parsing and compression
app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging
app.use(morgan('combined', { stream: { write: message => loggingService.info(message.trim()) } }));
app.use(requestLogger);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0'
  });
});

// API Routes
const apiRouter = express.Router();

// Route registry for API Gateway pattern
const routes = [
  { path: '/api/v1/auth', router: authRoutes },
  { path: '/api/v1/users', router: userRoutes },
  { path: '/api/v1/assignments', router: assignmentRoutes },
  { path: '/api/v1/queries', router: queryRoutes },
  { path: '/api/v1/chat', router: chatRoutes },
  { path: '/api/v1/articles', router: articleRoutes },
  { path: '/api/v1/schedule', router: scheduleRoutes },
  { path: '/api/v1/payments', router: paymentRoutes },
  { path: '/api/v1/uploads', router: uploadRoutes },
  { path: '/api/v1/analytics', router: analyticsRoutes }
];

// Register routes with API Gateway pattern
routes.forEach(({ path, router }) => {
  app.use(path, validateRequest, router);
  loggingService.info(`Registered route: ${path}`);
});

// Initialize Socket.IO
const io = new Server(server, {
  cors: {
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
    methods: ['GET', 'POST'],
    credentials: true
  }
});

// Initialize socket service
socketService.initialize(io);

// Error handling middleware (must be last)
app.use(notFound);
app.use(errorHandler);

// Graceful shutdown
process.on('SIGTERM', async () => {
  loggingService.info('SIGTERM received, shutting down gracefully');
  server.close(async () => {
    await redisClient.quit();
    await databaseService.disconnect();
    process.exit(0);
  });
});

process.on('SIGINT', async () => {
  loggingService.info('SIGINT received, shutting down gracefully');
  server.close(async () => {
    await redisClient.quit();
    await databaseService.disconnect();
    process.exit(0);
  });
});

// Start server
const PORT = process.env.PORT || 5000;

server.listen(PORT, async () => {
  try {
    await databaseService.connect();
    await redisClient.connect();
    await socketService.initialize();
    
    loggingService.info(`Server running on port ${PORT}`);
    loggingService.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
    loggingService.info(`Database connected: ${databaseService.isConnected()}`);
    loggingService.info(`Redis connected: ${redisClient.isOpen}`);
    
  } catch (error) {
    loggingService.error('Failed to start server:', error);
    process.exit(1);
  }
});

module.exports = app;