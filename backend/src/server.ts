import 'dotenv/config';
import { createApp } from './app';
import { connectDatabase, disconnectDatabase } from './prisma/client';
import { logger } from './utils/logger';

const PORT = parseInt(process.env.PORT ?? '3000', 10);

async function bootstrap(): Promise<void> {
  // Validate required environment variables
  const required = ['DATABASE_URL', 'JWT_SECRET', 'JWT_REFRESH_SECRET'];
  const missing = required.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    logger.error('Variables de entorno faltantes', { missing });
    process.exit(1);
  }

  await connectDatabase();

  const app = createApp();

  const server = app.listen(PORT, () => {
    logger.info(`🔐 Claveo Backend iniciado`, {
      environment: process.env.NODE_ENV,
      port: PORT,
      pid: process.pid,
    });
  });

  const gracefulShutdown = async (signal: string): Promise<void> => {
    logger.info(`${signal} recibido, cerrando servidor...`);
    server.close(async () => {
      await disconnectDatabase();
      logger.info('Servidor cerrado correctamente');
      process.exit(0);
    });

    // Force exit after 10 seconds
    setTimeout(() => {
      logger.error('Forzando cierre después de 10s');
      process.exit(1);
    }, 10_000);
  };

  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
  process.on('SIGINT', () => gracefulShutdown('SIGINT'));

  process.on('unhandledRejection', (reason) => {
    logger.error('Promesa rechazada sin manejar', { reason });
  });

  process.on('uncaughtException', (error) => {
    logger.error('Excepción no capturada', { error });
    process.exit(1);
  });
}

bootstrap().catch((error) => {
  logger.error('Error al iniciar el servidor', { error });
  process.exit(1);
});
