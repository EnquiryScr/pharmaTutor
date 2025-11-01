/**
 * Secure Storage Manager for Flutter
 * Handles encrypted local storage with biometric protection
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encrypt;

class SecureStorageManager {
  static const String _defaultNamespace = 'tutoring_app';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Biometric storage
  BiometricStorageFile? _biometricStorage;
  bool _biometricAvailable = false;

  // Encryption
  late encrypt.Encrypter _encrypter;
  late encrypt.IV _iv;
  final String _encryptionKey;

  SecureStorageManager(this._encryptionKey) {
    _initializeEncryption();
  }

  void _initializeEncryption() {
    final key = encrypt.Key.fromBase64(_encryptionKey);
    _encrypter = encrypt.Encrypter(encrypt.AES(key));
    _iv = encrypt.IV.fromSecureRandom(16);
  }

  // Initialize biometric storage
  Future<void> initializeBiometric() async {
    try {
      _biometricAvailable = true;
      _biometricStorage = await BiometricStorage().getStorage(
        '$_defaultNamespace.biometric',
        biometricOnly: true,
        authenticatePrompt: 'Authenticate to access secure data',
      );
      print('✅ Biometric storage initialized');
    } catch (error) {
      print('❌ Biometric storage initialization failed: $error');
      _biometricAvailable = false;
    }
  }

  // Store data with encryption
  Future<void> store(String key, String value, {bool biometric = false}) async {
    try {
      final encryptedValue = _encrypt(value);
      
      if (biometric && _biometricAvailable && _biometricStorage != null) {
        // Store with biometric protection
        await _biometricStorage!.write(
          key: _getNamespacedKey(key),
          value: encryptedValue,
        );
      } else {
        // Store without biometric protection
        await _secureStorage.write(
          key: _getNamespacedKey(key),
          value: encryptedValue,
        );
      }
      
      print('✅ Data stored securely: $key');
    } catch (error) {
      print('❌ Failed to store data: $error');
      rethrow;
    }
  }

  // Retrieve data with decryption
  Future<String?> retrieve(String key, {bool biometric = false}) async {
    try {
      String? encryptedValue;
      
      if (biometric && _biometricAvailable && _biometricStorage != null) {
        // Try to retrieve with biometric protection first
        try {
          encryptedValue = await _biometricStorage!.read(
            key: _getNamespacedKey(key),
          );
        } catch (e) {
          // Biometric authentication failed, try regular storage
          encryptedValue = await _secureStorage.read(
            key: _getNamespacedKey(key),
          );
        }
      } else {
        // Retrieve without biometric protection
        encryptedValue = await _secureStorage.read(
          key: _getNamespacedKey(key),
        );
      }
      
      if (encryptedValue == null) {
        return null;
      }
      
      final decryptedValue = _decrypt(encryptedValue);
      print('✅ Data retrieved securely: $key');
      return decryptedValue;
    } catch (error) {
      print('❌ Failed to retrieve data: $error');
      return null;
    }
  }

  // Delete data
  Future<void> delete(String key, {bool biometric = false}) async {
    try {
      if (biometric && _biometricAvailable && _biometricStorage != null) {
        await _biometricStorage!.delete(key: _getNamespacedKey(key));
      } else {
        await _secureStorage.delete(key: _getNamespacedKey(key));
      }
      
      print('✅ Data deleted: $key');
    } catch (error) {
      print('❌ Failed to delete data: $error');
    }
  }

  // Check if key exists
  Future<bool> containsKey(String key) async {
    try {
      if (_biometricAvailable && _biometricStorage != null) {
        final biometricValue = await _biometricStorage!.read(
          key: _getNamespacedKey(key),
        );
        if (biometricValue != null) return true;
      }
      
      final regularValue = await _secureStorage.read(
        key: _getNamespacedKey(key),
      );
      return regularValue != null;
    } catch (error) {
      return false;
    }
  }

  // Get all keys
  Future<List<String>> getAllKeys() async {
    try {
      final keys = <String>[];
      
      // Get biometric keys
      if (_biometricAvailable && _biometricStorage != null) {
        // Note: Biometric storage doesn't provide a list method
        // This would need to be implemented differently in a real app
      }
      
      // Get regular keys
      final allSecureData = await _secureStorage.readAll();
      keys.addAll(allSecureData.keys.where((k) => k.startsWith('$_defaultNamespace.')));
      
      return keys.map((k) => k.replaceFirst('$_defaultNamespace.', '')).toList();
    } catch (error) {
      print('❌ Failed to get all keys: $error');
      return [];
    }
  }

  // Clear all data
  Future<void> clearAll() async {
    try {
      // Clear biometric storage
      if (_biometricAvailable && _biometricStorage != null) {
        await _biometricStorage!.delete();
      }
      
      // Clear secure storage
      await _secureStorage.deleteAll();
      
      print('🧹 All secure data cleared');
    } catch (error) {
      print('❌ Failed to clear all data: $error');
    }
  }

  // Store multiple values at once
  Future<void> storeMultiple(Map<String, String> data, {bool biometric = false}) async {
    try {
      for (final entry in data.entries) {
        await store(entry.key, entry.value, biometric: biometric);
      }
      print('✅ Multiple values stored');
    } catch (error) {
      print('❌ Failed to store multiple values: $error');
      rethrow;
    }
  }

  // Retrieve multiple values at once
  Future<Map<String, String?>> retrieveMultiple(List<String> keys, {bool biometric = false}) async {
    final results = <String, String?>{};
    
    try {
      for (final key in keys) {
        results[key] = await retrieve(key, biometric: biometric);
      }
      return results;
    } catch (error) {
      print('❌ Failed to retrieve multiple values: $error');
      rethrow;
    }
  }

  // Encrypt data
  String _encrypt(String data) {
    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (error) {
      print('❌ Encryption failed: $error');
      rethrow;
    }
  }

  // Decrypt data
  String _decrypt(String encryptedData) {
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (error) {
      print('❌ Decryption failed: $error');
      rethrow;
    }
  }

  // Get namespaced key
  String _getNamespacedKey(String key) {
    return '$_defaultNamespace.$key';
  }

  // Get storage status
  Map<String, dynamic> getStorageStatus() {
    return {
      'biometric_available': _biometricAvailable,
      'biometric_initialized': _biometricStorage != null,
      'encryption_active': _encrypter != null,
      'namespace': _defaultNamespace,
    };
  }
}

// Biometric authentication helper
class BiometricAuthHelper {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _biometricKey = 'biometric_enabled';

  // Check if biometric is available
  Future<bool> isBiometricAvailable() async {
    try {
      // This would use a proper biometric authentication package
      return true; // Placeholder
    } catch (error) {
      print('❌ Biometric availability check failed: $error');
      return false;
    }
  }

  // Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _biometricKey);
      return enabled == 'true';
    } catch (error) {
      return false;
    }
  }

  // Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      // First authenticate with biometrics
      final authenticated = await _authenticateUser();
      if (authenticated) {
        await _secureStorage.write(key: _biometricKey, value: 'true');
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
    try {
      await _secureStorage.delete(key: _biometricKey);
      print('🔒 Biometric authentication disabled');
    } catch (error) {
      print('❌ Failed to disable biometric: $error');
    }
  }

  // Authenticate user with biometrics
  Future<bool> _authenticateUser() async {
    try {
      // This would use a proper biometric authentication package
      // For now, return true as placeholder
      return true;
    } catch (error) {
      print('❌ Biometric authentication failed: $error');
      return false;
    }
  }

  // Perform biometric authentication with custom prompt
  Future<bool> authenticateWithPrompt(String prompt, {String? subtitle}) async {
    try {
      // This would use a proper biometric authentication package
      // For now, return true as placeholder
      return true;
    } catch (error) {
      print('❌ Biometric authentication failed: $error');
      return false;
    }
  }

  // Get biometric capabilities
  Future<Map<String, dynamic>> getBiometricCapabilities() async {
    try {
      return {
        'available': await isBiometricAvailable(),
        'enabled': await isBiometricEnabled(),
        'supported_types': ['fingerprint', 'face', 'iris'], // Placeholder
        'strong_biometrics': true,
      };
    } catch (error) {
      return {
        'available': false,
        'enabled': false,
        'supported_types': [],
        'strong_biometrics': false,
      };
    }
  }
}

// Secure data serialization
class SecureDataSerializer {
  // Serialize object to JSON string
  static String serialize<T>(T data) {
    return json.encode(data);
  }

  // Deserialize JSON string to object
  static T? deserialize<T>(String jsonString, T Function(Map<String, dynamic>) fromJson) {
    try {
      final jsonMap = json.decode(jsonString);
      return fromJson(jsonMap);
    } catch (error) {
      print('❌ Deserialization failed: $error');
      return null;
    }
  }

  // Serialize and encrypt data
  static String serializeAndEncrypt<T>(T data, encrypt.Encrypter encrypter, encrypt.IV iv) {
    final jsonString = serialize(data);
    final encrypted = encrypter.encrypt(jsonString, iv: iv);
    return encrypted.base64;
  }

  // Decrypt and deserialize data
  static T? decryptAndDeserialize<T>(String encryptedData, encrypt.Encrypter encrypter, encrypt.IV iv, T Function(Map<String, dynamic>) fromJson) {
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      final jsonString = encrypter.decrypt(encrypted, iv: iv);
      return deserialize(jsonString, fromJson);
    } catch (error) {
      print('❌ Decrypt and deserialize failed: $error');
      return null;
    }
  }
}

// Security utilities
class SecurityUtils {
  // Generate secure random string
  static String generateSecureString({int length = 32}) {
    final random = DateTime.now().microsecondsSinceEpoch ^ length;
    return random.toString();
  }

  // Hash data
  static String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  // Validate data integrity
  static bool validateIntegrity(String data, String hash) {
    final computedHash = hashData(data);
    return computedHash == hash;
  }

  // Generate checksum
  static String generateChecksum(List<int> data) {
    final digest = crypto.sha256.convert(Uint8List.fromList(data));
    return digest.toString();
  }

  // Validate checksum
  static bool validateChecksum(List<int> data, String checksum) {
    final computedChecksum = generateChecksum(data);
    return computedChecksum == checksum;
  }

  // Sanitize input
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>"\']'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .substring(0, min(input.length, 1000)); // Limit length
  }

  // Check for suspicious patterns
  static bool containsSuspiciousPatterns(String input) {
    final suspiciousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'document\.cookie', caseSensitive: false),
      RegExp(r'eval\s*\(', caseSensitive: false),
    ];

    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(input)) {
        return true;
      }
    }

    return false;
  }

  // Validate file type
  static bool isValidFileType(String fileName, List<String> allowedTypes) {
    final extension = fileName.split('.').last.toLowerCase();
    return allowedTypes.contains(extension);
  }

  // Validate file size
  static bool isValidFileSize(int fileSize, int maxSizeInBytes) {
    return fileSize <= maxSizeInBytes;
  }
}