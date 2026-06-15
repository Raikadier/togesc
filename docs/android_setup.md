# Android — desarrollo y pruebas (TOGESC)

Guía para ejecutar la app en **emulador** o **teléfono físico** en Windows.

## Estado mínimo requerido

`flutter doctor` debe mostrar:

```text
[✓] Android toolchain - develop for Android devices
```

Y al menos un dispositivo:

```powershell
flutter devices
# Debe aparecer algo como: sdk gphone64 ... • emulator-5554 • android
```

---

## Paso 1 — Completar el SDK (Android Studio)

Ya tienes Android Studio en `C:\Program Files\Android\Android Studio` y parte del SDK en  
`C:\Users\david\AppData\Local\Android\sdk`.

Faltan **cmdline-tools** y **licencias**.

1. Abre **Android Studio**
2. **More Actions** → **SDK Manager** (o *Settings → Languages & Frameworks → Android SDK*)
3. Pestaña **SDK Tools** → marca:
   - **Android SDK Command-line Tools (latest)**
   - **Android SDK Platform-Tools** (si no está)
   - **Android Emulator**
4. Pestaña **SDK Platforms** → marca al menos:
   - **Android 16 (API 36)** — requerido por Flutter 3.41+
   - (Opcional) Android 14 (API 34) para emuladores antiguos
5. **Apply** → espera la descarga

### Licencias

En PowerShell:

```powershell
flutter doctor --android-licenses
```

Pulsa `y` en cada pregunta.

Verifica:

```powershell
flutter doctor
```

---

## Paso 2 — Emulador (recomendado para empezar)

En Android Studio:

1. **More Actions** → **Virtual Device Manager**
2. **Create Device** → p. ej. Pixel 7
3. System image → **API 34** o **35** (descarga si hace falta)
4. **Finish** → ▶ **Launch**

Comprueba:

```powershell
flutter devices
```

---

## Alternativa — Teléfono físico

1. En el móvil: **Ajustes → Opciones de desarrollador → Depuración USB** (activada)
2. Conecta por USB
3. Acepta “Permitir depuración USB”
4. Instala drivers OEM si Windows no lo detecta (Samsung, Xiaomi, etc.)

```powershell
adb devices
flutter devices
```

---

## Paso 3 — Ejecutar TOGESC

```powershell
cd "D:\Github repos\togesc\TOGESC\togesc"
flutter pub get
flutter run
```

Si hay varios dispositivos:

```powershell
flutter run -d emulator-5554
# o
flutter run -d <id-del-movil>
```

La primera compilación Android puede tardar **10–20 minutos**.

---

## Problemas frecuentes

### `cmdline-tools component is missing`

Repite **Paso 1** (SDK Command-line Tools).

### `Android license status unknown`

```powershell
flutter doctor --android-licenses
```

### No aparece ningún dispositivo Android

- Emulador: ábrelo desde Device Manager antes de `flutter run`
- Físico: `adb devices` debe listar el teléfono

### Error de symlinks / build raro

```powershell
cd "D:\Github repos\togesc\TOGESC\togesc"
flutter clean
flutter pub get
flutter run
```

---

## Build release (Play Store, más adelante)

Cuando quieras publicar:

```powershell
flutter build appbundle --release
```

Salida: `build/app/outputs/bundle/release/app-release.aab`

Hoy el `applicationId` es `com.example.togesc` (válido para pruebas; cámbialo antes de Play Store).

---

## Orden sugerido contigo

1. Completar SDK + licencias (**~15 min**)
2. Crear emulador (**~10 min**)
3. `flutter run` en Android
4. Después: `flutter run -d windows` cuando quieras probar escritorio
