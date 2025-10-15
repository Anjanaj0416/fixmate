// test/report_generator.dart
// Generates beautiful HTML test reports
// Run with: dart test/report_generator.dart

import 'dart:io';
import 'dart:convert';

class TestReportGenerator {
  static const String outputDir = 'test_reports';
  static const String reportFileName = 'test_report.html';

  /// Generate HTML test report
  static Future<void> generateReport({
    required Map<String, TestResult> results,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // Create output directory
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Calculate statistics
    final stats = _calculateStatistics(results);
    final duration = endTime.difference(startTime);

    // Generate HTML
    final html = _generateHTML(results, stats, startTime, endTime, duration);

    // Write to file
    final file = File('$outputDir/$reportFileName');
    await file.writeAsString(html);

    print('✅ Test report generated: $outputDir/$reportFileName');

    // Try to open in browser
    _openInBrowser('$outputDir/$reportFileName');
  }

  /// Calculate test statistics
  static TestStatistics _calculateStatistics(Map<String, TestResult> results) {
    int total = results.length;
    int passed = 0;
    int failed = 0;
    int skipped = 0;

    for (var result in results.values) {
      switch (result.status) {
        case TestStatus.passed:
          passed++;
          break;
        case TestStatus.failed:
          failed++;
          break;
        case TestStatus.skipped:
          skipped++;
          break;
      }
    }

    final successRate =
        total > 0 ? (passed / total * 100).toStringAsFixed(1) : '0.0';

    return TestStatistics(
      total: total,
      passed: passed,
      failed: failed,
      skipped: skipped,
      successRate: successRate,
    );
  }

  /// Generate HTML content
  static String _generateHTML(
    Map<String, TestResult> results,
    TestStatistics stats,
    DateTime startTime,
    DateTime endTime,
    Duration duration,
  ) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FixMate Authentication Test Report</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            min-height: 100vh;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            overflow: hidden;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }

        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            font-weight: 700;
        }

        .header p {
            font-size: 1.2em;
            opacity: 0.9;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 40px;
            background: #f8f9fa;
        }

        .stat-card {
            background: white;
            padding: 30px;
            border-radius: 15px;
            text-align: center;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s ease;
        }

        .stat-card:hover {
            transform: translateY(-5px);
        }

        .stat-number {
            font-size: 3em;
            font-weight: bold;
            margin-bottom: 10px;
        }

        .stat-label {
            color: #6c757d;
            font-size: 1.1em;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .passed { color: #28a745; }
        .failed { color: #dc3545; }
        .skipped { color: #ffc107; }
        .total { color: #667eea; }

        .info-section {
            padding: 30px 40px;
            border-bottom: 1px solid #e9ecef;
        }

        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }

        .info-item {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }

        .info-label {
            color: #6c757d;
            font-size: 0.9em;
            margin-bottom: 5px;
        }

        .info-value {
            color: #212529;
            font-size: 1.1em;
            font-weight: 600;
        }

        .test-results {
            padding: 40px;
        }

        .test-results h2 {
            color: #212529;
            margin-bottom: 30px;
            font-size: 2em;
        }

        .test-group {
            margin-bottom: 40px;
        }

        .test-group h3 {
            color: #495057;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e9ecef;
            font-size: 1.5em;
        }

        .test-case {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            transition: all 0.3s ease;
        }

        .test-case:hover {
            background: #e9ecef;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }

        .test-case-info {
            flex: 1;
        }

        .test-id {
            font-weight: bold;
            color: #667eea;
            font-size: 1.1em;
        }

        .test-name {
            color: #495057;
            margin-top: 5px;
        }

        .test-status {
            padding: 8px 20px;
            border-radius: 20px;
            font-weight: bold;
            font-size: 0.9em;
            text-transform: uppercase;
        }

        .status-passed {
            background: #d4edda;
            color: #155724;
        }

        .status-failed {
            background: #f8d7da;
            color: #721c24;
        }

        .status-skipped {
            background: #fff3cd;
            color: #856404;
        }

        .test-duration {
            color: #6c757d;
            font-size: 0.9em;
            margin-top: 5px;
        }

        .footer {
            background: #212529;
            color: white;
            padding: 30px;
            text-align: center;
        }

        .footer p {
            margin: 5px 0;
        }

        .progress-bar {
            width: 100%;
            height: 30px;
            background: #e9ecef;
            border-radius: 15px;
            overflow: hidden;
            margin: 20px 0;
        }

        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #28a745 0%, #20c997 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            transition: width 0.3s ease;
        }

        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .container {
                box-shadow: none;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <h1>🧪 FixMate Authentication Test Report</h1>
            <p>Comprehensive Test Execution Results</p>
        </div>

        <!-- Statistics -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-number total">${stats.total}</div>
                <div class="stat-label">Total Tests</div>
            </div>
            <div class="stat-card">
                <div class="stat-number passed">${stats.passed}</div>
                <div class="stat-label">Passed</div>
            </div>
            <div class="stat-card">
                <div class="stat-number failed">${stats.failed}</div>
                <div class="stat-label">Failed</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">${stats.successRate}%</div>
                <div class="stat-label">Success Rate</div>
            </div>
        </div>

        <!-- Progress Bar -->
        <div class="info-section">
            <div class="progress-bar">
                <div class="progress-fill" style="width: ${stats.successRate}%;">
                    ${stats.successRate}% Complete
                </div>
            </div>
        </div>

        <!-- Test Information -->
        <div class="info-section">
            <h2>Test Information</h2>
            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">Start Time</div>
                    <div class="info-value">${_formatDateTime(startTime)}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">End Time</div>
                    <div class="info-value">${_formatDateTime(endTime)}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Duration</div>
                    <div class="info-value">${_formatDuration(duration)}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Test Suite</div>
                    <div class="info-value">Authentication & Account Management</div>
                </div>
            </div>
        </div>

        <!-- Test Results -->
        <div class="test-results">
            <h2>Test Results</h2>
            
            ${_generateTestGroups(results)}
        </div>

        <!-- Footer -->
        <div class="footer">
            <p><strong>FixMate Test Suite v1.0.0</strong></p>
            <p>Generated on ${_formatDateTime(DateTime.now())}</p>
            <p>© 2025 FixMate. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
''';
  }

  /// Generate test groups HTML
  static String _generateTestGroups(Map<String, TestResult> results) {
    final coreTests = <String, TestResult>{};
    final validationTests = <String, TestResult>{};

    for (var entry in results.entries) {
      if (entry.key.startsWith('FT-00')) {
        coreTests[entry.key] = entry.value;
      } else {
        validationTests[entry.key] = entry.value;
      }
    }

    return '''
      <div class="test-group">
        <h3>🔐 Core Authentication Tests</h3>
        ${_generateTestCases(coreTests)}
      </div>

      <div class="test-group">
        <h3>🔖 Validation & Security Tests</h3>
        ${_generateTestCases(validationTests)}
      </div>
    ''';
  }

  /// Generate test cases HTML
  static String _generateTestCases(Map<String, TestResult> tests) {
    return tests.entries.map((entry) {
      final result = entry.value;
      final statusClass = 'status-${result.status.name}';
      final statusIcon = result.status == TestStatus.passed
          ? '✅'
          : result.status == TestStatus.failed
              ? '❌'
              : '⚠️';

      return '''
        <div class="test-case">
          <div class="test-case-info">
            <div class="test-id">${entry.key}</div>
            <div class="test-name">${result.name}</div>
            ${result.duration != null ? '<div class="test-duration">Duration: ${_formatDuration(result.duration!)}</div>' : ''}
            ${result.error != null ? '<div class="test-error" style="color: #dc3545; margin-top: 10px;">${result.error}</div>' : ''}
          </div>
          <div class="test-status $statusClass">
            $statusIcon ${result.status.name.toUpperCase()}
          </div>
        </div>
      ''';
    }).join('\n');
  }

  /// Format DateTime
  static String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  /// Format Duration
  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else if (seconds > 0) {
      return '${seconds}s';
    } else {
      return '${milliseconds}ms';
    }
  }

  /// Open report in browser
  static void _openInBrowser(String path) {
    final file = File(path).absolute;

    try {
      if (Platform.isMacOS) {
        Process.run('open', [file.path]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [file.path]);
      } else if (Platform.isWindows) {
        Process.run('start', [file.path], runInShell: true);
      }
    } catch (e) {
      print('⚠️  Could not open browser automatically');
      print('   Open manually: ${file.path}');
    }
  }
}

/// Test result model
class TestResult {
  final String name;
  final TestStatus status;
  final Duration? duration;
  final String? error;

  TestResult({
    required this.name,
    required this.status,
    this.duration,
    this.error,
  });
}

/// Test status enum
enum TestStatus {
  passed,
  failed,
  skipped,
}

/// Test statistics model
class TestStatistics {
  final int total;
  final int passed;
  final int failed;
  final int skipped;
  final String successRate;

  TestStatistics({
    required this.total,
    required this.passed,
    required this.failed,
    required this.skipped,
    required this.successRate,
  });
}

/// Example usage
void main() async {
  // Sample test results
  final results = {
    'FT-001': TestResult(
      name: 'User Account Creation',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 523),
    ),
    'FT-002': TestResult(
      name: 'Email/Password Login',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 412),
    ),
    'FT-003': TestResult(
      name: 'Google OAuth Login',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 834),
    ),
    'FT-004': TestResult(
      name: 'Password Reset',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 367),
    ),
    'FT-005': TestResult(
      name: 'Account Type Selection',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 298),
    ),
    'FT-006': TestResult(
      name: 'Switch to Professional Account',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 456),
    ),
    'FT-007': TestResult(
      name: 'Two-Factor Authentication (SMS)',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 589),
    ),
    'FT-036': TestResult(
      name: 'Invalid Email Format',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 234),
    ),
    'FT-037': TestResult(
      name: 'Weak Password Validation',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 189),
    ),
    'FT-038': TestResult(
      name: 'Duplicate Email Prevention',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 345),
    ),
    'FT-039': TestResult(
      name: 'Account Lockout After Failed Attempts',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 678),
    ),
    'FT-040': TestResult(
      name: 'Unverified Email Login',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 423),
    ),
    'FT-041': TestResult(
      name: 'Password Reset with Invalid Email',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 289),
    ),
    'FT-042': TestResult(
      name: 'Google OAuth Cancelled Authorization',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 156),
    ),
    'FT-043': TestResult(
      name: 'Expired OTP Code',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 234),
    ),
    'FT-044': TestResult(
      name: 'Multiple Incorrect OTP Attempts',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 567),
    ),
    'FT-045': TestResult(
      name: 'Account Type Switch Back to Customer',
      status: TestStatus.passed,
      duration: Duration(milliseconds: 401),
    ),
  };

  final startTime = DateTime.now().subtract(Duration(minutes: 2));
  final endTime = DateTime.now();

  await TestReportGenerator.generateReport(
    results: results,
    startTime: startTime,
    endTime: endTime,
  );
}
