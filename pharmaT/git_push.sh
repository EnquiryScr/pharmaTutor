#!/bin/bash

# Git Push Script for pharmaT
# Output will be saved to git_push_output.txt

OUTPUT_FILE="/workspace/pharmaT/git_push_output.txt"

echo "=== pharmaT Git Push Script ===" > "$OUTPUT_FILE"
echo "Started at: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Navigate to pharmaT directory
cd /workspace/pharmaT

# Configure git
echo "Step 1: Configuring Git..." >> "$OUTPUT_FILE"
git config --global user.name "EnquiryScr" >> "$OUTPUT_FILE" 2>&1
git config --global user.email "enquiryscr@gmail.com" >> "$OUTPUT_FILE" 2>&1
echo "✓ Git configured" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Initialize git repository
echo "Step 2: Initializing Git repository..." >> "$OUTPUT_FILE"
if [ -d ".git" ]; then
    echo "✓ Git repository already initialized" >> "$OUTPUT_FILE"
else
    git init >> "$OUTPUT_FILE" 2>&1
    echo "✓ Git repository initialized" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# Add all files
echo "Step 3: Adding all files..." >> "$OUTPUT_FILE"
git add . >> "$OUTPUT_FILE" 2>&1
echo "✓ Files added" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Check status
echo "Step 4: Checking status..." >> "$OUTPUT_FILE"
git status >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# Commit
echo "Step 5: Creating commit..." >> "$OUTPUT_FILE"
git commit -m "Initial commit: pharmaT pharmacy tutoring platform - Complete Flutter app with 120,000+ lines, comprehensive documentation, deployment configs, and research" >> "$OUTPUT_FILE" 2>&1
echo "✓ Commit created" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Rename branch to main
echo "Step 6: Renaming branch to main..." >> "$OUTPUT_FILE"
git branch -M main >> "$OUTPUT_FILE" 2>&1
echo "✓ Branch renamed to main" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Add remote origin
echo "Step 7: Adding remote origin..." >> "$OUTPUT_FILE"
git remote remove origin 2>/dev/null
git remote add origin https://github.com/EnquiryScr/pharmaT.git >> "$OUTPUT_FILE" 2>&1
echo "✓ Remote origin added" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Check remote
echo "Step 8: Verifying remote..." >> "$OUTPUT_FILE"
git remote -v >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# Attempt push
echo "Step 9: Attempting to push to GitHub..." >> "$OUTPUT_FILE"
echo "NOTE: This may require authentication. If it fails, you'll need to:" >> "$OUTPUT_FILE"
echo "  1. Create a Personal Access Token on GitHub" >> "$OUTPUT_FILE"
echo "  2. Use: git push https://TOKEN@github.com/EnquiryScr/pharmaT.git main" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

git push -u origin main >> "$OUTPUT_FILE" 2>&1
PUSH_STATUS=$?

echo "" >> "$OUTPUT_FILE"
if [ $PUSH_STATUS -eq 0 ]; then
    echo "✓✓✓ SUCCESS! Repository pushed to GitHub ✓✓✓" >> "$OUTPUT_FILE"
else
    echo "⚠ Push failed (exit code: $PUSH_STATUS)" >> "$OUTPUT_FILE"
    echo "This usually means authentication is required." >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "Next steps:" >> "$OUTPUT_FILE"
    echo "1. Go to: https://github.com/settings/tokens" >> "$OUTPUT_FILE"
    echo "2. Generate new token (classic) with 'repo' scope" >> "$OUTPUT_FILE"
    echo "3. Run: git push https://YOUR_TOKEN@github.com/EnquiryScr/pharmaT.git main" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "Completed at: $(date)" >> "$OUTPUT_FILE"
echo "=== End of Script ===" >> "$OUTPUT_FILE"

echo "Script execution complete. Check git_push_output.txt for results."
