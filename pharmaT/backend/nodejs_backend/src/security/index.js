/**
 * Security Module - Central Security Infrastructure
 * Comprehensive security implementation for the tutoring platform
 */

const rateLimit = require('./api/rateLimit');
const inputValidation = require('./api/inputValidation');
const sqlInjectionProtection = require('./api/sqlInjectionProtection');
const xssProtection = require('./api/xssProtection');
const encryption = require('./encryption/encryption');
const keyManagement = require('./encryption/keyManagement');
const tokenSecurity = require('./authentication/tokenSecurity');
const biometricIntegration = require('./authentication/biometricIntegration');
const sessionManagement = require('./authentication/sessionManagement');
const fileUploadSecurity = require('./fileUpload/fileUploadSecurity');
const virusScanner = require('./fileUpload/virusScanner');
const networkSecurity = require('./network/networkSecurity');
const certificatePinning = require('./network/certificatePinning');
const secureHeaders = require('./network/secureHeaders');
const gdprCompliance = require('./compliance/gdprCompliance');
const coppaCompliance = require('./compliance/coppaCompliance');
const consentManagement = require('./compliance/consentManagement');
const vulnerabilityScanner = require('./vulnerability/vulnerabilityScanner');
const securityTester = require('./vulnerability/securityTester');
const codeReviewGuidelines = require('./guidelines/codeReviewGuidelines');
const incidentResponse = require('./monitoring/incidentResponse');
const securityMonitoring = require('./monitoring/securityMonitoring');
const backupSecurity = require('./backup/backupSecurity');
const disasterRecovery = require('./backup/disasterRecovery');

class SecurityManager {
  constructor() {
    this.isInitialized = false;
    this.monitoring = null;
    this.encryption = null;
    this.rateLimiter = null;
  }

  async initialize() {
    try {
      console.log('🔒 Initializing Security Infrastructure...');

      // Initialize core components
      await this.initializeEncryption();
      await this.initializeRateLimiting();
      await this.initializeMonitoring();
      await this.initializeCompliance();

      // Initialize middleware components
      await this.initializeInputValidation();
      await this.initializeFileUploadSecurity();
      await this.initializeNetworkSecurity();
      await this.initializeBackupSystems();

      this.isInitialized = true;
      console.log('✅ Security Infrastructure initialized successfully');
    } catch (error) {
      console.error('❌ Failed to initialize security infrastructure:', error);
      throw error;
    }
  }

  async initializeEncryption() {
    this.encryption = new encryption.EncryptionService();
    await this.encryption.initialize();
  }

  async initializeRateLimiting() {
    this.rateLimiter = new rateLimit.AdvancedRateLimiter();
    await this.rateLimiter.initialize();
  }

  async initializeMonitoring() {
    this.monitoring = new securityMonitoring.SecurityMonitoring();
    await this.monitoring.initialize();
  }

  async initializeCompliance() {
    const gdpr = new gdprCompliance.GDPRCompliance();
    const coppa = new coppaCompliance.COPPACompliance();
    const consent = new consentManagement.ConsentManager();
    
    await gdpr.initialize();
    await coppa.initialize();
    await consent.initialize();
  }

  async initializeInputValidation() {
    inputValidation.initialize();
  }

  async initializeFileUploadSecurity() {
    const fileSecurity = new fileUploadSecurity.FileUploadSecurity();
    const scanner = new virusScanner.VirusScanner();
    
    await fileSecurity.initialize();
    await scanner.initialize();
  }

  async initializeNetworkSecurity() {
    const network = new networkSecurity.NetworkSecurity();
    const certPin = new certificatePinning.CertificatePinning();
    
    await network.initialize();
    await certPin.initialize();
  }

  async initializeBackupSystems() {
    const backup = new backupSecurity.BackupSecurity();
    const disasterRecovery = new disasterRecovery.DisasterRecovery();
    
    await backup.initialize();
    await disasterRecovery.initialize();
  }

  // Middleware for API security
  getSecurityMiddleware() {
    return {
      rateLimit: this.rateLimiter.middleware(),
      validateInput: inputValidation.middleware(),
      preventSQLInjection: sqlInjectionProtection.middleware(),
      preventXSS: xssProtection.middleware(),
      secureHeaders: secureHeaders.middleware(),
      enforceHTTPS: networkSecurity.enforceHTTPS(),
      monitorRequests: this.monitoring.middleware()
    };
  }

  // Authentication methods
  getAuthMethods() {
    return {
      secureTokens: tokenSecurity,
      biometric: biometricIntegration,
      sessions: sessionManagement
    };
  }

  // File security methods
  getFileSecurityMethods() {
    return {
      upload: fileUploadSecurity,
      scan: virusScanner
    };
  }

  // Compliance methods
  getComplianceMethods() {
    return {
      gdpr: gdprCompliance,
      coppa: coppaCompliance,
      consent: consentManagement
    };
  }

  // Monitoring methods
  getMonitoringMethods() {
    return {
      security: this.monitoring,
      incidentResponse: incidentResponse
    };
  }

  // Vulnerability testing
  async runSecurityTests() {
    const tester = new securityTester.SecurityTester();
    return await tester.runAllTests();
  }

  // Backup and recovery
  async createSecureBackup() {
    const backup = new backupSecurity.BackupSecurity();
    return await backup.createBackup();
  }

  async restoreFromBackup(backupId) {
    const disasterRecovery = new disasterRecovery.DisasterRecovery();
    return await disasterRecovery.restore(backupId);
  }

  isReady() {
    return this.isInitialized;
  }
}

module.exports = {
  SecurityManager,
  // Export individual modules for direct use
  rateLimit,
  inputValidation,
  encryption,
  tokenSecurity,
  sessionManagement,
  fileUploadSecurity,
  securityMonitoring,
  incidentResponse
};