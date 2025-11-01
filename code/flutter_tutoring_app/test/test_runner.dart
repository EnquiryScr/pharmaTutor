import 'dart:io';

import '../test_config.dart';
import '../helpers/test_helpers.dart';

/// Comprehensive test runner for the Flutter tutoring platform
/// 
/// This script provides a centralized way to run all types of tests:
/// - Unit tests
/// - Widget tests
/// - Integration tests
/// - Performance tests
/// - Accessibility tests
/// 
/// Usage:
/// ```bash
/// dart test_runner.dart --type all
/// dart test_runner.dart --type unit --coverage
/// dart test_runner.dart --type integration
/// dart test_runner.dart --type performance
/// dart test_runner.dart --type accessibility
/// ```

class TestRunner {
  final List<String> arguments;
  TestRunner(this.arguments);

  // Test configuration
  static const String testDirectory = 'test';
  static const String integrationTestDirectory = 'integration_test';
  
  // Colors for output
  static const String green = '\x1B[32m';
  static const String red = '\x1B[31m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';

  Future<void> run() async {
    print('${bold}${blue}Flutter Tutoring Platform - Comprehensive Test Runner${reset}');
    print('=' * 60);

    final type = _parseTestType();
    final shouldGenerateCoverage = _shouldGenerateCoverage();
    final verbose = _isVerbose();
    final parallel = _shouldRunParallel();

    print('${blue}Configuration:${reset}');
    print('  Test Type: $type');
    print('  Coverage: ${shouldGenerateCoverage ? "Enabled" : "Disabled"}');
    print('  Verbose: ${verbose ? "Enabled" : "Disabled"}');
    print('  Parallel: ${parallel ? "Enabled" : "Disabled"}');
    print('');

    final stopwatch = Stopwatch()..start();

    try {
      switch (type) {
        case 'unit':
          await _runUnitTests(
            generateCoverage: shouldGenerateCoverage,
            verbose: verbose,
            parallel: parallel,
          );
          break;
        case 'widget':
          await _runWidgetTests(
            generateCoverage: shouldGenerateCoverage,
            verbose: verbose,
            parallel: parallel,
          );
          break;
        case 'integration':
          await _runIntegrationTests(
            verbose: verbose,
          );
          break;
        case 'performance':
          await _runPerformanceTests(
            verbose: verbose,
          );
          break;
        case 'accessibility':
          await _runAccessibilityTests(
            verbose: verbose,
          );
          break;
        case 'all':
          await _runAllTests(
            generateCoverage: shouldGenerateCoverage,
            verbose: verbose,
            parallel: parallel,
          );
          break;
        default:
          throw ArgumentError('Unknown test type: $type');
      }

      stopwatch.stop();
      print('\n${bold}${green}✅ All tests completed successfully!${reset}');
      print('${blue}Total execution time: ${stopwatch.elapsedMilliseconds}ms${reset}');

    } catch (e) {
      stopwatch.stop();
      print('\n${bold}${red}❌ Test execution failed!${reset}');
      print('${red}Error: $e${reset}');
      print('${blue}Execution time before failure: ${stopwatch.elapsedMilliseconds}ms${reset}');
      exit(1);
    }
  }

  String _parseTestType() {
    for (int i = 0; i < arguments.length; i++) {
      if (arguments[i] == '--type' && i + 1 < arguments.length) {
        return arguments[i + 1];
      }
    }
    return 'all'; // Default to all tests
  }

  bool _shouldGenerateCoverage() {
    return arguments.contains('--coverage') || arguments.contains('-c');
  }

  bool _isVerbose() {
    return arguments.contains('--verbose') || arguments.contains('-v');
  }

  bool _shouldRunParallel() {
    return !arguments.contains('--no-parallel') && !arguments.contains('-np');
  }

  Future<void> _runUnitTests({
    required bool generateCoverage,
    required bool verbose,
    required bool parallel,
  }) async {
    print('${blue}🧪 Running Unit Tests...${reset}');

    final command = [
      'flutter',
      'test',
      '$testDirectory/unit/',
      if (generateCoverage) '--coverage',
      if (verbose) '--verbose',
      if (parallel) '--concurrency=4',
    ];

    print('${yellow}Command: ${command.join(' ')}${reset}');
    
    final result = await Process.run(
      command.first,
      command.sublist(1),
      workingDirectory: Directory.current.path,
    );

    print(result.stdout);
    if (result.stderr.isNotEmpty) {
      print('${red}Errors:${reset}');
      print(result.stderr);
    }

    if (result.exitCode != 0) {
      throw Exception('Unit tests failed with exit code ${result.exitCode}');
    }

    print('${green}✅ Unit tests passed!${reset}');
  }

  Future<void> _runWidgetTests({
    required bool generateCoverage,
    required bool verbose,
    required bool parallel,
  }) async {
    print('${blue}🖼️ Running Widget Tests...${reset}');

    final command = [
      'flutter',
      'test',
      '$testDirectory/widget/',
      if (generateCoverage) '--coverage',
      if (verbose) '--verbose',
      if (parallel) '--concurrency=2',
    ];

    print('${yellow}Command: ${command.join(' ')}${reset}');
    
    final result = await Process.run(
      command.first,
      command.sublist(1),
      workingDirectory: Directory.current.path,
    );

    print(result.stdout);
    if (result.stderr.isNotEmpty) {
      print('${red}Errors:${reset}');
      print(result.stderr);
    }

    if (result.exitCode != 0) {
      throw Exception('Widget tests failed with exit code ${result.exitCode}');
    }

    print('${green}✅ Widget tests passed!${reset}');
  }

  Future<void> _runIntegrationTests({
    required bool verbose,
  }) async {
    print('${blue}🔗 Running Integration Tests...${reset}');

    final command = [
      'flutter',
      'test',
      '$integrationTestDirectory/',
      if (verbose) '--verbose',
    ];

    print('${yellow}Command: ${command.join(' ')}${reset}');
    
    final result = await Process.run(
      command.first,
      command.sublist(1),
      workingDirectory: Directory.current.path,
    );

    print(result.stdout);
    if (result.stderr.isNotEmpty) {
      print('${red}Errors:${reset}');
      print(result.stderr);
    }

    if (result.exitCode != 0) {
      throw Exception('Integration tests failed with exit code ${result.exitCode}');
    }

    print('${green}✅ Integration tests passed!${reset}');
  }

  Future<void> _runPerformanceTests({
    required bool verbose,
  }) async {
    print('${blue}⚡ Running Performance Tests...${reset}');
    print('${yellow}Note: Performance tests may take longer to complete${reset}');

    final command = [
      'flutter',
      'test',
      '$integrationTestDirectory/performance/',
      if (verbose) '--verbose',
    ];

    print('${yellow}Command: ${command.join(' ')}${reset}');
    
    final result = await Process.run(
      command.first,
      command.sublist(1),
      workingDirectory: Directory.current.path,
    );

    print(result.stdout);
    if (result.stderr.isNotEmpty) {
      print('${red}Errors:${reset}');
      print(result.stderr);
    }

    if (result.exitCode != 0) {
      throw Exception('Performance tests failed with exit code ${result.exitCode}');
    }

    print('${green}✅ Performance tests passed!${reset}');
  }

  Future<void> _runAccessibilityTests({
    required bool verbose,
  }) async {
    print('${blue}♿ Running Accessibility Tests...${reset}');

    final command = [
      'flutter',
      'test',
      '$integrationTestDirectory/accessibility/',
      if (verbose) '--verbose',
    ];

    print('${yellow}Command: ${command.join(' ')}${reset}');
    
    final result = await Process.run(
      command.first,
      command.sublist(1),
      workingDirectory: Directory.current.path,
    );

    print(result.stdout);
    if (result.stderr.isNotEmpty) {
      print('${red}Errors:${reset}');
      print(result.stderr);
    }

    if (result.exitCode != 0) {
      throw Exception('Accessibility tests failed with exit code ${result.exitCode}');
    }

    print('${green}✅ Accessibility tests passed!${reset}');
  }

  Future<void> _runAllTests({
    required bool generateCoverage,
    required bool verbose,
    required bool parallel,
  }) async {
    print('${blue}🚀 Running All Tests...${reset}');
    print('${yellow}This will run all test suites in sequence${reset}');
    print('');

    await _runUnitTests(
      generateCoverage: generateCoverage,
      verbose: verbose,
      parallel: parallel,
    );

    print('');

    await _runWidgetTests(
      generateCoverage: generateCoverage,
      verbose: verbose,
      parallel: parallel,
    );

    print('');

    await _runIntegrationTests(verbose: verbose);

    print('');

    await _runPerformanceTests(verbose: verbose);

    print('');

    await _runAccessibilityTests(verbose: verbose);

    print('');
    print('${green}🎉 All test suites completed successfully!${reset}');
  }
}

/// Test analysis and reporting utilities
class TestAnalyzer {
  static void generateTestReport() {
    print('${blue}📊 Generating Test Report...${reset}');
    
    // Analyze test coverage
    _analyzeCoverage();
    
    // Analyze test performance
    _analyzePerformance();
    
    // Analyze test structure
    _analyzeTestStructure();
  }

  static void _analyzeCoverage() {
    print('\n${bold}Coverage Analysis:${reset}');
    
    final coverageFiles = [
      'coverage/lcov.info',
      'coverage/index.html',
    ];
    
    for (final file in coverageFiles) {
      final filePath = File(file);
      if (filePath.existsSync()) {
        print('${green}✅ $file exists${reset}');
      } else {
        print('${red}❌ $file not found${reset}');
      }
    }
    
    // Parse coverage report if available
    final lcovFile = File('coverage/lcov.info');
    if (lcovFile.existsSync()) {
      final lines = lcovFile.readAsLinesSync();
      final totalLines = lines.where((line) => line.startsWith('DA:')).length;
      final coveredLines = lines.where((line) => 
        line.startsWith('DA:') && !line.endsWith(',0')).length;
      
      if (totalLines > 0) {
        final coveragePercentage = (coveredLines / totalLines * 100);
        print('${blue}Coverage: ${coveragePercentage.toStringAsFixed(1)}% ($coveredLines/$totalLines lines)${reset}');
        
        if (coveragePercentage >= 90) {
          print('${green}✅ Excellent coverage (>90%)${reset}');
        } else if (coveragePercentage >= 80) {
          print('${yellow}⚠️ Good coverage (80-90%)${reset}');
        } else {
          print('${red}❌ Low coverage (<80%)${reset}');
        }
      }
    }
  }

  static void _analyzePerformance() {
    print('\n${bold}Performance Analysis:${reset}');
    
    // Analyze test execution times
    final testFiles = _findTestFiles();
    print('${blue}Test Files Found: ${testFiles.length}${reset}');
    
    for (final file in testFiles.take(5)) { // Show first 5
      print('  - ${file.path}');
    }
    
    if (testFiles.length > 5) {
      print('  ... and ${testFiles.length - 5} more');
    }
  }

  static void _analyzeTestStructure() {
    print('\n${bold}Test Structure Analysis:${reset}');
    
    final structure = {
      'Unit Tests': _countTestFiles('test/unit'),
      'Widget Tests': _countTestFiles('test/widget'),
      'Integration Tests': _countTestFiles('test/integration'),
      'Integration Test Directory': _countTestFiles('integration_test'),
    };
    
    for (final entry in structure.entries) {
      print('${blue}${entry.key}: ${entry.value} files${reset}');
    }
  }

  static List<FileSystemEntity> _findTestFiles() {
    final directory = Directory('test');
    if (!directory.existsSync()) {
      return [];
    }
    
    return directory
        .listSync(recursive: true)
        .where((entity) => 
            entity is File && 
            entity.path.endsWith('_test.dart'))
        .toList();
  }

  static int _countTestFiles(String path) {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      return 0;
    }
    
    return directory
        .listSync(recursive: true)
        .where((entity) => 
            entity is File && 
            entity.path.endsWith('_test.dart'))
        .length;
  }
}

/// Utility functions for test execution
class TestUtils {
  static Future<void> setupTestEnvironment() async {
    print('${blue}🔧 Setting up test environment...${reset}');
    
    // Clean previous test results
    await _cleanTestArtifacts();
    
    // Setup mock services
    await _setupMockServices();
    
    // Initialize test configuration
    TestHelpers.validateTestConfig();
    
    print('${green}✅ Test environment setup complete${reset}');
  }

  static Future<void> _cleanTestArtifacts() async {
    final artifacts = [
      '.dart_tool/test_cache',
      'coverage',
      'test_results',
    ];
    
    for (final artifact in artifacts) {
      final directory = Directory(artifact);
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
        print('${yellow}Cleaned: $artifact${reset}');
      }
    }
  }

  static Future<void> _setupMockServices() async {
    print('${yellow}Setting up mock services...${reset}');
    // Initialize mock services for testing
    // This would typically involve setting up test doubles
  }

  static void printUsage() {
    print('${bold}Flutter Tutoring Platform - Test Runner${reset}');
    print('');
    print('Usage:');
    print('  dart test_runner.dart [options]');
    print('');
    print('Options:');
    print('  --type <type>          Test type to run (unit|widget|integration|performance|accessibility|all)');
    print('  --coverage, -c         Generate coverage report');
    print('  --verbose, -v          Verbose output');
    print('  --no-parallel, -np     Run tests sequentially (not parallel)');
    print('  --help, -h             Show this help message');
    print('');
    print('Examples:');
    print('  dart test_runner.dart --type all');
    print('  dart test_runner.dart --type unit --coverage');
    print('  dart test_runner.dart --type integration --verbose');
    print('  dart test_runner.dart --type performance');
  }
}

void main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    TestUtils.printUsage();
    return;
  }

  // Setup test environment
  await TestUtils.setupTestEnvironment();

  // Run tests
  final runner = TestRunner(arguments);
  await runner.run();

  // Generate test report
  TestAnalyzer.generateTestReport();

  print('\n${bold}${green}🎯 Test execution completed!${reset}');
  print('${blue}Check the output above for detailed results${reset}');
}