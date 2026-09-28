import { PrismaClient } from '@prisma/client';
import { Request } from 'express';

const prisma = new PrismaClient();

export async function logAudit(
  actorId: string,
  action: string,
  entityType: string,
  entityId: string,
  req: Request
) {
  try {
    const ipAddress = (req.headers['x-forwarded-for'] as string) || req.ip || '127.0.0.1';
    await prisma.auditLog.create({
      data: {
        actorId,
        action,
        entityType,
        entityId,
        ipAddress,
      }
    });
  } catch (error) {
    console.error('Audit Logging Error:', error);
  }
}
