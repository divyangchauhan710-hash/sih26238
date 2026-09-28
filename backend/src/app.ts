import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { apiRateLimiter } from './middleware/rateLimiter';
import authRoutes from './routes/authRoutes';
import studentRoutes from './routes/studentRoutes';
import applicationRoutes from './routes/applicationRoutes';
import documentRoutes from './routes/documentRoutes';
import adminRoutes from './routes/adminRoutes';
import chatbotRoutes from './routes/chatbotRoutes';

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());
app.use(apiRateLimiter);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'EkVidya Node/Express API Gateway',
    timestamp: new Date().toISOString()
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/applications', applicationRoutes);
app.use('/api/documents', documentRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/chatbot', chatbotRoutes);

export default app;
