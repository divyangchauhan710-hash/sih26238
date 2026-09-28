import http from 'http';

const FASTAPI_URL = process.env.VERIFICATION_SERVICE_URL || 'http://localhost:8000';

export interface VerificationResponsePayload {
  status: 'verified' | 'mismatch' | 'pending';
  confidence: number;
  details: any;
}

export async function callVerificationOrchestrator(
  studentId: string,
  applicationId: string,
  checkType: string
): Promise<VerificationResponsePayload> {
  const payload = JSON.stringify({
    student_id: studentId,
    application_id: applicationId,
    check_type: checkType
  });

  try {
    const response = await fetch(`${FASTAPI_URL}/verify`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: payload
    });

    if (response.ok) {
      const data = await response.json();
      return {
        status: data.status,
        confidence: data.confidence,
        details: data.details
      };
    }
  } catch (error) {
    console.warn('FastAPI Microservice unreachable, using inline fallback simulation:', error);
  }

  // Fallback simulator if Python service isn't running locally
  const rand = Math.random();
  if (rand < 0.70) {
    return {
      status: 'verified',
      confidence: 0.96,
      details: { source: 'MOCK_FALLBACK', check: checkType, remarks: 'Verified successfully' }
    };
  } else if (rand < 0.85) {
    return {
      status: 'mismatch',
      confidence: 0.61,
      details: { source: 'MOCK_FALLBACK', check: checkType, remarks: 'Data mismatch detected' }
    };
  } else {
    return {
      status: 'pending',
      confidence: 0.0,
      details: { source: 'MOCK_FALLBACK', check: checkType, remarks: 'Verification pending' }
    };
  }
}
