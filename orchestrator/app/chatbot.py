"""
Chatbot FAQ Engine & Multilingual Integration Module
===================================================
Production Integration Note:
----------------------------
In a production deployment for the Ministry of Tribal Affairs:
1. Multilingual Support: Integrate BHASHINI API (bhashini.gov.in) for real-time translation & transliteration
   across 22 official Indian languages (e.g. Hindi, Santhali, Gondi, Ho, Mundari, Oraon).
2. Voice & Conversational AI: Integrate JAGO / Bhashini Voice Bot for low-literacy ST beneficiaries.
3. LLM NLU: Route query to a fine-tuned Llama-3 / Indic-BERT model trained on MoTA guidelines & scheme rules.
"""

from typing import Dict, Any

FAQS = [
    {
        "keywords": ["eligibility", "eligible", "who can apply", "income limit", "criteria"],
        "answer_en": "ST students enrolled in registered institutions with family income within scheme limits are eligible:\n- Pre-Matric: Max income ₹2.5L/yr (Classes 9-10)\n- Post-Matric: Max income ₹2.5L/yr (Post Class 10)\n- Top Class Education: Max income ₹6.0L/yr (Notified Top Institutes like IIT/NIT/AIIMS)\n- NFST (Fellowship): M.Phil/Ph.D. students\n- NOS (Overseas): Max income ₹6.0L/yr, min 55% marks.",
        "answer_hi": "अनुसूचित जनजाति (ST) के छात्र जिनकी पारिवारिक आय योजना की सीमा के भीतर है, वे पात्र हैं:\n- प्री-मैट्रिक: अधिकतम आय ₹2.5 लाख/वर्ष (कक्षा 9-10)\n- पोस्ट-मैट्रिक: अधिकतम आय ₹2.5 लाख/वर्ष (कक्षा 10 के बाद)\n- टॉप क्लास: अधिकतम आय ₹6.0 लाख/वर्ष (आईआईटी/एनआईटी)\n- एनएफएसटी: एम.फिल/पीएचडी छात्र\n- एनओएस (विदेश अध्ययन): अधिकतम आय ₹6.0 लाख/वर्ष, न्यूनतम 55% अंक।"
    },
    {
        "keywords": ["document", "documents", "certificate", "caste", "income cert", "aadhaar", "digilocker"],
        "answer_en": "Required Documents for EkVidya:\n1. ST Caste Certificate (Digitally verified via DigiLocker)\n2. Annual Income Certificate (e-District)\n3. Aadhaar Card (UIDAI e-KYC)\n4. Bank Passbook / DBT Account Details\n5. Academic Marksheet & Institution Bonafide (AISHE/UDISE/APAAR)\nNote: Documents uploaded once can be reused across multiple scholarship applications!",
        "answer_hi": "एकविद्या के लिए आवश्यक दस्तावेज:\n1. एसटी जाति प्रमाण पत्र (डिजीलॉकर के माध्यम से सत्यापित)\n2. आय प्रमाण पत्र (ई-डिस्ट्रिक्ट)\n3. आधार कार्ड (यूआईडीएआई ई-केवाईसी)\n4. बैंक पासबुक / डीबीटी खाता विवरण\n5. शैक्षणिक अंकपत्र और संस्थान बोनाफाइड"
    },
    {
        "keywords": ["status", "track", "application status", "verification", "check status", "pending"],
        "answer_en": "You can track your application directly on the EkVidya Dashboard! Applications pass through 4 stages: Submitted ➔ Automatic Multi-Agency Verification ➔ Sanctioned ➔ Disbursed via Direct Benefit Transfer (DBT). If your application has a mismatch, it will be reviewed by the district verifier.",
        "answer_hi": "आप एकविद्या डैशबोर्ड पर अपने आवेदन को ट्रैक कर सकते हैं! आवेदन 4 चरणों से गुजरते हैं: जमा किया गया ➔ स्वचालित सत्यापन ➔ स्वीकृत ➔ डीबीटी (DBT) के माध्यम से हस्तांतरित।"
    },
    {
        "keywords": ["disbursement", "dbt", "payment", "money", "bank", "credit", "when will i get"],
        "answer_en": "Disbursements are processed directly into your Aadhaar-seeded Bank Account via Public Financial Management System (PFMS) Direct Benefit Transfer (DBT). Once sanctioned, payment is credited within 5-7 working days.",
        "answer_hi": "डीबीटी (DBT) के माध्यम से छात्रवृत्ति राशि सीधे आपके आधार से जुड़े बैंक खाते में 5-7 कार्य दिवसों के भीतर भेज दी जाती है।"
    }
]

DEFAULT_RESPONSE = {
    "answer_en": "I am EkVidya AI Assistant. You can ask me about Scheme Eligibility, Required Documents, Application Status, or Disbursement Timelines. (Production mode supports Bhashini Multilingual & Voice Bot).",
    "answer_hi": "मैं एकविद्या एआई सहायक हूं। आप मुझसे योजना पात्रता, आवश्यक दस्तावेज, आवेदन स्थिति, या डीबीटी भुगतान समयसीमा के बारे में पूछ सकते हैं।"
}

def process_query(query: str, lang: str = "en") -> Dict[str, Any]:
  query_lower = query.lower()
  
  for faq in FAQS:
    for kw in faq["keywords"]:
      if kw in query_lower:
        ans = faq["answer_hi"] if lang.lower() == "hi" else faq["answer_en"]
        return {
            "query": query,
            "matched_intent": faq["keywords"][0],
            "answer": ans,
            "confidence": 0.95,
            "provider_note": "Keyword Intent Match (Bhashini & JAGO ready)"
        }
        
  ans = DEFAULT_RESPONSE["answer_hi"] if lang.lower() == "hi" else DEFAULT_RESPONSE["answer_en"]
  return {
      "query": query,
      "matched_intent": "general_faq",
      "answer": ans,
      "confidence": 0.70,
      "provider_note": "Default FAQ Response (Bhashini & JAGO ready)"
  }
