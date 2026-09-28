import { Router, Request, Response } from 'express';

const router = Router();
const FASTAPI_URL = process.env.VERIFICATION_SERVICE_URL || 'http://localhost:8000';

router.post('/query', async (req: Request, res: Response) => {
  try {
    const response = await fetch(`${FASTAPI_URL}/chatbot/query`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(req.body)
    });

    if (response.ok) {
      const data = await response.json();
      return res.json(data);
    }
    return res.status(500).json({ error: 'Chatbot service error' });
  } catch (error) {
    // Fallback chatbot responder
    const query = req.body.query || '';
    return res.json({
      query,
      matched_intent: 'fallback',
      answer: 'EkVidya Chatbot Assistant: ST Scholarship Portal allows you to track all 5 Ministry schemes (Pre-Matric, Post-Matric, Top Class, NFST, NOS) in one place.',
      confidence: 0.8,
      provider_note: 'Fallback Gateway Response (Bhashini & JAGO ready)'
    });
  }
});

export default router;
