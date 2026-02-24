import { prisma } from '../prisma/client';
import { AppError } from '../middleware/error.middleware';
import { CreateVaultEntryInput, UpdateVaultEntryInput } from './vault.schemas';
import { VaultEntryPublic } from '../types';
import { logger } from '../utils/logger';

const VAULT_ENTRY_SELECT = {
  id: true,
  encryptedData: true,
  iv: true,
  mac: true,
  createdAt: true,
  updatedAt: true,
} as const;

export class VaultService {
  async getAll(userId: string): Promise<VaultEntryPublic[]> {
    return prisma.vaultEntry.findMany({
      where: { userId },
      select: VAULT_ENTRY_SELECT,
      orderBy: { updatedAt: 'desc' },
    });
  }

  async create(userId: string, input: CreateVaultEntryInput): Promise<VaultEntryPublic> {
    const entry = await prisma.vaultEntry.create({
      data: {
        userId,
        encryptedData: input.encryptedData,
        iv: input.iv,
        mac: input.mac,
      },
      select: VAULT_ENTRY_SELECT,
    });

    logger.info('Entrada de vault creada', { userId, entryId: entry.id });
    return entry;
  }

  async update(
    userId: string,
    entryId: string,
    input: UpdateVaultEntryInput,
  ): Promise<VaultEntryPublic> {
    const existing = await prisma.vaultEntry.findFirst({
      where: { id: entryId, userId },
      select: { id: true },
    });

    if (!existing) {
      throw new AppError('Entrada no encontrada', 404, 'ENTRY_NOT_FOUND');
    }

    const entry = await prisma.vaultEntry.update({
      where: { id: entryId },
      data: {
        encryptedData: input.encryptedData,
        iv: input.iv,
        mac: input.mac,
      },
      select: VAULT_ENTRY_SELECT,
    });

    logger.info('Entrada de vault actualizada', { userId, entryId });
    return entry;
  }

  async delete(userId: string, entryId: string): Promise<void> {
    const existing = await prisma.vaultEntry.findFirst({
      where: { id: entryId, userId },
      select: { id: true },
    });

    if (!existing) {
      throw new AppError('Entrada no encontrada', 404, 'ENTRY_NOT_FOUND');
    }

    await prisma.vaultEntry.delete({ where: { id: entryId } });
    logger.info('Entrada de vault eliminada', { userId, entryId });
  }
}

export const vaultService = new VaultService();
