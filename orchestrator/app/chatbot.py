"""
Chatbot FAQ Engine & Groq LLM Integration Module
=================================================
Processes incoming chatbot queries using Groq's llama-3.3-70b-versatile model
grounded in authenticated student context from Postgres database.
"""

from typing import Dict, Any
from .groq_service import ask_assistant

def process_query(query: str, lang: str = "en", student_context: Dict[str, Any] = None) -> Dict[str, Any]:
    answer = ask_assistant(
        user_message=query,
        student_context=student_context or {},
        target_language=lang
    )

    return {
        "query": query,
        "matched_intent": "groq_llm_qa",
        "answer": answer,
        "confidence": 0.99,
        "provider_note": "Groq LLM (llama-3.3-70b-versatile)"
    }
