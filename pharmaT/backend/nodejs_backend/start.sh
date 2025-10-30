#!/bin/bash

# Tutoring Platform Backend Startup Script

echo "🎓 Starting Tutoring Platform Backend..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please run 'npm run setup' first."
    exit 1
fi

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Check if required directories exist
mkdir -p uploads/{assignments,queries,profile,general}
mkdir -p logs

# Start the application
echo "🚀 Starting server..."
npm run dev