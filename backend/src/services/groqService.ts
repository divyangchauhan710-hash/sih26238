import { PrismaClient } from '@prisma/client';
import { logAudit } from '../utils/auditLogger';

const prisma = new PrismaClient();
const GROQ_API_KEY = process.env.GROQ_API_KEY || '';
const GROQ_API_URL = 'https://api.groq.com/openai/v1/chat/completions';
const MODEL_NAME = 'qwen/qwen3.8-27b';

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

  try {
    const response = await fetch(GROQ_API_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${GROQ_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: MODEL_NAME,
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
      if (content) return content.trim();
    } else {
      const errText = await response.text();
      console.error(`Groq API Error ${response.status}:`, errText);
    }
  } catch (error) {
    console.error('Groq request exception:', error);
  }

  // Graceful fallback
  if (lang === 'hi' || lang === 'hindi') {
    return 'एकविद्या एआई सहायक: आपका प्रश्न प्राप्त हो गया है। आप एकविद्या पोर्टल पर प्री-मैट्रिक, पोस्ट-मैट्रिक, टॉप क्लास, एनएफएसटी और एनओएस योजनाओं के अपने आवेदन और डीबीटी भुगतान स्थिति की जांच कर सकते हैं।';
  }
  return 'EkVidya AI Assistant: Your query has been received. You can track your applications for Pre-Matric, Post-Matric, Top Class, NFST, and NOS schemes directly on the EkVidya Dashboard.';
}
