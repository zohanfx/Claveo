# Claveo — Gestor de Contraseñas de Conocimiento Cero

Claveo es un gestor de contraseñas **zero-knowledge** diseñado para usuarios hispanohablantes en LATAM. Toda la encriptación ocurre en el dispositivo. El servidor **nunca** tiene acceso a tus contraseñas.

---

## Arquitectura de Seguridad

```
Master Password
       │
       ├─► PBKDF2(600K iter) ──► Encryption Key (AES-256-GCM) ──► Cifra el vault
       │
       └─► PBKDF2(100K iter) ──► Auth Password (base64) ──► bcrypt ──► Servidor
```

- **Clave de cifrado**: nunca sale del dispositivo
- **Auth password**: derivada del master password con salt distinto, hasheada con bcrypt en el servidor
- **Vault**: enviado como blob cifrado (el servidor solo ve texto cifrado)

---

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Mobile | Flutter (Dart) |
| State | Riverpod |
| Navigation | GoRouter |
| Backend | Node.js + TypeScript + Express |
| ORM | Prisma |
| Database | PostgreSQL 16 |
| Crypto (app) | AES-256-GCM + PBKDF2 |
| Crypto (server) | bcrypt |
| Auth | JWT (access 15min) + Refresh Token rotation |
| Storage local | Flutter Secure Storage (Keychain / Keystore) |
| Biométrico | FaceID / Huella digital |
| Infraestructura | Docker Compose |

---

## Prerrequisitos

| Herramienta | Versión mínima |
|-------------|---------------|
| Flutter SDK | 3.22+ |
| Dart SDK | 3.3+ |
| Node.js | 20+ |
| Docker & Docker Compose | 24+ |
| PostgreSQL (opcional, sin Docker) | 16+ |

---

## Inicio rápido con Docker

### 1. Clonar e ingresar al proyecto
```bash
git clone <repo-url> claveo
cd claveo
```

### 2. Configurar variables de entorno del backend
```bash
cp backend/.env.example backend/.env
# Editar backend/.env con tus valores secretos
```

### 3. Levantar servicios
```bash
docker compose up --build
```

El backend estará disponible en `http://localhost:3000`.

### 4. Verificar que el backend funciona
```bash
curl http://localhost:3000/health
# {"status":"ok","timestamp":"..."}
```

---

## Desarrollo local (sin Docker)

### Backend
```bash
cd backend
npm install
cp .env.example .env
# Editar .env con DATABASE_URL apuntando a tu PostgreSQL local

npx prisma migrate dev --name init
npx prisma generate
npm run dev
```

### Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter run
```

> Para cambiar la URL del API, edita `lib/core/constants/app_constants.dart` o pasa `--dart-define=API_BASE_URL=http://TU_IP:3000` al correr flutter.

---

## Variables de entorno del backend

Copia `backend/.env.example` a `backend/.env`:

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `DATABASE_URL` | Conexión a PostgreSQL | `postgresql://user:pass@localhost:5432/claveo` |
| `JWT_SECRET` | Secreto para access tokens (mínimo 32 chars) | `super-secret-key-32-chars-min!!!` |
| `JWT_REFRESH_SECRET` | Secreto para refresh tokens | `another-secret-refresh-key-32!!` |
| `PORT` | Puerto del servidor | `3000` |
| `NODE_ENV` | Entorno | `development` o `production` |
| `ALLOWED_ORIGINS` | CORS: orígenes permitidos | `http://localhost:3000` |

---

## Endpoints del API

### Autenticación

| Método | Ruta | Descripción |
|--------|------|-------------|
| `GET` | `/auth/salt?email=...` | Obtener salt KDF del usuario |
| `POST` | `/auth/register` | Registrar usuario |
| `POST` | `/auth/login` | Iniciar sesión |
| `POST` | `/auth/refresh` | Renovar access token |
| `POST` | `/auth/logout` | Cerrar sesión (requiere auth) |

### Vault (requieren JWT)

| Método | Ruta | Descripción |
|--------|------|-------------|
| `GET` | `/vault` | Obtener todas las entradas cifradas |
| `POST` | `/vault` | Crear entrada cifrada |
| `PUT` | `/vault/:id` | Actualizar entrada cifrada |
| `DELETE` | `/vault/:id` | Eliminar entrada |

---

## Estructura del proyecto

```
claveo/
├── backend/                    # Node.js + TypeScript
│   ├── prisma/
│   │   └── schema.prisma       # Esquema de base de datos
│   ├── src/
│   │   ├── app.ts              # Express app (middleware, rutas)
│   │   ├── server.ts           # Entry point
│   │   ├── auth/               # Módulo de autenticación
│   │   ├── vault/              # Módulo del vault
│   │   ├── middleware/         # Auth, errores, validación
│   │   ├── prisma/             # Cliente Prisma
│   │   ├── types/              # TypeScript types
│   │   └── utils/              # Logger, JWT helpers
│   ├── Dockerfile
│   ├── package.json
│   └── .env.example
├── frontend/                   # Flutter
│   └── lib/
│       ├── core/               # Tema, constantes, utilidades, crypto
│       ├── data/               # Datasources, modelos, repos impl
│       ├── domain/             # Entidades, repos interfaces, use cases
│       └── presentation/       # Screens, widgets, providers
├── docker-compose.yml
└── docs/                       # Documentación técnica
```

---

## Comandos útiles

```bash
# Ver logs del backend
docker compose logs backend -f

# Acceder a Prisma Studio (GUI de base de datos)
cd backend && npx prisma studio

# Correr migraciones en producción
cd backend && npx prisma migrate deploy

# Build del backend
cd backend && npm run build

# Tests del backend (próximamente)
cd backend && npm test
```

---

## Despliegue en producción

1. Cambiar `NODE_ENV=production` en el `.env`
2. Generar JWT secrets fuertes (mínimo 64 caracteres)
3. Usar un PostgreSQL administrado (RDS, Supabase, etc.)
4. Configurar HTTPS (nginx + Let's Encrypt recomendado)
5. Cambiar `API_BASE_URL` en Flutter antes del build de release:
   ```bash
   flutter build apk --dart-define=API_BASE_URL=https://api.tuclaveo.com
   ```

---

## Licencia

MIT
