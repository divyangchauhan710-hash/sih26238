"""
EkVidya Verification & AI Microservice (FastAPI)
================================================
Orchestrates automated background verification checks across Government Source System Adapters
(DigiLocker, AISHE/UDISE+, APAAR, UIDAI, e-District) and serves the EkVidya FAQ Chatbot.
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from .schemas import VerificationRequest, VerificationResponse, ChatbotRequest, ChatbotResponse
from .adapters import (
    verify_digilocker,
    verify_aishe_udise,
    verify_apaar,
    verify_uidai,
    verify_edistrict
)
from .chatbot import process_query

app = FastAPI(
    title="EkVidya Verification & AI Microservice",
    description="Automated Government System Verification Orchestrator & AI Chatbot Gateway for Ministry of Tribal Affairs ST Scholarships",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {
        "status": "online",
        "service": "EkVidya Verification Orchestrator",
        "adapters": ["DigiLocker", "AISHE", "UDISE+", "APAAR", "UIDAI", "e-District"]
    }

@app.post("/verify", response_model=VerificationResponse)
def run_verification(payload: VerificationRequest):
    check_type_upper = payload.check_type.upper()
    
    # Route to appropriate source system adapter
    if check_type_upper in ["IDENTITY"]:
        result = verify_uidai(payload.student_id, payload.application_id, payload.check_type)
    elif check_type_upper in ["ST_CERTIFICATE"]:
        result = verify_digilocker(payload.student_id, payload.application_id, payload.check_type)
    elif check_type_upper in ["INSTITUTION", "ACADEMIC_RECORD"]:
        result = verify_aishe_udise(payload.student_id, payload.application_id, payload.check_type)
    elif check_type_upper in ["APAAR_ID", "NET_JRF"]:
        result = verify_apaar(payload.student_id, payload.application_id, payload.check_type)
    elif check_type_upper in ["INCOME", "DOMICILE"]:
        result = verify_edistrict(payload.student_id, payload.application_id, payload.check_type)
    else:
        # Default fallback adapter (DigiLocker)
        result = verify_digilocker(payload.student_id, payload.application_id, payload.check_type)
        
    return VerificationResponse(
        status=result["status"],
        confidence=result["confidence"],
        details=result["details"]
    )

@app.post("/chatbot/query", response_model=ChatbotResponse)
def query_chatbot(payload: ChatbotRequest):
    res = process_query(payload.query, payload.language or "en")
    return ChatbotResponse(
        query=res["query"],
        matched_intent=res["matched_intent"],
        answer=res["answer"],
        confidence=res["confidence"],
        provider_note=res["provider_note"]
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
