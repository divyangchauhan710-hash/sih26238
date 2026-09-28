import { Router } from 'express';
import { getManualReviewQueue, resolveManualReviewItem } from '../controllers/adminController';
import { authenticateToken, authorizeRoles } from '../middleware/authMiddleware';
import { Role } from '@prisma/client';

const router = Router();

router.use(authenticateToken);
router.use(authorizeRoles(Role.ADMIN, Role.VERIFIER));

router.get('/manual-review-queue', getManualReviewQueue);
router.patch('/manual-review-queue/:id', resolveManualReviewItem);

export default router;
