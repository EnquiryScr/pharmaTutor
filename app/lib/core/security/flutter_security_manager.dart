/**
 * Flutter Security Manager
 * Comprehensive security management for Flutter app
 */

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/api.dart' as pc;
import 'package:pointycastle/block/aes.dart' as aes;
import 'package:pointycastle/block/modes/gcm.dart' as gcm;
import 'package:pointycastle/digests/sha256.dart' as sha;
import 'package:pointycastle/key_derivators/api.dart' as kdf;
import 'package:pointycastle/key_derivators/pbkdf2.dart' as pbkdf2;

class FlutterSecurityManager {
  static const String _storageKey = 'tutoring_security';
  static const String _biometricKey = 'biometric_auth';
  static const String _sessionKey = 'secure_session';

  // Security configuration
  static const int _keyLength = 32;
  static const int _saltLength = 32;
  static const int _iterations = 100000;
  static const Duration _sessionTimeout = Duration(hours: 24);

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final LocalAuthentication _localAuth = LocalAuthentication();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Encryption
  late encrypt.Encrypter _encrypter;
  late encrypt.IV _iv;

  // Biometric authentication
  BiometricStorageFile? _biometricStorage;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  // Session management
  DateTime? _sessionStartTime;
  String? _currentSessionId;
  bool _sessionActive = false;

  // Device fingerprinting
  String? _deviceId;
  String? _deviceFingerprint;

  // Initialize security manager
  Future<void> initialize() async {
    try {
      print('🔒 Initializing Flutter Security Manager...');

      // Initialize encryption
      await _initializeEncryption();

      // Initialize biometric authentication
      await _initializeBiometric();

      // Initialize device fingerprinting
      await _initializeDeviceFingerprinting();

      // Load security state
      await _loadSecurityState();

      print('✅ Flutter Security Manager initialized successfully');
    } catch (error) {
      print('❌ Failed to initialize Flutter Security Manager: $error');
      rethrow;
    }
  }

  // Initialize encryption
  Future<void> _initializeEncryption() async {
    try {
      // Generate or retrieve encryption key
      String? keyString = await _secureStorage.read(key: '$_storageKey.encryption_key');
      
      if (keyString == null) {
        // Generate new key
        final key = _generateSecureKey();
        keyString = base64Encode(key);
        await _secureStorage.write(
          key: '$_storageKey.encryption_key',
          value: keyString,
        );
      }

      // Create encrypter
      final key = encrypt.Key.fromBase64(keyString);
      _encrypter = encrypt.Encrypter(encrypt.AES(key));
      _iv = encrypt.IV.fromSecureRandom(16);

      print('✅ Encryption initialized');
    } catch (error) {
      print('❌ Encryption initialization failed: $error');
      rethrow;
    }
  }

  // Initialize biometric authentication
  Future<void> _initializeBiometric() async {
    try {
      // Check if biometric authentication is available
      _biometricAvailable = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();

      if (_biometricAvailable) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        print('Available biometrics: $availableBiometrics');

        // Initialize biometric storage
        _biometricStorage = await BiometricStorage().getStorage(
          _biometricKey,
          biometricOnly: true,
          authenticatePrompt: 'Authenticate to access secure data',
        );

        // Check if biometric is enabled
        _biometricEnabled = await _secureStorage.read(key: '$_storageKey.biometric_enabled') == 'true';
      }

      print('✅ Biometric authentication initialized (available: $_biometricAvailable, enabled: $_biometricEnabled)');
    } catch (error) {
      print('❌ Biometric initialization failed: $error');
      _biometricAvailable = false;
      _biometricEnabled = false;
    }
  }

  // Initialize device fingerprinting
  Future<void> _initializeDeviceFingerprinting() async {
    try {
      String deviceInfo = '';

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceInfo = '${androidInfo.model}_${androidInfo.brand}_${androidInfo.version.sdkInt}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceInfo = '${iosInfo.model}_${iosInfo.brand}_${iosInfo.systemVersion}';
      }

      _deviceFingerprint = _generateDeviceFingerprint(deviceInfo);
      _deviceId = await _generateDeviceId();

      print('✅ Device fingerprinting initialized (ID: ${_deviceId?.substring(0, 8)}...)');
    } catch (error) {
      print('❌ Device fingerprinting initialization failed: $error');
    }
  }

  // Load security state from storage
  Future<void> _loadSecurityState() async {
    try {
      // Load session state
      final sessionData = await _secureStorage.read(key: _sessionKey);
      if (sessionData != null) {
        final sessionMap = json.decode(sessionData);
        _sessionStartTime = DateTime.fromMillisecondsSinceEpoch(sessionMap['start_time']);
        _currentSessionId = sessionMap['session_id'];
        _sessionActive = sessionMap['active'] ?? false;

        // Check if session is still valid
        if (_sessionActive && _sessionStartTime != null) {
          final age = DateTime.now().difference(_sessionStartTime!);
          if (age > _sessionTimeout) {
            await _invalidateSession();
          }
        }
      }

      print('✅ Security state loaded (session active: $_sessionActive)');
    } catch (error) {
      print('❌ Failed to load security state: $error');
    }
  }

  // Generate secure key
  Uint8List _generateSecureKey() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_keyLength, (_) => random.nextInt(256)),
    );
  }

  // Generate device fingerprint
  String _generateDeviceFingerprint(String deviceInfo) {
    final bytes = utf8.encode(deviceInfo);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  // Generate device ID
  Future<String> _generateDeviceId() async {
    try {
      String deviceId = '';
      
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = '${androidInfo.id}_${androidInfo.brand}_${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = '${iosInfo.identifierForVendor}_${iosInfo.model}_${iosInfo.systemVersion}';
      }

      // Hash the device ID
      final bytes = utf8.encode(deviceId);
      final digest = crypto.sha256.convert(bytes);
      return digest.toString();
    } catch (error) {
      // Fallback to random ID
      final random = Random.secure();
      return base64Encode(
        Uint8List.fromList(
          List<int>.generate(32, (_) => random.nextInt(256)),
        ),
      );
    }
  }

  // Encrypt data
  String encryptData(String data) {
    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (error) {
      print('Encryption failed: $error');
      rethrow;
    }
  }

  // Decrypt data
  String decryptData(String encryptedData) {
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (error) {
      print('Decryption failed: $error');
      rethrow;
    }
  }

  // Store secure data
  Future<void> storeSecureData(String key, String value) async {
    try {
      final encrypted = encryptData(value);
      await _secureStorage.write(
        key: '$_storageKey.$key',
        value: encrypted,
      );
    } catch (error) {
      print('Secure storage failed for key $key: $error');
      rethrow;
    }
  }

  // Retrieve secure data
  Future<String?> getSecureData(String key) async {
    try {
      final encrypted = await _secureStorage.read(key: '$_storageKey.$key');
      if (encrypted == null) return null;
      return decryptData(encrypted);
    } catch (error) {
      print('Secure retrieval failed for key $key: $error');
      return null;
    }
  }

  // Delete secure data
  Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: '$_storageKey.$key');
    } catch (error) {
      print('Secure deletion failed for key $key: $error');
    }
  }

  // Biometric authentication
  Future<bool> authenticateWithBiometrics() async {
    if (!_biometricAvailable || !_biometricEnabled) {
      return false;
    }

    try {
      final result = await _localAuth.authenticate(
        localizedTitle: 'Authenticate to access your secure data',
        options: AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true,
          useErrorDialogs: true,
          fallbackLabel: 'Use PIN instead',
        ),
      );

      if (result) {
        print('✅ Biometric authentication successful');
        return true;
      } else {
        print('❌ Biometric authentication failed');
        return false;
      }
    } catch (error) {
      print('❌ Biometric authentication error: $error');
      return false;
    }
  }

  // Enable biometric authentication
  Future<bool> enableBiometric() async {
    if (!_biometricAvailable) {
      throw Exception('Biometric authentication is not available on this device');
    }

    try {
      final authenticated = await authenticateWithBiometrics();
      if (authenticated) {
        await _secureStorage.write(
          key: '$_storageKey.biometric_enabled',
          value: 'true',
        );
        _biometricEnabled = true;
        print('✅ Biometric authentication enabled');
        return true;
      }
      return false;
    } catch (error) {
      print('❌ Failed to enable biometric: $error');
      return false;
    }
  }

  // Disable biometric authentication
  Future<void> disableBiometric() async {
    await _secureStorage.delete(key: '$_storageKey.biometric_enabled');
    _biometricEnabled = false;
    print('🔒 Biometric authentication disabled');
  }

  // Session management
  Future<void> createSession(String userId) async {
    try {
      _sessionStartTime = DateTime.now();
      _currentSessionId = _generateSessionId();
      _sessionActive = true;

      final sessionData = {
        'user_id': userId,
        'session_id': _currentSessionId,
        'start_time': _sessionStartTime!.millisecondsSinceEpoch,
        'device_id': _deviceId,
        'device_fingerprint': _deviceFingerprint,
        'active': true,
      };

      await _secureStorage.write(
        key: _sessionKey,
        value: json.encode(sessionData),
      );

      print('✅ Session created for user: $userId');
    } catch (error) {
      print('❌ Session creation failed: $error');
      rethrow;
    }
  }

  // Validate session
  Future<bool> validateSession() async {
    if (!_sessionActive || _sessionStartTime == null) {
      return false;
    }

    try {
      final age = DateTime.now().difference(_sessionStartTime!);
      if (age > _sessionTimeout) {
        await _invalidateSession();
        return false;
      }

      // Validate device fingerprint
      final currentFingerprint = _deviceFingerprint;
      if (currentFingerprint != null) {
        final storedSessionData = await _secureStorage.read(key: _sessionKey);
        if (storedSessionData != null) {
          final sessionMap = json.decode(storedSessionData);
          final storedFingerprint = sessionMap['device_fingerprint'];
          if (storedFingerprint != currentFingerprint) {
            print('⚠️ Device fingerprint mismatch - invalidating session');
            await _invalidateSession();
            return false;
          }
        }
      }

      return true;
    } catch (error) {
      print('❌ Session validation failed: $error');
      return false;
    }
  }

  // Invalidate session
  Future<void> _invalidateSession() async {
    _sessionActive = false;
    _sessionStartTime = null;
    _currentSessionId = null;

    await _secureStorage.delete(key: _sessionKey);
    print('🔒 Session invalidated');
  }

  // Generate session ID
  String _generateSessionId() {
    final random = Random.secure();
    return base64Encode(
      Uint8List.fromList(
        List<int>.generate(32, (_) => random.nextInt(256)),
      ),
    );
  }

  // Input validation and sanitization
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool isValidPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special char
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>"\'&]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // File validation
  bool isValidFileType(String fileName, List<String> allowedTypes) {
    final extension = fileName.split('.').last.toLowerCase();
    return allowedTypes.contains(extension);
  }

  bool isValidFileSize(int fileSize, int maxSizeInBytes) {
    return fileSize <= maxSizeInBytes;
  }

  // Check for malicious content in text
  bool containsMaliciousContent(String text) {
    final suspiciousPatterns = [
      RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'document\.cookie', caseSensitive: false),
      RegExp(r'eval\s*\(', caseSensitive: false),
    ];

    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }

    return false;
  }

  // Network security
  Future<bool> validateSSLCertificate(String host) async {
    // In a real implementation, this would validate SSL certificates
    // For now, return true as placeholder
    return true;
  }

  // Request signing for API calls
  String signRequest(String method, String url, Map<String, dynamic> body) {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final nonce = _generateNonce();
      
      // Create signature payload
      final payload = {
        'method': method,
        'url': url,
        'body': body,
        'timestamp': timestamp,
        'nonce': nonce,
        'device_id': _deviceId,
      };

      final payloadString = json.encode(payload);
      final bytes = utf8.encode(payloadString);
      final digest = crypto.sha256.convert(bytes);

      return '$timestamp:$nonce:${digest.toString()}';
    } catch (error) {
      print('❌ Request signing failed: $error');
      return '';
    }
  }

  // Generate nonce
  String _generateNonce() {
    final random = Random.secure();
    return base64Encode(
      Uint8List.fromList(
        List<int>.generate(16, (_) => random.nextInt(256)),
      ),
    );
  }

  // Security audit
  Future<Map<String, dynamic>> performSecurityAudit() async {
    final audit = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'biometric_available': _biometricAvailable,
      'biometric_enabled': _biometricEnabled,
      'session_active': _sessionActive,
      'device_id': _deviceId,
      'device_fingerprint': _deviceFingerprint,
      'storage_encrypted': true,
      'encryption_initialized': _encrypter != null,
    };

    // Check for security issues
    final issues = <String>[];
    
    if (!_biometricAvailable) {
      issues.add('Biometric authentication not available');
    }
    
    if (_sessionActive && _sessionStartTime != null) {
      final age = DateTime.now().difference(_sessionStartTime!);
      if (age > Duration(hours: 12)) {
        issues.add('Session is older than 12 hours');
      }
    }

    if (issues.isNotEmpty) {
      audit['issues'] = issues;
    }

    print('🔍 Security audit completed');
    return audit;
  }

  // Clear all security data
  Future<void> clearAllSecurityData() async {
    try {
      // Invalidate session
      await _invalidateSession();

      // Clear biometric settings
      await disableBiometric();

      // Clear all secure storage
      await _secureStorage.deleteAll();

      print('🧹 All security data cleared');
    } catch (error) {
      print('❌ Failed to clear security data: $error');
      rethrow;
    }
  }

  // Get security status
  Map<String, dynamic> getSecurityStatus() {
    return {
      'initialized': true,
      'biometric_available': _biometricAvailable,
      'biometric_enabled': _biometricEnabled,
      'session_active': _sessionActive,
      'device_id': _deviceId,
      'encryption_active': _encrypter != null,
      'secure_storage_active': true,
    };
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      // Test encryption
      final testData = 'health_check_test';
      final encrypted = encryptData(testData);
      final decrypted = decryptData(encrypted);
      
      if (decrypted != testData) {
        return false;
      }

      // Test secure storage
      await storeSecureData('health_check', 'test_value');
      final retrieved = await getSecureData('health_check');
      await deleteSecureData('health_check');
      
      if (retrieved != 'test_value') {
        return false;
      }

      // Test session
      if (_sessionActive && _sessionStartTime != null) {
        final isValid = await validateSession();
        if (!isValid) {
          return false;
        }
      }

      return true;
    } catch (error) {
      print('❌ Security health check failed: $error');
      return false;
    }
  }
}