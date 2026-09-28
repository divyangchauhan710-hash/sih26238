import { Request, Response } from 'express';
import { PrismaClient, VerificationStatus, ApplicationStatus } from '@prisma/client';
import { z } from 'zod';
import { logAudit } from '../utils/auditLogger';

const prisma = new PrismaClient();

const ResolveQueueSchema = z.object({
  status: z.enum(['APPROVED', 'REJECTED']),
  notes: z.string().min(2)
});

export async function getManualReviewQueue(req: Request, res: Response) {
  try {
    const queueItems = await prisma.manualReviewQueue.findMany({
      include: {
        verificationCheck: {
          include: {
            application: {
              include: {
                student: true,
                scheme: true
              }
            }
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    await logAudit(req.user?.userId || 'ADMIN', 'VIEW_MANUAL_REVIEW_QUEUE', 'ManualReviewQueue', 'ALL', req);

    return res.json({ queue: queueItems });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function resolveManualReviewItem(req: Request, res: Response) {
  try {
    const queueId = req.params.id;
    const parseResult = ResolveQueueSchema.safeParse(req.body);
    if (!parseResult.success) {
      return res.status(400).json({ error: 'Validation error', details: parseResult.error.errors });
    }

    const { status, notes } = parseResult.data;

    const queueItem = await prisma.manualReviewQueue.findUnique({
      where: { id: queueId },
      include: { verificationCheck: true }
    });

    if (!queueItem) {
      return res.status(404).json({ error: 'Review queue item not found' });
    }

    // Update Queue Item
    const updatedQueue = await prisma.manualReviewQueue.update({
      where: { id: queueId },
      data: {
        status,
        notes: `${queueItem.notes ? queueItem.notes + ' | ' : ''}Verifier Decision (${status}): ${notes}`,
        assignedTo: req.user?.userId || 'VERIFIER_1'
      }
    });

    // Update Verification Check status
    const newVerificationStatus = status === 'APPROVED' ? VerificationStatus.VERIFIED : VerificationStatus.MISMATCH;
    await prisma.verificationCheck.update({
      where: { id: queueItem.verificationCheckId },
      data: {
        status: newVerificationStatus,
        confidenceScore: status === 'APPROVED' ? 1.0 : 0.0
      }
    });

    // Check if all verifications for this application are now resolved
    const allAppChecks = await prisma.verificationCheck.findMany({
      where: { applicationId: queueItem.verificationCheck.applicationId }
    });

    const isAllVerified = allAppChecks.every(c => c.status === VerificationStatus.VERIFIED);
    if (isAllVerified) {
      await prisma.application.update({
        where: { id: queueItem.verificationCheck.applicationId },
        data: { status: ApplicationStatus.SANCTIONED }
      });
    } else if (status === 'REJECTED') {
      await prisma.application.update({
        where: { id: queueItem.verificationCheck.applicationId },
        data: { status: ApplicationStatus.REJECTED }
      });
    }

    await logAudit(req.user?.userId || 'ADMIN', `RESOLVE_MANUAL_REVIEW_${status}`, 'ManualReviewQueue', queueId, req);

    return res.json({
      message: `Review decision logged successfully as ${status}`,
      queueItem: updatedQueue
    });
  } catch (error: any) {
    console.error('Resolve review error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
