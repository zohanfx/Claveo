import { Router } from 'express';
import { vaultController } from './vault.controller';
import { authenticate } from '../middleware/auth.middleware';
import { validate } from '../middleware/validation.middleware';
import {
  createVaultEntrySchema,
  updateVaultEntrySchema,
  deleteVaultEntrySchema,
} from './vault.schemas';
import { AuthenticatedRequest } from '../types';

const router = Router();

// All vault routes require authentication
router.use(authenticate);

router.get('/', (req, res, next) =>
  vaultController.getAll(req as AuthenticatedRequest, res, next),
);

router.post('/', validate(createVaultEntrySchema), (req, res, next) =>
  vaultController.create(req as AuthenticatedRequest, res, next),
);

router.put('/:id', validate(updateVaultEntrySchema), (req, res, next) =>
  vaultController.update(req as AuthenticatedRequest, res, next),
);

router.delete('/:id', validate(deleteVaultEntrySchema), (req, res, next) =>
  vaultController.delete(req as AuthenticatedRequest, res, next),
);

export default router;
