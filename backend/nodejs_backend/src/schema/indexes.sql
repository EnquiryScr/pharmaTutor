# Additional Database Indexes for Performance Optimization

-- Performance indexes for frequently queried columns
CREATE INDEX IF NOT EXISTS idx_assignments_subject_status ON assignments(subject, status);
CREATE INDEX IF NOT EXISTS idx_assignments_tutor_status ON assignments(tutor_id, status);
CREATE INDEX IF NOT EXISTS idx_assignments_deadline_status ON assignments(deadline, status);

-- Composite indexes for user queries
CREATE INDEX IF NOT EXISTS idx_users_role_active ON users(role, is_active);
CREATE INDEX IF NOT EXISTS idx_users_email_active ON users(email, is_active);

-- Message indexes for chat functionality
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(sender_id, recipient_id, sent_at);
CREATE INDEX IF NOT EXISTS idx_messages_room_time ON messages(room_id, sent_at);

-- Query/ticket indexes
CREATE INDEX IF NOT EXISTS idx_queries_user_status ON queries(user_id, status);
CREATE INDEX IF NOT EXISTS idx_queries_assigned_status ON queries(assigned_to, status);
CREATE INDEX IF NOT EXISTS idx_queries_priority_status ON queries(priority, status);

-- Appointment indexes
CREATE INDEX IF NOT EXISTS idx_appointments_tutor_time ON appointments(tutor_id, start_time);
CREATE INDEX IF NOT EXISTS idx_appointments_student_time ON appointments(student_id, start_time);
CREATE INDEX IF NOT EXISTS idx_appointments_status_time ON appointments(status, start_time);

-- Article indexes for search and discovery
CREATE INDEX IF NOT EXISTS idx_articles_category_published ON articles(category, is_published);
CREATE INDEX IF NOT EXISTS idx_articles_author_published ON articles(author_id, is_published);
CREATE INDEX IF NOT EXISTS idx_articles_tags_gin ON articles USING GIN(tags);

-- Full-text search indexes
CREATE INDEX IF NOT EXISTS idx_articles_search ON articles USING GIN(to_tsvector('english', title || ' ' || content));
CREATE INDEX IF NOT EXISTS idx_queries_search ON queries USING GIN(to_tsvector('english', subject || ' ' || description));

-- Payment indexes
CREATE INDEX IF NOT EXISTS idx_payments_user_status ON payments(user_id, status);
CREATE INDEX IF NOT EXISTS idx_payments_status_time ON payments(status, created_at);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_analytics_events_user_time ON analytics_events(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_analytics_events_type_time ON analytics_events(event_type, created_at);

-- Notification indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_user_time ON notifications(user_id, created_at);

-- File upload indexes
CREATE INDEX IF NOT EXISTS idx_file_uploads_user_purpose ON file_uploads(user_id, purpose);
CREATE INDEX IF NOT EXISTS idx_file_uploads_entity ON file_uploads(entity_id, purpose);

-- Partial indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_active_only ON users(id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_assignments_published ON assignments(id) WHERE status = 'published';
CREATE INDEX IF NOT EXISTS idx_messages_unread ON messages(id) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(id) WHERE is_read = false;