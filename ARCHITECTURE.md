# System Architecture — EkVidya (SIH26238)

**EkVidya** is a unified mobile platform engineered for Scheduled Tribe (ST) students under the **Ministry of Tribal Affairs**. It aggregates 5 previously disconnected government portals into a single mobile dashboard with automated, multi-agency verification.

---

## 1. High-Level System Architecture Diagram (Mermaid)

```mermaid
flowchart TD
    subgraph Mobile Client [Flutter Mobile Application]
        UI[Flutter UI - Android/Web]
        State[AppState / Provider]
        Wallet[Document Wallet]
        ChatUI[AI Chatbot UI]
    end

    subgraph Gateway [Node.js + Express API Gateway]
        Auth[JWT & Bcrypt Auth]
        Limit[Rate Limiter]
        Crypto[AES-256 Field Encryptor]
        Audit[Audit Log Writer]
        Routes[API Routes Controller]
    end

    subgraph Database [PostgreSQL + Prisma ORM]
        DB[(Relational DB: Students, Schemes, Applications, Verifications, Sanctions, Disbursements, AuditLogs)]
    end

    subgraph Microservice [Python FastAPI Verification Orchestrator]
        Orch[POST /verify Orchestrator]
        BotEngine[POST /chatbot/query AI Engine]
    end

    subgraph Government Adapters [Mock Source System Adapters]
        DigiLocker[DigiLocker Adapter\n(ST Certificate & Identity)]
        AISHE[AISHE / UDISE+ Adapter\n(Institution & Enrollment)]
        APAAR[APAAR Adapter\n(One Nation One Student ID)]
        UIDAI[UIDAI Adapter\n(e-KYC Identity)]
        EDistrict[e-District Adapter\n(Income & Domicile)]
    end

    subgraph External Ready [Production External Services]
        Bhashini[Bhashini Multilingual API]
        PFMS[PFMS Direct Benefit Transfer]
    end

    %% Flow Connections
    UI -->|REST / HTTPS| Gateway
    Gateway --> Crypto
    Gateway --> Audit
    Audit --> DB
    Routes --> DB

    Gateway -->|Internal REST| Microservice
    Orch --> DigiLocker
    Orch --> AISHE
    Orch --> APAAR
    Orch --> UIDAI
    Orch --> EDistrict

    Orch -->|Mismatch Detected| Queue[Manual Review Queue]
    Queue --> DB

    BotEngine -.->|Production Ready| Bhashini
    DB -.->|DBT Transaction| PFMS
```

---

## 2. Core Architectural Differentiators (SIH Pitch Callouts)

1. **Gateway ➔ Orchestrator ➔ Adapter Architecture**:
   - The Express API Gateway manages student workflows, security, and data persistence.
   - The Python FastAPI Orchestrator executes high-throughput, parallel verification calls to background government system adapters.

2. **Isolated Adapter Interface**:
   - Each adapter (`DigiLocker`, `AISHE`, `APAAR`, `UIDAI`, `e-District`) conforms to a unified return contract (`status`, `confidence`, `details`).
   - Mock functions return ~70% verified, ~15% mismatch, and ~15% pending to simulate realistic government system latencies.
   - In production, adapter function bodies are replaced with live NDSAP REST calls without altering the orchestrator interface.

3. **Automated Manual Review Routing**:
   - When an adapter returns a data mismatch (e.g. income discrepancy between certificate and e-District portal), the orchestrator automatically routes the case to the `ManualReviewQueue` for district verifier resolution rather than blocking the beneficiary.

4. **Document Reuse ("Upload Once, Benefit Anywhere")**:
   - Documents stored in the digital document wallet carry `reused_from_application_id` references, allowing ST students to apply across multiple schemes without re-submitting physical or digital certificates.
