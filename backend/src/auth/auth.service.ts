import bcrypt from 'bcrypt';
import { prisma } from '../prisma/client';
import {
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken,
  getRefreshExpiryDate,
} from '../utils/jwt';
import { AppError } from '../middleware/error.middleware';
import { RegisterInput, LoginInput, RefreshInput } from './auth.schemas';
import { UserTokens, UserPublic } from '../types';
import { logger } from '../utils/logger';

const BCRYPT_ROUNDS = 12;

export class AuthService {
  async register(
    input: RegisterInput,
  ): Promise<{ user: UserPublic; tokens: UserTokens }> {
    const existing = await prisma.user.findUnique({
      where: { email: input.email },
      select: { id: true },
    });

    if (existing) {
      throw new AppError('El email ya está registrado', 409, 'EMAIL_EXISTS');
    }

    const passwordHash = await bcrypt.hash(input.authPassword, BCRYPT_ROUNDS);

    const user = await prisma.user.create({
      data: {
        email: input.email,
        passwordHash,
        kdfSalt: input.kdfSalt,
      },
      select: { id: true, email: true },
    });

    const tokens = await this.issueTokens(user.id, user.email);
    logger.info('Usuario registrado', { userId: user.id });

    return { user, tokens };
  }

  async login(
    input: LoginInput,
  ): Promise<{ user: UserPublic & { kdfSalt: string }; tokens: UserTokens }> {
    const user = await prisma.user.findUnique({
      where: { email: input.email },
      select: { id: true, email: true, passwordHash: true, kdfSalt: true },
    });

    // Constant-time comparison to prevent timing attacks
    const dummyHash =
      '$2b$12$invalidhashforcomparison0000000000000000000000000000000';
    const hashToCompare = user?.passwordHash ?? dummyHash;
    const isValid = await bcrypt.compare(input.authPassword, hashToCompare);

    if (!user || !isValid) {
      throw new AppError('Credenciales inválidas', 401, 'INVALID_CREDENTIALS');
    }

    const tokens = await this.issueTokens(user.id, user.email);
    logger.info('Sesión iniciada', { userId: user.id });

    return {
      user: { id: user.id, email: user.email, kdfSalt: user.kdfSalt },
      tokens,
    };
  }

  async refresh(input: RefreshInput): Promise<UserTokens> {
    let payload;
    try {
      payload = verifyRefreshToken(input.refreshToken);
    } catch {
      throw new AppError('Refresh token inválido o expirado', 401, 'INVALID_REFRESH_TOKEN');
    }

    if (payload.type !== 'refresh') {
      throw new AppError('Tipo de token inválido', 401, 'INVALID_TOKEN_TYPE');
    }

    const storedToken = await prisma.refreshToken.findUnique({
      where: { token: input.refreshToken },
      select: { id: true, userId: true, expiresAt: true },
    });

    if (!storedToken || storedToken.userId !== payload.userId) {
      throw new AppError('Refresh token no encontrado', 401, 'REFRESH_TOKEN_NOT_FOUND');
    }

    if (storedToken.expiresAt < new Date()) {
      await prisma.refreshToken.delete({ where: { id: storedToken.id } });
      throw new AppError('Refresh token expirado', 401, 'REFRESH_TOKEN_EXPIRED');
    }

    // Rotate: delete old, issue new
    await prisma.refreshToken.delete({ where: { id: storedToken.id } });
    const tokens = await this.issueTokens(payload.userId, payload.email);

    logger.info('Token renovado', { userId: payload.userId });
    return tokens;
  }

  async logout(refreshToken: string | undefined, userId: string): Promise<void> {
    if (!refreshToken) return;

    await prisma.refreshToken.deleteMany({
      where: { token: refreshToken, userId },
    });

    logger.info('Sesión cerrada', { userId });
  }

  async getSalt(email: string): Promise<string> {
    const user = await prisma.user.findUnique({
      where: { email },
      select: { kdfSalt: true },
    });

    if (!user) {
      throw new AppError('Usuario no encontrado', 404, 'USER_NOT_FOUND');
    }

    return user.kdfSalt;
  }

  private async issueTokens(userId: string, email: string): Promise<UserTokens> {
    const accessToken = signAccessToken({ userId, email });
    const refreshToken = signRefreshToken({ userId, email });

    await prisma.refreshToken.create({
      data: {
        token: refreshToken,
        userId,
        expiresAt: getRefreshExpiryDate(),
      },
    });

    return { accessToken, refreshToken };
  }
}

export const authService = new AuthService();
