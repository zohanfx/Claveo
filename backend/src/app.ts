import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import { errorMiddleware } from './middleware/error.middleware';
import authRoutes from './auth/auth.routes';
import vaultRoutes from './vault/vault.routes';
import { logger } from './utils/logger';

export function createApp(): express.Application {
  const app = express();

  // Trust proxy (for rate limiting behind nginx/docker)
  app.set('trust proxy', 1);

  // Security headers
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          scriptSrc: ["'self'"],
          styleSrc: ["'self'"],
          imgSrc: ["'self'", 'data:'],
        },
      },
      hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true,
      },
    }),
  );

  // CORS
  const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',').map((o) => o.trim()) ?? [
    'http://localhost:3000',
  ];

  app.use(
    cors({
      origin: (origin, callback) => {
        if (!origin || allowedOrigins.includes(origin)) {
          callback(null, true);
        } else {
          callback(new Error('No permitido por CORS'));
        }
      },
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      credentials: true,
    }),
  );

  // Global rate limiting
  app.use(
    rateLimit({
      windowMs: 15 * 60 * 1000,
      max: 300,
      standardHeaders: true,
      legacyHeaders: false,
      message: { success: false, message: 'Demasiadas solicitudes, intenta más tarde' },
    }),
  );

  // Body parsing
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // Request logging
  app.use((req, _res, next) => {
    logger.debug(`→ ${req.method} ${req.path}`, {
      ip: req.ip,
      ua: req.get('User-Agent')?.substring(0, 80),
    });
    next();
  });

  // Health check
  app.get('/health', (_req, res) => {
    res.json({
      status: 'ok',
      service: 'claveo-backend',
      timestamp: new Date().toISOString(),
    });
  });

  // API Routes
  app.use('/auth', authRoutes);
  app.use('/vault', vaultRoutes);

  // 404
  app.use((_req, res) => {
    res.status(404).json({ success: false, message: 'Ruta no encontrada' });
  });

  // Error handler (must be last)
  app.use(errorMiddleware);

  return app;
}
