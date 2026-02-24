# Modelo de Seguridad de Claveo

## Diseño Zero-Knowledge

Claveo implementa un modelo de seguridad de **conocimiento cero verdadero**: el servidor nunca tiene acceso a las contraseñas del usuario ni a los datos sin cifrar.

---

## Flujo criptográfico

### 1. Derivación de claves (PBKDF2)

Cuando el usuario ingresa su contraseña maestra:

```
masterPassword + email + salt
       │
       ├─► PBKDF2-HMAC-SHA256 (600,000 iter) ──► encryptionKey (256-bit)
       │   nonce = email + ":enc:claveo-v1" + salt
       │
       └─► PBKDF2-HMAC-SHA256 (100,000 iter) ──► authPassword (base64url)
           nonce = email + ":auth:claveo-v1" + salt
```

- **encryptionKey**: Nunca sale del dispositivo. Cifra/descifra el vault.
- **authPassword**: Se envía al servidor como "contraseña". El servidor la hashea con bcrypt (12 rondas).
- **masterPassword**: Nunca se envía al servidor.

### 2. Registro

```
[Cliente]                              [Servidor]
   │                                       │
   ├── Genera salt aleatorio (32 bytes)    │
   ├── Deriva encryptionKey                │
   ├── Deriva authPassword                 │
   ├── POST /auth/register ─────────────►  │
   │   { email, authPassword, kdfSalt }    │
   │                                       ├── bcrypt.hash(authPassword, 12)
   │                                       └── Guarda: email, hash, kdfSalt
```

### 3. Login

```
[Cliente]                              [Servidor]
   │                                       │
   ├── GET /auth/salt?email=... ─────────► │
   │ ◄───── { salt } ──────────────────── │
   ├── Deriva encryptionKey con salt       │
   ├── Deriva authPassword con salt        │
   ├── POST /auth/login ─────────────────► │
   │   { email, authPassword }             │
   │                                       ├── bcrypt.compare(authPassword, hash)
   │ ◄───── { tokens, kdfSalt } ──────── │
   └── Guarda encryptionKey en Keychain    │
```

### 4. Operaciones del vault

```
[Cliente]                              [Servidor]
   │                                       │
   ├── plaintext = JSON(vaultEntry)        │
   ├── {ciphertext, iv, mac} = AES-256-GCM(plaintext, encryptionKey)
   ├── POST /vault ────────────────────►   │
   │   { encryptedData, iv, mac }          │
   │                                       └── Guarda blob cifrado
   │                                           (sin acceso al contenido)
```

---

## Algoritmos

| Función | Algoritmo | Parámetros |
|---------|-----------|-----------|
| Derivación (cifrado) | PBKDF2-HMAC-SHA256 | 600,000 iteraciones, 256 bits |
| Derivación (auth) | PBKDF2-HMAC-SHA256 | 100,000 iteraciones, 256 bits |
| Cifrado simétrico | AES-256-GCM | IV 96 bits, TAG 128 bits |
| Hash de contraseña (server) | bcrypt | 12 rondas |
| Autenticación | JWT (HS256) | Access: 15min, Refresh: 7 días |
| Salt KDF | CSPRNG | 32 bytes, base64url |

---

## Almacenamiento seguro en dispositivo

| Plataforma | Mecanismo |
|------------|-----------|
| iOS | Keychain con `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` |
| Android | AES-256-GCM con clave en Android Keystore (API 23+) |

La clave de cifrado se almacena en el keychain/keystore nativo del sistema operativo. Requiere desbloquearse con biometría o PIN del dispositivo.

---

## Autenticación biométrica

La autenticación biométrica (FaceID, huella) **no reemplaza** la contraseña maestra — la protege:

1. Al hacer login, la clave de cifrado se guarda en el keychain protegida por el OS
2. Para acceder: biometría → OS desbloquea el keychain → recupera encryptionKey
3. La contraseña maestra nunca se guarda en disco

---

## Rotación de tokens

- **Access token**: Expira en 15 minutos
- **Refresh token**: Expira en 7 días
- Cada refresh **rota** el refresh token (el anterior se invalida)
- Un refresh token solo puede usarse **una vez**

---

## Protecciones del servidor

| Protección | Implementación |
|------------|----------------|
| Rate limiting | 10 req/15min en auth, 300/15min global |
| Cabeceras seguras | Helmet.js (CSP, HSTS, etc.) |
| CORS | Lista blanca configurable |
| Validación | Zod con sanitización |
| SQL injection | Prisma ORM (queries parametrizadas) |
| Logs | Sin datos sensibles (sin contraseñas, sin claves) |

---

## Limitaciones conocidas

1. **Pérdida de contraseña maestra**: Irrecuperable por diseño. No hay reset de contraseña.
2. **Memoria de proceso**: Dart GC puede retener copias de la encryptionKey en memoria por tiempo indeterminado.
3. **Dispositivo comprometido (root/jailbreak)**: La seguridad del keychain puede verse comprometida si el dispositivo está rooteado.
4. **Biometría falsa**: La biometría de baja calidad puede ser vulnerada. Se recomienda PIN de respaldo fuerte.

---

## Recomendaciones para producción

- Usar HTTPS exclusivamente
- Configurar HSTS con preload
- Rotar JWT_SECRET periódicamente
- Monitorear intentos de login fallidos
- Implementar 2FA como capa adicional (futura funcionalidad)
- Auditar el código criptográfico regularmente
