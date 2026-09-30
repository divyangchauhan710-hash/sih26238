"""
Groq LLM Service Module (llama-3.3-70b-versatile)
=================================================
Handles intelligent, grounded Q&A and multilingual output in a single call.
Grounds responses in student's real database context and 5 MoTA ST scholarship schemes rules.
"""

import os
import json
import requests
from typing import Dict, Any

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
MODEL_NAME = "qwen/qwen3.8-27b"

def build_system_prompt(student_context: Dict[str, Any], target_language: str) -> str:
    lang = (target_language or "en").lower()
    if lang in ["hi", "hindi"]:
        lang_instruction = "Respond ONLY in Hindi (using Devanagari script). Be natural, polite, and accurate."
    else:
        lang_instruction = "Respond in clear, professional English."

    prompt = f"""You are EkVidya AI Assistant, the official conversational AI for the Ministry of Tribal Affairs (MoTA), Government of India.
Your mission is to help Scheduled Tribe (ST) students with scholarship eligibility, required documents, application status tracking, and Direct Benefit Transfer (DBT) disbursements.

CRITICAL LANGUAGE INSTRUCTION:
{lang_instruction}

OFFICIAL MOTA ST SCHOLARSHIP SCHEMES RULES:
1. Pre-Matric Scholarship for ST Students:
   - For Classes 9 and 10 in recognized schools.
   - Max family income limit: ₹2,50,000 per annum.
   - Scholarship amount: up to ₹4,000 / yr.
2. Post-Matric Scholarship for ST Students:
   - For post-secondary, ITI, Diploma, Degree, PG courses.
   - Max family income limit: ₹2,50,000 per annum.
   - Scholarship amount: up to ₹25,000 / yr.
3. Top Class Education Scheme for ST Students:
   - For full-time studies in notified premier institutions (IITs, NITs, IIMs, AIIMS, NIFTs).
   - Max family income limit: ₹6,000,000 per annum.
   - Full tuition fee coverage + maintenance allowance up to ₹2,00,000.
4. National Fellowship for ST Students (NFST):
   - For ST scholars pursuing M.Phil and Ph.D. degrees in Indian universities.
   - Monthly fellowship stipend: ₹31,000+ per month plus HRA.
5. National Overseas Scholarship for ST Students (NOS):
   - For higher studies (Master's, Ph.D., Post-Doc) abroad in specified fields.
   - Max family income limit: ₹6,000,000 per annum, minimum 55% marks in qualifying degree.
   - Financial support: up to ₹15,00,000 per annum.

AUTHENTICATED STUDENT REAL DATABASE CONTEXT:
{json.dumps(student_context or {}, indent=2, ensure_ascii=False)}

GUIDELINES FOR YOUR RESPONSE:
- Use the student's real data above (their name, state, district, ST certificate reference, application status, verification check statuses, and DBT disbursement records) to answer personal queries specifically.
- If they ask about required documents, list: ST Caste Certificate (DigiLocker), Income Certificate (e-District), Aadhaar Card (UIDAI), Bank Account Passbook (PFMS DBT), and Academic Marksheet.
- Keep responses concise, accurate, helpful, and grounded in reality.
- Strictly adhere to the CRITICAL LANGUAGE INSTRUCTION!
"""
    return prompt

def ask_assistant(user_message: str, student_context: Dict[str, Any] = None, target_language: str = "en") -> str:
    if not user_message or not user_message.strip():
        return "Please ask a question regarding your scholarship or application status."

    if not GROQ_API_KEY:
        return _fallback_response(user_message, target_language)

    system_prompt = build_system_prompt(student_context or {}, target_language)

    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": MODEL_NAME,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message.strip()}
        ],
        "temperature": 0.3,
        "max_tokens": 1024
    }

    try:
        response = requests.post(GROQ_API_URL, headers=headers, json=payload, timeout=12)
        if response.status_code == 200:
            data = response.json()
            content = data["choices"][0]["message"]["content"]
            return content.strip()
        else:
            print(f"Groq API HTTP Error {response.status_code}: {response.text}")
            return _fallback_response(user_message, target_language)
    except Exception as e:
        print(f"Groq Assistant Exception: {e}")
        return _fallback_response(user_message, target_language)

def _fallback_response(user_message: str, target_language: str) -> str:
    is_hi = (target_language or "en").lower() in ["hi", "hindi"]
    if is_hi:
        return "एकविद्या एआई सहायक: आपका प्रश्न प्राप्त हो गया है। आप एकविद्या पोर्टल पर प्री-मैट्रिक, पोस्ट-मैट्रिक, टॉप क्लास, एनएफएसटी और एनओएस योजनाओं के अपने आवेदन और डीबीटी भुगतान स्थिति की जांच कर सकते हैं।"
    return "EkVidya AI Assistant: Your query has been received. You can track your applications for Pre-Matric, Post-Matric, Top Class, NFST, and NOS schemes directly on the EkVidya Dashboard."
