import { Request, Response } from 'express';
import { PrismaClient, ApplicationStatus, CheckType, SourceSystem, VerificationStatus } from '@prisma/client';
import { z } from 'zod';
import { callVerificationOrchestrator } from '../services/verificationService';
import { logAudit } from '../utils/auditLogger';

const prisma = new PrismaClient();

const CreateApplicationSchema = z.object({
  studentId: z.string().uuid(),
  schemeId: z.string().uuid(),
  academicYear: z.string().default('2025-2026')
});

export async function getStudentApplications(req: Request, res: Response) {
  try {
    const studentId = req.params.id;

    if (req.user?.role === 'STUDENT' && req.user.studentId !== studentId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const applications = await prisma.application.findMany({
      where: { studentId },
      include: {
        scheme: true,
        verifications: true,
        sanctions: {
          include: {
            disbursements: true
          }
        }
      },
      orderBy: { submittedAt: 'desc' }
    });

    await logAudit(req.user?.userId || 'SYSTEM', 'VIEW_STUDENT_APPLICATIONS', 'Student', studentId, req);

    return res.json({ applications });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function createApplication(req: Request, res: Response) {
  try {
    const parseResult = CreateApplicationSchema.safeParse(req.body);
    if (!parseResult.success) {
      return res.status(400).json({ error: 'Validation error', details: parseResult.error.errors });
    }

    const { studentId, schemeId, academicYear } = parseResult.data;

    // Check student ownership
    if (req.user?.role === 'STUDENT' && req.user.studentId !== studentId) {
      return res.status(403).json({ error: 'Cannot apply on behalf of another student' });
    }

    // BUSINESS RULE: "only one active scheme at a time"
    const activeApplications = await prisma.application.findMany({
      where: {
        studentId,
        status: {
          in: [ApplicationStatus.SUBMITTED, ApplicationStatus.UNDER_VERIFICATION, ApplicationStatus.SANCTIONED]
        }
      },
      include: { scheme: true }
    });

    if (activeApplications.length > 0) {
      const activeApp = activeApplications[0];
      return res.status(400).json({
        error: 'BUSINESS_RULE_VIOLATION',
        eligible: false,
        message: `Eligibility Conflict: You already have an active application under '${activeApp.scheme.name}' (Status: ${activeApp.status}). Government policy allows only one active scholarship application at a time. Please wait for completion or withdrawal.`
      });
    }

    // Create Application
    const application = await prisma.application.create({
      data: {
        studentId,
        schemeId,
        academicYear,
        status: ApplicationStatus.UNDER_VERIFICATION,
        submittedAt: new Date()
      },
      include: { scheme: true }
    });

    // Auto-generate standard verification checks based on scheme
    const initialChecks = [
      { checkType: CheckType.IDENTITY, sourceSystem: SourceSystem.UIDAI },
      { checkType: CheckType.ST_CERTIFICATE, sourceSystem: SourceSystem.DIGILOCKER },
      { checkType: CheckType.INSTITUTION, sourceSystem: SourceSystem.AISHE },
      { checkType: CheckType.INCOME, sourceSystem: SourceSystem.E_DISTRICT }
    ];

    for (const chk of initialChecks) {
      await prisma.verificationCheck.create({
        data: {
          applicationId: application.id,
          checkType: chk.checkType,
          sourceSystem: chk.sourceSystem,
          status: VerificationStatus.PENDING,
          confidenceScore: 0.0
        }
      });
    }

    await logAudit(req.user?.userId || 'SYSTEM', 'SUBMIT_APPLICATION', 'Application', application.id, req);

    return res.status(201).json({
      message: 'Application submitted successfully! Multi-agency background verification triggered.',
      application
    });
  } catch (error: any) {
    console.error('Create application error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getApplicationVerifications(req: Request, res: Response) {
  try {
    const applicationId = req.params.id;

    const verifications = await prisma.verificationCheck.findMany({
      where: { applicationId },
      include: {
        manualReview: true
      },
      orderBy: { checkedAt: 'asc' }
    });

    return res.json({ applicationId, verifications });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function triggerVerificationCheck(req: Request, res: Response) {
  try {
    const verificationId = req.params.id;

    const check = await prisma.verificationCheck.findUnique({
      where: { id: verificationId },
      include: { application: true }
    });

    if (!check) {
      return res.status(404).json({ error: 'Verification check not found' });
    }

    // Call Python FastAPI Verification Orchestrator
    const result = await callVerificationOrchestrator(
      check.application.studentId,
      check.applicationId,
      check.checkType
    );

    let dbStatus: VerificationStatus = VerificationStatus.PENDING;
    if (result.status === 'verified') dbStatus = VerificationStatus.VERIFIED;
    if (result.status === 'mismatch') dbStatus = VerificationStatus.MISMATCH;

    const updatedCheck = await prisma.verificationCheck.update({
      where: { id: verificationId },
      data: {
        status: dbStatus,
        confidenceScore: result.confidence,
        rawResponseRef: JSON.stringify(result.details),
        checkedAt: new Date()
      }
    });

    // If MISMATCH returned, automatically route to ManualReviewQueue!
    if (result.status === 'mismatch') {
      const existingQueue = await prisma.manualReviewQueue.findUnique({
        where: { verificationCheckId: verificationId }
      });

      if (!existingQueue) {
        await prisma.manualReviewQueue.create({
          data: {
            verificationCheckId: verificationId,
            status: 'PENDING',
            notes: `Automated ${check.checkType} mismatch detected by source system adapter (${check.sourceSystem}). Confidence score: ${result.confidence}`
          }
        });
      }
    }

    await logAudit(req.user?.userId || 'SYSTEM', 'TRIGGER_VERIFICATION', 'VerificationCheck', verificationId, req);

    return res.json({
      message: 'Verification check updated',
      verification: updatedCheck,
      details: result.details
    });
  } catch (error: any) {
    console.error('Trigger verification error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
