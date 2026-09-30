"""
Gemini LLM Service Module
=========================
Handles intelligent, grounded Q&A and multilingual output using Google Gemini API.
Grounds responses in student's real database context and official MoTA ST scholarship scheme rules.
"""

import os
import json
import re
import requests
from typing import Dict, Any

try:
    from dotenv import load_dotenv
    load_dotenv()
    backend_env = os.path.join(os.path.dirname(__file__), "..", "..", "backend", ".env")
    if os.path.exists(backend_env):
        load_dotenv(backend_env)
except ImportError:
    pass

CANDIDATE_MODELS = [
    "gemini-3.5-flash-lite",
    "gemini-3.5-flash",
    "gemini-flash-latest"
]

def get_gemini_api_key() -> str:
    key = os.getenv("GEMINI_API_KEY", "")
    return key.strip() if key else ""

def get_gemini_model() -> str:
    env_model = os.getenv("GEMINI_MODEL", "").strip()
    if env_model:
        return env_model
    return CANDIDATE_MODELS[0] if CANDIDATE_MODELS else "gemini-1.5-flash"

def detect_language(user_query: str, target_language: str) -> str:
    t_lang = (target_language or "en").lower()
    if t_lang in ["hi", "hindi"]:
        return "hi"

    q = (user_query or "").lower()
    if re.search(r'[\u0900-\u097F]', user_query or ""):
        return "hi"

    if any(phrase in q for phrase in ["hindi me", "hindi mein", "in hindi", "hindi mai"]):
        return "hi"

    hindi_keywords = [
        "hindi", "हिंदी", "jvab", "jawaab", "jawab", "batao", "bataiye", "kya", "mera", "meri", "mere",
        "kaise", "kab", "aayega", "aayegi", "hai", "hain", "karo", "kripya", "namaste", "shukriya", "me", "mein", "do"
    ]
    words = q.split()
    if any(w in hindi_keywords for w in words):
        return "hi"

    return "en"

def build_system_prompt(student_context: Dict[str, Any], effective_lang: str) -> str:
    if effective_lang == "hi":
        lang_instruction = "Respond ONLY in Hindi (using Devanagari script). Be natural, polite, and accurate."
    else:
        lang_instruction = "Respond in clear, professional English. If the user query is in Hindi or Hinglish, respond in Hindi (Devanagari script)."

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

    api_key = get_gemini_api_key()
    effective_lang = detect_language(user_message, target_language)
    system_prompt = build_system_prompt(student_context or {}, effective_lang)

    if api_key:
        models_to_try = []
        env_model = os.getenv("GEMINI_MODEL", "").strip()
        if env_model:
            models_to_try.append(env_model)
        for m in CANDIDATE_MODELS:
            if m not in models_to_try:
                models_to_try.append(m)

        for model_name in models_to_try:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent"
            headers = {
                "Content-Type": "application/json",
                "x-goog-api-key": api_key
            }
            payload = {
                "systemInstruction": {
                    "parts": [{"text": system_prompt}]
                },
                "contents": [
                    {
                        "parts": [{"text": user_message.strip()}]
                    }
                ]
            }

            try:
                print(f"[GEMINI] Calling Gemini API [{model_name}] (Detected Lang: {effective_lang}) for query: \"{user_message}\"...")
                response = requests.post(url, headers=headers, json=payload, timeout=12)
                
                if response.status_code == 200:
                    data = response.json()
                    try:
                        content = data["candidates"][0]["content"]["parts"][0]["text"]
                        if content and len(content.strip()) > 0:
                            print(f"[GEMINI] Live call [{model_name}] succeeded!")
                            return content.strip()
                    except (KeyError, IndexError) as e:
                        print(f"[GEMINI] Failed to parse response candidates: {e}, Data: {data}")
                else:
                    print(f"[GEMINI] API Error ({model_name}) HTTP {response.status_code}: {response.text}")
            except Exception as e:
                print(f"[GEMINI] API request exception ({model_name}): {e}")
    else:
        print("[GEMINI] GEMINI_API_KEY environment variable is missing!")

    return build_intelligent_fallback(user_message, effective_lang, student_context or {})

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
