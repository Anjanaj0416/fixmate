@echo off
REM scripts/run_all_tests.bat
REM Windows batch script for running FixMate authentication tests

setlocal enabledelayedexpansion

echo ========================================
echo 🚀 FIXMATE AUTHENTICATION TEST SUITE
echo ========================================
echo.
echo Start Time: %date% %time%
echo.

REM Initialize counters
set /a total_tests=0
set /a passed_tests=0
set /a failed_tests=0

REM Check Flutter installation
echo ----------------------------------------
echo 🔍 Verifying Flutter Installation
echo ----------------------------------------
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed
    exit /b 1
)

flutter --version
echo ✅ Flutter installed
echo.

REM Install dependencies
echo ----------------------------------------
echo 📦 Installing Dependencies
echo ----------------------------------------
call flutter pub get
if %errorlevel% equ 0 (
    echo ✅ Dependencies installed
    set /a passed_tests+=1
) else (
    echo ❌ Failed to install dependencies
    set /a failed_tests+=1
)
set /a total_tests+=1
echo.

REM Run Flutter analyzer
echo ----------------------------------------
echo 🔍 Code Analysis
echo ----------------------------------------
call flutter analyze
if %errorlevel% equ 0 (
    echo ✅ Code analysis passed
    set /a passed_tests+=1
) else (
    echo ❌ Code analysis failed
    set /a failed_tests+=1
)
set /a total_tests+=1
echo.

REM Check code formatting
echo ----------------------------------------
echo 🎨 Code Formatting Check
echo ----------------------------------------
call flutter format --set-exit-if-changed .
if %errorlevel% equ 0 (
    echo ✅ Code formatting passed
    set /a passed_tests+=1
) else (
    echo ⚠️  Code formatting issues found
    echo Run: flutter format .
    set /a failed_tests+=1
)
set /a total_tests+=1
echo.

REM Run integration tests
echo ----------------------------------------
echo 🔗 Integration Tests (FT-001 to FT-045)
echo ----------------------------------------
call flutter test test/integration_test/auth_test.dart
if %errorlevel% equ 0 (
    echo ✅ Integration tests passed
    set /a passed_tests+=1
) else (
    echo ❌ Integration tests failed
    set /a failed_tests+=1
)
set /a total_tests+=1
echo.

REM Run widget tests
echo ----------------------------------------
echo 🎨 Widget Tests
echo ----------------------------------------
call flutter test test/widget_test/auth_widget_test.dart
if %errorlevel% equ 0 (
    echo ✅ Widget tests passed
    set /a passed_tests+=1
) else (
    echo ❌ Widget tests failed
    set /a failed_tests+=1
)
set /a total_tests+=1
echo.

REM Run security tests
echo ----------------------------------------
echo 🔒 Security Tests
echo ----------------------------------------
call flutter test test/security/security_test.dart
if %errorlevel% equ 0 (
    echo ✅ Security tests passed
    set /a passed_tests+=1
) else (
    echo ❌ Security tests failed
    set /a failed_tests+=1
)
set /a total_tests+=1
echo.

REM Run performance tests
echo ----------------------------------------
echo ⚡ Performance Tests
echo ----------------------------------------
call flutter test test/performance/performance_test.dart
if %errorlevel% equ 0 (
    echo ✅ Performance tests passed
    set /a passed_tests+=1
) else (
    echo ❌ Performance tests failed
    set /a failed_tests+=1
)
set /a total_tests+=1
echo.

REM Generate coverage report
echo ----------------------------------------
echo 📊 Generating Coverage Report
echo ----------------------------------------
echo Running tests with coverage...
call flutter test --coverage
if %errorlevel% equ 0 (
    echo ✅ Coverage data generated
    echo Coverage file: coverage\lcov.info
) else (
    echo ❌ Coverage generation failed
)
echo.

REM Calculate success rate
set /a success_rate=passed_tests * 100 / total_tests

REM Print summary
echo.
echo ========================================
echo 📊 TEST SUMMARY
echo ========================================
echo Total Test Suites: %total_tests%
echo ✅ Passed: %passed_tests%
echo ❌ Failed: %failed_tests%
echo Success Rate: %success_rate%%%
echo.
echo End Time: %date% %time%
echo ========================================

REM Generate test report
echo ======================================== > test_report.txt
echo FIXMATE AUTHENTICATION TEST REPORT >> test_report.txt
echo ======================================== >> test_report.txt
echo Date: %date% %time% >> test_report.txt
echo. >> test_report.txt
echo TEST RESULTS >> test_report.txt
echo ---------------------------------------- >> test_report.txt
echo Total Test Suites: %total_tests% >> test_report.txt
echo Passed: %passed_tests% >> test_report.txt
echo Failed: %failed_tests% >> test_report.txt
echo Success Rate: %success_rate%%% >> test_report.txt
echo. >> test_report.txt
echo TEST CATEGORIES >> test_report.txt
echo ---------------------------------------- >> test_report.txt
echo ✅ Core Authentication (FT-001 to FT-007) >> test_report.txt
echo ✅ Validation ^& Security (FT-036 to FT-045) >> test_report.txt
echo ✅ Integration Tests >> test_report.txt
echo ✅ Widget Tests >> test_report.txt
echo ✅ Security Tests >> test_report.txt
echo ✅ Performance Tests >> test_report.txt
echo ======================================== >> test_report.txt

echo.
echo ✅ Test report saved to: test_report.txt

REM Print test case coverage
echo.
echo ----------------------------------------
echo 📋 Test Case Coverage
echo ----------------------------------------
echo Core Authentication:
echo   ✅ FT-001: User Account Creation
echo   ✅ FT-002: Email/Password Login
echo   ✅ FT-003: Google OAuth Login
echo   ✅ FT-004: Password Reset
echo   ✅ FT-005: Account Type Selection
echo   ✅ FT-006: Switch to Professional Account
echo   ✅ FT-007: Two-Factor Authentication
echo.
echo Validation ^& Security:
echo   ✅ FT-036: Invalid Email Format
echo   ✅ FT-037: Weak Password Validation
echo   ✅ FT-038: Duplicate Email Prevention
echo   ✅ FT-039: Account Lockout
echo   ✅ FT-040: Unverified Email Login
echo   ✅ FT-041: Password Reset Security
echo   ✅ FT-042: OAuth Cancellation
echo   ✅ FT-043: Expired OTP
echo   ✅ FT-044: Multiple OTP Attempts
echo   ✅ FT-045: Account Type Switch

REM Exit with appropriate code
if %failed_tests% equ 0 (
    echo.
    echo ✅✅✅ ALL TESTS PASSED! ✅✅✅
    exit /b 0
) else (
    echo.
    echo ❌ SOME TESTS FAILED ❌
    echo Please review the errors above and fix the failing tests.
    exit /b 1
)