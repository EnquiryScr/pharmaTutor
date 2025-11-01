/**
 * Advanced Rate Limiting with Multiple Strategies
 * Implements sliding window, fixed window, and token bucket algorithms
 */

const Redis = require('redis');
const { createHash } = require('crypto');

class AdvancedRateLimiter {
  constructor() {
    this.redisClient = null;
    this.strategies = {
      sliding: 'sliding',
      fixed: 'fixed',
      tokenBucket: 'token_bucket'
    };
    this.configs = new Map();
  }

  async initialize() {
    this.redisClient = Redis.createClient({
      host: process.env.REDIS_HOST || 'localhost',
      port: process.env.REDIS_PORT || 6379,
      password: process.env.REDIS_PASSWORD
    });
    
    await this.redisClient.connect();
    console.log('✅ Advanced Rate Limiter initialized');
  }

  // Sliding window rate limiting
  slidingWindowRateLimit(options = {}) {
    const {
      windowMs = 60000, // 1 minute
      max = 100, // requests per window
      keyGenerator = (req) => req.ip,
      skipSuccessfulRequests = false,
      skipFailedRequests = false,
      skip = (req) => false,
      onLimitReached = (req, res, optionsUsed) => {
        res.status(429).json({
          error: 'Rate limit exceeded',
          retryAfter: Math.ceil(optionsUsed.windowMs / 1000)
        });
      }
    } = options;

    return async (req, res, next) => {
      if (skip(req)) return next();

      try {
        const key = `rate_limit:sliding:${keyGenerator(req)}`;
        const now = Date.now();
        const windowStart = now - windowMs;

        // Remove old entries from sorted set
        await this.redisClient.zRemRangeByScore(key, '-inf', windowStart);
        
        // Count current requests in window
        const currentRequests = await this.redisClient.zCard(key);
        
        if (currentRequests >= max) {
          onLimitReached(req, res, { windowMs, max });
          return;
        }

        // Track this request
        const member = `${now}:${Math.random()}`;
        await this.redisClient.zAdd(key, [{ score: now, value: member }]);
        await this.redisClient.expire(key, Math.ceil(windowMs / 1000));

        next();
      } catch (error) {
        console.error('Rate limiting error:', error);
        next(); // Fail open on Redis errors
      }
    };
  }

  // Fixed window rate limiting
  fixedWindowRateLimit(options = {}) {
    const {
      windowMs = 60000,
      max = 100,
      keyGenerator = (req) => req.ip,
      skipSuccessfulRequests = false,
      skipFailedRequests = false,
      skip = (req) => false,
      onLimitReached = (req, res, optionsUsed) => {
        res.status(429).json({
          error: 'Rate limit exceeded',
          retryAfter: Math.ceil(optionsUsed.windowMs / 1000)
        });
      }
    } = options;

    return async (req, res, next) => {
      if (skip(req)) return next();

      try {
        const key = `rate_limit:fixed:${keyGenerator(req)}:${Math.floor(Date.now() / windowMs)}`;
        const current = await this.redisClient.incr(key);
        
        if (current === 1) {
          await this.redisClient.expire(key, Math.ceil(windowMs / 1000));
        }

        if (current > max) {
          onLimitReached(req, res, { windowMs, max });
          return;
        }

        // Track successful/failed attempts for conditional limiting
        if (skipSuccessfulRequests || skipFailedRequests) {
          req.rateLimit = {
            current,
            limit: max
          };
        }

        next();
      } catch (error) {
        console.error('Rate limiting error:', error);
        next();
      }
    };
  }

  // Token bucket algorithm
  tokenBucketRateLimit(options = {}) {
    const {
      capacity = 100, // bucket capacity
      refillRate = 1, // tokens per refillPeriod
      refillPeriod = 1000, // milliseconds
      keyGenerator = (req) => req.ip,
      skip = (req) => false,
      onLimitReached = (req, res) => {
        res.status(429).json({
          error: 'Rate limit exceeded',
          retryAfter: Math.ceil(refillPeriod / 1000)
        });
      }
    } = options;

    return async (req, res, next) => {
      if (skip(req)) return next();

      try {
        const key = `rate_limit:bucket:${keyGenerator(req)}`;
        const now = Date.now();
        
        // Get current bucket state
        const bucketState = await this.redisClient.hmGet(key, 'tokens', 'lastRefill');
        let tokens = parseInt(bucketState[0]) || capacity;
        const lastRefill = parseInt(bucketState[1]) || now;
        
        // Calculate tokens to add based on time elapsed
        const timeElapsed = now - lastRefill;
        const tokensToAdd = Math.floor(timeElapsed / refillPeriod) * refillRate;
        tokens = Math.min(capacity, tokens + tokensToAdd);
        
        if (tokens >= 1) {
          // Consume a token
          await this.redisClient.hMSet(key, {
            tokens: tokens - 1,
            lastRefill: now
          });
          await this.redisClient.expire(key, Math.ceil((refillPeriod * capacity) / 1000));
          next();
        } else {
          onLimitReached(req, res);
        }
      } catch (error) {
        console.error('Token bucket error:', error);
        next();
      }
    };
  }

  // User-specific rate limiting
  userRateLimit(options = {}) {
    const {
      windowMs = 3600000, // 1 hour
      max = 1000, // requests per hour
      skip = (req) => !req.user,
      onLimitReached = (req, res) => {
        res.status(429).json({
          error: 'User rate limit exceeded',
          retryAfter: Math.ceil(windowMs / 1000)
        });
      }
    } = options;

    return this.slidingWindowRateLimit({
      ...options,
      windowMs,
      max,
      keyGenerator: (req) => req.user?.id || 'anonymous',
      skip,
      onLimitReached
    });
  }

  // API endpoint specific rate limiting
  endpointRateLimit(options = {}) {
    const {
      endpoint = '/api',
      windowMs = 60000,
      max = 50,
      skipSuccessfulRequests = false,
      skipFailedRequests = false
    } = options;

    return this.slidingWindowRateLimit({
      ...options,
      windowMs,
      max,
      keyGenerator: (req) => `${req.ip}:${req.route?.path || req.path}`,
      onLimitReached: (req, res) => {
        console.warn(`Rate limit exceeded for ${req.ip} on ${req.path}`);
        res.status(429).json({
          error: 'Endpoint rate limit exceeded',
          endpoint: req.path,
          retryAfter: Math.ceil(windowMs / 1000)
        });
      }
    });
  }

  // Email/SMS rate limiting
  communicationRateLimit(options = {}) {
    const {
      type = 'email', // 'email' or 'sms'
      windowMs = 3600000, // 1 hour
      max = 5,
      skipSuccessfulRequests = false,
      skipFailedRequests = false
    } = options;

    return this.fixedWindowRateLimit({
      ...options,
      windowMs,
      max,
      keyGenerator: (req) => `${type}:${req.user?.email || req.user?.phone || req.ip}`,
      onLimitReached: (req, res) => {
        res.status(429).json({
          error: `${type} rate limit exceeded`,
          retryAfter: Math.ceil(windowMs / 1000)
        });
      }
    });
  }

  // Authentication attempt rate limiting
  authRateLimit(options = {}) {
    const {
      windowMs = 900000, // 15 minutes
      max = 5,
      skipSuccessfulRequests = true,
      skipFailedRequests = false
    } = options;

    return this.slidingWindowRateLimit({
      ...options,
      windowMs,
      max,
      keyGenerator: (req) => `auth:${req.ip}:${req.body?.email || req.body?.username || 'unknown'}`,
      skipSuccessfulRequests,
      skipFailedRequests,
      onLimitReached: (req, res) => {
        res.status(429).json({
          error: 'Too many authentication attempts',
          retryAfter: Math.ceil(windowMs / 1000)
        });
      }
    });
  }

  // File upload rate limiting
  uploadRateLimit(options = {}) {
    const {
      windowMs = 3600000, // 1 hour
      max = 10,
      maxFileSize = 10485760 // 10MB
    } = options;

    return this.slidingWindowRateLimit({
      ...options,
      windowMs,
      max,
      keyGenerator: (req) => `upload:${req.user?.id || req.ip}`,
      onLimitReached: (req, res) => {
        res.status(429).json({
          error: 'Upload rate limit exceeded',
          retryAfter: Math.ceil(windowMs / 1000)
        });
      }
    });
  }

  // Distributed rate limiting using Redis
  async getRateLimitStatus(key, windowMs, max) {
    try {
      const windowStart = Date.now() - windowMs;
      const count = await this.redisClient.zCount(`rate_limit:sliding:${key}`, windowStart, Date.now());
      return {
        current: count,
        limit: max,
        remaining: Math.max(0, max - count),
        resetTime: new Date(Date.now() + windowMs)
      };
    } catch (error) {
      console.error('Error getting rate limit status:', error);
      return null;
    }
  }

  // Clean up expired rate limit data
  async cleanup() {
    try {
      const keys = await this.redisClient.keys('rate_limit:*');
      if (keys.length > 0) {
        await this.redisClient.del(keys);
      }
      console.log('Rate limiter cleanup completed');
    } catch (error) {
      console.error('Error during rate limiter cleanup:', error);
    }
  }

  // Main middleware method
  middleware(options = {}) {
    return this.slidingWindowRateLimit(options);
  }
}

module.exports = {
  AdvancedRateLimiter
};