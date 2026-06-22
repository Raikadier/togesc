# Publicación móvil — Android (Play Store) e iOS (TestFlight)

**Bundle ID / Application ID:** `com.raikadier.togesc`

---

## Requisitos previos

| Herramienta | Android | iOS |
|-------------|---------|-----|
| SDK | Android SDK (Flutter doctor ✓) | Xcode + Mac |
| Cuenta | Google Play Console (~25 USD) | Apple Developer (99 USD/año) |
| Firma | Keystore JKS | Certificados + provisioning en Xcode |

---

## Android — AAB firmado

### 1. Crear keystore (una vez)

```powershell
mkdir "D:\Github repos\togesc\TOGESC\togesc\android\keystores"
keytool -genkey -v `
  -keystore "D:\Github repos\togesc\TOGESC\togesc\android\keystores\togesc-release.jks" `
  -alias togesc -keyalg RSA -keysize 2048 -validity 10000
```

Guarda el keystore y contraseñas en un gestor seguro. **No subas el `.jks` a git.**

### 2. Configurar firma

```powershell
copy "TOGESC\togesc\android\key.properties.example" "TOGESC\togesc\android\key.properties"
# Editar key.properties con tus contraseñas
```

### 3. Build AAB

```powershell
cd "D:\Github repos\togesc"
.\scripts\build-android-release.ps1
```

Salida: `TOGESC/togesc/build/app/outputs/bundle/release/app-release.aab`

Sin `key.properties`, el build usa firma debug (solo pruebas locales, **no válido para Play Store**).

### 4. Play Console

1. Crear app → paquete `com.raikadier.togesc`
2. Subir AAB en **Producción** o **Prueba interna**
3. Completar: política de privacidad (URL web `/privacy`), capturas, icono, clasificación de contenido
4. Declarar permisos: `RECORD_AUDIO` (modo canto), `POST_NOTIFICATIONS` (recordatorios)

---

## iOS — TestFlight

### 1. Xcode

```bash
cd TOGESC/togesc
open ios/Runner.xcworkspace
```

- **Signing & Capabilities:** Team de Apple Developer, bundle `com.raikadier.togesc`
- Añadir **Microphone Usage Description** (ya en Info.plist)

### 2. Archive

Product → Archive → Distribute App → App Store Connect → Upload

### 3. App Store Connect

- Crear app con bundle ID `com.raikadier.togesc`
- TestFlight → testers internos
- Misma URL de privacidad que web

---

## CI (opcional)

Workflow manual `.github/workflows/build-android.yml` — `workflow_dispatch` para generar AAB en GitHub Actions con secrets:

| Secret | Descripción |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Keystore en base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Password del store |
| `ANDROID_KEY_ALIAS` | `togesc` |
| `ANDROID_KEY_PASSWORD` | Password de la clave |

---

## Versión

Editar en `TOGESC/togesc/pubspec.yaml`:

```yaml
version: 1.0.1+2   # 1.0.1 nombre, +2 versionCode/build
```

Cada subida a Play Store requiere `versionCode` (número después de `+`) mayor que la anterior.
