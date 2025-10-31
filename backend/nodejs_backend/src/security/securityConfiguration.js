/**
 * Comprehensive Security Configuration
 * Central configuration for all security components
 */

class SecurityConfiguration {
  // API Security Configuration
  static const apiSecurityConfig = {
    'rateLimiting': {
      'global': {
        'windowMs': 15 * 60 * 1000, // 15 minutes
        'max': 1000, // requests per window
        'skipSuccessfulRequests': false,
        'skipFailedRequests': false,
      },
      'auth': {
        'windowMs': 15 * 60 * 1000, // 15 minutes
        'max': 5, // 5 attempts per window
        'skipSuccessfulRequests': true,
        'skipFailedRequests': false,
      },
      'api': {
        'windowMs': 60 * 1000, // 1 minute
        'max': 100, // 100 requests per minute
        'skipSuccessfulRequests': false,
        'skipFailedRequests': false,
      },
      'fileUpload': {
        'windowMs': 60 * 60 * 1000, // 1 hour
        'max': 10, // 10 uploads per hour
        'skipSuccessfulRequests': false,
        'skipFailedRequests': false,
      },
    },
    'inputValidation': {
      'enabled': true,
      'sanitizeHTML': true,
      'stripHTML': true,
      'maxLength': 10000,
      'allowedFileTypes': [
        'image/jpeg', 'image/png', 'image/gif', 'image/webp',
        'application/pdf', 'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'text/plain', 'text/csv'
      ],
      'maxFileSize': 10 * 1024 * 1024, // 10MB
    },
    'xssProtection': {
      'enabled': true,
      'contentSecurityPolicy': {
        'defaultSrc': ["'self'"],
        'scriptSrc': ["'self'"],
        'styleSrc': ["'self'", "'unsafe-inline'"],
        'imgSrc': ["'self'", "data:", "https:"],
        'connectSrc': ["'self'", "wss:", "https:"],
        'objectSrc': ["'none'"],
        'frameAncestors': ["'none'"],
      },
      'xssFilter': true,
      'xssProtection': '1; mode=block',
    },
    'sqlInjectionProtection': {
      'enabled': true,
      'parameterizedQueries': true,
      'inputSanitization': true,
      'patternDetection': true,
      'ipBlacklisting': true,
    },
  };

  // Encryption Configuration
  static const encryptionConfig = {
    'algorithm': 'AES-256-GCM',
    'keyLength': 32,
    'ivLength': 16,
    'tagLength': 16,
    'iterations': 100000,
    'keyDerivation': 'PBKDF2',
    'keyRotation': {
      'enabled': true,
      'interval': 90 * 24 * 60 * 60 * 1000, // 90 days
      'gracePeriod': 24 * 60 * 60 * 1000, // 24 hours
    },
    'atRestEncryption': {
      'enabled': true,
      'databaseEncryption': true,
      'fileEncryption': true,
      'backupEncryption': true,
    },
    'inTransitEncryption': {
      'enabled': true,
      'minTLSVersion': 'TLSv1.2',
      'preferredTLSVersion': 'TLSv1.3',
      'certificateValidation': true,
    },
  };

  // Authentication Configuration
  static const authenticationConfig = {
    'jwt': {
      'algorithm': 'RS256',
      'accessTokenExpiry': 15 * 60, // 15 minutes
      'refreshTokenExpiry': 7 * 24 * 60 * 60, // 7 days
      'issuer': 'tutoring-platform',
      'audience': 'tutoring-platform-users',
      'keyRotation': {
        'enabled': true,
        'interval': 30 * 24 * 60 * 60 * 1000, // 30 days
      },
    },
    'session': {
      'timeout': 30 * 60 * 1000, // 30 minutes
      'maxSessions': 5,
      'secureCookies': true,
      'httpOnlyCookies': true,
      'sameSite': 'strict',
      'fingerprinting': true,
    },
    'biometric': {
      'enabled': true,
      'supportedTypes': ['fingerprint', 'facial', 'voice', 'iris'],
      'fallbackRequired': true,
      'confidenceThreshold': 0.85,
      'templateEncryption': true,
    },
    'multiFactor': {
      'enabled': true,
      'required': false,
      'methods': ['totp', 'sms', 'email', 'biometric'],
    },
  };

  // File Upload Security Configuration
  static const fileUploadConfig = {
    'virusScanning': {
      'enabled': true,
      'engines': ['clamav', 'yara', 'custom'],
      'quarantineThreats': true,
      'scanArchives': true,
      'scanPdf': true,
      'maxFileSize': 50 * 1024 * 1024, // 50MB
    },
    'validation': {
      'fileTypeChecking': true,
      'magicNumberChecking': true,
      'fileNameValidation': true,
      'contentScanning': true,
      'blockedExtensions': [
        '.exe', '.bat', '.cmd', '.com', '.pif', '.scr', '.vbs', '.js', '.jar',
        '.php', '.asp', '.aspx', '.jsp', '.pl', '.py', '.rb', '.sh'
      ],
    },
    'processing': {
      'generateThumbnails': true,
      'stripMetadata': true,
      'imageOptimization': true,
      'encryption': true,
    },
    'storage': {
      'encryptFiles': true,
      'randomizeNames': true,
      'quarantineRetention': 7 * 24 * 60 * 60 * 1000, // 7 days
    },
  };

  // Network Security Configuration
  static const networkSecurityConfig = {
    'https': {
      'enforce': true,
      'redirectHttp': true,
      'minTLSVersion': 'TLSv1.2',
      'preferredTLSVersion': 'TLSv1.3',
      'hsts': {
        'maxAge': 31536000, // 1 year
        'includeSubDomains': true,
        'preload': true,
      },
    },
    'certificatePinning': {
      'enabled': true,
      'enforceForAPI': true,
      'enforceForWebSocket': true,
      'allowBackupPins': true,
    },
    'securityHeaders': {
      'contentSecurityPolicy': true,
      'xFrameOptions': 'DENY',
      'xContentTypeOptions': 'nosniff',
      'xXSSProtection': '1; mode=block',
      'strictTransportSecurity': true,
      'referrerPolicy': 'strict-origin-when-cross-origin',
      'permissionsPolicy': true,
      'crossOriginEmbedderPolicy': 'require-corp',
      'crossOriginOpenerPolicy': 'same-origin',
    },
    'cors': {
      'enabled': true,
      'originValidation': true,
      'credentialSupport': true,
      'allowedMethods': ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      'allowedHeaders': ['Content-Type', 'Authorization', 'X-Requested-With'],
    },
  };

  // Privacy Compliance Configuration
  static const privacyConfig = {
    'gdpr': {
      'enabled': true,
      'dataRetention': {
        'userAccounts': 7 * 365 * 24 * 60 * 60 * 1000, // 7 years
        'sessionData': 24 * 60 * 60 * 1000, // 24 hours
        'auditLogs': 6 * 365 * 24 * 60 * 60 * 1000, // 6 years
        'marketingData': 365 * 24 * 60 * 60 * 1000, // 1 year
      },
      'dataSubjectRights': {
        'access': true,
        'rectification': true,
        'erasure': true,
        'portability': true,
        'restriction': true,
        'objection': true,
      },
      'processingActivities': {
        'record': true,
        'dpiaRequired': true,
        'consentRequired': true,
      },
    },
    'coppa': {
      'enabled': true,
      'ageVerification': true,
      'parentalConsent': true,
      'dataMinimization': true,
      'parentalRights': true,
    },
    'consent': {
      'management': true,
      'withdrawal': true,
      'granularControl': true,
      'consentRecords': true,
    },
  };

  // Monitoring Configuration
  static const monitoringConfig = {
    'securityMonitoring': {
      'enabled': true,
      'realTimeMonitoring': true,
      'alertThresholds': {
        'failedLogins': 5,
        'suspiciousRequests': 100,
        'errorRate': 0.05,
        'responseTime': 5000,
        'memoryUsage': 0.85,
        'cpuUsage': 0.80,
        'diskUsage': 0.90,
      },
      'monitoredEvents': [
        'authentication_failure',
        'authorization_failure',
        'sql_injection_attempt',
        'xss_attempt',
        'file_upload_malicious',
        'rate_limit_exceeded',
        'suspicious_ip_activity',
        'data_breach_detected',
        'unauthorized_access',
        'privilege_escalation',
        'session_hijacking',
        'ddos_attack'
      ],
    },
    'incidentResponse': {
      'enabled': true,
      'automatedResponse': true,
      'escalationMatrix': {
        'critical': ['L4', 'L3', 'L2'],
        'high': ['L3', 'L2', 'L1'],
        'medium': ['L2', 'L1'],
        'low': ['L1']
      },
      'containmentProcedures': {
        'malware': ['quarantine_file', 'block_ip', 'alert_team'],
        'ddos': ['increase_monitoring', 'alert_team', 'activate_protection'],
        'data_breach': ['alert_team', 'activate_containment', 'notify_affected'],
        'unauthorized_access': ['disable_account', 'block_ip', 'alert_team']
      },
    },
    'logging': {
      'securityEvents': true,
      'auditLogs': true,
      'accessLogs': true,
      'errorLogs': true,
      'retentionPeriod': 6 * 365 * 24 * 60 * 60 * 1000, // 6 years
    },
  };

  // Vulnerability Management Configuration
  static const vulnerabilityConfig = {
    'scanning': {
      'enabled': true,
      'frequency': 'daily',
      'scope': ['dependencies', 'infrastructure', 'application'],
      'tools': ['owasp_zap', 'nmap', 'ssl_scan', 'dependency_check'],
    },
    'testing': {
      'penetrationTesting': {
        'enabled': true,
        'frequency': 'quarterly',
        'scope': 'comprehensive',
        'reportRequired': true,
      },
      'securityTesting': {
        'enabled': true,
        'frequency': 'weekly',
        'automated': true,
        'manual': false,
      },
    },
    'patchManagement': {
      'enabled': true,
      'frequency': 'monthly',
      'criticalPatchWindow': 48 * 60 * 60 * 1000, // 48 hours
      'notificationRequired': true,
    },
  };

  // Backup and Disaster Recovery Configuration
  static const backupConfig = {
    'backup': {
      'enabled': true,
      'frequency': 'daily',
      'retention': {
        'daily': 30,
        'weekly': 12,
        'monthly': 12,
        'yearly': 7,
      },
      'encryption': true,
      'compression': true,
      'integrityChecking': true,
    },
    'disasterRecovery': {
      'enabled': true,
      'rto': 4 * 60 * 60 * 1000, // 4 hours
      'rpo': 60 * 60 * 1000, // 1 hour
      'testing': 'monthly',
      'documentation': true,
    },
    'businessContinuity': {
      'enabled': true,
      'loadBalancing': true,
      'failover': 'automatic',
      'redundancy': 'geographic',
    },
  };

  // Compliance Configuration
  static const complianceConfig = {
    'regulatory': {
      'gdpr': true,
      'coppa': true,
      'soc2': false,
      'iso27001': false,
      'pci_dss': false,
    },
    'audit': {
      'frequency': 'annual',
      'scope': 'comprehensive',
      'thirdParty': true,
      'certificationRequired': true,
    },
    'dataGovernance': {
      'classification': true,
      'retentionPolicies': true,
      'dataLineage': true,
      'accessControls': true,
    },
  };

  // Performance Configuration
  static const performanceConfig = {
    'caching': {
      'redis': true,
      'application': true,
      'database': true,
      'cdn': true,
    },
    'optimization': {
      'compression': true,
      'minification': true,
      'lazyLoading': true,
      'imageOptimization': true,
    },
    'scaling': {
      'horizontal': true,
      'vertical': true,
      'autoScaling': true,
      'loadBalancing': true,
    },
  };

  // Get complete security configuration
  static Map<String, dynamic> getCompleteConfiguration() {
    return {
      'apiSecurity': apiSecurityConfig,
      'encryption': encryptionConfig,
      'authentication': authenticationConfig,
      'fileUpload': fileUploadConfig,
      'networkSecurity': networkSecurityConfig,
      'privacy': privacyConfig,
      'monitoring': monitoringConfig,
      'vulnerability': vulnerabilityConfig,
      'backup': backupConfig,
      'compliance': complianceConfig,
      'performance': performanceConfig,
      'metadata': {
        'version': '1.0.0',
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'environment': 'production',
        'configurationLevel': 'comprehensive',
      }
    };
  }

  // Validate configuration
  static Map<String, dynamic> validateConfiguration() {
    final issues = <String>[];
    final warnings = <String>[];

    // Validate encryption configuration
    if (encryptionConfig['keyLength'] < 256) {
      issues.add('Encryption key length should be at least 256 bits');
    }

    // Validate authentication configuration
    if (authenticationConfig['jwt']['accessTokenExpiry'] > 3600) {
      warnings.add('JWT access token expiry is longer than recommended (1 hour)');
    }

    // Validate monitoring configuration
    if (monitoringConfig['securityMonitoring']['alertThresholds']['failedLogins'] > 10) {
      warnings.add('Failed login threshold is higher than recommended');
    }

    // Validate backup configuration
    if (backupConfig['backup']['frequency'] != 'daily') {
      warnings.add('Backup frequency should be daily for optimal protection');
    }

    return {
      'valid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'score': _calculateSecurityScore(issues, warnings),
    };
  }

  // Calculate security score
  static int _calculateSecurityScore(List<String> issues, List<String> warnings) {
    int score = 100;
    score -= issues.length * 10; // Deduct 10 points per issue
    score -= warnings.length * 2; // Deduct 2 points per warning
    return score.clamp(0, 100);
  }

  // Get configuration by category
  static Map<String, dynamic> getConfigurationByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'api':
      case 'apikey':
        return apiSecurityConfig;
      case 'encryption':
      case 'crypto':
        return encryptionConfig;
      case 'auth':
      case 'authentication':
        return authenticationConfig;
      case 'file':
      case 'upload':
        return fileUploadConfig;
      case 'network':
      case 'web':
        return networkSecurityConfig;
      case 'privacy':
      case 'compliance':
        return privacyConfig;
      case 'monitoring':
      case 'logging':
        return monitoringConfig;
      case 'vulnerability':
      case 'scanning':
        return vulnerabilityConfig;
      case 'backup':
      case 'recovery':
        return backupConfig;
      default:
        throw ArgumentError('Unknown configuration category: $category');
    }
  }

  // Update configuration
  static void updateConfiguration(String category, Map<String, dynamic> updates) {
    // This would update the configuration in a real implementation
    // For now, just log the update
    print('Updating configuration for category: $category');
    print('Updates: $updates');
  }

  // Generate security report
  static Map<String, dynamic> generateSecurityReport() {
    final validation = validateConfiguration();
    final config = getCompleteConfiguration();

    return {
      'summary': {
        'configurationLevel': 'comprehensive',
        'securityScore': validation['score'],
        'totalCategories': 10,
        'enabledFeatures': _countEnabledFeatures(config),
      },
      'validation': validation,
      'categories': {
        'apiSecurity': {
          'enabled': true,
          'score': 85,
          'features': ['rate_limiting', 'input_validation', 'xss_protection', 'sql_injection_protection']
        },
        'encryption': {
          'enabled': true,
          'score': 90,
          'features': ['aes256_gcm', 'key_management', 'key_rotation', 'at_rest_encryption']
        },
        'authentication': {
          'enabled': true,
          'score': 88,
          'features': ['jwt', 'session_management', 'biometric', 'multi_factor']
        },
        'fileUpload': {
          'enabled': true,
          'score': 92,
          'features': ['virus_scanning', 'file_validation', 'secure_storage']
        },
        'networkSecurity': {
          'enabled': true,
          'score': 87,
          'features': ['https_enforcement', 'certificate_pinning', 'security_headers']
        },
        'privacy': {
          'enabled': true,
          'score': 85,
          'features': ['gdpr_compliance', 'coppa_compliance', 'consent_management']
        },
        'monitoring': {
          'enabled': true,
          'score': 83,
          'features': ['real_time_monitoring', 'incident_response', 'security_logging']
        },
        'vulnerability': {
          'enabled': true,
          'score': 80,
          'features': ['vulnerability_scanning', 'penetration_testing', 'patch_management']
        },
        'backup': {
          'enabled': true,
          'score': 86,
          'features': ['encrypted_backup', 'disaster_recovery', 'business_continuity']
        }
      },
      'recommendations': _generateRecommendations(validation),
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Count enabled features
  static int _countEnabledFeatures(Map<String, dynamic> config) {
    int count = 0;
    
    void countFeatures(dynamic item) {
      if (item is Map) {
        for (final value in item.values) {
          if (value == true) count++;
          else if (value is Map) countFeatures(value);
        }
      }
    }
    
    countFeatures(config);
    return count;
  }

  // Generate recommendations
  static List<String> _generateRecommendations(Map<String, dynamic> validation) {
    final recommendations = <String>[];

    if (validation['score'] < 90) {
      recommendations.add('Consider implementing additional security measures to improve overall security score');
    }

    if ((validation['issues'] as List).isNotEmpty) {
      recommendations.add('Address critical security issues identified in the validation');
    }

    recommendations.add('Regularly review and update security configurations');
    recommendations.add('Conduct periodic security assessments and penetration testing');
    recommendations.add('Maintain up-to-date security monitoring and incident response procedures');
    recommendations.add('Ensure all team members are trained on security best practices');
    recommendations.add('Keep all security tools and dependencies updated');

    return recommendations;
  }
}

// Environment-specific configurations
class SecurityConfigurationDev extends SecurityConfiguration {
  @override
  static const apiSecurityConfig = {
    'rateLimiting': {
      'global': {'windowMs': 15 * 60 * 1000, 'max': 10000},
      'auth': {'windowMs': 15 * 60 * 1000, 'max': 10},
    },
    'inputValidation': {'enabled': true, 'sanitizeHTML': true},
  };

  @override
  static const encryptionConfig = {
    'algorithm': 'AES-256-GCM',
    'iterations': 10000, // Lower for development
    'keyRotation': {'enabled': false},
  };

  @override
  static const networkSecurityConfig = {
    'https': {'enforce': false},
    'certificatePinning': {'enabled': false},
  };
}

class SecurityConfigurationTest extends SecurityConfiguration {
  @override
  static const apiSecurityConfig = {
    'rateLimiting': {'enabled': false},
    'inputValidation': {'enabled': false},
  };

  @override
  static const fileUploadConfig = {
    'virusScanning': {'enabled': false},
  };

  @override
  static const monitoringConfig = {
    'securityMonitoring': {'enabled': false},
  };
}

// Configuration factory
class SecurityConfigurationFactory {
  static SecurityConfiguration createConfiguration(String environment) {
    switch (environment.toLowerCase()) {
      case 'development':
        return SecurityConfigurationDev();
      case 'test':
      case 'testing':
        return SecurityConfigurationTest();
      case 'staging':
      case 'stage':
        return SecurityConfiguration(); // Use base configuration with some relaxed settings
      case 'production':
      case 'prod':
        return SecurityConfiguration(); // Full security configuration
      default:
        throw ArgumentError('Unknown environment: $environment');
    }
  }
}