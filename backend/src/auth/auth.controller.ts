import { Request, Response, NextFunction } from 'express';
import { authService } from './auth.service';
import { AuthenticatedRequest } from '../types';
import { AppError } from '../middleware/error.middleware';

export class AuthController {
  async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await authService.register(req.body as Parameters<typeof authService.register>[0]);
      res.status(201).json({
        success: true,
        data: result,
        message: 'Cuenta creada exitosamente',
      });
    } catch (error) {
      next(error);
    }
  }

  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await authService.login(req.body as Parameters<typeof authService.login>[0]);
      res.json({
        success: true,
        data: result,
        message: 'Sesión iniciada exitosamente',
      });
    } catch (error) {
      next(error);
    }
  }

  async refresh(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const tokens = await authService.refresh(req.body as Parameters<typeof authService.refresh>[0]);
      res.json({
        success: true,
        data: tokens,
      });
    } catch (error) {
      next(error);
    }
  }

  async logout(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.userId) {
        throw new AppError('No autorizado', 401, 'UNAUTHORIZED');
      }
      const { refreshToken } = req.body as { refreshToken?: string };
      await authService.logout(refreshToken, req.userId);
      res.json({
        success: true,
        message: 'Sesión cerrada exitosamente',
      });
    } catch (error) {
      next(error);
    }
  }

  async getSalt(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const email = (req.query.email as string).toLowerCase().trim();
      const salt = await authService.getSalt(email);
      res.json({
        success: true,
        data: { salt },
      });
    } catch (error) {
      next(error);
    }
  }
}

export const authController = new AuthController();
