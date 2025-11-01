#!/bin/bash

echo "🚀 Pushing all folders to GitHub..."
cd /workspace/pharmaT

# Configure git
git config --global user.email "enquiryscr@gmail.com"
git config --global user.name "EnquiryScr"

# Add all files
git add -A

# Commit all changes
git commit -m "Add comprehensive cloud Flutter setup and development configuration"

# Push to GitHub
git push origin main

echo "✅ All files pushed to GitHub successfully!"

# Show current status
echo "Current status:"
git status