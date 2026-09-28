# EkVidya — Unified ST Scholarship Mobile Platform (SIH26238)

[![Ministry of Tribal Affairs](https://img.shields.io/badge/Ministry-Tribal%20Affairs%20Govt%20of%20India-blue)](https://tribal.gov.in)
[![Hackathon](https://img.shields.io/badge/Smart%20India%20Hackathon-SIH26238-orange)](#)

## 📌 Architecture Summary in One Paragraph
**EkVidya** is a unified mobile application architecture that consolidates 5 previously disconnected Ministry of Tribal Affairs scholarship portals (Pre-Matric, Post-Matric, Top Class, NFST, NOS) into a single low-bandwidth-optimized mobile experience. Built with a **Flutter** mobile client, a **Node.js/Express (TypeScript)** API gateway, a **PostgreSQL** relational database with **Prisma ORM**, and a **Python/FastAPI** background verification orchestrator, it automates multi-agency verification across DigiLocker, AISHE/UDISE+, APAAR, UIDAI, and e-District via isolated mock adapters, automatically routing flagged mismatches to a verifier manual review queue while protecting sensitive student identifiers with AES-256 field-level encryption and full audit logging.

---

## 🛠️ Tech Stack & Directory Structure

```
d:\sih26238\
├── backend/               # Node.js + Express + TypeScript Gateway API
│   ├── prisma/            # Schema & Seed Script (3 Demo Students & Verifications)
│   ├── src/               # Controllers, Middleware, AES-256 Crypto, Audit Logger
│   └── package.json
├── orchestrator/          # Python + FastAPI Microservice
│   ├── app/adapters.py    # DigiLocker, AISHE, APAAR, UIDAI, e-District Adapters
│   ├── app/chatbot.py     # Intent/Keyword FAQ Engine (Bhashini/JAGO ready)
│   └── app/main.py
├── mobile_app/            # Flutter Mobile Application
│   ├── lib/screens/       # Login, Dashboard, Timeline, Wallet, Chatbot, Admin
│   ├── lib/l10n/          # English & Hindi Internationalization (intl)
│   └── web/index.html     # Web Simulator Preview
├── docker-compose.yml     # Containerized Stack (Postgres + Gateway + Microservice)
├── ARCHITECTURE.md        # Mermaid Flow Diagram & Component Spec
└── SECURITY.md            # AES-256, Audit Logs & Production Roadmap
```

---

## 🚀 Quick Setup & How to Run

### Method 1: Running via Docker Compose (Recommended)

1. Ensure Docker Desktop is running on your system.
2. Open terminal in the project root directory (`d:\sih26238`) and execute:
   ```bash
   docker-compose up --build
   ```
3. The services will start:
   - **Postgres Database**: `localhost:5432`
   - **Python Verification Microservice**: `http://localhost:8000` (Docs: `http://localhost:8000/docs`)
   - **Express API Gateway**: `http://localhost:5000` (Health: `http://localhost:5000/health`)

---

### Method 2: Running Services Locally (Development Mode)

#### 1. Backend API Gateway (Node.js/Express)
```bash
cd backend
npm install
npx prisma generate
# (Ensure Postgres or SQLite is running, then run seed script)
npx prisma db push
npx prisma db seed
npm run dev
```

#### 2. Verification Microservice (Python/FastAPI)
```bash
cd orchestrator
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --port 8000
```

#### 3. Flutter Mobile Application
```bash
cd mobile_app
flutter pub get
flutter run
```

*Note: For quick browser preview without Flutter installed, open [`mobile_app/web/index.html`](file:///d:/sih26238/mobile_app/web/index.html) in any browser.*

---

## 🔑 Pre-Seeded Demo Accounts (SIH Hackathon Pitching)

| Role | Email / User | Password | Applications & Verification State Demonstrated |
|---|---|---|---|
| **Student 1** | `ramesh.munda@example.com` | `Password@123` | **Post-Matric Scholarship**: Fully verified across DigiLocker & AISHE; **Sanctioned & Disbursed via DBT** (₹25,000). |
| **Student 2** | `sunita.marandi@example.com` | `Password@123` | **NFST (Fellowship)**: Under verification with genuine **e-District Income Mismatch** routed to `ManualReviewQueue`. |
| **Student 3** | `birsa.oraon@example.com` | `Password@123` | **Pre-Matric Scholarship**: Mid-verification (DigiLocker verified, UDISE pending). Demonstrates live adapter trigger button. |
| **Verifier/Admin**| `admin@ekvidya.gov.in` | `Password@123` | **Admin Review Queue**: Full review queue screen to approve or reject flagged verification discrepancies. |

---

## 🔒 Security Features Implemented
- **AES-256-GCM Field-Level Encryption**: Encrypts Aadhaar numbers and bank accounts at rest in Postgres.
- **Short-Lived JWT & Refresh Flow**: 15-min access tokens with role-based authorization (`STUDENT`, `ADMIN`, `VERIFIER`).
- **Audit Logging**: Mandatory logging of every identity/financial data access and document view to `AuditLog`.
- **Single Active Scheme Enforcer**: Enforces government business rules prohibiting double-dipping.
- See [`SECURITY.md`](file:///d:/sih26238/SECURITY.md) for full audit.
