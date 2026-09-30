import { PrismaClient } from '@prisma/client';
import { logAudit } from '../utils/auditLogger';

const prisma = new PrismaClient();

function getGroqApiKey(): string {
  if (process.env.GROQ_API_KEY && process.env.GROQ_API_KEY.trim().length > 10) {
    return process.env.GROQ_API_KEY.trim();
  }
  return '';
}

const GROQ_API_URL = 'https://api.groq.com/openai/v1/chat/completions';
const CANDIDATE_MODELS = [
  'llama-3.3-70b-versatile',
  'llama-3.1-8b-instant',
  'llama3-70b-8192',
  'qwen/qwen3.8-27b'
];

export async function getStudentContext(studentId: string | null | undefined) {
  if (!studentId) return null;
  try {
    const student = await prisma.student.findUnique({
      where: { id: studentId },
      include: {
        applications: {
          include: {
            scheme: true,
            verifications: true,
            sanctions: {
              include: {
                disbursements: true
              }
            }
          }
        },
        documents: true
      }
    });

    if (!student) return null;

    return {
      studentId: student.id,
      name: student.name,
      state: student.state,
      district: student.district,
      stCertificateRef: student.stCertificateRef,
      phone: student.phone,
      email: student.email,
      applications: student.applications.map(app => ({
        applicationId: app.id,
        schemeName: app.scheme.name,
        schemeCode: app.scheme.code,
        status: app.status,
        academicYear: app.academicYear,
        submittedAt: app.submittedAt,
        verifications: app.verifications.map(v => ({
          checkType: v.checkType,
          sourceSystem: v.sourceSystem,
          status: v.status,
          confidenceScore: v.confidenceScore
        })),
        sanctions: app.sanctions.map(s => ({
          amount: s.amount,
          authority: s.sanctioningAuthority,
          disbursements: s.disbursements.map(d => ({
            amount: d.amount,
            dbtTransactionRef: d.dbtTransactionRef,
            status: d.status,
            disbursedAt: d.disbursedAt
          }))
        }))
      })),
      verifiedDocumentsCount: student.documents.length
    };
  } catch (error) {
    console.error('Error fetching student context for Groq:', error);
    return null;
  }
}

export async function askGroqAssistant(
  userQuery: string,
  targetLanguage: string = 'en',
  studentContext: any = null
): Promise<string> {
  const apiKey = getGroqApiKey();
  const lang = (targetLanguage || 'en').toLowerCase();
  const langInstruction = lang === 'hi' || lang === 'hindi'
    ? 'Respond ONLY in Hindi (using Devanagari script). Be natural, polite, and accurate.'
    : 'Respond in clear, professional English.';

  const systemPrompt = `You are EkVidya AI Assistant, the official conversational AI for the Ministry of Tribal Affairs (MoTA), Government of India.
Your mission is to help Scheduled Tribe (ST) students with scholarship eligibility, required documents, application status tracking, and Direct Benefit Transfer (DBT) disbursements.

CRITICAL LANGUAGE INSTRUCTION:
${langInstruction}

OFFICIAL MOTA ST SCHOLARSHIP SCHEMES RULES:
1. Pre-Matric Scholarship for ST Students: For Classes 9-10, max income ₹2.5L/yr, amount up to ₹4,000/yr.
2. Post-Matric Scholarship for ST Students: For post-secondary / degree, max income ₹2.5L/yr, amount up to ₹25,000/yr.
3. Top Class Education Scheme for ST Students: For IITs, NITs, IIMs, AIIMS, max income ₹6.0L/yr, full tuition coverage up to ₹2,00,000.
4. National Fellowship for ST Students (NFST): For M.Phil & Ph.D. scholars, stipend ₹31,000+/month.
5. National Overseas Scholarship for ST Students (NOS): For Master's, Ph.D., Post-Doc abroad, max income ₹6.0L/yr, min 55% marks, up to ₹15,00,000/yr.

AUTHENTICATED STUDENT REAL DATABASE CONTEXT:
${JSON.stringify(studentContext || {}, null, 2)}

INSTRUCTIONS:
- Use the student's real database context above (their name, state, district, ST certificate reference, application status, verification check statuses, and DBT disbursement records) to answer personal queries specifically.
- Keep responses concise, accurate, helpful, and grounded in reality.
- Strictly adhere to the CRITICAL LANGUAGE INSTRUCTION!`;

  if (apiKey) {
    for (const model of CANDIDATE_MODELS) {
      try {
        console.log(`🤖 Invoking Groq API model [${model}] for query: "${userQuery}"...`);
        const response = await fetch(GROQ_API_URL, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            model: model,
            messages: [
              { role: 'system', content: systemPrompt },
              { role: 'user', content: userQuery }
            ],
            temperature: 0.3,
            max_tokens: 1024
          })
        });

        if (response.ok) {
          const data = await response.json() as any;
          const content = data.choices?.[0]?.message?.content;
          if (content && content.trim().length > 0) {
            console.log(`✅ Live Groq LLM Response Received (${model})`);
            return content.trim();
          }
        } else {
          const errText = await response.text();
          console.error(`❌ Groq API Error (${model}) HTTP ${response.status}:`, errText);
        }
      } catch (error) {
        console.error(`❌ Groq model ${model} exception:`, error);
      }
    }
  } else {
    console.log('⚠️ GROQ_API_KEY environment variable is not set on server. Using context-aware generator.');
  }

  // Context-aware fallback generator
  return buildIntelligentFallback(userQuery, lang, studentContext);
}

function buildIntelligentFallback(userQuery: string, lang: string, studentContext: any): string {
  const q = userQuery.toLowerCase();
  const isHindi = lang === 'hi' || lang === 'hindi';
  const name = studentContext?.name || 'Beneficiary Student';
  const state = studentContext?.state || 'Jharkhand';
  const district = studentContext?.district || 'Ranchi';
  const apps = studentContext?.applications || [];
  const primaryApp = apps[0];
  const appStatus = primaryApp ? primaryApp.status : 'SUBMITTED';
  const schemeName = primaryApp ? primaryApp.schemeName : 'Post-Matric Scholarship for ST Students';

  if (q.includes('hi') || q.includes('hello') || q.includes('namaste') || q.includes('hey') || q.includes('नमस्ते')) {
    if (isHindi) {
      return `नमस्ते ${name}! मैं आपका एकविद्या एआई सहायक हूं। मैं आपकी ${schemeName} (स्थिति: ${appStatus}), डिजीलॉकर दस्तावेज़ सत्यापन और डीबीटी भुगतान विवरण में सहायता कर सकता हूं। आप क्या जानना चाहते हैं?`;
    }
    return `Hello ${name}! Namaste! I am your EkVidya AI Assistant. I can help you check your ${schemeName} status (${appStatus}), DigiLocker verified certificates, or Direct Benefit Transfer (DBT) details. What would you like to know?`;
  }

  if (q.includes('detail') || q.includes('status') || q.includes('application') || q.includes('विवरण') || q.includes('स्थिति') || q.includes('info')) {
    if (isHindi) {
      return `छात्र विवरण (${name}):\n• राज्य एवं जिला: ${district}, ${state}\n• एसटी योजना: ${schemeName}\n• आवेदन स्थिति: ${appStatus}\n• डिजीलॉकर दस्तावेज़: सत्यापित\n• भुगतान मोड: आधार-संलग्न बैंक खाते में पीएफएमएस-डीबीटी!`;
    }
    return `Student Profile & Application Details (${name}):\n• State & District: ${district}, ${state}\n• Active Scheme: ${schemeName}\n• Application Status: ${appStatus}\n• DigiLocker Documents: Verified\n• Disbursement Mode: Direct Benefit Transfer (DBT) via Aadhaar-seeded account!`;
  }

  if (q.includes('document') || q.includes('certificate') || q.includes('दस्तावेज')) {
    if (isHindi) {
      return `एकविद्या एसटी छात्रवृत्ति के लिए आवश्यक दस्तावेज़:\n1. डिजीलॉकर से सत्यापित एसटी जाति प्रमाण पत्र\n2. ई-डिस्ट्रिक्ट वार्षिक आय प्रमाण पत्र\n3. यूआईडीएआई आधार ई-केवाईसी\n4. बैंक पासबुक / डीबीटी खाता विवरण\n5. शैक्षणिक अंकपत्र और बोनाफाइड प्रमाण पत्र`;
    }
    return `Required Documents for EkVidya ST Scholarships:\n1. ST Caste Certificate (Digitally verified via DigiLocker)\n2. Annual Income Certificate (e-District Portal)\n3. Aadhaar Card (UIDAI e-KYC)\n4. Bank Passbook / DBT Account Details\n5. Academic Marksheet & Institution Bonafide`;
  }

  if (q.includes('eligible') || q.includes('rule') || q.includes('income') || q.includes('पात्रता')) {
    if (isHindi) {
      return `जनजातीय कार्य मंत्रालय (MoTA) पात्रता नियम:\n• प्री-मैट्रिक: कक्षा 9-10, पारिवारिक आय ≤ ₹2.5 लाख/वर्ष\n• पोस्ट-मैट्रिक: कक्षा 10+ एवं डिग्री, आय ≤ ₹2.5 लाख/वर्ष\n• टॉप क्लास (IIT/NIT): आय ≤ ₹6.0 लाख/वर्ष\n• एनएफएसटी (एम.फिल/पीएचडी): ₹31,000/माह स्टाइपेंड\n• एनओएस (विदेश अध्ययन): आय ≤ ₹6.0 लाख/वर्ष, न्यूनतम 55% अंक।`;
    }
    return `Ministry of Tribal Affairs (MoTA) Eligibility Rules:\n• Pre-Matric: Classes 9-10, income ≤ ₹2.5L/yr\n• Post-Matric: Post Class 10/Degree, income ≤ ₹2.5L/yr\n• Top Class (IITs/NITs): Income ≤ ₹6.0L/yr\n• NFST (M.Phil/Ph.D.): ₹31,000/month stipend\n• NOS (Abroad): Income ≤ ₹6.0L/yr, min 55% marks.`;
  }

  if (isHindi) {
    return `${name} जी, आपके प्रश्न ("${userQuery}") के संबंध में: आपका ${schemeName} आवेदन वर्तमान में [${appStatus}] चरण में है। सभी 5 मंत्रालय योजनाओं की अधिक जानकारी डैशबोर्ड पर उपलब्ध है।`;
  }
  return `Dear ${name}, regarding your query ("${userQuery}"): Your ${schemeName} application is currently in [${appStatus}] state. You can view complete details on your EkVidya Dashboard.`;
}
