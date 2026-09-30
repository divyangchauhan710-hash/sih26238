import { Router, Request, Response } from 'express';
import { getStudentContext, askGroqAssistant } from '../services/groqService';
import { logAudit } from '../utils/auditLogger';

const router = Router();
const FASTAPI_URL = process.env.VERIFICATION_SERVICE_URL || 'http://localhost:8000';

router.post('/query', async (req: Request, res: Response) => {
  try {
    const userQuery = req.body.message || req.body.query || 'Tell me about ST scholarship schemes';
    const targetLang = req.body.target_language || req.body.language || 'en';
    const studentId = req.body.studentId || (req as any).user?.studentId;

    console.log(`\n🤖 [CHATBOT QUERY] Lang: ${targetLang} | StudentId: ${studentId || 'None'}`);
    console.log(`❓ User Question: "${userQuery}"`);

    // Fetch real Postgres student data if available
    const studentContext = await getStudentContext(studentId);
    if (studentContext) {
      console.log(`📊 Grounded in real Postgres DB context for Student: ${studentContext.name} (${studentContext.district}, ${studentContext.state})`);
    } else {
      console.log(`ℹ️ Running query with general MoTA ST schemes knowledge.`);
    }

    let answer: string = '';
    let matchedIntent = 'groq_llm';
    let providerNote = 'Groq LLM (llama-3.3-70b-versatile)';

    // Try FastAPI service first
    try {
      const fastApiResponse = await fetch(`${FASTAPI_URL}/chatbot/query`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          query: userQuery,
          message: userQuery,
          language: targetLang,
          target_language: targetLang,
          student_context: studentContext
        })
      });

      if (fastApiResponse.ok) {
        const data = await fastApiResponse.json() as any;
        answer = data.answer;
        matchedIntent = data.matched_intent || matchedIntent;
        providerNote = data.provider_note || providerNote;
      }
    } catch (_) {
      // FastAPI not running - call Groq direct service in Node
    }

    if (!answer) {
      answer = await askGroqAssistant(userQuery, targetLang, studentContext);
    }

    console.log(`💬 [GROQ AI RESPONSE]: "${answer.substring(0, 120)}..."\n`);

    // Log chat exchange for demo/audit purposes
    if ((req as any).user?.userId) {
      await logAudit((req as any).user.userId, 'CHATBOT_QUERY', 'Chatbot', studentId || 'GUEST', req);
    }

    return res.json({
      query: userQuery,
      matched_intent: matchedIntent,
      answer: answer,
      confidence: 0.99,
      provider_note: providerNote
    });
  } catch (error: any) {
    console.error('Chatbot route exception:', error);
    return res.status(500).json({
      query: req.body.message || req.body.query || '',
      matched_intent: 'fallback',
      answer: 'EkVidya AI Assistant is currently operating in offline mode. Please track your ST scholarship applications on the EkVidya Dashboard.',
      confidence: 0.70,
      provider_note: 'Fallback Gateway Response'
    });
  }
});

export default router;
