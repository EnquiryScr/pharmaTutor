# Multi-stage Dockerfile for tutoring platform backend

# Base stage with common dependencies
FROM node:18-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    ffmpeg \
    gcc \
    make \
    python3 \
    g++

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Development stage
FROM base AS development

# Install development dependencies
RUN npm ci

# Copy source code
COPY . .

# Expose port
EXPOSE 3000

# Start in development mode
CMD ["npm", "run", "dev"]

# Build stage for optimization
FROM base AS build

# Install development dependencies for build
RUN npm ci

# Copy source code
COPY . .

# Generate code (if using code generation tools)
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Install security updates
RUN apk update && apk upgrade && apk add --no-cache \
    tini \
    curl \
    ffmpeg

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production && npm cache clean --force

# Copy built application from build stage
COPY --from=build --chown=nextjs:nodejs /app/src ./src
COPY --from=build --chown=nextjs:nodejs /app/uploads ./uploads
COPY --from=build --chown=nextjs:nodejs /app/logs ./logs

# Set ownership
RUN chown -R nextjs:nodejs /app

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Start application
CMD ["npm", "start"]

# Add labels for better maintainability
LABEL maintainer="Tutoring Platform Team <dev@tutoring-platform.com>"
LABEL version="1.0.0"
LABEL description="Tutoring Platform Backend API"
LABEL org.opencontainers.image.title="Tutoring Platform Backend"
LABEL org.opencontainers.image.description="Node.js backend API for global tutoring platform"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.vendor="Tutoring Platform"
LABEL org.opencontainers.image.licenses="MIT"