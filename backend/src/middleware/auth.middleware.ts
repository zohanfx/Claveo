import { Response, NextFunction } from 'express';
import { verifyAccessToken } from '../utils/jwt';
import { AuthenticatedRequest } from '../types';
import { AppError } from './error.middleware';

export function authenticate(
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction,
): void {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader?.startsWith('Bearer ')) {
      throw new AppError('Token de autenticación requerido', 401, 'AUTH_REQUIRED');
    }

    const token = authHeader.substring(7);

    if (!token || token.trim() === '') {
      throw new AppError('Token de autenticación inválido', 401, 'INVALID_TOKEN');
    }

    const payload = verifyAccessToken(token);

    if (payload.type !== 'access') {
      throw new AppError('Tipo de token inválido', 401, 'INVALID_TOKEN_TYPE');
    }

    req.userId = payload.userId;
    req.userEmail = payload.email;

    next();
  } catch (error) {
    next(error);
  }
}
