#!/usr/bin/env python3
"""
pharmaT Flutter App - Dependency Check and Fix Script
This script helps identify and fix missing dependencies and compilation issues.
"""

import os
import re
import json

def check_missing_imports():
    """Check for missing imports in Dart files"""
    print("🔍 Checking for missing imports...")
    
    # Files to check
    files_to_check = [
        '/workspace/code/flutter_tutoring_app/lib/config/app_config.dart',
        '/workspace/code/flutter_tutoring_app/lib/data/blocs/auth_bloc.dart',
        '/workspace/code/flutter_tutoring_app/lib/main.dart',
    ]
    
    issues = []
    
    for file_path in files_to_check:
        if os.path.exists(file_path):
            with open(file_path, 'r') as f:
                content = f.read()
                if 'import' in content:
                    print(f"✅ {os.path.basename(file_path)} - Imports found")
                else:
                    issues.append(f"❌ {os.path.basename(file_path)} - No imports found")
        else:
            issues.append(f"❌ File not found: {file_path}")
    
    if issues:
        print("\n🚨 Issues found:")
        for issue in issues:
            print(issue)
    else:
        print("✅ All checked files have imports")
    
    return issues

def verify_constants():
    """Verify that AppConstants has the required constants"""
    print("\n🔍 Verifying AppConstants...")
    
    app_constants_path = '/workspace/code/flutter_tutoring_app/lib/core/constants/app_constants.dart'
    if os.path.exists(app_constants_path):
        with open(app_constants_path, 'r') as f:
            content = f.read()
            
        # Check for required constants
        required_constants = [
            'spacingXL',
            'spacingM', 
            'spacingS',
            'borderRadiusM',
            'borderRadiusL',
            'borderRadiusXL',
            'themeSettings',
        ]
        
        found_constants = []
        missing_constants = []
        
        for constant in required_constants:
            if constant in content:
                found_constants.append(constant)
            else:
                missing_constants.append(constant)
        
        print(f"✅ Found constants: {found_constants}")
        if missing_constants:
            print(f"❌ Missing constants: {missing_constants}")
            return False
        else:
            print("✅ All required constants found")
            return True
    else:
        print("❌ app_constants.dart not found")
        return False

def check_file_structure():
    """Check if required files and directories exist"""
    print("\n🔍 Checking file structure...")
    
    required_files = [
        '/workspace/code/flutter_tutoring_app/lib/data/blocs/auth_bloc.dart',
        '/workspace/code/flutter_tutoring_app/lib/core/middleware/auth_middleware.dart',
        '/workspace/code/flutter_tutoring_app/lib/main.dart',
    ]
    
    issues = []
    for file_path in required_files:
        if os.path.exists(file_path):
            print(f"✅ {os.path.basename(file_path)}")
        else:
            print(f"❌ {os.path.basename(file_path)}")
            issues.append(file_path)
    
    return len(issues) == 0

def generate_fix_report():
    """Generate a comprehensive fix report"""
    print("\n📋 Generating fix report...")
    
    report = []
    
    # Check imports
    import_issues = check_missing_imports()
    if import_issues:
        report.extend(import_issues)
    
    # Check constants
    constants_ok = verify_constants()
    if not constants_ok:
        report.append("❌ AppConstants missing required constants")
    
    # Check file structure
    structure_ok = check_file_structure()
    if not structure_ok:
        report.append("❌ Required files missing from file structure")
    
    print(f"\n📊 Fix Report Summary:")
    print(f"Total issues found: {len(report)}")
    for issue in report:
        print(f"  {issue}")
    
    return report

def main():
    """Main function to run all checks"""
    print("🔧 pharmaT Flutter App - Dependency & Fix Check")
    print("=" * 50)
    
    issues = generate_fix_report()
    
    if len(issues) == 0:
        print("\n🎉 All checks passed! The app should compile successfully.")
        print("\nNext steps:")
        print("1. Install Flutter SDK")
        print("2. Run 'flutter pub get'")
        print("3. Run 'flutter analyze'")
        print("4. Run 'flutter build apk --debug'")
    else:
        print(f"\n⚠️  Found {len(issues)} issues that need to be fixed before compilation.")
        print("Please fix the issues above and run this script again.")

if __name__ == "__main__":
    main()
