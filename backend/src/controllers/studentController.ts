import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { decryptField } from '../utils/crypto';
import { logAudit } from '../utils/auditLogger';

const prisma = new PrismaClient();

export async function getStudentDashboard(req: Request, res: Response) {
  try {
    const studentId = req.params.id;

    // Verify ownership or admin/verifier role
    if (req.user?.role === 'STUDENT' && req.user.studentId !== studentId) {
      return res.status(403).json({ error: 'Access denied to other student profiles' });
    }

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

    if (!student) {
      return res.status(404).json({ error: 'Student not found' });
    }

    // Write AuditLog row for accessing sensitive student financial/identity profile
    await logAudit(req.user?.userId || 'SYSTEM', 'VIEW_STUDENT_DASHBOARD_SENSITIVE', 'Student', studentId, req);

    // Fetch all 5 schemes for comprehensive coverage
    const allSchemes = await prisma.scheme.findMany();

    // Compute aggregation summary across schemes
    let totalDisbursedAmount = 0;
    let totalSanctionedAmount = 0;
    let pendingVerificationCount = 0;
    let activeApplicationCount = 0;

    const schemeOverview = allSchemes.map(scheme => {
      const app = student.applications.find(a => a.schemeId === scheme.id);
      
      if (app) {
        if (app.status === 'UNDER_VERIFICATION' || app.status === 'SUBMITTED') {
          activeApplicationCount++;
        }

        app.verifications.forEach(v => {
          if (v.status === 'PENDING' || v.status === 'MANUAL_REVIEW') {
            pendingVerificationCount++;
          }
        });

        app.sanctions.forEach(s => {
          totalSanctionedAmount += s.amount;
          s.disbursements.forEach(d => {
            if (d.status === 'SUCCESS') {
              totalDisbursedAmount += d.amount;
            }
          });
        });
      }

      return {
        schemeId: scheme.id,
        schemeName: scheme.name,
        schemeCode: scheme.code,
        maxAmount: scheme.maxAmount,
        hasApplied: !!app,
        applicationId: app?.id || null,
        status: app?.status || 'NOT_APPLIED',
        submittedAt: app?.submittedAt || null,
        academicYear: app?.academicYear || '2025-2026'
      };
    });

    // Decrypt sensitive info for student view (Aadhaar & Bank)
    const decryptedAadhaar = decryptField(student.aadhaarHash);
    const decryptedBank = decryptField(student.bankAccountRef);

    return res.json({
      student: {
        id: student.id,
        name: student.name,
        dob: student.dob,
        gender: student.gender,
        phone: student.phone,
        email: student.email,
        state: student.state,
        district: student.district,
        stCertificateRef: student.stCertificateRef,
        aadhaarMasked: decryptedAadhaar.length >= 12 ? `XXXX-XXXX-${decryptedAadhaar.slice(-4)}` : decryptedAadhaar,
        bankAccountMasked: decryptedBank
      },
      summary: {
        totalDisbursedAmount,
        totalSanctionedAmount,
        pendingVerificationCount,
        activeApplicationCount,
        totalSchemesAvailable: allSchemes.length
      },
      schemes: schemeOverview,
      applications: student.applications,
      documentsCount: student.documents.length
    });
  } catch (error: any) {
    console.error('Get Dashboard error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getStudentProfile(req: Request, res: Response) {
  try {
    const studentId = req.params.id;

    if (req.user?.role === 'STUDENT' && req.user.studentId !== studentId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const student = await prisma.student.findUnique({ where: { id: studentId } });
    if (!student) {
      return res.status(404).json({ error: 'Student not found' });
    }

    await logAudit(req.user?.userId || 'SYSTEM', 'VIEW_STUDENT_PROFILE', 'Student', studentId, req);

    return res.json({
      ...student,
      aadhaarMasked: 'XXXX-XXXX-'.concat(decryptField(student.aadhaarHash).slice(-4)),
      bankAccountDecrypted: decryptField(student.bankAccountRef)
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
}
