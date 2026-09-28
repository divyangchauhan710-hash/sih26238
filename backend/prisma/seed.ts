import { PrismaClient, Role, ApplicationStatus, CheckType, SourceSystem, VerificationStatus, DisbursementStatus } from '@prisma/client';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';

const prisma = new PrismaClient();

function encrypt(text: string): string {
  const ALGORITHM = 'aes-256-gcm';
  const SECRET_KEY = Buffer.from(
    process.env.ENCRYPTION_KEY || '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    'hex'
  );
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv(ALGORITHM, SECRET_KEY, iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  const authTag = cipher.getAuthTag().toString('hex');
  return `${iv.toString('hex')}:${authTag}:${encrypted}`;
}

async function main() {
  console.log('🌱 Clearing existing database records...');
  await prisma.manualReviewQueue.deleteMany({});
  await prisma.verificationCheck.deleteMany({});
  await prisma.disbursement.deleteMany({});
  await prisma.sanction.deleteMany({});
  await prisma.document.deleteMany({});
  await prisma.application.deleteMany({});
  await prisma.scheme.deleteMany({});
  await prisma.student.deleteMany({});
  await prisma.user.deleteMany({});
  await prisma.auditLog.deleteMany({});

  console.log('🌱 Seeding Schemes...');
  const schemesData = [
    {
      name: 'Pre-Matric Scholarship for ST Students',
      code: 'PRE_MATRIC',
      description: 'Financial assistance for Scheduled Tribe students studying in classes IX and X.',
      maxAmount: 4000.0,
      eligibilityJson: JSON.stringify({
        minClass: 9,
        maxClass: 10,
        maxIncome: 250000,
        category: 'ST',
        stateList: ['ALL']
      })
    },
    {
      name: 'Post-Matric Scholarship for ST Students',
      code: 'POST_MATRIC',
      description: 'Support for post-secondary education including degree, diploma, and post-graduate courses.',
      maxAmount: 25000.0,
      eligibilityJson: JSON.stringify({
        minClass: 11,
        maxIncome: 250000,
        category: 'ST',
        stateList: ['ALL']
      })
    },
    {
      name: 'Top Class Education Scheme for ST Students',
      code: 'TOP_CLASS',
      description: 'Scholarship for pursuing full-time studies in notified top institutions (IITs, NITs, IIMs, AIIMS).',
      maxAmount: 200000.0,
      eligibilityJson: JSON.stringify({
        institutionList: ['IIT', 'NIT', 'IIM', 'AIIMS'],
        maxIncome: 600000,
        category: 'ST'
      })
    },
    {
      name: 'National Fellowship for ST Students (NFST)',
      code: 'NFST',
      description: 'Financial assistance to ST students pursuing M.Phil and Ph.D. degrees in Indian universities.',
      maxAmount: 31000.0, // per month stipend
      eligibilityJson: JSON.stringify({
        degree: ['M.Phil', 'Ph.D.'],
        netOrJrfRequired: true,
        category: 'ST'
      })
    },
    {
      name: 'National Overseas Scholarship for ST Students (NOS)',
      code: 'NOS',
      description: 'Financial support for pursuing Master’s, Ph.D., and Post-Doctoral research abroad.',
      maxAmount: 1500000.0,
      eligibilityJson: JSON.stringify({
        studyLocation: 'ABROAD',
        maxIncome: 600000,
        minMarksPercentage: 55,
        category: 'ST'
      })
    }
  ];

  const schemes = [];
  for (const s of schemesData) {
    const scheme = await prisma.scheme.create({ data: s });
    schemes.push(scheme);
  }

  console.log('🌱 Seeding Users & Students...');
  const passwordHash = await bcrypt.hash('Password@123', 10);

  // Admin User
  const adminUser = await prisma.user.create({
    data: {
      email: 'admin@ekvidya.gov.in',
      password: passwordHash,
      role: Role.ADMIN
    }
  });

  // Verifier User
  const verifierUser = await prisma.user.create({
    data: {
      email: 'verifier.jharkhand@ekvidya.gov.in',
      password: passwordHash,
      role: Role.VERIFIER
    }
  });

  // Student 1: Ramesh Munda (Fully Verified & Disbursed)
  const user1 = await prisma.user.create({
    data: {
      email: 'ramesh.munda@example.com',
      password: passwordHash,
      role: Role.STUDENT
    }
  });

  const student1 = await prisma.student.create({
    data: {
      userId: user1.id,
      name: 'Ramesh Munda',
      dob: '2002-05-14',
      gender: 'Male',
      aadhaarHash: encrypt('987654321098'),
      stCertificateRef: 'ST/JH/RNC/2021/88421',
      phone: '9876543210',
      email: 'ramesh.munda@example.com',
      state: 'Jharkhand',
      district: 'Ranchi',
      bankAccountRef: encrypt('SBI-309485710293')
    }
  });

  // Student 2: Sunita Marandi (Income mismatch -> Sitting in Manual Review)
  const user2 = await prisma.user.create({
    data: {
      email: 'sunita.marandi@example.com',
      password: passwordHash,
      role: Role.STUDENT
    }
  });

  const student2 = await prisma.student.create({
    data: {
      userId: user2.id,
      name: 'Sunita Marandi',
      dob: '2001-11-20',
      gender: 'Female',
      aadhaarHash: encrypt('876543210987'),
      stCertificateRef: 'ST/JH/DUM/2022/44102',
      phone: '9876543211',
      email: 'sunita.marandi@example.com',
      state: 'Jharkhand',
      district: 'Dumka',
      bankAccountRef: encrypt('PNB-902341850123')
    }
  });

  // Student 3: Birsa Oraon (Under Verification / Mid-verification)
  const user3 = await prisma.user.create({
    data: {
      email: 'birsa.oraon@example.com',
      password: passwordHash,
      role: Role.STUDENT
    }
  });

  const student3 = await prisma.student.create({
    data: {
      userId: user3.id,
      name: 'Birsa Oraon',
      dob: '2006-08-10',
      gender: 'Male',
      aadhaarHash: encrypt('765432109876'),
      stCertificateRef: 'ST/JH/GUM/2023/11094',
      phone: '9876543212',
      email: 'birsa.oraon@example.com',
      state: 'Jharkhand',
      district: 'Gumla',
      bankAccountRef: encrypt('BOI-771234905812')
    }
  });

  console.log('🌱 Seeding Applications & Verifications...');

  // --- APP 1: Ramesh Munda -> Post-Matric Scholarship (DISBURSED) ---
  const postMatricScheme = schemes.find(s => s.code === 'POST_MATRIC')!;
  const app1 = await prisma.application.create({
    data: {
      studentId: student1.id,
      schemeId: postMatricScheme.id,
      status: ApplicationStatus.DISBURSED,
      academicYear: '2025-2026',
      submittedAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    }
  });

  // Verification checks for App 1
  await prisma.verificationCheck.create({
    data: {
      applicationId: app1.id,
      checkType: CheckType.IDENTITY,
      sourceSystem: SourceSystem.UIDAI,
      status: VerificationStatus.VERIFIED,
      confidenceScore: 0.98,
      rawResponseRef: 'UIDAI_RESP_99841'
    }
  });
  await prisma.verificationCheck.create({
    data: {
      applicationId: app1.id,
      checkType: CheckType.ST_CERTIFICATE,
      sourceSystem: SourceSystem.DIGILOCKER,
      status: VerificationStatus.VERIFIED,
      confidenceScore: 0.96,
      rawResponseRef: 'DIGILOCKER_CERT_88421'
    }
  });
  await prisma.verificationCheck.create({
    data: {
      applicationId: app1.id,
      checkType: CheckType.INSTITUTION,
      sourceSystem: SourceSystem.AISHE,
      status: VerificationStatus.VERIFIED,
      confidenceScore: 0.95,
      rawResponseRef: 'AISHE_RESP_4421'
    }
  });
  await prisma.verificationCheck.create({
    data: {
      applicationId: app1.id,
      checkType: CheckType.INCOME,
      sourceSystem: SourceSystem.E_DISTRICT,
      status: VerificationStatus.VERIFIED,
      confidenceScore: 0.94,
      rawResponseRef: 'EDIST_INC_7741'
    }
  });

  // Sanction & Disbursement for App 1
  const sanction1 = await prisma.sanction.create({
    data: {
      applicationId: app1.id,
      amount: 25000.0,
      sanctioningAuthority: 'Ministry of Tribal Affairs - Direct Benefit Transfer Cell',
      sanctionedAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000)
    }
  });

  await prisma.disbursement.create({
    data: {
      sanctionId: sanction1.id,
      amount: 25000.0,
      dbtTransactionRef: 'DBT/ST/2026/099182743',
      status: DisbursementStatus.SUCCESS,
      disbursedAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000)
    }
  });

  // --- APP 2: Sunita Marandi -> NFST (UNDER_VERIFICATION with Manual Review Queue) ---
  const nfstScheme = schemes.find(s => s.code === 'NFST')!;
  const app2 = await prisma.application.create({
    data: {
      studentId: student2.id,
      schemeId: nfstScheme.id,
      status: ApplicationStatus.UNDER_VERIFICATION,
      academicYear: '2025-2026',
      submittedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    }
  });

  const check1 = await prisma.verificationCheck.create({
    data: {
      applicationId: app2.id,
      checkType: CheckType.IDENTITY,
      sourceSystem: SourceSystem.DIGILOCKER,
      status: VerificationStatus.VERIFIED,
      confidenceScore: 0.97,
      rawResponseRef: 'DIGILOCKER_ID_55102'
    }
  });

  const check2Mismatch = await prisma.verificationCheck.create({
    data: {
      applicationId: app2.id,
      checkType: CheckType.INCOME,
      sourceSystem: SourceSystem.E_DISTRICT,
      status: VerificationStatus.MISMATCH,
      confidenceScore: 0.62,
      rawResponseRef: 'EDIST_INC_MISMATCH_9941'
    }
  });

  // Route mismatch to ManualReviewQueue
  await prisma.manualReviewQueue.create({
    data: {
      verificationCheckId: check2Mismatch.id,
      assignedTo: verifierUser.id,
      status: 'PENDING',
      notes: 'Income certificate declared ₹1.8 Lakhs/yr, but e-District API returned ₹3.1 Lakhs/yr. Manual verification of physical document needed.'
    }
  });

  // --- APP 3: Birsa Oraon -> Pre-Matric Scholarship (UNDER_VERIFICATION mid-process) ---
  const preMatricScheme = schemes.find(s => s.code === 'PRE_MATRIC')!;
  const app3 = await prisma.application.create({
    data: {
      studentId: student3.id,
      schemeId: preMatricScheme.id,
      status: ApplicationStatus.UNDER_VERIFICATION,
      academicYear: '2025-2026',
      submittedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
    }
  });

  await prisma.verificationCheck.create({
    data: {
      applicationId: app3.id,
      checkType: CheckType.ST_CERTIFICATE,
      sourceSystem: SourceSystem.DIGILOCKER,
      status: VerificationStatus.VERIFIED,
      confidenceScore: 0.99,
      rawResponseRef: 'DIGILOCKER_ST_11094'
    }
  });

  await prisma.verificationCheck.create({
    data: {
      applicationId: app3.id,
      checkType: CheckType.INSTITUTION,
      sourceSystem: SourceSystem.UDISE,
      status: VerificationStatus.PENDING,
      confidenceScore: 0.0,
      rawResponseRef: null
    }
  });

  console.log('🌱 Seeding Documents (Demonstrating Reuse)...');
  const doc1 = await prisma.document.create({
    data: {
      studentId: student1.id,
      docType: 'ST_CERTIFICATE',
      digilockerUri: 'digilocker://in.gov.jharkhand/st_certificate/88421',
      reusedFromApplicationId: app1.id
    }
  });

  await prisma.document.create({
    data: {
      studentId: student1.id,
      docType: 'INCOME_CERTIFICATE',
      digilockerUri: 'digilocker://in.gov.jharkhand/income/99421',
      reusedFromApplicationId: app1.id
    }
  });

  await prisma.document.create({
    data: {
      studentId: student2.id,
      docType: 'ST_CERTIFICATE',
      digilockerUri: 'digilocker://in.gov.jharkhand/st_certificate/44102',
      reusedFromApplicationId: app2.id
    }
  });

  console.log('🌱 Seeding Initial Audit Logs...');
  await prisma.auditLog.create({
    data: {
      actorId: student1.id,
      action: 'APPLICATION_SUBMITTED',
      entityType: 'Application',
      entityId: app1.id,
      ipAddress: '127.0.0.1'
    }
  });

  await prisma.auditLog.create({
    data: {
      actorId: verifierUser.id,
      action: 'MANUAL_REVIEW_FLAGGED',
      entityType: 'ManualReviewQueue',
      entityId: check2Mismatch.id,
      ipAddress: '10.0.0.42'
    }
  });

  console.log('✅ EkVidya Seed Completed Successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed: Unable to connect to PostgreSQL database.');
    console.error('👉 Please make sure PostgreSQL is running on localhost:5432 or execute `docker-compose up -d postgres`.');
    console.error('Detailed Error:', e.message || e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
