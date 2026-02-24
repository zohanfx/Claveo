import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { authController } from './auth.controller';
import { authenticate } from '../middleware/auth.middleware';
import { validate } from '../middleware/validation.middleware';
import {
  registerSchema,
  loginSchema,
  refreshSchema,
  logoutSchema,
  saltQuerySchema,
} from './auth.schemas';

const router = Router();

// Strict rate limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Demasiados intentos de autenticación. Intenta de nuevo en 15 minutos.',
    code: 'RATE_LIMIT_EXCEEDED',
  },
  skipSuccessfulRequests: false,
});

// Salt endpoint (slightly more lenient)
const saltLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
});

router.get('/salt', saltLimiter, validate(saltQuerySchema), (req, res, next) =>
  authController.getSalt(req, res, next),
);

router.post('/register', authLimiter, validate(registerSchema), (req, res, next) =>
  authController.register(req, res, next),
);

router.post('/login', authLimiter, validate(loginSchema), (req, res, next) =>
  authController.login(req, res, next),
);

router.post('/refresh', validate(refreshSchema), (req, res, next) =>
  authController.refresh(req, res, next),
);

router.post('/logout', authenticate, validate(logoutSchema), (req, res, next) =>
  authController.logout(req as Parameters<typeof authController.logout>[0], res, next),
);

export default router;
