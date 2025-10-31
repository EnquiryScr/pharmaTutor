const Redis = require('redis');
const { logger } = require('../middleware/logger');
const { v4: uuidv4 } = require('uuid');

class RedisService {
  constructor() {
    this.client = null;
    this.isConnected = false;
    this.defaultTTL = 3600; // 1 hour
    this.prefix = 'tutoring:';
  }

  async connect() {
    try {
      this.client = Redis.createClient({
        host: process.env.REDIS_HOST || 'localhost',
        port: process.env.REDIS_PORT || 6379,
        password: process.env.REDIS_PASSWORD || null,
        db: process.env.REDIS_DB || 0,
        
        retry_strategy: (options) => {
          if (options.error && options.error.code === 'ECONNREFUSED') {
            return new Error('Redis server refused connection');
          }
          if (options.total_retry_time > 1000 * 60 * 60) {
            return new Error('Retry time exhausted');
          }
          if (options.attempt > 10) {
            return undefined;
          }
          return Math.min(options.attempt * 100, 3000);
        },
        
        retry_delay_on_failover: 100,
        enable_offline_queue: false
      });

      this.client.on('connect', () => {
        logger.info('Redis connected successfully');
        this.isConnected = true;
      });

      this.client.on('error', (error) => {
        logger.error('Redis connection error:', error);
        this.isConnected = false;
      });

      this.client.on('end', () => {
        logger.info('Redis connection ended');
        this.isConnected = false;
      });

      this.client.on('reconnecting', () => {
        logger.info('Redis reconnecting...');
      });

      await this.client.connect();
      
    } catch (error) {
      logger.error('Failed to connect to Redis:', error);
      throw error;
    }
  }

  async disconnect() {
    try {
      if (this.client) {
        await this.client.quit();
        this.isConnected = false;
        logger.info('Redis disconnected successfully');
      }
    } catch (error) {
      logger.error('Error disconnecting from Redis:', error);
      throw error;
    }
  }

  // Basic Redis operations
  async get(key) {
    try {
      if (!this.isConnected) return null;
      
      const fullKey = this.prefix + key;
      const value = await this.client.get(fullKey);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      logger.error('Redis GET error:', error);
      return null;
    }
  }

  async set(key, value, ttl = this.defaultTTL) {
    try {
      if (!this.isConnected) return false;
      
      const fullKey = this.prefix + key;
      const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
      
      if (ttl > 0) {
        await this.client.setEx(fullKey, ttl, stringValue);
      } else {
        await this.client.set(fullKey, stringValue);
      }
      
      return true;
    } catch (error) {
      logger.error('Redis SET error:', error);
      return false;
    }
  }

  async setNX(key, value, ttl = this.defaultTTL) {
    try {
      if (!this.isConnected) return false;
      
      const fullKey = this.prefix + key;
      const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
      
      const result = await this.client.setNX(fullKey, stringValue);
      
      if (result && ttl > 0) {
        await this.client.expire(fullKey, ttl);
      }
      
      return result;
    } catch (error) {
      logger.error('Redis SETNX error:', error);
      return false;
    }
  }

  async del(key) {
    try {
      if (!this.isConnected) return false;
      
      const fullKey = this.prefix + key;
      await this.client.del(fullKey);
      return true;
    } catch (error) {
      logger.error('Redis DEL error:', error);
      return false;
    }
  }

  async exists(key) {
    try {
      if (!this.isConnected) return false;
      
      const fullKey = this.prefix + key;
      const result = await this.client.exists(fullKey);
      return result === 1;
    } catch (error) {
      logger.error('Redis EXISTS error:', error);
      return false;
    }
  }

  async expire(key, ttl) {
    try {
      if (!this.isConnected) return false;
      
      const fullKey = this.prefix + key;
      const result = await this.client.expire(fullKey, ttl);
      return result === 1;
    } catch (error) {
      logger.error('Redis EXPIRE error:', error);
      return false;
    }
  }

  async ttl(key) {
    try {
      if (!this.isConnected) return -1;
      
      const fullKey = this.prefix + key;
      const result = await this.client.ttl(fullKey);
      return result;
    } catch (error) {
      logger.error('Redis TTL error:', error);
      return -1;
    }
  }

  // Hash operations
  async hget(key, field) {
    try {
      if (!this.isConnected) return null;
      
      const fullKey = this.prefix + key;
      const value = await this.client.hGet(fullKey, field);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      logger.error('Redis HGET error:', error);
      return null;
    }
  }

  async hset(key, field, value) {
    try {
      if (!this.isConnected) return false;
      
      const fullKey = this.prefix + key;
      const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
      await this.client.hSet(fullKey, field, stringValue);
      return true;
    } catch (error) {
      logger.error('Redis HSET error:', error);
      return false;
    }
  }

  async hgetall(key) {
    try {
      if (!this.isConnected) return {};
      
      const fullKey = this.prefix + key;
      const hash = await this.client.hGetAll(fullKey);
      
      // Parse JSON values
      const parsed = {};
      for (const [field, value] of Object.entries(hash)) {
        try {
          parsed[field] = JSON.parse(value);
        } catch {
          parsed[field] = value;
        }
      }
      
      return parsed;
    } catch (error) {
      logger.error('Redis HGETALL error:', error);
      return {};
    }
  }

  async hdel(key, field) {
    try {
      if (!this.isConnected) return false;
      
      const fullKey = this.prefix + key;
      await this.client.hDel(fullKey, field);
      return true;
    } catch (error) {
      logger.error('Redis HDEL error:', error);
      return false;
    }
  }

  // List operations
  async lpush(key, value) {
    try {
      if (!this.isConnected) return false;
      
      const fullKey = this.prefix + key;
      const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
      await this.client.lPush(fullKey, stringValue);
      return true;
    } catch (error) {
      logger.error('Redis LPUSH error:', error);
      return false;
    }
  }

  async rpop(key) {
    try {
      if (!this.isConnected) return null;
      
      const fullKey = this.prefix + key;
      const value = await this.client.rPop(fullKey);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      logger.error('Redis RPOP error:', error);
      return null;
    }
  }

  async lrange(key, start, stop) {
    try {
      if (!this.isConnected) return [];
      
      const fullKey = this.prefix + key;
      const values = await this.client.lRange(fullKey, start, stop);
      return values.map(value => {
        try {
          return JSON.parse(value);
        } catch {
          return value;
        }
      });
    } catch (error) {
      logger.error('Redis LRANGE error:', error);
      return [];
    }
  }

  // Set operations
  async sadd(key, member) {
    try {
      if (!this.isConnected) return false;
      
      const fullKey = this.prefix + key;
      const stringMember = typeof member === 'string' ? member : JSON.stringify(member);
      await this.client.sAdd(fullKey, stringMember);
      return true;
    } catch (error) {
      logger.error('Redis SADD error:', error);
      return false;
    }
  }

  async srem(key, member) {
    try {
      if (!this.isConnected) return false;
      
      const fullKey = this.prefix + key;
      const stringMember = typeof member === 'string' ? member : JSON.stringify(member);
      await this.client.sRem(fullKey, stringMember);
      return true;
    } catch (error) {
      logger.error('Redis SREM error:', error);
      return false;
    }
  }

  async smembers(key) {
    try {
      if (!this.isConnected) return [];
      
      const fullKey = this.prefix + key;
      const members = await this.client.sMembers(fullKey);
      return members.map(member => {
        try {
          return JSON.parse(member);
        } catch {
          return member;
        }
      });
    } catch (error) {
      logger.error('Redis SMEMBERS error:', error);
      return [];
    }
  }

  // Session management
  async createSession(sessionId, userData, ttl = 86400) { // 24 hours default
    const key = `session:${sessionId}`;
    return await this.set(key, userData, ttl);
  }

  async getSession(sessionId) {
    const key = `session:${sessionId}`;
    return await this.get(key);
  }

  async destroySession(sessionId) {
    const key = `session:${sessionId}`;
    return await this.del(key);
  }

  async extendSession(sessionId, ttl = 86400) {
    const key = `session:${sessionId}`;
    return await this.expire(key, ttl);
  }

  // User online status
  async setUserOnline(userId, socketId) {
    const userOnlineKey = `user:online:${userId}`;
    const socketUserKey = `socket:user:${socketId}`;
    
    const userData = {
      userId,
      socketId,
      onlineAt: new Date().toISOString()
    };
    
    await Promise.all([
      this.set(userOnlineKey, userData, 3600), // 1 hour TTL
      this.set(socketUserKey, userData, 3600)  // 1 hour TTL
    ]);
  }

  async setUserOffline(userId, socketId) {
    const userOnlineKey = `user:online:${userId}`;
    const socketUserKey = `socket:user:${socketId}`;
    
    await Promise.all([
      this.del(userOnlineKey),
      this.del(socketUserKey)
    ]);
  }

  async isUserOnline(userId) {
    const userOnlineKey = `user:online:${userId}`;
    return await this.exists(userOnlineKey);
  }

  async getOnlineUsers() {
    try {
      if (!this.isConnected) return [];
      
      const keys = await this.client.keys(this.prefix + 'user:online:*');
      const users = [];
      
      for (const key of keys) {
        const userData = await this.client.get(key);
        if (userData) {
          users.push(JSON.parse(userData));
        }
      }
      
      return users;
    } catch (error) {
      logger.error('Error getting online users:', error);
      return [];
    }
  }

  // Caching patterns
  async cacheGetOrSet(key, fetcherFn, ttl = this.defaultTTL) {
    try {
      // Try to get from cache first
      let data = await this.get(key);
      
      if (data === null) {
        // Cache miss, fetch from data source
        data = await fetcherFn();
        
        // Cache the result
        if (data !== null) {
          await this.set(key, data, ttl);
        }
      }
      
      return data;
    } catch (error) {
      logger.error('Cache get or set error:', error);
      // If cache fails, just fetch from data source
      return await fetcherFn();
    }
  }

  async invalidatePattern(pattern) {
    try {
      if (!this.isConnected) return;
      
      const fullPattern = this.prefix + pattern;
      const keys = await this.client.keys(fullPattern);
      
      if (keys.length > 0) {
        await this.client.del(keys);
      }
      
      return keys.length;
    } catch (error) {
      logger.error('Error invalidating pattern:', error);
      return 0;
    }
  }

  // Rate limiting
  async checkRateLimit(key, limit, window) {
    try {
      const fullKey = `rate_limit:${key}`;
      const current = await this.client.incr(fullKey);
      
      if (current === 1) {
        await this.client.expire(fullKey, window);
      }
      
      return {
        allowed: current <= limit,
        current,
        remaining: Math.max(0, limit - current)
      };
    } catch (error) {
      logger.error('Rate limiting error:', error);
      return { allowed: true, current: 0, remaining: limit };
    }
  }

  // Real-time features
  async storeMessage(messageId, messageData, ttl = 604800) { // 7 days default
    const key = `message:${messageId}`;
    return await this.set(key, messageData, ttl);
  }

  async getMessage(messageId) {
    const key = `message:${messageId}`;
    return await this.get(key);
  }

  async addToConversation(conversationId, messageId, ttl = 2592000) { // 30 days default
    const key = `conversation:${conversationId}`;
    await this.lpush(key, messageId);
    await this.expire(key, ttl);
  }

  async getConversationHistory(conversationId, limit = 50) {
    const key = `conversation:${conversationId}`;
    return await this.lrange(key, 0, limit - 1);
  }

  // Analytics and tracking
  async incrementCounter(key, amount = 1) {
    try {
      if (!this.isConnected) return 0;
      
      const fullKey = this.prefix + `counter:${key}`;
      const result = await this.client.incrBy(fullKey, amount);
      return result;
    } catch (error) {
      logger.error('Counter increment error:', error);
      return 0;
    }
  }

  async getCounter(key) {
    try {
      if (!this.isConnected) return 0;
      
      const fullKey = this.prefix + `counter:${key}`;
      const result = await this.client.get(fullKey);
      return result ? parseInt(result, 10) : 0;
    } catch (error) {
      logger.error('Counter get error:', error);
      return 0;
    }
  }

  // Health check
  async healthCheck() {
    try {
      if (!this.isConnected) return false;
      
      const result = await this.client.ping();
      return result === 'PONG';
    } catch (error) {
      logger.error('Redis health check failed:', error);
      return false;
    }
  }

  // Cleanup expired keys
  async cleanupExpired() {
    try {
      if (!this.isConnected) return;
      
      const info = await this.client.info('keyspace');
      logger.info('Redis keyspace info:', info);
    } catch (error) {
      logger.error('Error cleaning up Redis:', error);
    }
  }

  // Get Redis info
  async getInfo() {
    try {
      if (!this.isConnected) return {};
      
      const info = await this.client.info();
      const lines = info.split('\r\n').filter(line => line && !line.startsWith('#'));
      const infoObj = {};
      
      lines.forEach(line => {
        const [key, value] = line.split(':');
        if (key && value) {
          infoObj[key] = value;
        }
      });
      
      return infoObj;
    } catch (error) {
      logger.error('Error getting Redis info:', error);
      return {};
    }
  }
}

module.exports = RedisService;