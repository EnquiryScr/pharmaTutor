# SSL Certificate Management and Domain Configuration

## Overview
This document outlines the SSL certificate management strategy and domain configuration for the tutoring platform across all environments.

## SSL Certificate Strategy

### Certificate Authority: Let's Encrypt
- Primary CA: Let's Encrypt (Free, automated renewal)
- Backup CA: AWS Certificate Manager (for enterprise features)
- Self-signed certificates for development environments

### Certificate Types

#### 1. Wildcard Certificate (*.tutoring-platform.com)
```
Domain: *.tutoring-platform.com
Subject Alternative Names:
  - tutoring-platform.com
  - www.tutoring-platform.com
  - api.tutoring-platform.com
  - admin.tutoring-platform.com
  - app.tutoring-platform.com
  - staging.tutoring-platform.com
  - cdn.tutoring-platform.com
  - *.app.tutoring-platform.com
```

#### 2. SAN Certificate for API
```
Domain: api.tutoring-platform.com
Subject Alternative Names:
  - api.tutoring-platform.com
  - api-staging.tutoring-platform.com
  - api-dev.tutoring-platform.com
```

#### 3. Development Certificates
```
Self-signed certificates for local development
Generated using mkcert or similar tools
```

## Certificate Lifecycle Management

### Automated Renewal Process
```bash
#!/bin/bash
# SSL Renewal Script

# Check certificate expiry
cert_expiry=$(openssl x509 -in /etc/ssl/certs/tutoring-platform.com.crt -noout -enddate | cut -d= -f2)
current_date=$(date)
expiry_epoch=$(date -d "$cert_expiry" +%s)
current_epoch=$(date -d "$current_date" +%s)
days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))

if [ $days_until_expiry -lt 30 ]; then
    echo "Certificate expires in $days_until_expiry days, renewing..."
    
    # Renew with Let's Encrypt
    certbot renew --force-renewal
    
    # Reload web servers
    nginx -s reload
    systemctl reload apache2
    
    # Update CloudFlare
    cf_api_update_certificates
    
    # Send notification
    send_notification "SSL certificate renewed successfully"
else
    echo "Certificate is valid for $days_until_expiry more days"
fi
```

### Cron Job for Auto-Renewal
```cron
# SSL Certificate Renewal - Daily check
0 2 * * * /opt/scripts/ssl-renewal.sh >> /var/log/ssl-renewal.log 2>&1
```

## CloudFlare SSL Configuration

### DNS Records Management
```yaml
# CloudFlare DNS Configuration
dns_records:
  - name: tutoring-platform.com
    type: A
    value: LOAD_BALANCER_IP
    proxied: true
    ttl: auto
    
  - name: www
    type: CNAME
    value: tutoring-platform.com
    proxied: true
    ttl: auto
    
  - name: api
    type: CNAME
    value: api-load-balancer.elb.amazonaws.com
    proxied: true
    ttl: auto
    
  - name: admin
    type: CNAME
    value: admin-load-balancer.elb.amazonaws.com
    proxied: true
    ttl: auto
    
  - name: app
    type: CNAME
    value: app-cdn.cloudfront.net
    proxied: true
    ttl: auto
```

### CloudFlare SSL Settings
```json
{
  "ssl": {
    "mode": "strict",
    "min_tls_version": "1.2",
    "always_use_https": "on",
    "tls_1_3": "zrt",
    "automatic_https_rewrites": "on",
    "opportunistic_encryption": "on",
    "tls_fallback_sni": "on",
    "automatic_https_rewrites": "on"
  },
  "security": {
    "level": "medium",
    "ssl_recommendations": "on"
  }
}
```

## NGINX SSL Configuration

### Production NGINX Configuration
```nginx
# /etc/nginx/sites-available/tutoring-platform.com

server {
    listen 80;
    server_name tutoring-platform.com www.tutoring-platform.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name tutoring-platform.com www.tutoring-platform.com;
    
    # SSL Configuration
    ssl_certificate /etc/ssl/certs/tutoring-platform.com.crt;
    ssl_certificate_key /etc/ssl/private/tutoring-platform.com.key;
    ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # Security Headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.firebaseio.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' wss: https:;" always;
    
    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;
    
    # Root Directory
    root /var/www/tutoring-platform;
    index index.html;
    
    # API Proxy
    location /api/ {
        proxy_pass http://backend-cluster;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Static Files
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Health Check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

## Load Balancer SSL Configuration

### AWS Application Load Balancer
```json
{
  "LoadBalancerAttributes": {
    "AccessLoggingSettings": {
      "Enabled": true,
      "S3BucketName": "tutoring-platform-alb-logs"
    },
    "RoutingRules": [
      {
        "Rules": [
          {
            "Actions": [
              {
                "Type": "redirect",
                "RedirectConfig": {
                  "Protocol": "HTTPS",
                  "Port": "443",
                  "StatusCode": "HTTP_301"
                }
              }
            ],
            "Conditions": [
              {
                "Field": "protocol",
                "Values": ["HTTP"]
              }
            ],
            "Priority": "1"
          }
        ]
      }
    ]
  },
  "Listeners": [
    {
      "Port": "443",
      "Protocol": "HTTPS",
      "Certificates": [
        {
          "CertificateArn": "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
        }
      ],
      "DefaultActions": [
        {
          "Type": "forward",
          "TargetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/backend-targets/1234567890123456"
        }
      ]
    }
  ]
}
```

## Certificate Monitoring

### SSL Certificate Monitoring Script
```python
#!/usr/bin/env python3
"""
SSL Certificate Monitor
Monitors SSL certificate expiration and sends alerts
"""

import ssl
import socket
import smtplib
from datetime import datetime, timedelta
import requests
import json

class SSLMonitor:
    def __init__(self, config):
        self.config = config
        
    def check_certificate(self, domain, port=443):
        """Check SSL certificate for domain"""
        try:
            context = ssl.create_default_context()
            with socket.create_connection((domain, port)) as sock:
                with context.wrap_socket(sock, server_hostname=domain) as ssock:
                    cert = ssock.getpeercert()
                    
            expiry_date = datetime.strptime(cert['notAfter'], '%b %d %H:%M:%S %Y %Z')
            days_until_expiry = (expiry_date - datetime.now()).days
            
            return {
                'domain': domain,
                'valid_until': expiry_date.isoformat(),
                'days_until_expiry': days_until_expiry,
                'issuer': cert['issuer'],
                'subject': cert['subject']
            }
        except Exception as e:
            return {
                'domain': domain,
                'error': str(e),
                'days_until_expiry': -1
            }
    
    def check_multiple_domains(self, domains):
        """Check multiple domains"""
        results = []
        for domain in domains:
            result = self.check_certificate(domain)
            results.append(result)
            
            if result['days_until_expiry'] < 30:
                self.send_alert(domain, result)
                
        return results
    
    def send_alert(self, domain, cert_info):
        """Send SSL certificate alert"""
        subject = f"SSL Certificate Alert: {domain}"
        body = f"""
        SSL Certificate Status Alert
        =============================
        
        Domain: {domain}
        Expiry Date: {cert_info['valid_until']}
        Days Until Expiry: {cert_info['days_until_expiry']}
        
        Please renew the certificate before it expires.
        
        Automatic renewal should handle this, but manual intervention may be required.
        """
        
        # Send email alert
        self.send_email(subject, body)
        
        # Send Slack notification
        self.send_slack_notification(domain, cert_info)
    
    def send_email(self, subject, body):
        """Send email notification"""
        try:
            msg = f"From: {self.config['email_from']}\nTo: {self.config['email_to']}\nSubject: {subject}\n\n{body}"
            
            server = smtplib.SMTP(self.config['smtp_host'], self.config['smtp_port'])
            server.starttls()
            server.login(self.config['smtp_user'], self.config['smtp_password'])
            server.sendmail(self.config['email_from'], self.config['email_to'], msg)
            server.quit()
        except Exception as e:
            print(f"Failed to send email: {e}")
    
    def send_slack_notification(self, domain, cert_info):
        """Send Slack notification"""
        try:
            webhook_url = self.config['slack_webhook']
            payload = {
                "text": f"🔒 SSL Certificate Alert",
                "attachments": [
                    {
                        "color": "warning",
                        "fields": [
                            {
                                "title": "Domain",
                                "value": domain,
                                "short": True
                            },
                            {
                                "title": "Days Until Expiry",
                                "value": str(cert_info['days_until_expiry']),
                                "short": True
                            }
                        ]
                    }
                ]
            }
            
            requests.post(webhook_url, json=payload)
        except Exception as e:
            print(f"Failed to send Slack notification: {e}")

# Configuration
config = {
    'email_from': 'alerts@tutoring-platform.com',
    'email_to': 'admin@tutoring-platform.com',
    'smtp_host': 'smtp.gmail.com',
    'smtp_port': 587,
    'smtp_user': 'alerts@tutoring-platform.com',
    'smtp_password': 'your_app_password',
    'slack_webhook': 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
}

# Domains to monitor
domains = [
    'tutoring-platform.com',
    'www.tutoring-platform.com',
    'api.tutoring-platform.com',
    'admin.tutoring-platform.com',
    'app.tutoring-platform.com'
]

# Run monitoring
if __name__ == "__main__":
    monitor = SSLMonitor(config)
    results = monitor.check_multiple_domains(domains)
    
    # Log results
    with open('/var/log/ssl-monitor.log', 'a') as f:
        f.write(f"\n{datetime.now().isoformat()}: SSL Certificate Check Results\n")
        for result in results:
            f.write(json.dumps(result) + '\n')
```

## Domain Management

### DNS Configuration
```bash
#!/bin/bash
# DNS Management Script

# Primary domain: tutoring-platform.com
# TTL: 300 seconds

# A Records
dig @8.8.8.8 tutoring-platform.com +short
dig @8.8.8.8 www.tutoring-platform.com +short

# CNAME Records
dig @8.8.8.8 api.tutoring-platform.com +short
dig @8.8.8.8 admin.tutoring-platform.com +short
dig @8.8.8.8 app.tutoring-platform.com +short

# TXT Records (SPF, DKIM, DMARC)
dig @8.8.8.8 tutoring-platform.com TXT +short

# MX Records
dig @8.8.8.8 tutoring-platform.com MX +short
```

### Domain Validation Script
```python
#!/usr/bin/env python3
"""
Domain and DNS Validation
Validates domain configuration and DNS settings
"""

import dns.resolver
import requests
import json

def validate_domain(domain):
    """Validate domain configuration"""
    validation_results = {
        'domain': domain,
        'dns_resolves': False,
        'ssl_certificate': False,
        'https_redirect': False,
        'headers_secure': False,
        'errors': []
    }
    
    # Check DNS resolution
    try:
        result = dns.resolver.resolve(domain, 'A')
        validation_results['dns_resolves'] = True
        validation_results['ip_addresses'] = [str(rdata) for rdata in result]
    except Exception as e:
        validation_results['errors'].append(f"DNS resolution failed: {e}")
    
    # Check HTTPS redirect
    try:
        response = requests.get(f"http://{domain}", timeout=10)
        if response.url.startswith('https://'):
            validation_results['https_redirect'] = True
        else:
            validation_results['errors'].append("HTTPS redirect not working")
    except Exception as e:
        validation_results['errors'].append(f"HTTPS redirect check failed: {e}")
    
    # Check SSL certificate
    try:
        response = requests.get(f"https://{domain}", timeout=10)
        if response.status_code == 200:
            validation_results['ssl_certificate'] = True
    except Exception as e:
        validation_results['errors'].append(f"SSL certificate check failed: {e}")
    
    # Check security headers
    try:
        response = requests.get(f"https://{domain}", timeout=10)
        security_headers = [
            'Strict-Transport-Security',
            'X-Frame-Options',
            'X-Content-Type-Options',
            'X-XSS-Protection'
        ]
        
        present_headers = []
        for header in security_headers:
            if header in response.headers:
                present_headers.append(header)
        
        if len(present_headers) == len(security_headers):
            validation_results['headers_secure'] = True
        else:
            validation_results['errors'].append(f"Missing security headers: {set(security_headers) - set(present_headers)}")
    except Exception as e:
        validation_results['errors'].append(f"Security headers check failed: {e}")
    
    return validation_results

# Validate all domains
domains = [
    'tutoring-platform.com',
    'www.tutoring-platform.com',
    'api.tutoring-platform.com',
    'admin.tutoring-platform.com',
    'app.tutoring-platform.com'
]

results = []
for domain in domains:
    result = validate_domain(domain)
    results.append(result)

# Output results
print(json.dumps(results, indent=2))
```

## SSL Troubleshooting

### Common Issues and Solutions

#### 1. Certificate Not Trusted
```bash
# Check certificate chain
openssl s_client -connect tutoring-platform.com:443 -servername tutoring-platform.com

# Update CA certificates
sudo apt update && sudo apt install ca-certificates
sudo update-ca-certificates
```

#### 2. Mixed Content Issues
```bash
# Check for mixed content
curl -k -I https://tutoring-platform.com | grep -i content-security-policy

# Update CSP headers to allow mixed content if necessary
add_header Content-Security-Policy "upgrade-insecure-requests" always;
```

#### 3. Certificate Renewal Issues
```bash
# Check Let's Encrypt renewal
sudo certbot certificates
sudo certbot renew --dry-run

# Manual renewal
sudo certbot renew --force-renewal
```

#### 4. SSL Labs Testing
```bash
# Use SSL Labs API for testing
curl -s "https://api.ssllabs.com/api/v3/analyze?host=tutoring-platform.com&publish=off&startNew=on" | jq '.'
```

## Backup and Recovery

### Certificate Backup Script
```bash
#!/bin/bash
# Backup SSL certificates

BACKUP_DIR="/backup/ssl-certificates"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR/$DATE"

# Backup Let's Encrypt certificates
sudo cp -r /etc/letsencrypt "$BACKUP_DIR/$DATE/"

# Backup private keys with encryption
sudo tar -czf "$BACKUP_DIR/$DATE/private-keys.tar.gz" -C /etc/ssl/private .
sudo gpg --cipher-algo AES256 --compress-algo 1 --s2k-mode 3 --s2k-digest-algo SHA512 --s2k-count 65536 --symmetric --output "$BACKUP_DIR/$DATE/private-keys.tar.gz.gpg" "$BACKUP_DIR/$DATE/private-keys.tar.gz"
rm "$BACKUP_DIR/$DATE/private-keys.tar.gz"

# Backup CloudFlare certificates
cf_api_token="YOUR_CF_API_TOKEN"
cf_zone_id="YOUR_ZONE_ID"

# Get certificates from CloudFlare
curl -X GET "https://api.cloudflare.com/client/v4/zones/$cf_zone_id/ssl/certificate_packs" \
  -H "Authorization: Bearer $cf_api_token" \
  -H "Content-Type: application/json" > "$BACKUP_DIR/$DATE/cloudflare-certificates.json"

echo "SSL certificates backed up to $BACKUP_DIR/$DATE"
```

This comprehensive SSL and domain configuration ensures secure, reliable, and monitored certificate management across all environments.