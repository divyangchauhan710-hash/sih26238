import { Request, Response } from 'express';
import { PrismaClient, Role } from '@prisma/client';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { encryptField } from '../utils/crypto';
import { logAudit } from '../utils/auditLogger';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'ekvidya_sih26238_jwt_secret_key_super_secure_123';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'ekvidya_sih26238_refresh_secret_key_456';

const RegisterSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  name: z.string().min(2),
  dob: z.string(),
  gender: z.string(),
  aadhaarNumber: z.string().length(12),
  stCertificateRef: z.string(),
  phone: z.string().length(10),
  state: z.string(),
  district: z.string(),
  bankAccountNumber: z.string()
});

const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string()
});

export async function registerStudent(req: Request, res: Response) {
  try {
    const parseResult = RegisterSchema.safeParse(req.body);
    if (!parseResult.success) {
      return res.status(400).json({ error: 'Validation error', details: parseResult.error.errors });
    }

    const { email, password, name, dob, gender, aadhaarNumber, stCertificateRef, phone, state, district, bankAccountNumber } = parseResult.data;

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ error: 'User with this email already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const aadhaarHash = encryptField(aadhaarNumber);
    const bankAccountRef = encryptField(bankAccountNumber);

    const user = await prisma.user.create({
      data: {
        email,
        password: passwordHash,
        role: Role.STUDENT,
        student: {
          create: {
            name,
            dob,
            gender,
            aadhaarHash,
            stCertificateRef,
            phone,
            email,
            state,
            district,
            bankAccountRef
          }
        }
      },
      include: {
        student: true
      }
    });

    await logAudit(user.id, 'STUDENT_REGISTERED', 'Student', user.student!.id, req);

    const accessToken = jwt.sign(
      { userId: user.id, studentId: user.student!.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '15m' }
    );

    const refreshToken = jwt.sign(
      { userId: user.id },
      JWT_REFRESH_SECRET,
      { expiresIn: '7d' }
    );

    return res.status(201).json({
      message: 'Student registered successfully',
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        studentId: user.student!.id,
        name: user.student!.name
      },
      accessToken,
      refreshToken
    });
  } catch (error: any) {
    console.error('Register error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function loginUser(req: Request, res: Response) {
  try {
    const parseResult = LoginSchema.safeParse(req.body);
    if (!parseResult.success) {
      return res.status(400).json({ error: 'Validation error', details: parseResult.error.errors });
    }

    const { email, password } = parseResult.data;
    const user = await prisma.user.findUnique({
      where: { email },
      include: { student: true }
    });

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const studentId = user.student ? user.student.id : undefined;

    const accessToken = jwt.sign(
      { userId: user.id, studentId, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '15m' }
    );

    const refreshToken = jwt.sign(
      { userId: user.id },
      JWT_REFRESH_SECRET,
      { expiresIn: '7d' }
    );

    await logAudit(user.id, 'USER_LOGGED_IN', 'User', user.id, req);

    return res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        studentId,
        name: user.student ? user.student.name : 'Administrator'
      },
      accessToken,
      refreshToken
    });
  } catch (error: any) {
    console.error('Login error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function refreshToken(req: Request, res: Response) {
  const { refreshToken } = req.body;
  if (!refreshToken) {
    return res.status(400).json({ error: 'Refresh token required' });
  }

  try {
    const decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET) as { userId: string };
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      include: { student: true }
    });

    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }

    const accessToken = jwt.sign(
      { userId: user.id, studentId: user.student?.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '15m' }
    );

    return res.json({ accessToken });
  } catch (error) {
    return res.status(403).json({ error: 'Invalid or expired refresh token' });
  }
}

export async function logoutUser(req: Request, res: Response) {
  if (req.user) {
    await logAudit(req.user.userId, 'USER_LOGGED_OUT', 'User', req.user.userId, req);
  }
  return res.json({ message: 'Logged out successfully' });
}
