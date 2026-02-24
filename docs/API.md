# Claveo API Reference

Base URL: `http://localhost:3000` (desarrollo)

Todos los endpoints retornan JSON con el formato:
```json
{
  "success": true,
  "data": { ... },
  "message": "Mensaje opcional"
}
```

En caso de error:
```json
{
  "success": false,
  "message": "Descripción del error",
  "code": "ERROR_CODE"
}
```

---

## Autenticación

### GET /auth/salt

Obtener el salt KDF del usuario (necesario antes del login).

**Query params:**
- `email` (string, requerido)

**Respuesta 200:**
```json
{
  "success": true,
  "data": { "salt": "base64url-encoded-salt" }
}
```

**Errores:**
- `404` — Usuario no encontrado

---

### POST /auth/register

Registrar un nuevo usuario.

**Body:**
```json
{
  "email": "usuario@ejemplo.com",
  "authPassword": "base64url-derivado-del-master-password",
  "kdfSalt": "base64url-encoded-salt"
}
```

**Respuesta 201:**
```json
{
  "success": true,
  "data": {
    "user": { "id": "uuid", "email": "usuario@ejemplo.com" },
    "tokens": {
      "accessToken": "eyJ...",
      "refreshToken": "eyJ..."
    }
  }
}
```

**Errores:**
- `400` — Validación fallida
- `409` — Email ya registrado
- `429` — Rate limit excedido (10 req/15min)

---

### POST /auth/login

Iniciar sesión.

**Body:**
```json
{
  "email": "usuario@ejemplo.com",
  "authPassword": "base64url-derivado-del-master-password"
}
```

**Respuesta 200:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "usuario@ejemplo.com",
      "kdfSalt": "base64url-encoded-salt"
    },
    "tokens": {
      "accessToken": "eyJ...",
      "refreshToken": "eyJ..."
    }
  }
}
```

**Errores:**
- `401` — Credenciales inválidas (`INVALID_CREDENTIALS`)
- `429` — Rate limit excedido

---

### POST /auth/refresh

Renovar access token usando refresh token.

**Body:**
```json
{
  "refreshToken": "eyJ..."
}
```

**Respuesta 200:**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

**Errores:**
- `401` — Refresh token inválido, expirado, o ya usado

---

### POST /auth/logout

Cerrar sesión e invalidar refresh token.

**Headers:** `Authorization: Bearer <accessToken>`

**Body:**
```json
{
  "refreshToken": "eyJ..."
}
```

**Respuesta 200:**
```json
{
  "success": true,
  "message": "Sesión cerrada exitosamente"
}
```

---

## Vault

> Todos los endpoints de vault requieren: `Authorization: Bearer <accessToken>`

### GET /vault

Obtener todas las entradas cifradas del vault.

**Respuesta 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "encryptedData": "base64-ciphertext",
      "iv": "base64-iv",
      "mac": "base64-mac",
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

---

### POST /vault

Crear una entrada cifrada en el vault.

**Body:**
```json
{
  "encryptedData": "base64-ciphertext",
  "iv": "base64-iv",
  "mac": "base64-mac"
}
```

**Respuesta 201:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "encryptedData": "...",
    "iv": "...",
    "mac": "...",
    "createdAt": "...",
    "updatedAt": "..."
  }
}
```

---

### PUT /vault/:id

Actualizar una entrada cifrada existente.

**Params:** `id` (UUID)

**Body:** Igual que POST /vault

**Respuesta 200:** La entrada actualizada

**Errores:**
- `404` — Entrada no encontrada o no pertenece al usuario

---

### DELETE /vault/:id

Eliminar una entrada del vault.

**Params:** `id` (UUID)

**Respuesta 200:**
```json
{
  "success": true,
  "message": "Entrada eliminada exitosamente"
}
```

---

## Códigos de error comunes

| Código | Descripción |
|--------|-------------|
| `EMAIL_EXISTS` | El email ya está registrado |
| `INVALID_CREDENTIALS` | Credenciales incorrectas |
| `AUTH_REQUIRED` | Token de autenticación requerido |
| `TOKEN_EXPIRED` | El access token expiró |
| `INVALID_TOKEN` | Token malformado |
| `INVALID_REFRESH_TOKEN` | Refresh token inválido o expirado |
| `ENTRY_NOT_FOUND` | Entrada del vault no encontrada |
| `RATE_LIMIT_EXCEEDED` | Demasiadas solicitudes |
| `INTERNAL_ERROR` | Error interno del servidor |

---

## Rate Limits

| Endpoint | Límite |
|----------|--------|
| `/auth/register` | 10 requests / 15 minutos |
| `/auth/login` | 10 requests / 15 minutos |
| `/auth/salt` | 30 requests / 15 minutos |
| Demás rutas | 300 requests / 15 minutos |
