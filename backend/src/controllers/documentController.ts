import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { z } from 'zod';
import { logAudit } from '../utils/auditLogger';

const prisma = new PrismaClient();

const CreateDocumentSchema = z.object({
  studentId: z.string().uuid(),
  docType: z.string(), // "ST_CERTIFICATE", "INCOME_CERT", "MARKSHEET", "ID_PROOF"
  digilockerUri: z.string(),
  reusedFromApplicationId: z.string().uuid().optional().nullable()
});

export async function getStudentDocuments(req: Request, res: Response) {
  try {
    const studentId = req.params.id;

    if (req.user?.role === 'STUDENT' && req.user.studentId !== studentId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const documents = await prisma.document.findMany({
      where: { studentId },
      include: {
        reusedFromApplication: {
          include: {
            scheme: true
          }
        }
      },
      orderBy: { uploadedAt: 'desc' }
    });

    await logAudit(req.user?.userId || 'SYSTEM', 'VIEW_DOCUMENT_WALLET', 'Student', studentId, req);

    return res.json({ documents });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function uploadDocument(req: Request, res: Response) {
  try {
    const parseResult = CreateDocumentSchema.safeParse(req.body);
    if (!parseResult.success) {
      return res.status(400).json({ error: 'Validation error', details: parseResult.error.errors });
    }

    const { studentId, docType, digilockerUri, reusedFromApplicationId } = parseResult.data;

    if (req.user?.role === 'STUDENT' && req.user.studentId !== studentId) {
      return res.status(403).json({ error: 'Cannot add document for another student' });
    }

    const document = await prisma.document.create({
      data: {
        studentId,
        docType,
        digilockerUri,
        reusedFromApplicationId: reusedFromApplicationId || null
      }
    });

    await logAudit(req.user?.userId || 'SYSTEM', 'UPLOAD_DOCUMENT', 'Document', document.id, req);

    return res.status(201).json({
      message: 'Document saved to wallet successfully',
      document
    });
  } catch (error: any) {
    console.error('Upload document error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
