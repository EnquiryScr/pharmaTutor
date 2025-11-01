const { Pool } = require('pg');
const Redis = require('redis');
const { logger } = require('../middleware/logger');
const fs = require('fs').promises;
const path = require('path');

class DatabaseService {
  constructor() {
    // PostgreSQL connection pool
    this.pgPool = new Pool({
      host: process.env.POSTGRES_HOST || 'localhost',
      port: process.env.POSTGRES_PORT || 5432,
      database: process.env.POSTGRES_DB || 'tutoring_platform',
      user: process.env.POSTGRES_USER || 'postgres',
      password: process.env.POSTGRES_PASSWORD || 'password',
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    // Redis client
    this.redisClient = Redis.createClient({
      host: process.env.REDIS_HOST || 'localhost',
      port: process.env.REDIS_PORT || 6379,
      password: process.env.REDIS_PASSWORD || null,
      retry_strategy: (options) => {
        if (options.error && options.error.code === 'ECONNREFUSED') {
          return new Error('The server refused the connection');
        }
        if (options.total_retry_time > 1000 * 60 * 60) {
          return new Error('Retry time exhausted');
        }
        if (options.attempt > 10) {
          return undefined;
        }
        return Math.min(options.attempt * 100, 3000);
      }
    });

    this.isConnected = false;
    this.queries = {
      // User queries
      users: {
        create: 'INSERT INTO users (id, email, password, first_name, last_name, role, phone, bio, subjects, timezone, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW(), NOW()) RETURNING *',
        findById: 'SELECT * FROM users WHERE id = $1',
        findByEmail: 'SELECT * FROM users WHERE email = $1',
        findAll: 'SELECT * FROM users WHERE role = $1 AND is_active = true ORDER BY created_at DESC LIMIT $2 OFFSET $3',
        update: 'UPDATE users SET first_name = $2, last_name = $3, phone = $4, bio = $5, subjects = $6, timezone = $7, updated_at = NOW() WHERE id = $1 RETURNING *',
        updatePassword: 'UPDATE users SET password = $2, updated_at = NOW() WHERE id = $1',
        deactivate: 'UPDATE users SET is_active = false, updated_at = NOW() WHERE id = $1',
        activate: 'UPDATE users SET is_active = true, updated_at = NOW() WHERE id = $1',
        search: 'SELECT * FROM users WHERE (first_name ILIKE $1 OR last_name ILIKE $1 OR email ILIKE $1) AND role = $2 AND is_active = true ORDER BY created_at DESC LIMIT $3 OFFSET $4'
      },

      // Assignment queries
      assignments: {
        create: 'INSERT INTO assignments (id, tutor_id, title, description, subject, grade_level, deadline, attachments, status, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW()) RETURNING *',
        findById: 'SELECT * FROM assignments WHERE id = $1',
        findByTutor: 'SELECT * FROM assignments WHERE tutor_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
        findByStudent: 'SELECT * FROM assignments WHERE student_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
        submit: 'UPDATE assignments SET student_id = $2, submission_content = $3, submission_attachments = $4, submitted_at = NOW(), status = $5 WHERE id = $1 RETURNING *',
        grade: 'UPDATE assignments SET grade = $2, feedback = $3, rubric_scores = $4, graded_at = NOW(), status = $5 WHERE id = $1 RETURNING *',
        update: 'UPDATE assignments SET title = $2, description = $3, subject = $4, grade_level = $5, deadline = $6, attachments = $7, updated_at = NOW() WHERE id = $1 RETURNING *',
        delete: 'DELETE FROM assignments WHERE id = $1',
        search: 'SELECT * FROM assignments WHERE title ILIKE $1 OR description ILIKE $1 OR subject ILIKE $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3'
      },

      // Query/Ticket queries
      queries: {
        create: 'INSERT INTO queries (id, user_id, subject, description, priority, category, status, attachments, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW()) RETURNING *',
        findById: 'SELECT * FROM queries WHERE id = $1',
        findByUser: 'SELECT * FROM queries WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
        findAll: 'SELECT * FROM queries WHERE status = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
        update: 'UPDATE queries SET subject = $2, description = $3, priority = $4, category = $5, status = $6, assigned_to = $7, resolution = $8, updated_at = NOW() WHERE id = $1 RETURNING *',
        addComment: 'INSERT INTO query_comments (id, query_id, user_id, comment, created_at) VALUES ($1, $2, $3, $4, NOW()) RETURNING *'
      },

      // Chat queries
      chat: {
        sendMessage: 'INSERT INTO messages (id, sender_id, recipient_id, room_id, message, message_type, attachments, sent_at) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW()) RETURNING *',
        findConversation: 'SELECT * FROM messages WHERE (sender_id = $1 AND recipient_id = $2) OR (sender_id = $2 AND recipient_id = $1) ORDER BY sent_at ASC LIMIT $3 OFFSET $4',
        findRoomMessages: 'SELECT * FROM messages WHERE room_id = $1 ORDER BY sent_at ASC LIMIT $2 OFFSET $3',
        createRoom: 'INSERT INTO chat_rooms (id, name, type, participants, created_by, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, NOW(), NOW()) RETURNING *',
        findRoom: 'SELECT * FROM chat_rooms WHERE id = $1',
        updateRoom: 'UPDATE chat_rooms SET name = $2, participants = $3, updated_at = NOW() WHERE id = $1 RETURNING *'
      },

      // Article queries
      articles: {
        create: 'INSERT INTO articles (id, author_id, title, content, summary, tags, category, difficulty_level, estimated_read_time, views, likes, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 0, 0, NOW(), NOW()) RETURNING *',
        findById: 'SELECT * FROM articles WHERE id = $1',
        findAll: 'SELECT * FROM articles WHERE is_published = true ORDER BY created_at DESC LIMIT $1 OFFSET $2',
        findByCategory: 'SELECT * FROM articles WHERE category = $1 AND is_published = true ORDER BY created_at DESC LIMIT $2 OFFSET $3',
        search: 'SELECT * FROM articles WHERE (title ILIKE $1 OR content ILIKE $1 OR tags::text ILIKE $1) AND is_published = true ORDER BY created_at DESC LIMIT $2 OFFSET $3',
        update: 'UPDATE articles SET title = $2, content = $3, summary = $4, tags = $5, category = $6, difficulty_level = $7, estimated_read_time = $8, is_published = $9, updated_at = NOW() WHERE id = $1 RETURNING *',
        incrementViews: 'UPDATE articles SET views = views + 1 WHERE id = $1',
        incrementLikes: 'UPDATE articles SET likes = likes + 1 WHERE id = $1'
      },

      // Schedule queries
      schedules: {
        createAppointment: 'INSERT INTO appointments (id, student_id, tutor_id, subject, start_time, end_time, status, notes, meeting_link, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW()) RETURNING *',
        findById: 'SELECT * FROM appointments WHERE id = $1',
        findByStudent: 'SELECT * FROM appointments WHERE student_id = $1 ORDER BY start_time ASC LIMIT $2 OFFSET $3',
        findByTutor: 'SELECT * FROM appointments WHERE tutor_id = $1 ORDER BY start_time ASC LIMIT $2 OFFSET $3',
        update: 'UPDATE appointments SET subject = $2, start_time = $3, end_time = $4, status = $5, notes = $6, meeting_link = $7, updated_at = NOW() WHERE id = $1 RETURNING *',
        updateStatus: 'UPDATE appointments SET status = $2, updated_at = NOW() WHERE id = $1 RETURNING *',
        getAvailability: 'SELECT * FROM availability WHERE tutor_id = $1 AND date = $2'
      },

      // Payment queries
      payments: {
        create: 'INSERT INTO payments (id, user_id, amount, currency, status, payment_method, metadata, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW()) RETURNING *',
        findById: 'SELECT * FROM payments WHERE id = $1',
        findByUser: 'SELECT * FROM payments WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
        updateStatus: 'UPDATE payments SET status = $2, payment_intent_id = $3, updated_at = NOW() WHERE id = $1 RETURNING *'
      }
    };

    this.initializeDatabase();
  }

  async initializeDatabase() {
    try {
      await this.createTables();
      await this.createIndexes();
      logger.info('Database initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize database:', error);
      throw error;
    }
  }

  async connect() {
    try {
      // Connect to PostgreSQL
      await this.pgPool.connect();
      this.isConnected = true;
      
      // Connect to Redis
      await this.redisClient.connect();
      
      logger.info('Database connected successfully');
    } catch (error) {
      logger.error('Failed to connect to database:', error);
      throw error;
    }
  }

  async disconnect() {
    try {
      await this.pgPool.end();
      await this.redisClient.quit();
      this.isConnected = false;
      logger.info('Database disconnected successfully');
    } catch (error) {
      logger.error('Failed to disconnect from database:', error);
      throw error;
    }
  }

  async createTables() {
    const schemaPath = path.join(__dirname, '../schema/database.sql');
    const schema = await fs.readFile(schemaPath, 'utf8');
    await this.pgPool.query(schema);
  }

  async createIndexes() {
    const indexesPath = path.join(__dirname, '../schema/indexes.sql');
    try {
      const indexes = await fs.readFile(indexesPath, 'utf8');
      await this.pgPool.query(indexes);
    } catch (error) {
      // Indexes file might not exist, continue
      logger.warn('Indexes file not found, skipping index creation');
    }
  }

  // PostgreSQL query methods
  async query(text, params) {
    const start = Date.now();
    try {
      const result = await this.pgPool.query(text, params);
      const duration = Date.now() - start;
      
      logger.debug('Executed PostgreSQL query', {
        text: text.split('\n')[0],
        duration,
        rows: result.rowCount
      });
      
      return result;
    } catch (error) {
      logger.error('PostgreSQL query error', {
        text: text.split('\n')[0],
        error: error.message
      });
      throw error;
    }
  }

  async getClient() {
    return await this.pgPool.connect();
  }

  // Redis methods
  async redisGet(key) {
    try {
      const value = await this.redisClient.get(key);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      logger.error('Redis GET error:', error);
      return null;
    }
  }

  async redisSet(key, value, expiry = 3600) {
    try {
      await this.redisClient.setEx(key, expiry, JSON.stringify(value));
      return true;
    } catch (error) {
      logger.error('Redis SET error:', error);
      return false;
    }
  }

  async redisDelete(key) {
    try {
      await this.redisClient.del(key);
      return true;
    } catch (error) {
      logger.error('Redis DELETE error:', error);
      return false;
    }
  }

  // Cache methods
  async getCached(key, queryFn, expiry = 3600) {
    try {
      // Try to get from cache first
      const cached = await this.redisGet(key);
      if (cached) {
        return cached;
      }

      // If not in cache, execute query
      const result = await queryFn();
      
      // Cache the result
      await this.redisSet(key, result, expiry);
      
      return result;
    } catch (error) {
      logger.error('Cache operation error:', error);
      // If cache fails, just execute query
      return await queryFn();
    }
  }

  async invalidateCache(pattern) {
    try {
      const keys = await this.redisClient.keys(pattern);
      if (keys.length > 0) {
        await this.redisClient.del(keys);
      }
      return true;
    } catch (error) {
      logger.error('Cache invalidation error:', error);
      return false;
    }
  }

  // Transaction methods
  async transaction(callback) {
    const client = await this.getClient();
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

module.exports = DatabaseService;