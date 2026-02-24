# ============================================================
# Stage 1: Dependencies
# ============================================================
FROM node:20 AS deps
WORKDIR /app

COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci --only=production && \
    npx prisma generate

# ============================================================
# Stage 2: Builder
# ============================================================
FROM node:20 AS builder
WORKDIR /app

COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci

COPY . .
RUN npm run build

# ============================================================
# Stage 3: Production runner
# ============================================================
FROM node:20 AS production
WORKDIR /app

ENV NODE_ENV=production

# Security: run as non-root (Debian compatible)
RUN groupadd -g 1001 nodejs && \
    useradd -u 1001 -g nodejs -m claveo

COPY --from=deps --chown=claveo:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=claveo:nodejs /app/dist ./dist
COPY --from=builder --chown=claveo:nodejs /app/prisma ./prisma
COPY --chown=claveo:nodejs package*.json ./

RUN mkdir -p logs && chown claveo:nodejs logs

USER claveo

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["sh", "-c", "npx prisma migrate deploy && node dist/server.js"]
