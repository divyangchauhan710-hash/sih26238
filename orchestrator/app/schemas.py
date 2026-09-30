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
    query: Optional[str] = None
    message: Optional[str] = None
    language: Optional[str] = "en"
    target_language: Optional[str] = None
    student_context: Optional[Dict[str, Any]] = None

    @property
    def get_query(self) -> str:
        return self.message or self.query or ""

    @property
    def get_lang(self) -> str:
        return self.target_language or self.language or "en"

class ChatbotResponse(BaseModel):
    query: str
    matched_intent: str
    answer: str
    confidence: float
    provider_note: str
