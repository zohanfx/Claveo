import { z } from 'zod';

export const createVaultEntrySchema = z.object({
  body: z.object({
    encryptedData: z
      .string({ required_error: 'Los datos cifrados son requeridos' })
      .min(1, 'Los datos cifrados no pueden estar vacíos'),
    iv: z
      .string({ required_error: 'El IV es requerido' })
      .min(1, 'El IV no puede estar vacío'),
    mac: z
      .string({ required_error: 'El MAC es requerido' })
      .min(1, 'El MAC no puede estar vacío'),
  }),
});

export const updateVaultEntrySchema = z.object({
  body: z.object({
    encryptedData: z
      .string({ required_error: 'Los datos cifrados son requeridos' })
      .min(1, 'Los datos cifrados no pueden estar vacíos'),
    iv: z
      .string({ required_error: 'El IV es requerido' })
      .min(1, 'El IV no puede estar vacío'),
    mac: z
      .string({ required_error: 'El MAC es requerido' })
      .min(1, 'El MAC no puede estar vacío'),
  }),
  params: z.object({
    id: z.string({ required_error: 'El ID es requerido' }).uuid('ID de formato inválido'),
  }),
});

export const deleteVaultEntrySchema = z.object({
  params: z.object({
    id: z.string({ required_error: 'El ID es requerido' }).uuid('ID de formato inválido'),
  }),
});

export type CreateVaultEntryInput = z.infer<typeof createVaultEntrySchema>['body'];
export type UpdateVaultEntryInput = z.infer<typeof updateVaultEntrySchema>['body'];
