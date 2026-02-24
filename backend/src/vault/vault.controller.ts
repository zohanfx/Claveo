import { Response, NextFunction } from 'express';
import { vaultService } from './vault.service';
import { AuthenticatedRequest } from '../types';
import { AppError } from '../middleware/error.middleware';

export class VaultController {
  async getAll(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.userId) throw new AppError('No autorizado', 401, 'UNAUTHORIZED');

      const entries = await vaultService.getAll(req.userId);
      res.json({
        success: true,
        data: entries,
      });
    } catch (error) {
      next(error);
    }
  }

  async create(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.userId) throw new AppError('No autorizado', 401, 'UNAUTHORIZED');

      const entry = await vaultService.create(
        req.userId,
        req.body as Parameters<typeof vaultService.create>[1],
      );
      res.status(201).json({
        success: true,
        data: entry,
        message: 'Entrada creada exitosamente',
      });
    } catch (error) {
      next(error);
    }
  }

  async update(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.userId) throw new AppError('No autorizado', 401, 'UNAUTHORIZED');

      const entry = await vaultService.update(
        req.userId,
        req.params.id,
        req.body as Parameters<typeof vaultService.update>[2],
      );
      res.json({
        success: true,
        data: entry,
        message: 'Entrada actualizada exitosamente',
      });
    } catch (error) {
      next(error);
    }
  }

  async delete(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.userId) throw new AppError('No autorizado', 401, 'UNAUTHORIZED');

      await vaultService.delete(req.userId, req.params.id);
      res.json({
        success: true,
        message: 'Entrada eliminada exitosamente',
      });
    } catch (error) {
      next(error);
    }
  }
}

export const vaultController = new VaultController();
