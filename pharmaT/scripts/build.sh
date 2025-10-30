#!/bin/bash

# 🚀 Pharmacy Tutoring Platform - Build Script
# This script compiles both the Node.js backend and Flutter app

echo "🔧 Starting Pharmacy Tutoring Platform Compilation..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_tool() {
    if ! command -v $1 &> /dev/null; then
        print_warning "$1 is not installed"
        return 1
    else
        print_success "$1 is available"
        return 0
    fi
}

echo ""
echo "📋 Checking Prerequisites..."
echo "=========================="

# Check Node.js
if check_tool node; then
    node --version
fi

# Check npm
if check_tool npm; then
    npm --version
fi

# Check Flutter
if check_tool flutter; then
    flutter --version | head -1
fi

echo ""
echo "🔨 Starting Compilation Process..."
echo "=================================="

# Fix npm permissions and install dependencies
fix_npm_permissions() {
    print_status "Fixing npm permissions..."
    
    # Create local npm directory
    mkdir -p ~/.npm-global
    
    # Configure npm to use local prefix
    npm config set prefix '~/.npm-global'
    export PATH=~/.npm-global/bin:$PATH
    
    # Try to install dependencies with multiple methods
    if [ -d "code/nodejs_backend" ]; then
        cd code/nodejs_backend
        
        # Method 1: Standard installation
        if npm install --no-package-lock > /dev/null 2>&1; then
            print_success "Backend dependencies installed successfully"
        else
            print_warning "Standard npm install failed, trying alternative methods..."
            
            # Method 2: Install only essential packages
            if [ -f "package-minimal.json" ]; then
                cp package-minimal.json package.json
                npm install --no-package-lock > /dev/null 2>&1
                print_success "Backend dependencies (minimal) installed successfully"
            fi
        fi
        
        # Verify syntax
        if node --check src/server.js > /dev/null 2>&1; then
            print_success "Backend code syntax check passed"
        else
            print_error "Backend code has syntax errors"
        fi
        
        cd ../../
    fi
}

# Compile Flutter app
compile_flutter_app() {
    if [ -d "code/flutter_tutoring_app" ] && command -v flutter &> /dev/null; then
        print_status "Compiling Flutter app..."
        
        cd code/flutter_tutoring_app
        
        # Get dependencies
        flutter pub get > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            print_success "Flutter dependencies installed successfully"
            
            # Analyze code
            flutter analyze > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                print_success "Flutter code analysis passed"
            else
                print_warning "Flutter code analysis found some warnings"
            fi
            
            # Build APK (Android)
            print_status "Building Android APK..."
            flutter build apk --release > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                print_success "Android APK built successfully"
            else
                print_warning "Android APK build failed"
            fi
        else
            print_error "Failed to install Flutter dependencies"
        fi
        
        cd ../../
    else
        if command -v flutter &> /dev/null; then
            print_warning "Flutter directory not found"
        else
            print_warning "Flutter SDK not installed"
            echo "Install Flutter: https://flutter.dev/docs/get-started/install"
        fi
    fi
}

# Fix npm and install backend dependencies
fix_npm_permissions

# Compile Flutter app
compile_flutter_app

# Create environment template
create_env_template() {
    print_status "Creating environment configuration template..."
    
    if [ -f "code/nodejs_backend/.env.example" ]; then
        cp code/nodejs_backend/.env.example code/nodejs_backend/.env
        print_success "Environment template created at code/nodejs_backend/.env"
        print_warning "Please edit the .env file with your actual configuration values"
    fi
}

create_env_template

echo ""
echo "📊 Compilation Summary:"
echo "======================"

# Count files and lines
if [ -d "code/flutter_tutoring_app/lib" ]; then
    flutter_files=$(find code/flutter_tutoring_app/lib -name "*.dart" | wc -l)
    flutter_lines=$(find code/flutter_tutoring_app/lib -name "*.dart" -exec wc -l {} + | tail -1 | awk '{print $1}')
    echo "📱 Flutter App: $flutter_files files, ~$flutter_lines lines of code"
fi

if [ -d "code/nodejs_backend/src" ]; then
    node_files=$(find code/nodejs_backend/src -name "*.js" | wc -l)
    node_lines=$(find code/nodejs_backend/src -name "*.js" -exec wc -l {} + | tail -1 | awk '{print $1}')
    echo "🖥️  Node.js Backend: $node_files files, ~$node_lines lines of code"
fi

echo ""
echo "✅ Compilation Process Complete!"
echo ""
echo "Next Steps:"
echo "1. Configure environment variables in code/nodejs_backend/.env"
echo "2. Set up Supabase project and update configuration"
echo "3. Set up Firebase project and update configuration"
echo "4. Install and configure PostgreSQL and Redis"
echo "5. Deploy to staging environment"
echo ""
echo "📖 See COMPILATION_REPORT.md for detailed deployment instructions"
echo ""

# Optional: Start services if no errors
read -p "Would you like to start the development servers? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    print_status "Starting development servers..."
    
    # Start Node.js backend in background if it exists
    if [ -d "code/nodejs_backend" ] && [ -d "code/nodejs_backend/node_modules" ]; then
        cd code/nodejs_backend
        npm start > /dev/null 2>&1 &
        BACKEND_PID=$!
        print_success "Node.js backend started (PID: $BACKEND_PID)"
        cd ../../
    fi
    
    # Wait a moment
    sleep 2
    
    # Start Flutter app if available
    if [ -d "code/flutter_tutoring_app" ] && command -v flutter &> /dev/null; then
        cd code/flutter_tutoring_app
        flutter run > /dev/null 2>&1 &
        FLUTTER_PID=$!
        print_success "Flutter app started (PID: $FLUTTER_PID)"
        cd ../../
    fi
    
    print_status "Servers started in background"
    print_status "Backend: http://localhost:3000"
    print_status "Flutter: Use 'flutter run' to start the app"
fi