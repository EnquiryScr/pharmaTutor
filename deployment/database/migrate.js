#!/usr/bin/env node

/**
 * Database Migration Manager
 * Handles database schema updates, data migrations, and rollback procedures
 */

const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const { promisify } = require('util');
const readdir = promisify(fs.readdir);
const readFile = promisify(fs.readFile);

class MigrationManager {
  constructor(config = {}) {
    this.pool = new Pool({
      host: config.host || process.env.DB_HOST || 'localhost',
      port: config.port || process.env.DB_PORT || 5432,
      database: config.database || process.env.DB_NAME || 'tutoring_db',
      user: config.user || process.env.DB_USER || 'tutoring_user',
      password: config.password || process.env.DB_PASSWORD,
      ssl: config.ssl || false,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    this.migrationsDir = path.join(__dirname, '../database/migrations');
    this.migrationTable = 'schema_migrations';
  }

  async connect() {
    await this.pool.connect();
    console.log('✅ Connected to database');
  }

  async disconnect() {
    await this.pool.end();
    console.log('✅ Disconnected from database');
  }

  async createMigrationTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS ${this.migrationTable} (
        id SERIAL PRIMARY KEY,
        version VARCHAR(255) UNIQUE NOT NULL,
        description TEXT,
        script TEXT NOT NULL,
        executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        execution_time INTEGER,
        success BOOLEAN DEFAULT TRUE,
        error_message TEXT
      );
    `;
    
    await this.pool.query(query);
    console.log(`✅ Migration table '${this.migrationTable}' ready`);
  }

  async getExecutedMigrations() {
    const query = `SELECT version FROM ${this.migrationTable} ORDER BY version`;
    const result = await this.pool.query(query);
    return result.rows.map(row => row.version);
  }

  async getPendingMigrations() {
    const executed = await this.getExecutedMigrations();
    const files = await readdir(this.migrationsDir);
    
    const migrationFiles = files
      .filter(file => file.endsWith('.sql') || file.endsWith('.js'))
      .sort()
      .filter(file => !executed.includes(path.basename(file, path.extname(file))));

    return migrationFiles;
  }

  async executeMigration(migrationFile) {
    const migrationName = path.basename(migrationFile, path.extname(migrationFile));
    const script = await readFile(path.join(this.migrationsDir, migrationFile), 'utf8');
    
    console.log(`🔄 Executing migration: ${migrationName}`);
    const startTime = Date.now();
    
    const client = await this.pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // Execute the migration script
      if (migrationFile.endsWith('.sql')) {
        await client.query(script);
      } else if (migrationFile.endsWith('.js')) {
        // For JavaScript migrations, require and execute
        const migration = require(path.join(this.migrationsDir, migrationFile));
        if (typeof migration.up === 'function') {
          await migration.up(client);
        }
      }
      
      // Record the migration
      const executionTime = Date.now() - startTime;
      const insertQuery = `
        INSERT INTO ${this.migrationTable} (version, description, script, execution_time, success)
        VALUES ($1, $2, $3, $4, $5)
      `;
      
      await client.query(insertQuery, [
        migrationName,
        this.getDescription(migrationFile),
        script,
        executionTime,
        true
      ]);
      
      await client.query('COMMIT');
      console.log(`✅ Migration completed: ${migrationName} (${executionTime}ms)`);
      
    } catch (error) {
      await client.query('ROLLBACK');
      
      // Record the failed migration
      const executionTime = Date.now() - startTime;
      const insertQuery = `
        INSERT INTO ${this.migrationTable} (version, description, script, execution_time, success, error_message)
        VALUES ($1, $2, $3, $4, $5, $6)
      `;
      
      await client.query(insertQuery, [
        migrationName,
        this.getDescription(migrationFile),
        script,
        executionTime,
        false,
        error.message
      ]);
      
      console.error(`❌ Migration failed: ${migrationName}`, error.message);
      throw error;
    } finally {
      client.release();
    }
  }

  getDescription(migrationFile) {
    // Extract description from filename or first comment line
    const name = path.basename(migrationFile, path.extname(migrationFile));
    // Convention: YYYYMMDD_HHMMSS_description.sql
    const parts = name.split('_');
    if (parts.length > 2) {
      return parts.slice(2).join(' ').replace(/-/g, ' ');
    }
    return name;
  }

  async runPendingMigrations() {
    await this.createMigrationTable();
    const pendingMigrations = await this.getPendingMigrations();
    
    if (pendingMigrations.length === 0) {
      console.log('✅ No pending migrations');
      return;
    }

    console.log(`📋 Found ${pendingMigrations.length} pending migrations`);
    
    for (const migration of pendingMigrations) {
      try {
        await this.executeMigration(migration);
      } catch (error) {
        console.error('🚨 Migration process stopped due to error');
        process.exit(1);
      }
    }
    
    console.log('🎉 All migrations completed successfully');
  }

  async rollbackMigration(version) {
    const client = await this.pool.connect();
    
    try {
      // Get the migration record
      const selectQuery = `SELECT script FROM ${this.migrationTable} WHERE version = $1`;
      const result = await client.query(selectQuery, [version]);
      
      if (result.rows.length === 0) {
        throw new Error(`Migration ${version} not found`);
      }
      
      const migrationScript = result.rows[0].script;
      
      // For rollback, we need to create a down migration
      // This is a simplified approach - in practice, you'd want proper down scripts
      console.log(`⚠️  Rollback for ${version} requires manual review and execution`);
      console.log('Please create and run a down migration script manually.');
      
    } catch (error) {
      console.error('❌ Rollback failed:', error.message);
      throw error;
    } finally {
      client.release();
    }
  }

  async getMigrationStatus() {
    await this.createMigrationTable();
    
    const query = `
      SELECT 
        version,
        executed_at,
        execution_time,
        success,
        error_message,
        description
      FROM ${this.migrationTable}
      ORDER BY executed_at DESC
    `;
    
    const result = await this.pool.query(query);
    return result.rows;
  }

  async seedDatabase() {
    const seedFiles = await readdir(path.join(__dirname, '../database/seeds'));
    
    for (const seedFile of seedFiles.sort()) {
      if (seedFile.endsWith('.sql')) {
        console.log(`🌱 Seeding with: ${seedFile}`);
        const seedScript = await readFile(path.join(__dirname, '../database/seeds', seedFile), 'utf8');
        await this.pool.query(seedScript);
      }
    }
    
    console.log('✅ Database seeding completed');
  }
}

// CLI Interface
async function main() {
  const command = process.argv[2];
  const migrationManager = new MigrationManager();
  
  try {
    await migrationManager.connect();
    
    switch (command) {
      case 'migrate':
        await migrationManager.runPendingMigrations();
        break;
        
      case 'seed':
        await migrationManager.seedDatabase();
        break;
        
      case 'status':
        const status = await migrationManager.getMigrationStatus();
        console.log('\n📊 Migration Status:');
        console.table(status);
        break;
        
      case 'rollback':
        const version = process.argv[3];
        if (!version) {
          console.error('❌ Please specify migration version to rollback');
          process.exit(1);
        }
        await migrationManager.rollbackMigration(version);
        break;
        
      default:
        console.log(`
🔧 Database Migration Manager

Usage:
  node migrate.js migrate    - Run pending migrations
  node migrate.js seed       - Seed database with initial data
  node migrate.js status     - Show migration status
  node migrate.js rollback <version> - Rollback specific migration

Examples:
  node migrate.js migrate
  node migrate.js status
  node migrate.js rollback 20240101000001_initial_schema
        `);
    }
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  } finally {
    await migrationManager.disconnect();
  }
}

if (require.main === module) {
  main();
}

module.exports = MigrationManager;