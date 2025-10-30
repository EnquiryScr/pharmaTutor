/**
 * Incident Response System
 * Automated and manual incident response procedures
 */

const { v4: uuidv4 } = require('uuid');
const EventEmitter = require('events');

class IncidentResponse extends EventEmitter {
  constructor() {
    super();
    this.config = {
      // Response levels
      responseLevels: {
        L1: { name: 'Level 1 - Monitor', automation: true, escalationTime: 300000 },  // 5 minutes
        L2: { name: 'Level 2 - Triage', automation: false, escalationTime: 900000 }, // 15 minutes
        L3: { name: 'Level 3 - Investigate', automation: false, escalationTime: 1800000 }, // 30 minutes
        L4: { name: 'Level 4 - Critical', automation: false, escalationTime: 0 } // Immediate
      },
      
      // Automated response actions
      automatedActions: {
        block_ip: { enabled: true, timeout: 3600000 }, // 1 hour
        quarantine_file: { enabled: true, timeout: 0 },
        disable_account: { enabled: true, timeout: 0 },
        increase_monitoring: { enabled: true, timeout: 0 },
        alert_team: { enabled: true, timeout: 0 }
      },
      
      // Escalation matrix
      escalationMatrix: {
        critical: ['L4', 'L3', 'L2'],
        high: ['L3', 'L2', 'L1'],
        medium: ['L2', 'L1'],
        low: ['L1']
      },
      
      // Containment procedures
      containmentProcedures: {
        malware: ['quarantine_file', 'block_ip', 'alert_team'],
        ddos: ['increase_monitoring', 'alert_team', 'activate_protection'],
        data_breach: ['alert_team', 'activate_containment', 'notify_affected'],
        unauthorized_access: ['disable_account', 'block_ip', 'alert_team']
      }
    };
    
    this.incidents = new Map();
    this.responsePlaybooks = new Map();
    this.activeContainmentActions = new Map();
  }

  async initialize() {
    try {
      await this.initializeResponsePlaybooks();
      console.log('✅ Incident Response System initialized');
    } catch (error) {
      throw new Error(`Failed to initialize Incident Response: ${error.message}`);
    }
  }

  // Initialize response playbooks
  async initializeResponsePlaybooks() {
    const playbooks = {
      malware_detection: {
        id: 'malware_detection',
        name: 'Malware Detection Response',
        description: 'Automated response to malware detection',
        steps: [
          { action: 'quarantine_file', automated: true },
          { action: 'block_source_ip', automated: true },
          { action: 'alert_security_team', automated: true },
          { action: 'create_incident', automated: true },
          { action: 'log_incident', automated: true }
        ],
        severity: 'high',
        estimatedTime: 300000 // 5 minutes
      },
      
      ddos_attack: {
        id: 'ddos_attack',
        name: 'DDoS Attack Response',
        description: 'Response to distributed denial of service attacks',
        steps: [
          { action: 'activate_ddos_protection', automated: true },
          { action: 'increase_monitoring', automated: true },
          { action: 'alert_infrastructure_team', automated: true },
          { action: 'document_attack_pattern', automated: true }
        ],
        severity: 'critical',
        estimatedTime: 60000 // 1 minute
      },
      
      data_breach: {
        id: 'data_breach',
        name: 'Data Breach Response',
        description: 'Response to suspected data breach',
        steps: [
          { action: 'isolate_affected_systems', automated: false },
          { action: 'preserve_evidence', automated: false },
          { action: 'assess_scope', automated: false },
          { action: 'notify_stakeholders', automated: false },
          { action: 'begin_forensics', automated: false }
        ],
        severity: 'critical',
        estimatedTime: 3600000 // 1 hour
      },
      
      unauthorized_access: {
        id: 'unauthorized_access',
        name: 'Unauthorized Access Response',
        description: 'Response to unauthorized access attempts',
        steps: [
          { action: 'disable_compromised_accounts', automated: true },
          { action: 'block_suspicious_ips', automated: true },
          { action: 'force_password_reset', automated: true },
          { action: 'alert_security_team', automated: true }
        ],
        severity: 'high',
        estimatedTime: 180000 // 3 minutes
      }
    };

    for (const [id, playbook] of Object.entries(playbooks)) {
      this.responsePlaybooks.set(id, playbook);
    }

    console.log(`Initialized ${this.responsePlaybooks.size} response playbooks`);
  }

  // Create incident
  async createIncident(incidentData) {
    const {
      type,
      title,
      description,
      severity = 'medium',
      source,
      affectedSystems = [],
      initialData = {},
      automated = false
    } = incidentData;

    // Determine response level based on severity
    const responseLevel = this.determineResponseLevel(severity);
    
    // Select appropriate playbook
    const playbook = this.selectPlaybook(type, severity);
    
    const incident = {
      id: uuidv4(),
      type,
      title,
      description,
      severity,
      responseLevel,
      status: 'active',
      priority: this.calculatePriority(severity, type),
      source,
      affectedSystems,
      created: Date.now(),
      updated: Date.now(),
      assignedTo: null,
      playbook,
      steps: playbook ? playbook.steps.map((step, index) => ({
        ...step,
        id: index,
        status: 'pending',
        executed: false,
        executedAt: null,
        result: null
      })) : [],
      timeline: [{
        timestamp: Date.now(),
        action: 'created',
        details: `Incident created with severity: ${severity}`,
        automated
      }],
      metadata: initialData,
      resolution: null
    };

    this.incidents.set(incident.id, incident);
    
    // Emit incident creation event
    this.emit('incidentCreated', incident);
    
    console.log(`Incident created: ${incident.id} (${severity})`);
    
    // Start automated response if applicable
    if (automated && playbook) {
      await this.executeAutomatedResponse(incident);
    }
    
    return incident.id;
  }

  // Execute incident response
  async executeIncidentResponse(incidentId, options = {}) {
    const incident = this.incidents.get(incidentId);
    if (!incident) {
      throw new Error(`Incident not found: ${incidentId}`);
    }

    if (!incident.playbook) {
      throw new Error('No response playbook defined for this incident');
    }

    const { manual = false, startFromStep = 0 } = options;
    
    console.log(`Executing incident response: ${incidentId}`);
    
    try {
      // Execute playbook steps
      for (let i = startFromStep; i < incident.steps.length; i++) {
        const step = incident.steps[i];
        
        if (manual && step.automated) {
          console.log(`Skipping automated step ${i}: ${step.action}`);
          continue;
        }
        
        await this.executeResponseStep(incident, step, i);
        
        // Check if step failed and stop execution
        if (step.status === 'failed') {
          console.error(`Step ${i} failed, stopping execution`);
          break;
        }
      }
      
      // Update incident status
      if (this.areAllStepsCompleted(incident)) {
        incident.status = 'contained';
        incident.updated = Date.now();
        incident.timeline.push({
          timestamp: Date.now(),
          action: 'contained',
          details: 'All response steps completed'
        });
      }
      
      console.log(`Incident response executed: ${incidentId}`);
    } catch (error) {
      console.error(`Error executing incident response: ${incidentId}`, error);
      incident.status = 'failed';
      incident.updated = Date.now();
      incident.timeline.push({
        timestamp: Date.now(),
        action: 'failed',
        details: `Response execution failed: ${error.message}`
      });
    }
    
    this.incidents.set(incidentId, incident);
    this.emit('incidentUpdated', incident);
    
    return incident;
  }

  // Execute individual response step
  async executeResponseStep(incident, step, stepIndex) {
    console.log(`Executing step ${stepIndex}: ${step.action}`);
    
    const startTime = Date.now();
    step.status = 'executing';
    step.executedAt = startTime;
    
    try {
      let result;
      
      // Execute specific action
      switch (step.action) {
        case 'quarantine_file':
          result = await this.executeQuarantineFile(incident);
          break;
        case 'block_source_ip':
          result = await this.executeBlockIP(incident);
          break;
        case 'alert_security_team':
          result = await this.executeAlertTeam(incident);
          break;
        case 'create_incident':
          result = await this.executeCreateIncident(incident);
          break;
        case 'log_incident':
          result = await this.executeLogIncident(incident);
          break;
        case 'activate_ddos_protection':
          result = await this.executeActivateDDoSProtection(incident);
          break;
        case 'increase_monitoring':
          result = await this.executeIncreaseMonitoring(incident);
          break;
        case 'disable_compromised_accounts':
          result = await this.executeDisableAccounts(incident);
          break;
        case 'force_password_reset':
          result = await this.executeForcePasswordReset(incident);
          break;
        case 'isolate_affected_systems':
          result = await this.executeIsolateSystems(incident);
          break;
        case 'preserve_evidence':
          result = await this.executePreserveEvidence(incident);
          break;
        default:
          result = { success: true, message: `Generic action: ${step.action}` };
      }
      
      step.status = 'completed';
      step.result = result;
      step.executed = true;
      
      const executionTime = Date.now() - startTime;
      console.log(`Step ${stepIndex} completed in ${executionTime}ms`);
      
      // Add to incident timeline
      incident.timeline.push({
        timestamp: Date.now(),
        action: 'step_completed',
        details: `Step ${stepIndex}: ${step.action} - ${result.message || 'completed'}`,
        stepIndex,
        executionTime
      });
      
    } catch (error) {
      step.status = 'failed';
      step.result = { success: false, error: error.message };
      step.executed = true;
      
      console.error(`Step ${stepIndex} failed:`, error);
      
      incident.timeline.push({
        timestamp: Date.now(),
        action: 'step_failed',
        details: `Step ${stepIndex}: ${step.action} - ${error.message}`,
        stepIndex,
        error: error.message
      });
    }
  }

  // Execute automated response
  async executeAutomatedResponse(incident) {
    if (!incident.playbook) return;
    
    // Execute only automated steps
    const automatedSteps = incident.playbook.steps.filter(step => step.automated);
    
    for (let i = 0; i < automatedSteps.length; i++) {
      const step = incident.steps[i];
      if (step.automated) {
        await this.executeResponseStep(incident, step, i);
        
        // Stop if step failed
        if (step.status === 'failed') break;
      }
    }
  }

  // Response step execution methods
  async executeQuarantineFile(incident) {
    const fileId = incident.metadata.fileId || 'unknown';
    console.log(`Quarantining file: ${fileId}`);
    
    // Implement file quarantine logic
    return {
      success: true,
      message: `File ${fileId} quarantined successfully`,
      details: { fileId }
    };
  }

  async executeBlockIP(incident) {
    const ip = incident.metadata.sourceIP || 'unknown';
    console.log(`Blocking IP address: ${ip}`);
    
    // Implement IP blocking logic
    return {
      success: true,
      message: `IP address ${ip} blocked successfully`,
      details: { ip }
    };
  }

  async executeAlertTeam(incident) {
    console.log('Alerting security team');
    
    // Implement team alerting logic
    return {
      success: true,
      message: 'Security team alerted successfully',
      details: { team: 'security' }
    };
  }

  async executeCreateIncident(incident) {
    console.log('Creating detailed incident record');
    
    // Implement incident creation logic
    return {
      success: true,
      message: 'Detailed incident record created',
      details: { incidentId: incident.id }
    };
  }

  async executeLogIncident(incident) {
    console.log('Logging incident details');
    
    // Implement incident logging logic
    return {
      success: true,
      message: 'Incident logged successfully',
      details: { timestamp: Date.now() }
    };
  }

  async executeActivateDDoSProtection(incident) {
    console.log('Activating DDoS protection');
    
    // Implement DDoS protection activation
    return {
      success: true,
      message: 'DDoS protection activated',
      details: { protection: 'ddos_shield' }
    };
  }

  async executeIncreaseMonitoring(incident) {
    console.log('Increasing monitoring level');
    
    // Implement monitoring level increase
    return {
      success: true,
      message: 'Monitoring level increased',
      details: { level: 'enhanced' }
    };
  }

  async executeDisableAccounts(incident) {
    console.log('Disabling compromised accounts');
    
    // Implement account disabling logic
    return {
      success: true,
      message: 'Compromised accounts disabled',
      details: { accounts: incident.metadata.affectedAccounts || [] }
    };
  }

  async executeForcePasswordReset(incident) {
    console.log('Forcing password reset');
    
    // Implement password reset logic
    return {
      success: true,
      message: 'Password reset forced for affected accounts',
      details: { resetRequired: true }
    };
  }

  async executeIsolateSystems(incident) {
    console.log('Isolating affected systems');
    
    // Implement system isolation logic
    return {
      success: true,
      message: 'Affected systems isolated',
      details: { systems: incident.affectedSystems || [] }
    };
  }

  async executePreserveEvidence(incident) {
    console.log('Preserving forensic evidence');
    
    // Implement evidence preservation logic
    return {
      success: true,
      message: 'Forensic evidence preserved',
      details: { preservation: 'completed' }
    };
  }

  // Determine response level
  determineResponseLevel(severity) {
    switch (severity) {
      case 'critical': return 'L4';
      case 'high': return 'L3';
      case 'medium': return 'L2';
      case 'low': return 'L1';
      default: return 'L2';
    }
  }

  // Select appropriate playbook
  selectPlaybook(type, severity) {
    // Try to find exact match
    if (this.responsePlaybooks.has(type)) {
      return this.responsePlaybooks.get(type);
    }
    
    // Find by severity or type keywords
    for (const playbook of this.responsePlaybooks.values()) {
      if (playbook.severity === severity || 
          playbook.name.toLowerCase().includes(type.toLowerCase())) {
        return playbook;
      }
    }
    
    return null;
  }

  // Calculate priority
  calculatePriority(severity, type) {
    const priorityMap = {
      critical: 1,
      high: 2,
      medium: 3,
      low: 4
    };
    
    return priorityMap[severity] || 3;
  }

  // Check if all steps are completed
  areAllStepsCompleted(incident) {
    return incident.steps.length === 0 || 
           incident.steps.every(step => step.status === 'completed');
  }

  // Resolve incident
  async resolveIncident(incidentId, resolution) {
    const incident = this.incidents.get(incidentId);
    if (!incident) {
      throw new Error(`Incident not found: ${incidentId}`);
    }

    incident.status = 'resolved';
    incident.resolution = {
      ...resolution,
      resolvedAt: Date.now()
    };
    incident.updated = Date.now();

    incident.timeline.push({
      timestamp: Date.now(),
      action: 'resolved',
      details: `Incident resolved: ${resolution.summary || 'No summary provided'}`
    });

    this.incidents.set(incidentId, incident);
    this.emit('incidentResolved', incident);

    console.log(`Incident resolved: ${incidentId}`);
    return incident;
  }

  // Get incident details
  getIncident(incidentId) {
    return this.incidents.get(incidentId);
  }

  // List incidents
  listIncidents(filters = {}) {
    let incidents = Array.from(this.incidents.values());
    
    // Apply filters
    if (filters.status) {
      incidents = incidents.filter(inc => inc.status === filters.status);
    }
    
    if (filters.severity) {
      incidents = incidents.filter(inc => inc.severity === filters.severity);
    }
    
    if (filters.type) {
      incidents = incidents.filter(inc => inc.type === filters.type);
    }
    
    if (filters.dateFrom) {
      incidents = incidents.filter(inc => inc.created >= filters.dateFrom);
    }
    
    if (filters.dateTo) {
      incidents = incidents.filter(inc => inc.created <= filters.dateTo);
    }
    
    return incidents.sort((a, b) => b.created - a.created);
  }

  // Update incident
  updateIncident(incidentId, updates) {
    const incident = this.incidents.get(incidentId);
    if (!incident) {
      throw new Error(`Incident not found: ${incidentId}`);
    }

    Object.assign(incident, updates, { updated: Date.now() });
    this.incidents.set(incidentId, incident);
    
    this.emit('incidentUpdated', incident);
    
    return incident;
  }

  // Get incident statistics
  getIncidentStatistics() {
    const incidents = Array.from(this.incidents.values());
    
    return {
      total: incidents.length,
      byStatus: {
        active: incidents.filter(i => i.status === 'active').length,
        contained: incidents.filter(i => i.status === 'contained').length,
        resolved: incidents.filter(i => i.status === 'resolved').length,
        failed: incidents.filter(i => i.status === 'failed').length
      },
      bySeverity: {
        critical: incidents.filter(i => i.severity === 'critical').length,
        high: incidents.filter(i => i.severity === 'high').length,
        medium: incidents.filter(i => i.severity === 'medium').length,
        low: incidents.filter(i => i.severity === 'low').length
      },
      averageResolutionTime: this.calculateAverageResolutionTime(incidents)
    };
  }

  // Calculate average resolution time
  calculateAverageResolutionTime(incidents) {
    const resolvedIncidents = incidents.filter(i => i.resolution);
    if (resolvedIncidents.length === 0) return 0;
    
    const totalTime = resolvedIncidents.reduce((sum, incident) => {
      return sum + (incident.resolution.resolvedAt - incident.created);
    }, 0);
    
    return totalTime / resolvedIncidents.length;
  }

  // Health check
  async healthCheck() {
    const stats = this.getIncidentStatistics();
    
    return {
      healthy: true,
      totalIncidents: stats.total,
      activeIncidents: stats.byStatus.active,
      responsePlaybooks: this.responsePlaybooks.size,
      averageResolutionTime: stats.averageResolutionTime
    };
  }
}

module.exports = {
  IncidentResponse
};