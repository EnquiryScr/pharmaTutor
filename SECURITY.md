# Security Policy

## Supported Versions

We actively maintain security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of PharmaTutor seriously. We appreciate your efforts to responsibly disclose any vulnerabilities.

### How to Report

If you discover a security vulnerability, please follow these steps:

1. **Do not** create a public GitHub issue for security vulnerabilities
2. Email your findings to: enquiryscr@gmail.com
3. Include detailed information about the vulnerability
4. Provide steps to reproduce the issue if possible

### What to Include

- Type of vulnerability
- Service or component affected  
- Detailed description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Resolution**: Within 30 days (depending on complexity)

### Recognition

We value the security community and will acknowledge security researchers who responsibly disclose vulnerabilities in our project.

## Security Best Practices

### For Developers

1. **Environment Variables**: Never commit sensitive data to version control
2. **Dependencies**: Keep all dependencies updated
3. **Code Review**: Require peer review for all changes
4. **Secrets Management**: Use secure credential storage
5. **Input Validation**: Validate all user inputs
6. **Authentication**: Implement proper authentication mechanisms

### For Users

1. **Strong Passwords**: Use unique, strong passwords
2. **Updates**: Keep your app updated to the latest version
3. **Official Sources**: Only download from official app stores
4. **Permissions**: Review app permissions before installation

## Security Measures Implemented

- **Authentication**: Supabase Auth with JWT tokens
- **Authorization**: Role-based access control
- **Data Encryption**: Sensitive data encrypted at rest and in transit
- **API Security**: Rate limiting and input validation
- **Secure Storage**: Flutter Secure Storage for sensitive data
- **Biometric Authentication**: Fingerprint/Face ID support

## Contact

For security-related questions, please contact: enquiryscr@gmail.com

## Legal

We reserve the right to pursue legal action against individuals who attempt to exploit security vulnerabilities for malicious purposes.