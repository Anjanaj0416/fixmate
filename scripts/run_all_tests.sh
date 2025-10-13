#!/bin/bash

# FixMate Test Execution Script
# This script helps run individual or all test cases easily

echo "🧪 FixMate Test Runner"
echo "====================="
echo ""

# Function to run all tests
run_all_tests() {
    echo "Running all tests..."
    flutter test
}

# Function to run specific test case
run_test_case() {
    local test_id=$1
    echo "Running test case: $test_id"
    flutter test test/integration_test/auth_test.dart --name "$test_id"
}

# Function to run test group
run_test_group() {
    local group_name=$1
    echo "Running test group: $group_name"
    flutter test test/integration_test/auth_test.dart --name "$group_name"
}

# Function to run specific test file
run_test_file() {
    local file_path=$1
    echo "Running test file: $file_path"
    flutter test "$file_path"
}

# Main menu
if [ $# -eq 0 ]; then
    echo "Usage:"
    echo "  ./run_tests.sh all                    # Run all tests"
    echo "  ./run_tests.sh case FT-001           # Run specific test case"
    echo "  ./run_tests.sh group \"Auth Tests\"    # Run test group"
    echo "  ./run_tests.sh file test/path.dart   # Run specific file"
    echo ""
    echo "Individual Test Cases:"
    echo "  FT-001: User Account Creation"
    echo "  FT-002: Email/Password Login"
    echo "  FT-004: Password Reset"
    echo "  FT-005: Account Type Selection"
    echo "  FT-006: Switch to Professional Account"
    echo "  FT-007: Two-Factor Authentication"
    echo "  FT-036: Invalid Email Format"
    echo "  FT-037: Weak Password Validation"
    echo "  FT-038: Duplicate Email Prevention"
    echo "  FT-039: Account Lockout"
    echo "  FT-040: Email Verification"
    echo "  FT-041: Password Reset Security"
    echo "  FT-043: OTP Expiration"
    echo "  FT-044: OTP Attempt Limiting"
    echo "  FT-045: Revert to Customer"
    echo ""
    echo "Test Groups:"
    echo "  \"Authentication Tests\""
    echo "  \"Validation Tests\""
    exit 1
fi

case "$1" in
    all)
        run_all_tests
        ;;
    case)
        if [ -z "$2" ]; then
            echo "Error: Please provide test case ID (e.g., FT-001)"
            exit 1
        fi
        run_test_case "$2"
        ;;
    group)
        if [ -z "$2" ]; then
            echo "Error: Please provide test group name"
            exit 1
        fi
        run_test_group "$2"
        ;;
    file)
        if [ -z "$2" ]; then
            echo "Error: Please provide test file path"
            exit 1
        fi
        run_test_file "$2"
        ;;
    *)
        echo "Error: Unknown command '$1'"
        echo "Use './run_tests.sh' without arguments to see usage"
        exit 1
        ;;
esac

echo ""
echo "✅ Test execution completed!"