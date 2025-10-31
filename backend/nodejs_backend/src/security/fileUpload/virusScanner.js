/**
 * Virus Scanner
 * Multi-engine virus scanning for uploaded files
 */

const { spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

class VirusScanner {
  constructor() {
    this.config = {
      // Scanning engines
      engines: {
        clamav: {
          enabled: process.env.CLAMAV_ENABLED === 'true',
          path: process.env.CLAMAV_PATH || '/usr/bin/clamscan',
          databasePath: process.env.CLAMAV_DATABASE_PATH || '/var/lib/clamav',
          timeout: 30000 // 30 seconds
        },
        yara: {
          enabled: process.env.YARA_ENABLED === 'true',
          path: process.env.YARA_PATH || '/usr/bin/yara',
          rulesPath: process.env.YARA_RULES_PATH || './security/yara-rules',
          timeout: 10000 // 10 seconds
        }
      },
      
      // Scanning options
      scanArchives: true,
      scanPdf: true,
      scanOfficeDocs: true,
      maxFileSize: 50 * 1024 * 1024, // 50MB
      timeout: 60000, // 60 seconds
      quarantineThreats: true,
      
      // YARA rules for custom threat detection
      customRules: {
        malicious_macros: 'malicious_macros.yar',
        suspicious_scripts: 'suspicious_scripts.yar',
        exploit_signatures: 'exploit_signatures.yar'
      }
    };
    
    this.scanHistory = [];
    this.threatPatterns = new Map();
    this.scannerStatus = {
      engines: {},
      lastUpdate: null,
      databaseCurrent: false
    };
  }

  async initialize() {
    try {
      await this.initializeEngines();
      await this.loadCustomRules();
      console.log('✅ Virus Scanner initialized');
    } catch (error) {
      throw new Error(`Failed to initialize Virus Scanner: ${error.message}`);
    }
  }

  // Initialize scanning engines
  async initializeEngines() {
    for (const [engineName, config] of Object.entries(this.config.engines)) {
      try {
        if (!config.enabled) {
          console.log(`⚠️  ${engineName} scanner disabled`);
          continue;
        }

        const isAvailable = await this.checkEngineAvailability(engineName, config);
        if (isAvailable) {
          this.scannerStatus.engines[engineName] = {
            available: true,
            healthy: true,
            lastCheck: Date.now()
          };
          console.log(`✅ ${engineName} scanner initialized`);
        } else {
          this.scannerStatus.engines[engineName] = {
            available: false,
            healthy: false,
            lastCheck: Date.now()
          };
          console.warn(`⚠️  ${engineName} scanner not available`);
        }
      } catch (error) {
        console.error(`Error initializing ${engineName} scanner:`, error);
        this.scannerStatus.engines[engineName] = {
          available: false,
          healthy: false,
          error: error.message,
          lastCheck: Date.now()
        };
      }
    }
  }

  // Check if scanning engine is available
  async checkEngineAvailability(engineName, config) {
    try {
      switch (engineName) {
        case 'clamav':
          return await this.checkClamAV(config);
        case 'yara':
          return await this.checkYara(config);
        default:
          return false;
      }
    } catch (error) {
      console.error(`Error checking ${engineName} availability:`, error);
      return false;
    }
  }

  // Check ClamAV availability
  async checkClamAV(config) {
    return new Promise((resolve) => {
      const proc = spawn(config.path, ['--version']);
      
      proc.on('close', (code) => {
        resolve(code === 0);
      });
      
      proc.on('error', () => {
        resolve(false);
      });
    });
  }

  // Check YARA availability
  async checkYara(config) {
    return new Promise((resolve) => {
      const proc = spawn(config.path, ['--version']);
      
      proc.on('close', (code) => {
        resolve(code === 0);
      });
      
      proc.on('error', () => {
        resolve(false);
      });
    });
  }

  // Load custom YARA rules
  async loadCustomRules() {
    try {
      const rulesDir = this.config.engines.yara.rulesPath;
      await fs.access(rulesDir);
      
      const files = await fs.readdir(rulesDir);
      for (const file of files) {
        if (file.endsWith('.yar') || file.endsWith('.yara')) {
          const ruleName = file.replace(/\.(yar|yara)$/, '');
          const rulePath = path.join(rulesDir, file);
          this.threatPatterns.set(ruleName, rulePath);
        }
      }
      
      console.log(`Loaded ${this.threatPatterns.size} custom threat patterns`);
    } catch (error) {
      console.warn('No custom threat patterns found:', error.message);
    }
  }

  // Scan file for threats
  async scanFile(file) {
    const startTime = Date.now();
    const scanId = crypto.randomBytes(8).toString('hex');
    
    try {
      console.log(`🔍 Starting scan ${scanId} for file: ${file.originalname}`);
      
      const results = [];
      
      // Scan with available engines
      for (const [engineName, config] of Object.entries(this.config.engines)) {
        if (config.enabled && this.scannerStatus.engines[engineName]?.available) {
          try {
            const result = await this.scanWithEngine(engineName, file, config);
            if (result) {
              results.push(result);
            }
          } catch (error) {
            console.error(`Error scanning with ${engineName}:`, error);
          }
        }
      }
      
      // Scan with custom patterns
      const customResults = await this.scanWithCustomPatterns(file);
      results.push(...customResults);
      
      // Analyze results
      const threatAnalysis = this.analyzeScanResults(results);
      const scanTime = Date.now() - startTime;
      
      const scanResult = {
        scanId,
        fileName: file.originalname,
        scanned: true,
        clean: threatAnalysis.clean,
        threats: threatAnalysis.threats,
        warnings: threatAnalysis.warnings,
        scanTime,
        engines: results.length,
        timestamp: Date.now()
      };
      
      // Log scan result
      await this.logScanResult(scanResult);
      
      // Update scan statistics
      this.updateScanStats(scanResult);
      
      console.log(`✅ Scan ${scanId} completed: ${scanResult.clean ? 'CLEAN' : 'THREATS DETECTED'}`);
      
      return scanResult;
    } catch (error) {
      console.error(`Scan ${scanId} failed:`, error);
      throw error;
    }
  }

  // Scan with specific engine
  async scanWithEngine(engineName, file, config) {
    switch (engineName) {
      case 'clamav':
        return await this.scanWithClamAV(file, config);
      case 'yara':
        return await this.scanWithYara(file, config);
      default:
        return null;
    }
  }

  // Scan with ClamAV
  async scanWithClamAV(file, config) {
    return new Promise((resolve, reject) => {
      try {
        // Write file to temporary location for scanning
        const tempFile = path.join('/tmp', `scan_${Date.now()}_${file.originalname}`);
        
        fs.writeFile(tempFile, file.buffer).then(() => {
          const args = [
            '--no-summary',
            '--recursive',
            '--bell',
            '--move=/tmp/quarantine',
            tempFile
          ];
          
          const proc = spawn(config.path, args, { timeout: config.timeout });
          
          let output = '';
          let errorOutput = '';
          
          proc.stdout.on('data', (data) => {
            output += data.toString();
          });
          
          proc.stderr.on('data', (data) => {
            errorOutput += data.toString();
          });
          
          proc.on('close', async (code) => {
            // Clean up temporary file
            try {
              await fs.unlink(tempFile);
            } catch (e) {
              console.warn('Could not delete temp file:', tempFile);
            }
            
            if (code === 0) {
              resolve({
                engine: 'clamav',
                clean: true,
                threats: [],
                output: output.trim()
              });
            } else if (code === 1) {
              // Threats found
              const threats = this.parseClamAVOutput(output);
              resolve({
                engine: 'clamav',
                clean: false,
                threats: threats,
                output: output.trim()
              });
            } else {
              // Error or timeout
              resolve({
                engine: 'clamav',
                clean: null,
                threats: [],
                error: errorOutput || `Exit code: ${code}`,
                output: output.trim()
              });
            }
          });
          
          proc.on('error', async (error) => {
            // Clean up on error
            try {
              await fs.unlink(tempFile);
            } catch (e) {}
            
            reject(error);
          });
        });
      } catch (error) {
        reject(error);
      }
    });
  }

  // Parse ClamAV output
  parseClamAVOutput(output) {
    const threats = [];
    const lines = output.split('\n');
    
    for (const line of lines) {
      // ClamAV output format: filename: THREAT_NAME FOUND
      const match = line.match(/(.+):\s*(.+)\s*FOUND/);
      if (match) {
        threats.push({
          file: match[1].trim(),
          threat: match[2].trim(),
          severity: 'high' // ClamAV typically reports high-severity threats
        });
      }
    }
    
    return threats;
  }

  // Scan with YARA
  async scanWithYara(file, config) {
    return new Promise((resolve, reject) => {
      try {
        const tempFile = path.join('/tmp', `scan_${Date.now()}_${file.originalname}`);
        
        fs.writeFile(tempFile, file.buffer).then(() => {
          // Build YARA command with all loaded rules
          const args = ['-r'];
          
          // Add custom rule files
          for (const [ruleName, rulePath] of this.threatPatterns.entries()) {
            args.push(rulePath);
          }
          
          args.push(tempFile);
          
          const proc = spawn(config.path, args, { timeout: config.timeout });
          
          let output = '';
          let errorOutput = '';
          
          proc.stdout.on('data', (data) => {
            output += data.toString();
          });
          
          proc.stderr.on('data', (data) => {
            errorOutput += data.toString();
          });
          
          proc.on('close', async (code) => {
            // Clean up temporary file
            try {
              await fs.unlink(tempFile);
            } catch (e) {
              console.warn('Could not delete temp file:', tempFile);
            }
            
            if (code === 0 && output.trim()) {
              // Matches found
              const matches = this.parseYaraOutput(output);
              resolve({
                engine: 'yara',
                clean: false,
                threats: matches,
                output: output.trim()
              });
            } else if (code === 0) {
              // No matches found
              resolve({
                engine: 'yara',
                clean: true,
                threats: [],
                output: output.trim()
              });
            } else {
              // Error
              resolve({
                engine: 'yara',
                clean: null,
                threats: [],
                error: errorOutput || `Exit code: ${code}`,
                output: output.trim()
              });
            }
          });
          
          proc.on('error', async (error) => {
            // Clean up on error
            try {
              await fs.unlink(tempFile);
            } catch (e) {}
            
            reject(error);
          });
        });
      } catch (error) {
        reject(error);
      }
    });
  }

  // Parse YARA output
  parseYaraOutput(output) {
    const threats = [];
    const lines = output.split('\n');
    
    for (const line of lines) {
      if (line.trim()) {
        // YARA output format: filename rule_name(offset)
        const match = line.match(/(.+)\s+(\w+)\(/);
        if (match) {
          threats.push({
            file: match[1].trim(),
            rule: match[2].trim(),
            severity: 'medium' // YARA rules can have variable severity
          });
        }
      }
    }
    
    return threats;
  }

  // Scan with custom patterns
  async scanWithCustomPatterns(file) {
    const results = [];
    
    // Check file signatures
    const signatureThreats = this.checkFileSignatures(file);
    if (signatureThreats.length > 0) {
      results.push({
        engine: 'signatures',
        clean: false,
        threats: signatureThreats
      });
    }
    
    // Check for suspicious content
    const contentThreats = this.checkFileContent(file);
    if (contentThreats.length > 0) {
      results.push({
        engine: 'content',
        clean: false,
        threats: contentThreats
      });
    }
    
    // Check file metadata
    const metadataThreats = this.checkFileMetadata(file);
    if (metadataThreats.length > 0) {
      results.push({
        engine: 'metadata',
        clean: false,
        threats: metadataThreats
      });
    }
    
    return results;
  }

  // Check file signatures
  checkFileSignatures(file) {
    const threats = [];
    
    // Common malicious file signatures
    const maliciousSignatures = [
      { pattern: '4D5A', name: 'PE Executable', severity: 'medium' }, // Windows executable
      { pattern: '7F454C46', name: 'ELF Executable', severity: 'low' }, // Linux executable
      { pattern: 'CAFEBABE', name: 'Java Class', severity: 'low' },
      { pattern: '504B0304', name: 'ZIP Archive', severity: 'low' },
      { pattern: 'D0CF11E0', name: 'OLE2 Document', severity: 'low' }
    ];
    
    const fileBuffer = file.buffer;
    const hexSignature = fileBuffer.slice(0, 4).toString('hex').toUpperCase();
    
    for (const sig of maliciousSignatures) {
      if (hexSignature.startsWith(sig.pattern)) {
        threats.push({
          file: file.originalname,
          threat: sig.name,
          severity: sig.severity,
          type: 'signature'
        });
      }
    }
    
    return threats;
  }

  // Check file content for suspicious patterns
  checkFileContent(file) {
    const threats = [];
    
    if (file.mimetype === 'text/plain' || file.mimetype === 'text/html') {
      const content = file.buffer.toString('utf8');
      
      // Suspicious patterns
      const suspiciousPatterns = [
        { pattern: /eval\s*\(/gi, name: 'JavaScript eval()', severity: 'high' },
        { pattern: /document\.write\s*\(/gi, name: 'Document write', severity: 'medium' },
        { pattern: /<script/gi, name: 'Script tag', severity: 'high' },
        { pattern: /javascript:/gi, name: 'JavaScript protocol', severity: 'high' },
        { pattern: /vbscript:/gi, name: 'VBScript protocol', severity: 'high' },
        { pattern: /cmd\.exe/gi, name: 'Command execution', severity: 'high' },
        { pattern: /powershell/gi, name: 'PowerShell', severity: 'high' },
        { pattern: /base64_decode/gi, name: 'Base64 decode', severity: 'medium' },
        { pattern: /system\s*\(/gi, name: 'System call', severity: 'high' },
        { pattern: /exec\s*\(/gi, name: 'Exec call', severity: 'high' }
      ];
      
      for (const sig of suspiciousPatterns) {
        if (sig.pattern.test(content)) {
          threats.push({
            file: file.originalname,
            threat: sig.name,
            severity: sig.severity,
            type: 'content'
          });
        }
      }
    }
    
    return threats;
  }

  // Check file metadata for suspicious information
  checkFileMetadata(file) {
    const threats = [];
    
    // Check for suspicious metadata in various file types
    if (file.mimetype === 'application/pdf') {
      const content = file.buffer.toString('utf8');
      
      // PDF-specific threats
      if (/javascript:/i.test(content)) {
        threats.push({
          file: file.originalname,
          threat: 'PDF with JavaScript',
          severity: 'high',
          type: 'pdf_metadata'
        });
      }
      
      if (/\/OpenAction|\/AA/i.test(content)) {
        threats.push({
          file: file.originalname,
          threat: 'PDF with automatic actions',
          severity: 'medium',
          type: 'pdf_metadata'
        });
      }
    }
    
    // Check Office documents for macros
    if (file.mimetype.includes('officedocument') || file.mimetype.includes('ms-')) {
      const content = file.buffer.toString('utf8');
      
      if (/vbaProject|VBProject/i.test(content)) {
        threats.push({
          file: file.originalname,
          threat: 'Office document with macros',
          severity: 'high',
          type: 'office_metadata'
        });
      }
    }
    
    return threats;
  }

  // Analyze scan results from multiple engines
  analyzeScanResults(results) {
    const allThreats = [];
    const warnings = [];
    let clean = true;
    
    for (const result of results) {
      if (!result.clean && result.threats) {
        clean = false;
        allThreats.push(...result.threats);
      } else if (result.clean === null) {
        warnings.push(`Scan engine ${result.engine} error: ${result.error}`);
      }
    }
    
    // Remove duplicate threats
    const uniqueThreats = allThreats.filter((threat, index, self) => 
      index === self.findIndex(t => t.threat === threat.threat && t.file === threat.file)
    );
    
    return {
      clean,
      threats: uniqueThreats,
      warnings
    };
  }

  // Log scan result
  async logScanResult(result) {
    try {
      this.scanHistory.push(result);
      
      // Keep only last 1000 scan results
      if (this.scanHistory.length > 1000) {
        this.scanHistory = this.scanHistory.slice(-1000);
      }
      
      console.log(`Scan logged: ${result.fileName} - ${result.clean ? 'CLEAN' : 'THREATS'}`);
    } catch (error) {
      console.error('Error logging scan result:', error);
    }
  }

  // Update scan statistics
  updateScanStats(result) {
    // This would typically update database statistics
    // For now, we'll just log them
    if (!result.clean) {
      console.warn(`Threats detected in ${result.fileName}:`, result.threats.map(t => t.threat).join(', '));
    }
  }

  // Get scan history
  getScanHistory(limit = 100) {
    return this.scanHistory.slice(-limit);
  }

  // Get scanner status
  getStatus() {
    return {
      ...this.scannerStatus,
      totalScans: this.scanHistory.length,
      lastScan: this.scanHistory.length > 0 ? this.scanHistory[this.scanHistory.length - 1] : null
    };
  }

  // Health check
  async healthCheck() {
    try {
      const availableEngines = Object.entries(this.scannerStatus.engines)
        .filter(([_, status]) => status.available).length;
      
      const recentScans = this.scanHistory.filter(scan => 
        Date.now() - scan.timestamp < 60000 // Last minute
      ).length;
      
      return {
        healthy: availableEngines > 0,
        availableEngines,
        totalEngines: Object.keys(this.config.engines).length,
        customRules: this.threatPatterns.size,
        recentScans,
        lastUpdate: this.scannerStatus.lastUpdate
      };
    } catch (error) {
      return {
        healthy: false,
        error: error.message
      };
    }
  }

  // Update virus definitions
  async updateDefinitions() {
    try {
      // Update ClamAV definitions
      if (this.config.engines.clamav.enabled) {
        await this.updateClamAVDefinitions();
      }
      
      // Update custom rules
      await this.loadCustomRules();
      
      this.scannerStatus.lastUpdate = Date.now();
      console.log('✅ Virus definitions updated');
    } catch (error) {
      console.error('Error updating virus definitions:', error);
      throw error;
    }
  }

  // Update ClamAV definitions
  async updateClamAVDefinitions() {
    return new Promise((resolve, reject) => {
      const proc = spawn('freshclam', ['--quiet']);
      
      proc.on('close', (code) => {
        if (code === 0) {
          this.scannerStatus.databaseCurrent = true;
          resolve();
        } else {
          reject(new Error(`freshclam failed with exit code: ${code}`));
        }
      });
      
      proc.on('error', reject);
    });
  }

  // Batch scan multiple files
  async batchScan(files) {
    const results = [];
    
    console.log(`Starting batch scan of ${files.length} files`);
    
    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      try {
        const result = await this.scanFile(file);
        results.push({
          file: file.originalname,
          result
        });
      } catch (error) {
        results.push({
          file: file.originalname,
          error: error.message
        });
      }
    }
    
    const summary = {
      total: files.length,
      clean: results.filter(r => r.result?.clean).length,
      threats: results.filter(r => r.result && !r.result.clean).length,
      errors: results.filter(r => r.error).length,
      results
    };
    
    console.log(`Batch scan completed: ${summary.clean} clean, ${summary.threats} threats, ${summary.errors} errors`);
    
    return summary;
  }
}

module.exports = {
  VirusScanner
};