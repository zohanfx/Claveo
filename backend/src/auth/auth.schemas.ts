import { z } from 'zod';

export const registerSchema = z.object({
  body: z.object({
    email: z
      .string({ required_error: 'El email es requerido' })
      .email('Formato de email inválido')
      .min(3, 'Email muy corto')
      .max(255, 'Email muy largo')
      .transform((v) => v.toLowerCase().trim()),
    authPassword: z
      .string({ required_error: 'La contraseña de autenticación es requerida' })
      .min(32, 'Contraseña de autenticación demasiado corta')
      .max(1024, 'Contraseña de autenticación demasiado larga'),
    kdfSalt: z
      .string({ required_error: 'El salt KDF es requerido' })
      .min(16, 'Salt demasiado corto')
      .max(256, 'Salt demasiado largo'),
  }),
});

export const loginSchema = z.object({
  body: z.object({
    email: z
      .string({ required_error: 'El email es requerido' })
      .email('Formato de email inválido')
      .transform((v) => v.toLowerCase().trim()),
    authPassword: z
      .string({ required_error: 'La contraseña es requerida' })
      .min(1, 'La contraseña no puede estar vacía'),
  }),
});

export const refreshSchema = z.object({
  body: z.object({
    refreshToken: z
      .string({ required_error: 'El refresh token es requerido' })
      .min(1, 'Refresh token requerido'),
  }),
});

export const logoutSchema = z.object({
  body: z.object({
    refreshToken: z.string().optional(),
  }),
});

export const saltQuerySchema = z.object({
  query: z.object({
    email: z
      .string({ required_error: 'El email es requerido' })
      .email('Formato de email inválido')
      .transform((v) => v.toLowerCase().trim()),
  }),
});

export type RegisterInput = z.infer<typeof registerSchema>['body'];
export type LoginInput = z.infer<typeof loginSchema>['body'];
export type RefreshInput = z.infer<typeof refreshSchema>['body'];
