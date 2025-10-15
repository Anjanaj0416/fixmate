@echo off
REM FixMate Test Execution Script for Windows
REM This script helps run individual or all test cases easily

echo.
echo 🧪 FixMate Test Runner
echo =====================
echo.

if "%1"=="" goto usage

if "%1"=="all" goto run_all
if "%1"=="case" goto run_case
if "%1"=="group" goto run_group
if "%1"=="file" goto run_file
goto unknown

:run_all
echo Running all tests...
flutter test
goto end

:run_case
if "%2"=="" (
    echo Error: Please provide test case ID (e.g., FT-001)
    exit /b 1
)
echo Running test case: %2
flutter test test/integration_test/auth_test.dart --name "%2"
goto end

:run_group
if "%2"=="" (
    echo Error: Please provide test group name
    exit /b 1
)
echo Running test group: %2
flutter test test/integration_test/auth_test.dart --name "%2"
goto end

:run_file
if "%2"=="" (
    echo Error: Please provide test file path
    exit /b 1
)
echo Running test file: %2
flutter test "%2"
goto end

:usage
echo Usage:
echo   run_tests.bat all                      # Run all tests
echo   run_tests.bat case FT-001             # Run specific test case
echo   run_tests.bat group "Auth Tests"      # Run test group
echo   run_tests.bat file test/path.dart     # Run specific file
echo.
echo Individual Test Cases:
echo   FT-001: User Account Creation
echo   FT-002: Email/Password Login
echo   FT-004: Password Reset
echo   FT-005: Account Type Selection
echo   FT-006: Switch to Professional Account
echo   FT-007: Two-Factor Authentication
echo   FT-036: Invalid Email Format
echo   FT-037: Weak Password Validation
echo   FT-038: Duplicate Email Prevention
echo   FT-039: Account Lockout
echo   FT-040: Email Verification
echo   FT-041: Password Reset Security
echo   FT-043: OTP Expiration
echo   FT-044: OTP Attempt Limiting
echo   FT-045: Revert to Customer
echo.
echo Test Groups:
echo   "Authentication Tests"
echo   "Validation Tests"
echo.
echo Examples:
echo   run_tests.bat all
echo   run_tests.bat case FT-001
echo   run_tests.bat case FT-002
echo   run_tests.bat group "Authentication Tests"
goto end

:unknown
echo Error: Unknown command '%1'
echo Use 'run_tests.bat' without arguments to see usage
exit /b 1

:end
echo.
echo ✅ Test execution completed!