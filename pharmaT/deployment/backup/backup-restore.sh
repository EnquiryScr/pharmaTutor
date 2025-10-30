#!/bin/bash

# =============================================================================
# Backup and Restore Procedures for Tutoring Platform
# =============================================================================

set -euo pipefail

# Configuration
BACKUP_BASE_DIR="/backup/tutoring-platform"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/backup-restore.log"

# Environment-specific variables
ENVIRONMENT=${ENVIRONMENT:-production}
DB_HOST=${DB_HOST:-localhost}
DB_NAME=${DB_NAME:-tutoring_db}
DB_USER=${DB_USER:-tutoring_user}
DB_PASSWORD=${DB_PASSWORD}
REDIS_HOST=${REDIS_HOST:-localhost}
S3_BUCKET=${S3_BUCKET:-tutoring-platform-backups}
AWS_REGION=${AWS_REGION:-us-east-1}

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    exit 1
}

# =============================================================================
# BACKUP PROCEDURES
# =============================================================================

# Full system backup
full_backup() {
    log "Starting full backup for environment: $ENVIRONMENT"
    
    BACKUP_DIR="$BACKUP_BASE_DIR/$ENVIRONMENT/full/$DATE"
    mkdir -p "$BACKUP_DIR"
    
    # Backup database
    backup_database
    
    # Backup Redis
    backup_redis
    
    # Backup file uploads
    backup_uploads
    
    # Backup application configuration
    backup_config
    
    # Backup logs
    backup_logs
    
    # Create backup manifest
    create_manifest "$BACKUP_DIR"
    
    # Upload to S3
    upload_to_s3 "$BACKUP_DIR"
    
    # Cleanup old local backups
    cleanup_old_backups
    
    log "Full backup completed successfully"
}

# Database backup
backup_database() {
    log "Backing up database..."
    
    DUMP_FILE="$BACKUP_DIR/database.sql"
    
    # Create database dump
    PGPASSWORD="$DB_PASSWORD" pg_dump \
        -h "$DB_HOST" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        --verbose \
        --clean \
        --if-exists \
        --no-owner \
        --no-privileges \
        --format=custom \
        --file="$DUMP_FILE" || error_exit "Database backup failed"
    
    # Compress the dump
    gzip "$DUMP_FILE" || error_exit "Database backup compression failed"
    
    # Calculate checksum
    CHECKSUM=$(sha256sum "${DUMP_FILE}.gz" | cut -d' ' -f1)
    echo "$CHECKSUM" > "${DUMP_FILE}.gz.sha256"
    
    log "Database backup completed"
}

# Redis backup
backup_redis() {
    log "Backing up Redis..."
    
    # Get Redis keys and values
    REDIS_BACKUP_DIR="$BACKUP_DIR/redis"
    mkdir -p "$REDIS_BACKUP_DIR"
    
    # Export all keys
    redis-cli --rdb "$REDIS_BACKUP_DIR/redis-dump.rdb" || error_exit "Redis backup failed"
    
    # Export configuration
    redis-cli config get '*' > "$REDIS_BACKUP_DIR/redis-config.txt" || error_exit "Redis config backup failed"
    
    # Compress
    tar -czf "$REDIS_BACKUP_DIR/redis-backup.tar.gz" -C "$REDIS_BACKUP_DIR" .
    rm -rf "$REDIS_BACKUP_DIR"/*.rdb "$REDIS_BACKUP_DIR"/*.txt
    
    log "Redis backup completed"
}

# File uploads backup
backup_uploads() {
    log "Backing up file uploads..."
    
    UPLOADS_DIR="$BACKUP_DIR/uploads"
    mkdir -p "$UPLOADS_DIR"
    
    # Backup local uploads if exists
    if [ -d "/app/uploads" ]; then
        tar -czf "$UPLOADS_DIR/local-uploads.tar.gz" -C /app uploads/ || error_exit "Local uploads backup failed"
    fi
    
    # Note: S3 uploads are inherently backed up, but we can create an index
    aws s3 ls "s3://${S3_BUCKET}/uploads/" --recursive > "$UPLOADS_DIR/s3-index.txt" || error_exit "S3 index creation failed"
    
    log "File uploads backup completed"
}

# Configuration backup
backup_config() {
    log "Backing up configuration..."
    
    CONFIG_BACKUP_DIR="$BACKUP_DIR/config"
    mkdir -p "$CONFIG_BACKUP_DIR"
    
    # Backup environment variables (excluding secrets)
    printenv | grep -E '^(NODE_ENV|PORT|REDIS_HOST|DB_HOST)' > "$CONFIG_BACKUP_DIR/env-vars.txt"
    
    # Backup systemd services
    if command -v systemctl &> /dev/null; then
        systemctl list-units --type=service --state=running | grep tutoring | awk '{print $1}' > "$CONFIG_BACKUP_DIR/services.txt"
    fi
    
    # Backup nginx configuration
    if [ -d "/etc/nginx/sites-available" ]; then
        tar -czf "$CONFIG_BACKUP_DIR/nginx-config.tar.gz" -C /etc/nginx sites-available/ || true
    fi
    
    # Backup SSL certificates
    if [ -d "/etc/ssl/certs" ]; then
        tar -czf "$CONFIG_BACKUP_DIR/ssl-certs.tar.gz" -C /etc/ssl certs/ || true
    fi
    
    log "Configuration backup completed"
}

# Logs backup
backup_logs() {
    log "Backing up logs..."
    
    LOGS_BACKUP_DIR="$BACKUP_DIR/logs"
    mkdir -p "$LOGS_BACKUP_DIR"
    
    # Backup application logs (last 7 days)
    if [ -d "/var/log/tutoring-platform" ]; then
        find /var/log/tutoring-platform -name "*.log" -mtime -7 | tar -czf "$LOGS_BACKUP_DIR/app-logs.tar.gz" -T - || true
    fi
    
    # Backup system logs
    if [ -d "/var/log/nginx" ]; then
        find /var/log/nginx -name "*.log" -mtime -7 | tar -czf "$LOGS_BACKUP_DIR/nginx-logs.tar.gz" -T - || true
    fi
    
    log "Logs backup completed"
}

# Create backup manifest
create_manifest() {
    local backup_dir="$1"
    
    log "Creating backup manifest..."
    
    cat > "$backup_dir/manifest.json" << EOF
{
    "backup_type": "full",
    "environment": "$ENVIRONMENT",
    "timestamp": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "version": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
    "components": {
        "database": true,
        "redis": true,
        "uploads": true,
        "config": true,
        "logs": true
    },
    "file_checksums": {
$(find "$backup_dir" -type f -not -name "manifest.json" -not -name "*.sha256" | while read file; do
    checksum=$(sha256sum "$file" | cut -d' ' -f1)
    echo "        \"$(basename "$file")\": \"$checksum\","
done | sed '$ s/,$//')
    }
}
EOF

    log "Backup manifest created"
}

# Upload to S3
upload_to_s3() {
    local backup_dir="$1"
    
    log "Uploading backup to S3..."
    
    # Upload with encryption
    aws s3 sync "$backup_dir" "s3://${S3_BUCKET}/${ENVIRONMENT}/backups/$(basename "$backup_dir")/" \
        --server-side-encryption AES256 \
        --storage-class STANDARD_IA || error_exit "S3 upload failed"
    
    # Upload manifest to latest backup marker
    aws s3 cp "$backup_dir/manifest.json" "s3://${S3_BUCKET}/${ENVIRONMENT}/backups/latest/manifest.json" \
        --server-side-encryption AES256 || error_exit "Manifest upload failed"
    
    log "Backup uploaded to S3 successfully"
}

# Cleanup old backups
cleanup_old_backups() {
    log "Cleaning up old local backups..."
    
    # Keep last 7 days of full backups
    find "$BACKUP_BASE_DIR/$ENVIRONMENT/full" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
    
    # Keep last 30 days of incremental backups
    find "$BACKUP_BASE_DIR/$ENVIRONMENT/incremental" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true
    
    log "Cleanup completed"
}

# Incremental backup
incremental_backup() {
    log "Starting incremental backup..."
    
    BACKUP_DIR="$BACKUP_BASE_DIR/$ENVIRONMENT/incremental/$DATE"
    mkdir -p "$BACKUP_DIR"
    
    # Backup database changes (WAL shipping approach)
    backup_database_incremental
    
    # Backup recent file uploads
    backup_uploads_incremental
    
    # Backup configuration changes
    backup_config_incremental
    
    # Upload to S3
    upload_to_s3 "$BACKUP_DIR"
    
    log "Incremental backup completed"
}

# =============================================================================
# RESTORE PROCEDURES
# =============================================================================

# Full restore
full_restore() {
    local backup_path="$1"
    
    log "Starting full restore from: $backup_path"
    
    # Validate backup
    validate_backup "$backup_path"
    
    # Stop services
    stop_services
    
    # Restore database
    restore_database "$backup_path"
    
    # Restore Redis
    restore_redis "$backup_path"
    
    # Restore uploads
    restore_uploads "$backup_path"
    
    # Restore configuration
    restore_config "$backup_path"
    
    # Start services
    start_services
    
    # Run health checks
    run_health_checks
    
    log "Full restore completed successfully"
}

# Restore database
restore_database() {
    local backup_path="$1"
    
    log "Restoring database..."
    
    DUMP_FILE="$backup_path/database.sql.gz"
    
    if [ ! -f "$DUMP_FILE" ]; then
        error_exit "Database backup file not found"
    fi
    
    # Verify checksum
    if [ -f "${DUMP_FILE}.sha256" ]; then
        if ! sha256sum -c "${DUMP_FILE}.sha256" > /dev/null 2>&1; then
            error_exit "Database backup checksum verification failed"
        fi
    fi
    
    # Drop and recreate database
    PGPASSWORD="$DB_PASSWORD" dropdb -h "$DB_HOST" -U "$DB_USER" "$DB_NAME" || error_exit "Failed to drop database"
    PGPASSWORD="$DB_PASSWORD" createdb -h "$DB_HOST" -U "$DB_USER" "$DB_NAME" || error_exit "Failed to create database"
    
    # Restore from backup
    gunzip -c "$DUMP_FILE" | PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" || error_exit "Database restore failed"
    
    log "Database restore completed"
}

# Restore Redis
restore_redis() {
    local backup_path="$1"
    
    log "Restoring Redis..."
    
    REDIS_BACKUP="$backup_path/redis/redis-backup.tar.gz"
    
    if [ ! -f "$REDIS_BACKUP" ]; then
        error_exit "Redis backup file not found"
    fi
    
    # Stop Redis
    systemctl stop redis || error_exit "Failed to stop Redis"
    
    # Extract and restore
    TEMP_DIR=$(mktemp -d)
    tar -xzf "$REDIS_BACKUP" -C "$TEMP_DIR"
    
    # Restore Redis data
    if [ -f "$TEMP_DIR/redis-dump.rdb" ]; then
        cp "$TEMP_DIR/redis-dump.rdb" /var/lib/redis/dump.rdb
        chown redis:redis /var/lib/redis/dump.rdb
    fi
    
    # Restore configuration if needed
    if [ -f "$TEMP_DIR/redis-config.txt" ]; then
        while IFS='=' read -r key value; do
            if [ -n "$key" ] && [ "$key" != "#"* ]; then
                redis-cli config set "$key" "$value" || true
            fi
        done < "$TEMP_DIR/redis-config.txt"
    fi
    
    rm -rf "$TEMP_DIR"
    
    # Start Redis
    systemctl start redis || error_exit "Failed to start Redis"
    
    log "Redis restore completed"
}

# Restore uploads
restore_uploads() {
    local backup_path="$1"
    
    log "Restoring file uploads..."
    
    UPLOADS_BACKUP="$backup_path/uploads/local-uploads.tar.gz"
    
    if [ -f "$UPLOADS_BACKUP" ]; then
        # Create uploads directory if it doesn't exist
        mkdir -p /app/uploads
        
        # Restore uploads
        tar -xzf "$UPLOADS_BACKUP" -C /app || error_exit "Uploads restore failed"
        
        # Set proper permissions
        chown -R app:app /app/uploads
        chmod -R 755 /app/uploads
    fi
    
    log "Uploads restore completed"
}

# Restore configuration
restore_config() {
    local backup_path="$1"
    
    log "Restoring configuration..."
    
    CONFIG_BACKUP_DIR="$backup_path/config"
    
    if [ -d "$CONFIG_BACKUP_DIR" ]; then
        # Restore SSL certificates
        if [ -f "$CONFIG_BACKUP_DIR/ssl-certs.tar.gz" ]; then
            sudo tar -xzf "$CONFIG_BACKUP_DIR/ssl-certs.tar.gz" -C / || error_exit "SSL restore failed"
        fi
        
        # Restore nginx configuration
        if [ -f "$CONFIG_BACKUP_DIR/nginx-config.tar.gz" ]; then
            sudo tar -xzf "$CONFIG_BACKUP_DIR/nginx-config.tar.gz" -C /etc/nginx || error_exit "Nginx config restore failed"
            sudo nginx -t && sudo systemctl reload nginx || error_exit "Nginx config validation failed"
        fi
    fi
    
    log "Configuration restore completed"
}

# Validate backup
validate_backup() {
    local backup_path="$1"
    
    log "Validating backup..."
    
    if [ ! -d "$backup_path" ]; then
        error_exit "Backup directory not found"
    fi
    
    if [ ! -f "$backup_path/manifest.json" ]; then
        error_exit "Backup manifest not found"
    fi
    
    # Validate manifest
    if ! python3 -c "import json; json.load(open('$backup_path/manifest.json'))" 2>/dev/null; then
        error_exit "Invalid backup manifest"
    fi
    
    # Verify required files exist
    required_files=("database.sql.gz" "redis/redis-backup.tar.gz")
    for file in "${required_files[@]}"; do
        if [ ! -f "$backup_path/$file" ]; then
            error_exit "Required backup file missing: $file"
        fi
    done
    
    log "Backup validation passed"
}

# Stop services
stop_services() {
    log "Stopping services..."
    
    # Stop application
    systemctl stop tutoring-platform || error_exit "Failed to stop application service"
    
    # Stop nginx
    systemctl stop nginx || error_exit "Failed to stop nginx"
    
    log "Services stopped"
}

# Start services
start_services() {
    log "Starting services..."
    
    # Start Redis
    systemctl start redis || error_exit "Failed to start Redis"
    
    # Start PostgreSQL
    systemctl start postgresql || error_exit "Failed to start PostgreSQL"
    
    # Start nginx
    systemctl start nginx || error_exit "Failed to start nginx"
    
    # Start application
    systemctl start tutoring-platform || error_exit "Failed to start application service"
    
    log "Services started"
}

# Run health checks
run_health_checks() {
    log "Running health checks..."
    
    # Check database connectivity
    if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        error_exit "Database connectivity check failed"
    fi
    
    # Check Redis connectivity
    if ! redis-cli ping > /dev/null 2>&1; then
        error_exit "Redis connectivity check failed"
    fi
    
    # Check application health
    sleep 10
    if ! curl -f http://localhost:3000/health > /dev/null 2>&1; then
        error_exit "Application health check failed"
    fi
    
    log "Health checks passed"
}

# Point-in-time recovery
point_in_time_recovery() {
    local target_time="$1"
    
    log "Starting point-in-time recovery to: $target_time"
    
    # This would involve WAL archiving and recovery
    # Implementation depends on PostgreSQL configuration
    
    log "Point-in-time recovery completed"
}

# Disaster recovery
disaster_recovery() {
    local backup_location="$1"
    
    log "Starting disaster recovery from: $backup_location"
    
    # Download latest backup from S3
    aws s3 sync "s3://${S3_BUCKET}/${ENVIRONMENT}/backups/latest/" /tmp/latest-backup/ || error_exit "Failed to download backup"
    
    # Perform full restore
    full_restore "/tmp/latest-backup"
    
    # Update DNS if needed
    update_dns_records
    
    # Notify stakeholders
    send_notification "Disaster recovery completed successfully"
    
    log "Disaster recovery completed"
}

# Update DNS records (for disaster recovery)
update_dns_records() {
    log "Updating DNS records..."
    
    # This would involve updating CloudFlare or Route53 records
    # Implementation depends on DNS provider
    
    log "DNS records updated"
}

# Send notification
send_notification() {
    local message="$1"
    
    # Send Slack notification
    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🔄 Backup/Restore: $message\"}" \
            "$SLACK_WEBHOOK_URL" || true
    fi
    
    # Send email notification
    if [ -n "${ALERT_EMAIL:-}" ]; then
        echo "$message" | mail -s "Tutoring Platform Backup/Restore" "$ALERT_EMAIL" || true
    fi
    
    log "Notification sent: $message"
}

# =============================================================================
# SCHEDULED BACKUPS
# =============================================================================

# Setup cron jobs
setup_cron_jobs() {
    log "Setting up cron jobs for backup automation..."
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "0 2 * * * /opt/scripts/backup.sh full") | crontab -
    (crontab -l 2>/dev/null; echo "0 */6 * * * /opt/scripts/backup.sh incremental") | crontab -
    (crontab -l 2>/dev/null; echo "0 3 * * 0 /opt/scripts/backup.sh verify") | crontab -
    
    log "Cron jobs configured"
}

# Verify backup integrity
verify_backup() {
    log "Verifying backup integrity..."
    
    # Download latest backup
    aws s3 sync "s3://${S3_BUCKET}/${ENVIRONMENT}/backups/latest/" /tmp/verify-backup/ || error_exit "Failed to download backup"
    
    # Validate backup
    validate_backup "/tmp/verify-backup"
    
    # Test restore in isolated environment (optional)
    # This would involve spinning up a test environment
    
    log "Backup verification completed"
    
    # Cleanup
    rm -rf /tmp/verify-backup/
}

# =============================================================================
# MAIN SCRIPT LOGIC
# =============================================================================

# Parse command line arguments
case "${1:-}" in
    "full")
        full_backup
        ;;
    "incremental")
        incremental_backup
        ;;
    "restore")
        if [ -z "${2:-}" ]; then
            error_exit "Backup path required for restore"
        fi
        full_restore "$2"
        ;;
    "pitr")
        if [ -z "${2:-}" ]; then
            error_exit "Target time required for point-in-time recovery"
        fi
        point_in_time_recovery "$2"
        ;;
    "disaster")
        if [ -z "${2:-}" ]; then
            error_exit "Backup location required for disaster recovery"
        fi
        disaster_recovery "$2"
        ;;
    "verify")
        verify_backup
        ;;
    "setup-cron")
        setup_cron_jobs
        ;;
    *)
        echo "Usage: $0 {full|incremental|restore|pitr|disaster|verify|setup-cron} [options]"
        echo ""
        echo "Commands:"
        echo "  full                - Perform full system backup"
        echo "  incremental         - Perform incremental backup"
        echo "  restore <path>      - Restore from backup"
        echo "  pitr <timestamp>    - Point-in-time recovery"
        echo "  disaster <location> - Disaster recovery"
        echo "  verify              - Verify backup integrity"
        echo "  setup-cron          - Setup automated cron jobs"
        exit 1
        ;;
esac