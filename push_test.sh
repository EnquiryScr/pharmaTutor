#!/bin/bash
cd /workspace/pharmaT
git config user.name "EnquiryScr"
git config user.email "enquiryscr@gmail.com"

echo "=== Git Configuration ===" > /workspace/pharmaT/push_log.txt
git config --list | grep -E "user|remote" >> /workspace/pharmaT/push_log.txt 2>&1

echo "" >> /workspace/pharmaT/push_log.txt
echo "=== Git Status ===" >> /workspace/pharmaT/push_log.txt
git status >> /workspace/pharmaT/push_log.txt 2>&1

echo "" >> /workspace/pharmaT/push_log.txt
echo "=== Push Attempt ===" >> /workspace/pharmaT/push_log.txt
GIT_CURL_VERBOSE=1 GIT_TRACE=1 timeout 15 git push -u origin main >> /workspace/pharmaT/push_log.txt 2>&1
EXIT_CODE=$?

echo "" >> /workspace/pharmaT/push_log.txt
echo "Exit code: $EXIT_CODE" >> /workspace/pharmaT/push_log.txt

cat /workspace/pharmaT/push_log.txt
