import { Router } from 'express';
import { getStudentDashboard, getStudentProfile } from '../controllers/studentController';
import { authenticateToken } from '../middleware/authMiddleware';

const router = Router();

router.use(authenticateToken);

router.get('/:id/dashboard', getStudentDashboard);
router.get('/:id/profile', getStudentProfile);

export default router;
