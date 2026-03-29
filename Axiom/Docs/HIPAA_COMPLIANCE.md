# Axiom HIPAA Compliance Documentation

## Overview
Axiom handles protected health information (PHI) for users in clinical therapy programs. This document outlines our technical compliance with HIPAA Security Rule.

## Technical Safeguards

### Encryption (164.312(a)(2)(iv))
- All data encrypted at rest: AES-256-GCM
- All data in transit: TLS 1.3
- End-to-end encryption for therapist connections
- Encryption keys stored in macOS/iOS Keychain

### Access Controls (164.312(a)(1))
- User authentication required
- Biometric (Face ID/Touch ID) lock
- Session timeout: 5 minutes
- No shared accounts

### Audit Trails (164.312(b))
- All data access logged
- Append-only audit log
- 6-year retention

### PHI Handling (164.312(c)(1))
- No PHI shared with third parties
- Therapist access requires explicit user consent
- Data export is user-initiated only

### Breach Notification (164.408)
- Incident response plan documented
- User notification within 60 days of breach
- HHS notification as required
