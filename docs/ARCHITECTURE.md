# Arquitectura de Claveo

## Visión general

```
┌─────────────────────────────────────────────────────────────┐
│                     Cliente Flutter                          │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ Presentation │  │    Domain    │  │      Data        │  │
│  │              │  │              │  │                  │  │
│  │  Screens     │  │  Entities    │  │  RemoteDS (Dio)  │  │
│  │  Widgets     │◄─│  UseCases   │◄─│  LocalDS (Secure)│  │
│  │  Providers   │  │  Repos (I)  │  │  Repos (Impl)    │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│                              │                               │
│                     CryptoUtils (cliente)                    │
│                     AES-256-GCM + PBKDF2                     │
└─────────────────────────────────────────────────────────────┘
                              │ HTTPS
                              │ (solo datos cifrados)
┌─────────────────────────────────────────────────────────────┐
│                     Backend Node.js                          │
│                                                             │
│  Routes → Controllers → Services → Prisma → PostgreSQL      │
│                                                             │
│  Middleware: Auth JWT, Rate limit, Helmet, CORS, Zod        │
└─────────────────────────────────────────────────────────────┘
```

---

## Frontend (Flutter)

### Arquitectura de capas (Clean Architecture)

```
lib/
├── core/                    # Código compartido
│   ├── constants/           # Configuración estática
│   ├── errors/              # Tipos de error (Failure)
│   ├── router/              # GoRouter + redirección por estado auth
│   ├── theme/               # AppTheme, AppColors (Material 3)
│   └── utils/               # CryptoUtils, PasswordGenerator, Validators
│
├── domain/                  # Reglas de negocio (sin dependencias externas)
│   ├── entities/            # UserEntity, VaultEntryEntity
│   ├── repositories/        # Interfaces abstractas
│   └── usecases/            # LoginUseCase, RegisterUseCase, etc.
│
├── data/                    # Implementaciones concretas
│   ├── datasources/
│   │   ├── local/           # SecureStorageDatasource
│   │   └── remote/          # AuthRemoteDatasource, VaultRemoteDatasource
│   ├── models/              # UserModel, VaultEntryModel (JSON serialization)
│   └── repositories/        # AuthRepositoryImpl, VaultRepositoryImpl
│
└── presentation/            # UI
    ├── providers/           # Riverpod: AuthNotifier, VaultNotifier, ThemeNotifier
    ├── screens/             # 10 pantallas (Splash → Vault → Settings)
    └── widgets/             # Componentes reutilizables
```

### State Management (Riverpod)

- **`authProvider`** (`ChangeNotifierProvider<AuthNotifier>`): Estado global de autenticación
  - `AuthStatus`: `loading | authenticated | unauthenticated`
  - Contiene `encryptionKey` en memoria durante la sesión
  - Controla `isVaultUnlocked` y `onboardingDone`

- **`vaultProvider`** (`ChangeNotifierProvider<VaultNotifier>`): Estado del vault
  - Lista de entradas descifradas en memoria
  - Filtering reactivo por categoría y búsqueda
  - Operaciones CRUD con sincronización al servidor

- **`themeModeProvider`** (`StateNotifierProvider<ThemeModeNotifier, ThemeMode>`): Tema light/dark persistido

### Navegación (GoRouter)

```
/            → SplashScreen (determina destino inicial)
/onboarding  → OnboardingScreen (3 slides, primera vez)
/login       → LoginScreen
/register    → RegisterScreen
/biometric   → BiometricUnlockScreen (vault bloqueado)
/vault       → VaultDashboardScreen (requiere auth + unlock)
/vault/add   → AddPasswordScreen
/vault/:id   → ViewPasswordScreen
/vault/:id/edit → EditPasswordScreen
/settings    → SettingsScreen
```

La redirección es reactiva: el router escucha cambios en `authProvider`.

---

## Backend (Node.js + TypeScript)

### Estructura de módulos

```
src/
├── app.ts              # Express app (middleware, rutas)
├── server.ts           # Bootstrap (env validation, DB, HTTP)
├── auth/               # Módulo de autenticación
│   ├── auth.schemas.ts     # Validación Zod
│   ├── auth.service.ts     # Lógica de negocio
│   ├── auth.controller.ts  # HTTP handlers
│   └── auth.routes.ts      # Express Router
├── vault/              # Módulo del vault (idéntica estructura)
├── middleware/
│   ├── auth.middleware.ts      # JWT verification
│   ├── error.middleware.ts     # Manejo centralizado de errores
│   └── validation.middleware.ts # Zod schema validation
├── prisma/
│   └── client.ts       # Singleton PrismaClient
├── types/
│   └── index.ts        # TypeScript types compartidos
└── utils/
    ├── jwt.ts          # Sign/verify JWT
    └── logger.ts       # Winston logger
```

### Flujo de una request

```
Request
  → Global rate limiter
  → Helmet (security headers)
  → CORS
  → JSON body parser
  → Router (/auth o /vault)
  → [JWT authenticate middleware] (solo /vault)
  → [Zod validation middleware]
  → Controller
  → Service
  → Prisma ORM
  → PostgreSQL
  ← Response
  ← [Error middleware] (si hay error)
```

---

## Base de datos (PostgreSQL + Prisma)

```sql
users
  id           UUID PRIMARY KEY
  email        VARCHAR UNIQUE
  password_hash VARCHAR           -- bcrypt(authPassword)
  kdf_salt     VARCHAR           -- salt para PBKDF2 del cliente
  created_at   TIMESTAMP
  updated_at   TIMESTAMP

vault_entries
  id             UUID PRIMARY KEY
  user_id        UUID REFERENCES users(id) ON DELETE CASCADE
  encrypted_data TEXT             -- AES-256-GCM ciphertext
  iv             VARCHAR          -- AES-GCM nonce
  mac            VARCHAR          -- AES-GCM authentication tag
  created_at     TIMESTAMP
  updated_at     TIMESTAMP

refresh_tokens
  id         UUID PRIMARY KEY
  token      VARCHAR UNIQUE
  user_id    UUID REFERENCES users(id) ON DELETE CASCADE
  expires_at TIMESTAMP
  created_at TIMESTAMP
```

---

## Infraestructura Docker

```yaml
services:
  postgres:
    image: postgres:16-alpine
    volumes: [postgres_data:/var/lib/postgresql/data]

  backend:
    build: ./backend
    depends_on: [postgres]
    environment: [DATABASE_URL, JWT_SECRET, ...]
```

El Dockerfile del backend usa **multi-stage build**:
1. `deps`: instala solo dependencias de producción
2. `builder`: compila TypeScript a JavaScript
3. `production`: imagen mínima con usuario no-root

---

## Decisiones de diseño

| Decisión | Rationale |
|----------|-----------|
| Zero-knowledge | Usuario tiene control total; nosotros no podemos acceder a datos |
| PBKDF2 vs Argon2 | PBKDF2 tiene mejor soporte en el paquete `cryptography` de Dart |
| Riverpod vs Bloc | Riverpod: menos boilerplate, sintaxis Dart más natural |
| GoRouter | Soporte oficial de Flutter, deep linking, redirección declarativa |
| Dio vs http | Dio: interceptors, mejor manejo de errores, timeout configurables |
| Prisma vs TypeORM | Prisma: mejor type-safety, migraciones automáticas |
| JWT + Refresh | Access tokens cortos (15min) + refresh rotativos por seguridad |
| FlutterSecureStorage | Usa Keychain (iOS) y Keystore (Android) — almacenamiento del OS |
