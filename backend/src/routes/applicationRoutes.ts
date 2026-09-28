import { Router } from 'express';
import {
  getStudentApplications,
  createApplication,
  getApplicationVerifications,
  triggerVerificationCheck
} from '../controllers/applicationController';
import { authenticateToken } from '../middleware/authMiddleware';

const router = Router();

router.use(authenticateToken);

router.get('/student/:id', getStudentApplications);
router.post('/', createApplication);
router.get('/:id/verifications', getApplicationVerifications);
router.post('/verifications/:id/trigger', triggerVerificationCheck);

export default router;
