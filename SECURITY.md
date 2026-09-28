# Security Architecture & Implementation — EkVidya (SIH26238)

This document outlines the security architecture implemented in the **EkVidya Hackathon Prototype**, along with the production roadmap detailing how security controls would be expanded for nationwide deployment under the Ministry of Tribal Affairs.

---

## 1. Implemented Security Controls (Prototype Phase)

### A. Field-Level Data Encryption (AES-256-GCM)
- **Sensitive Identifiers**: Personally Identifiable Information (PII) including Aadhaar numbers and bank account references are encrypted at the application layer prior to PostgreSQL database insertion.
- **Algorithm**: `aes-256-gcm` utilizing authenticated encryption with dynamic Initialization Vectors (IV) and authentication tags.
- **Location**: Executed in [`backend/src/utils/crypto.ts`](file:///d:/sih26238/backend/src/utils/crypto.ts).

### B. Authentication & Session Management
- **Short-Lived Access Tokens**: Signed JWT access tokens with a 15-minute expiration window to prevent replay attacks.
- **Refresh Token Flow**: Cryptographically separate refresh token secret (`JWT_REFRESH_SECRET`) stored securely to grant new access tokens.
- **Password Hashing**: Bcrypt salted hashing (`saltRounds = 10`) for user credentials.

### C. Comprehensive Audit Logging
- **Mandatory Tracking**: Every access or retrieval of identity records, financial account numbers, digital documents, or manual review decisions writes an immutable row to the `AuditLog` table.
- **Recorded Context**: Captures `actorId`, `action`, `entityType`, `entityId`, `timestamp`, and client IP address (`ipAddress`).

### D. Rate Limiting & Protection
- **API Rate Limiter**: Enforces a ceiling of 200 requests per 15 minutes per IP (`express-rate-limit`).
- **Auth Guard**: Dedicated 20 request / 15 minute limit on authentication endpoints to prevent brute-force login attempts.

### E. Single Active Scheme Business Rule Guard
- Prevents double-dipping across multiple ST scholarship portals by strictly evaluating active applications before creating a new submission.

---

## 2. Production Deployment Security Roadmap

While the hackathon prototype demonstrates full end-to-end security patterns, a nationwide production rollout will introduce the following government-grade security mechanisms:

| Security Domain | Prototype Implementation | Production Target (MoTA Deployment) |
|---|---|---|
| **Inter-System Auth** | Node Gateway ➔ FastAPI REST call | **mTLS (Mutual TLS)** with X.509 client certificates between adapters and National Data Sharing Platform (NDSAP). |
| **Key Storage** | `.env`-based secret key management | **Hardware Security Module (HSM)** or AWS KMS / Azure Key Vault for AES-256 master key rotation. |
| **DigiLocker Auth** | Mock REST Adapter | **DigiLocker Signed JWT / OAuth 2.0 PKCE** flow with cryptographic assertion verification against DigiLocker public keys. |
| **Aadhaar Compliance** | App-level AES-256 encryption | **Aadhaar Vault (UIDAI Compliant)** utilizing mandatory reference keys instead of storing raw/encrypted Aadhaar numbers directly. |
| **Multilingual AI** | Intent/Keyword FAQ Matching | **Bhashini API Integration** over TLS 1.3 with sandboxed data processing for tribal voice queries. |
| **DBT Transfers** | Simulated Direct Benefit Transfer | **PFMS (Public Financial Management System) ISO 20022 XML Gateway** with dual-signatory authorization. |

---

## 3. Compliance Summary
- **DPDP Act 2023 (Digital Personal Data Protection)**: Field encryption + user consent logs ensure compliance with Indian data privacy mandates.
- **CERT-In Guidelines**: Audit logging and role-based access control (RBAC) satisfy Indian Computer Emergency Response Team security standards.
