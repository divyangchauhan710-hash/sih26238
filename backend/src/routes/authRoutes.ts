import { Router } from 'express';
import { registerStudent, loginUser, refreshToken, logoutUser } from '../controllers/authController';
import { authRateLimiter } from '../middleware/rateLimiter';
import { authenticateToken } from '../middleware/authMiddleware';

const router = Router();

router.post('/register', authRateLimiter, registerStudent);
router.post('/login', authRateLimiter, loginUser);
router.post('/refresh', authRateLimiter, refreshToken);
router.post('/logout', authenticateToken, logoutUser);

export default router;
