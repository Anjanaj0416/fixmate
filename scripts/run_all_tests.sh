
#!/bin/bash
# scripts/run_all_tests.sh
# Comprehensive test execution script for FixMate Authentication
# Makes this file executable: chmod +x scripts/run_all_tests.sh

set -e # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Emojis
CHECK="✅"
CROSS="❌"
ROCKET="🚀"
MAGNIFY="🔍"
REPORT="📊"
LOCK="🔒"
LIGHTNING="⚡"

echo -e "${BLUE}========================================${NC}"
echo -e "${ROCKET} ${GREEN}FIXMATE AUTHENTICATION TEST SUITE${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Start Time: $(date)"
echo ""

# Function to print section header
print_header() {
    echo ""
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${1}"
    echo -e "${BLUE}----------------------------------------${NC}"
}

# Function to run test with error handling
run_test() {
    local test_name=$1
    local test_command=$2
    
    echo -e "${YELLOW}▶️  Running: ${test_name}${NC}"
    
    if eval "$test_command"; then
        echo -e "${GREEN}${CHECK} ${test_name} PASSED${NC}"
        return 0
    else
        echo -e "${RED}${CROSS} ${test_name} FAILED${NC}"
        return 1
    fi
}

# Initialize counters
total_tests=0
passed_tests=0
failed_tests=0

# Check Flutter installation
print_header "${MAGNIFY} Verifying Flutter Installation"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}${CROSS} Flutter is not installed${NC}"
    exit 1
fi

flutter --version
echo -e "${GREEN}${CHECK} Flutter installed${NC}"

# Install dependencies
print_header "📦 Installing Dependencies"
if run_test "flutter pub get" "flutter pub get"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Run Flutter analyzer
print_header "${MAGNIFY} Code Analysis"
if run_test "flutter analyze" "flutter analyze"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Check code formatting
print_header "🎨 Code Formatting Check"
if run_test "flutter format check" "flutter format --set-exit-if-changed ."; then
    ((passed_tests++))
else
    echo -e "${YELLOW}⚠️  Code formatting issues found. Run: flutter format .${NC}"
    ((failed_tests++))
fi
((total_tests++))

# Run integration tests
print_header "🔗 Integration Tests (FT-001 to FT-045)"
if run_test "Integration Tests" "flutter test test/integration_test/auth_test.dart"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Run widget tests
print_header "🎨 Widget Tests"
if run_test "Widget Tests" "flutter test test/widget_test/auth_widget_test.dart"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Run security tests
print_header "${LOCK} Security Tests"
if run_test "Security Tests" "flutter test test/security/security_test.dart"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Run performance tests
print_header "${LIGHTNING} Performance Tests"
if run_test "Performance Tests" "flutter test test/performance/performance_test.dart"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Run specific test cases
print_header "🔐 Core Authentication Tests"
for test_id in FT-001 FT-002 FT-003 FT-004 FT-005 FT-006 FT-007; do
    if run_test "$test_id" "flutter test --name \"$test_id\""; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
done

# Run validation tests
print_header "🔖 Validation & Security Tests"
for test_id in FT-036 FT-037 FT-038 FT-039 FT-040 FT-041 FT-042 FT-043 FT-044 FT-045; do
    if run_test "$test_id" "flutter test --name \"$test_id\""; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
done

# Generate coverage report
print_header "${REPORT} Generating Coverage Report"
echo "Running tests with coverage..."
if flutter test --coverage; then
    echo -e "${GREEN}${CHECK} Coverage data generated${NC}"
    
    # Generate HTML report if lcov is available
    if command -v genhtml &> /dev/null; then
        echo "Generating HTML coverage report..."
        genhtml coverage/lcov.info -o coverage/html
        echo -e "${GREEN}${CHECK} Coverage report generated at: coverage/html/index.html${NC}"
        
        # Try to open in browser (macOS/Linux)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open coverage/html/index.html
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            xdg-open coverage/html/index.html 2>/dev/null || true
        fi
    else
        echo -e "${YELLOW}⚠️  lcov not installed. HTML report not generated.${NC}"
        echo "Install lcov:"
        echo "  macOS: brew install lcov"
        echo "  Linux: apt-get install lcov"
    fi
else
    echo -e "${RED}${CROSS} Coverage generation failed${NC}"
fi

# Calculate success rate
success_rate=$(echo "scale=1; ($passed_tests * 100) / $total_tests" | bc)

# Print summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${REPORT} ${GREEN}TEST SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Total Test Suites: ${total_tests}"
echo -e "${GREEN}${CHECK} Passed: ${passed_tests}${NC}"
echo -e "${RED}${CROSS} Failed: ${failed_tests}${NC}"
echo -e "Success Rate: ${success_rate}%"
echo ""
echo "End Time: $(date)"
echo -e "${BLUE}========================================${NC}"

# Generate test report
print_header "${REPORT} Generating Test Report"
cat > test_report.txt << EOF
========================================
FIXMATE AUTHENTICATION TEST REPORT
========================================
Date: $(date)
Flutter Version: $(flutter --version | head -n 1)

TEST RESULTS
----------------------------------------
Total Test Suites: ${total_tests}
Passed: ${passed_tests}
Failed: ${failed_tests}
Success Rate: ${success_rate}%

TEST CATEGORIES
----------------------------------------
✅ Core Authentication (FT-001 to FT-007)
✅ Validation & Security (FT-036 to FT-045)
✅ Integration Tests
✅ Widget Tests
✅ Security Tests
✅ Performance Tests

COVERAGE
----------------------------------------
Coverage report: coverage/html/index.html

NOTES
----------------------------------------
$(if [ $failed_tests -eq 0 ]; then
    echo "All tests passed successfully! ✅"
else
    echo "Some tests failed. Review the output above for details."
fi)
========================================
EOF

echo -e "${GREEN}${CHECK} Test report saved to: test_report.txt${NC}"

# Print test case coverage
print_header "📋 Test Case Coverage"
echo "Core Authentication:"
echo "  ✅ FT-001: User Account Creation"
echo "  ✅ FT-002: Email/Password Login"
echo "  ✅ FT-003: Google OAuth Login"
echo "  ✅ FT-004: Password Reset"
echo "  ✅ FT-005: Account Type Selection"
echo "  ✅ FT-006: Switch to Professional Account"
echo "  ✅ FT-007: Two-Factor Authentication"
echo ""
echo "Validation & Security:"
echo "  ✅ FT-036: Invalid Email Format"
echo "  ✅ FT-037: Weak Password Validation"
echo "  ✅ FT-038: Duplicate Email Prevention"
echo "  ✅ FT-039: Account Lockout After Failed Attempts"
echo "  ✅ FT-040: Unverified Email Login"
echo "  ✅ FT-041: Password Reset with Invalid Email"
echo "  ✅ FT-042: Google OAuth Cancelled Authorization"
echo "  ✅ FT-043: Expired OTP Code"
echo "  ✅ FT-044: Multiple Incorrect OTP Attempts"
echo "  ✅ FT-045: Account Type Switch Back to Customer"

# Exit with appropriate code
if [ $failed_tests -eq 0 ]; then
    echo ""
    echo -e "${GREEN}${CHECK}${CHECK}${CHECK} ALL TESTS PASSED! ${CHECK}${CHECK}${CHECK}${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}${CROSS} SOME TESTS FAILED ${CROSS}${NC}"
    echo "Please review the errors above and fix the failing tests."
    exit 1
fi