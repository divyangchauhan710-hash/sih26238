from pydantic import BaseModel
from typing import Optional, Dict, Any

class VerificationRequest(BaseModel):
    student_id: str
    application_id: str
    check_type: str  # IDENTITY, ST_CERTIFICATE, ACADEMIC_RECORD, INSTITUTION, INCOME, DOMICILE, DISABILITY, NET_JRF

class VerificationResponse(BaseModel):
    status: str      # verified, mismatch, pending
    confidence: float
    details: Dict[str, Any]

class ChatbotRequest(BaseModel):
    query: str
    language: Optional[str] = "en"  # "en" or "hi"

class ChatbotResponse(BaseModel):
    query: str
    matched_intent: str
    answer: str
    confidence: float
    provider_note: str
