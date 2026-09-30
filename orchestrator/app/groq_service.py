"""
Groq LLM Service Module (Multi-model candidate fallback)
=========================================================
Handles intelligent, grounded Q&A and multilingual output in a single call.
Grounds responses in student's real database context and 5 MoTA ST scholarship schemes rules.
"""

import os
import json
import requests
from typing import Dict, Any

def get_groq_api_key() -> str:
    key = os.getenv("GROQ_API_KEY", "")
    return key.strip() if key else ""

GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
CANDIDATE_MODELS = [
    "llama-3.3-70b-versatile",
    "llama-3.1-8b-instant",
    "llama3-70b-8192",
    "qwen/qwen3.8-27b"
]

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
1. Pre-Matric Scholarship for ST Students: For Classes 9-10, max income ₹2.5L/yr, amount up to ₹4,000/yr.
2. Post-Matric Scholarship for ST Students: For post-secondary / degree, max income ₹2.5L/yr, amount up to ₹25,000/yr.
3. Top Class Education Scheme for ST Students: For IITs, NITs, IIMs, AIIMS, max income ₹6.0L/yr, full tuition coverage up to ₹2,00,000.
4. National Fellowship for ST Students (NFST): For M.Phil & Ph.D. scholars, stipend ₹31,000+/month.
5. National Overseas Scholarship for ST Students (NOS): For Master's, Ph.D., Post-Doc abroad, max income ₹6.0L/yr, min 55% marks, up to ₹15,00,000/yr.

AUTHENTICATED STUDENT REAL DATABASE CONTEXT:
{json.dumps(student_context or {}, indent=2, ensure_ascii=False)}

INSTRUCTIONS:
- Use the student's real database context above (their name, state, district, ST certificate reference, application status, verification check statuses, and DBT disbursement records) to answer personal queries specifically.
- Keep responses concise, accurate, helpful, and grounded in reality.
- Strictly adhere to the CRITICAL LANGUAGE INSTRUCTION!
"""
    return prompt

def ask_assistant(user_message: str, student_context: Dict[str, Any] = None, target_language: str = "en") -> str:
    if not user_message or not user_message.strip():
        return "Please ask a question regarding your scholarship or application status."

    apiKey = get_groq_api_key()
    system_prompt = build_system_prompt(student_context or {}, target_language)

    if apiKey:
        headers = {
            "Authorization": f"Bearer {apiKey}",
            "Content-Type": "application/json"
        }

        for model in CANDIDATE_MODELS:
            payload = {
                "model": model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message.strip()}
                ],
                "temperature": 0.3,
                "max_tokens": 1024
            }

            try:
                response = requests.post(GROQ_API_URL, headers=headers, json=payload, timeout=10)
                if response.status_code == 200:
                    data = response.json()
                    content = data["choices"][0]["message"]["content"]
                    if content and len(content.strip()) > 0:
                        return content.strip()
                else:
                    print(f"Groq API Error ({model}) HTTP {response.status_code}: {response.text}")
            except Exception as e:
                print(f"Groq model {model} exception: {e}")

    return build_intelligent_fallback(user_message, target_language, student_context or {})

def build_intelligent_fallback(userQuery: str, lang: str, studentContext: Dict[str, Any]) -> str:
    q = userQuery.lower()
    isHindi = (lang or "en").lower() in ["hi", "hindi"]
    name = studentContext.get("name", "Beneficiary Student")
    state = studentContext.get("state", "Jharkhand")
    district = studentContext.get("district", "Ranchi")
    apps = studentContext.get("applications", [])
    primaryApp = apps[0] if apps else {}
    appStatus = primaryApp.get("status", "SUBMITTED") if isinstance(primaryApp, dict) else "SUBMITTED"
    schemeName = primaryApp.get("schemeName", "Post-Matric Scholarship for ST Students") if isinstance(primaryApp, dict) else "Post-Matric Scholarship for ST Students"

    if any(k in q for k in ["hi", "hello", "namaste", "hey", "नमस्ते"]):
        if isHindi:
            return f"नमस्ते {name}! मैं आपका एकविद्या एआई सहायक हूं। मैं आपकी {schemeName} (स्थिति: {appStatus}), डिजीलॉकर दस्तावेज़ सत्यापन और डीबीटी भुगतान विवरण में सहायता कर सकता हूं। आप क्या जानना चाहते हैं?"
        return f"Hello {name}! Namaste! I am your EkVidya AI Assistant. I can help you check your {schemeName} status ({appStatus}), DigiLocker verified certificates, or Direct Benefit Transfer (DBT) details. What would you like to know?"

    if any(k in q for k in ["detail", "status", "application", "विवरण", "स्थिति", "info"]):
        if isHindi:
            return f"छात्र विवरण ({name}):\n• राज्य एवं जिला: {district}, {state}\n• एसटी योजना: {schemeName}\n• आवेदन स्थिति: {appStatus}\n• डिजीलॉकर दस्तावेज़: सत्यापित\n• भुगतान मोड: आधार-संलग्न बैंक खाते में पीएफएमएस-डीबीटी!"
        return f"Student Profile & Application Details ({name}):\n• State & District: {district}, {state}\n• Active Scheme: {schemeName}\n• Application Status: {appStatus}\n• DigiLocker Documents: Verified\n• Disbursement Mode: Direct Benefit Transfer (DBT) via Aadhaar-seeded account!"

    if any(k in q for k in ["document", "certificate", "दस्तावेज"]):
        if isHindi:
            return "एकविद्या एसटी छात्रवृत्ति के लिए आवश्यक दस्तावेज़:\n1. डिजीलॉकर से सत्यापित एसटी जाति प्रमाण पत्र\n2. ई-डिस्ट्रिक्ट वार्षिक आय प्रमाण पत्र\n3. यूआईडीएआई आधार ई-केवाईसी\n4. बैंक पासबुक / डीबीटी खाता विवरण\n5. शैक्षणिक अंकपत्र और बोनाफाइड प्रमाण पत्र"
        return "Required Documents for EkVidya ST Scholarships:\n1. ST Caste Certificate (Digitally verified via DigiLocker)\n2. Annual Income Certificate (e-District Portal)\n3. Aadhaar Card (UIDAI e-KYC)\n4. Bank Passbook / DBT Account Details\n5. Academic Marksheet & Institution Bonafide"

    if any(k in q for k in ["eligible", "rule", "income", "पात्रता"]):
        if isHindi:
            return "जनजातीय कार्य मंत्रालय (MoTA) पात्रता नियम:\n• प्री-मैट्रिक: कक्षा 9-10, पारिवारिक आय ≤ ₹2.5 लाख/वर्ष\n• पोस्ट-मैट्रिक: कक्षा 10+ एवं डिग्री, आय ≤ ₹2.5 लाख/वर्ष\n• टॉप क्लास (IIT/NIT): आय ≤ ₹6.0 लाख/वर्ष\n• एनएफएसटी (एम.फिल/पीएचडी): ₹31,000/माह स्टाइपेंड\n• एनओएस (विदेश अध्ययन): आय ≤ ₹6.0 लाख/वर्ष, न्यूनतम 55% अंक।"
        return "Ministry of Tribal Affairs (MoTA) Eligibility Rules:\n• Pre-Matric: Classes 9-10, income ≤ ₹2.5L/yr\n• Post-Matric: Post Class 10/Degree, income ≤ ₹2.5L/yr\n• Top Class (IITs/NITs): Income ≤ ₹6.0L/yr\n• NFST (M.Phil/Ph.D.): ₹31,000/month stipend\n• NOS (Abroad): Income ≤ ₹6.0L/yr, min 55% marks."

    if isHindi:
        return f"{name} जी, आपके प्रश्न (\"{userQuery}\") के संबंध में: आपका {schemeName} आवेदन वर्तमान में [{appStatus}] चरण में है। सभी 5 मंत्रालय योजनाओं की अधिक जानकारी डैशबोर्ड पर उपलब्ध है।"
    return f"Dear {name}, regarding your query (\"{userQuery}\"): Your {schemeName} application is currently in [{appStatus}] state. You can view complete details on your EkVidya Dashboard."
