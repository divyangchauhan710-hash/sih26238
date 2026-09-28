import { Router } from 'express';
import { getStudentDocuments, uploadDocument } from '../controllers/documentController';
import { authenticateToken } from '../middleware/authMiddleware';

const router = Router();

router.use(authenticateToken);

router.get('/student/:id', getStudentDocuments);
router.post('/', uploadDocument);

export default router;
