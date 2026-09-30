"""
Chatbot FAQ Engine & Gemini LLM Integration Module
===================================================
Processes incoming chatbot queries using Google Gemini LLM API
grounded in authenticated student context from Postgres database.
"""

from typing import Dict, Any
from .gemini_service import ask_assistant, get_gemini_model

def process_query(query: str, lang: str = "en", student_context: Dict[str, Any] = None) -> Dict[str, Any]:
    answer = ask_assistant(
        user_message=query,
        student_context=student_context or {},
        target_language=lang
    )

    model_name = get_gemini_model()

    return {
        "query": query,
        "matched_intent": "gemini_llm_qa",
        "answer": answer,
        "confidence": 0.99,
        "provider_note": f"Gemini LLM ({model_name})"
    }
