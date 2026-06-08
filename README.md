# Attune - Gestión de Recursos Humanos (SaaS)

![Attune Logo](assets/images/logo.png)

**Attune** es una aplicación de gestión de capital humano y operación de negocios (SaaS). Provee una plataforma centralizada para el manejo de equipos de trabajo, perfiles laborales, evaluaciones de desempeño, permisos, vacaciones y jerarquías organizacionales, adaptada a la estructura de PYMES y grandes corporativos.

---

## 🎯 Entregables del Proyecto (Documentación Oficial)

La documentación completa del proyecto (que incluye el diseño detallado y análisis) se encuentra compilada en nuestro documento oficial en PDF que puedes solicitar o buscar en la rama de documentación:

1. **SRS (Especificación de Requisitos de Software):** Contiene la recopilación de historias de usuario, reglas de negocio y restricciones no funcionales (Capítulo 4 del Documento Oficial).
2. **Diseño Arquitectónico:** Presentación del patrón de arquitectura (Clean Architecture), Modelos de Datos en Firebase y flujos de interacción (Capítulo 6 del Documento Oficial).
3. **Diseño de Interfaces (UI/UX):** Mapas de navegación, componentes atómicos y paleta cromática utilizada en el desarrollo (Capítulo 6 del Documento Oficial).
4. **Informe de Hallazgos de Pruebas:** Reporte completo de defectos detectados durante las pruebas (Overflows, lógicas de evaluación, accesos) y sus respectivas resoluciones (Capítulo 9 del Documento Oficial).

---

## 🛠 Arquitectura y Tecnologías

- **Frontend / Framework:** Flutter (Dart) `>=3.9.2`
- **Backend / Base de Datos:** Firebase (Cloud Firestore & Authentication)
- **Gestión del Estado:** State Management nativo apoyado en inyección de dependencias ligeras.
- **Gráficos e Informes:** `fl_chart` para renderizado dinámico de estadísticas de rendimiento de empleados.
- **Arquitectura:** Componentizada por Roles (Empleado, Administrador, Super Admin), estructurando las vistas separadas de la lógica de negocio (Servicios).

## 🚀 Características Principales

- **Dashboard por Roles:** Paneles únicos dependiendo de los privilegios del usuario.
- **Estructura Organizacional:** Creación y asignación de Puestos y Departamentos en tiempo real.
- **Métricas y Desempeño:** Sistema de evaluaciones de desempeño semanales que previene la duplicidad de datos y calcula gráficas interactivas.
- **Directorio y Equipo:** Panel completo de empleados donde se puede dar de baja, editar información fiscal/contractual y ver el estatus de nómina.

---

## 💻 Instalación y Configuración

> Sigue la guía correspondiente a tu sistema operativo.

---

### 🐧 Linux (Ubuntu / Debian / Fedora)

#### 1. Instalar dependencias del sistema

**Ubuntu / Debian:**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git unzip xz-utils zip libglu1-mesa clang cmake \
  ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
```

**Fedora:**
```bash
sudo dnf install -y curl git unzip xz zip mesa-libGLU clang cmake ninja-build \
  gtk3-devel
```

#### 2. Instalar Flutter SDK

```bash
# Descargar Flutter (última versión estable)
cd ~
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.0-stable.tar.xz

# Extraer el archivo
tar xf flutter_linux_3.32.0-stable.tar.xz

# Mover a una ubicación permanente
mkdir -p ~/development
mv flutter ~/development/
```

#### 3. Agregar Flutter al PATH

```bash
# Editar el archivo de configuración de tu shell
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.bashrc

# Recargar la configuración
source ~/.bashrc

# Verificar instalación
flutter --version
```

> Si usas **Zsh** en lugar de Bash, reemplaza `~/.bashrc` por `~/.zshrc`.

#### 4. Instalar Android Studio (para emulador Android)

```bash
# Descargar Android Studio desde la web oficial:
# https://developer.android.com/studio

# Alternativa con snap:
sudo snap install android-studio --classic

# Aceptar licencias de Android SDK
flutter doctor --android-licenses
```

#### 5. Instalar Java (requerido por Android SDK)

```bash
sudo apt install -y openjdk-17-jdk   # Ubuntu/Debian
# o
sudo dnf install -y java-17-openjdk  # Fedora

# Verificar
java -version
```

#### 6. Instalar Firebase CLI

```bash
# Instalar Node.js primero (si no lo tienes)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Instalar Firebase CLI
npm install -g firebase-tools

# Verificar
firebase --version
```

#### 7. Instalar FlutterFire CLI

```bash
dart pub global activate flutterfire_cli

# Agregar al PATH si no está
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.bashrc
source ~/.bashrc
```

#### 8. Verificar entorno completo

```bash
flutter doctor -v
```

Asegúrate de que todos los checks estén en verde ✅ antes de continuar.

---

### 🪟 Windows

#### 1. Instalar Git

1. Descarga Git desde: https://git-scm.com/download/win
2. Ejecuta el instalador con las opciones predeterminadas.
3. Verifica en PowerShell o CMD:
```powershell
git --version
```

#### 2. Instalar Flutter SDK

```powershell
# Opción A: Con winget (recomendado, Windows 10/11)
winget install --id=Google.Flutter -e

# Opción B: Manual
# 1. Descarga el ZIP desde https://docs.flutter.dev/get-started/install/windows
# 2. Extrae el contenido a C:\flutter
# 3. Agrega C:\flutter\bin al PATH del sistema:
#    Panel de Control > Variables de entorno > Path > Nuevo > C:\flutter\bin
```

Verifica en una nueva terminal:
```powershell
flutter --version
```

#### 3. Instalar Android Studio

1. Descarga e instala Android Studio desde: https://developer.android.com/studio
2. Durante la instalación, marca:
   - ✅ Android SDK
   - ✅ Android SDK Platform
   - ✅ Android Virtual Device (AVD)
3. Abre Android Studio → SDK Manager → instala **Android SDK Platform 35** (o la más reciente).

#### 4. Configurar variables de entorno de Android

En PowerShell como Administrador:
```powershell
# Establecer ANDROID_HOME (ajusta la ruta si es diferente)
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LOCALAPPDATA\Android\Sdk", "User")

# Agregar herramientas al PATH
$path = [System.Environment]::GetEnvironmentVariable("Path", "User")
[System.Environment]::SetEnvironmentVariable("Path", "$path;$env:LOCALAPPDATA\Android\Sdk\platform-tools;$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin", "User")
```

Cierra y vuelve a abrir la terminal, luego verifica:
```powershell
adb --version
```

#### 5. Aceptar licencias de Android SDK

```powershell
flutter doctor --android-licenses
# Escribe "y" y presiona Enter en cada pregunta
```

#### 6. Instalar Java (JDK 17)

1. Descarga desde: https://adoptium.net/temurin/releases/?version=17
2. Instala con las opciones predeterminadas.
3. Verifica:
```powershell
java -version
```

#### 7. Instalar Node.js y Firebase CLI

1. Descarga Node.js desde: https://nodejs.org (versión LTS)
2. Instala con las opciones predeterminadas.
3. En PowerShell:
```powershell
npm install -g firebase-tools
firebase --version
```

#### 8. Instalar FlutterFire CLI

```powershell
dart pub global activate flutterfire_cli
```

Agrega al PATH si no está disponible:
```powershell
$path = [System.Environment]::GetEnvironmentVariable("Path", "User")
[System.Environment]::SetEnvironmentVariable("Path", "$path;$env:APPDATA\Pub\Cache\bin", "User")
```

#### 9. Verificar entorno completo

```powershell
flutter doctor -v
```

---

## 📦 Clonar y Configurar el Proyecto

Una vez configurado el entorno, sigue estos pasos en **cualquier sistema operativo**:

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu_usuario/attune.git
cd attune
```

### 2. Instalar dependencias de Flutter

```bash
flutter pub get
```

---

## 🔥 Configuración completa de Firebase

> ⚠️ Este paso es **obligatorio**. Sin él, la app no conectará con el backend.

### Paso 1 — Crear el proyecto en Firebase Console

1. Ve a [https://console.firebase.google.com/](https://console.firebase.google.com/) e inicia sesión con tu cuenta de Google.
2. Haz clic en **"Agregar proyecto"**.
3. Escribe el nombre del proyecto (ej. `attune-app`) y haz clic en **Continuar**.
4. Activa o desactiva Google Analytics según tu preferencia → **Crear proyecto**.
5. Espera a que el proyecto termine de crearse y haz clic en **Continuar**.

---

### Paso 2 — Habilitar Authentication

Attune utiliza **Email/Password** y **Google Sign-In** como proveedores de autenticación.

1. En la consola de Firebase, ve al menú lateral → **Authentication** → **Comenzar**.
2. Abre la pestaña **"Método de inicio de sesión"**.
3. Habilita los siguientes proveedores:

   **Correo electrónico / Contraseña**
   - Haz clic en el proveedor → activa la palanca → **Guardar**.

   **Google**
   - Haz clic en Google → activa la palanca.
   - Elige un correo de soporte del proyecto.
   - Haz clic en **Guardar**.

   **Facebook** *(opcional — requiere app en Meta for Developers)*
   - Haz clic en Facebook → activa la palanca.
   - Ingresa el **App ID** y **App Secret** de tu app en Meta for Developers.
   - Copia la URL de OAuth de Firebase y agrégala en tu app de Meta → **Guardar**.

---

### Paso 3 — Crear la base de datos de Firestore

1. En el menú lateral → **Firestore Database** → **Crear base de datos**.
2. Elige el modo de inicio:
   - **Modo de producción** (recomendado): las reglas empiezan denegando todo. Configura las reglas tú mismo.
   - **Modo de prueba**: permite lectura/escritura pública durante 30 días (solo para desarrollo).
3. Selecciona la **ubicación** del servidor más cercana a tus usuarios (ej. `us-central`, `southamerica-east1`).
4. Haz clic en **Habilitar**.

---

### Paso 4 — Registrar las aplicaciones en Firebase

Debes registrar cada plataforma que uses (Android, Web, Windows).

#### Android

1. En la consola → ⚙️ Configuración del proyecto → **Agregar app** → ícono Android.
2. **Nombre del paquete Android:** `com.example.attune`
   *(puedes encontrarlo en `android/app/build.gradle` → `applicationId`)*
3. Opcional: escribe un apodo para la app.
4. Haz clic en **Registrar app**.
5. **Descarga `google-services.json`** y colócalo en:
   ```
   android/app/google-services.json
   ```
6. Haz clic en **Siguiente** → **Siguiente** → **Ir a la consola** (los SDK ya están en `pubspec.yaml`).

#### Web / Windows

1. En la consola → ⚙️ Configuración del proyecto → **Agregar app** → ícono Web (`</>`).
2. Escribe un apodo (ej. `Attune Web`).
3. Haz clic en **Registrar app**.
4. Copia la configuración que aparece — la necesitarás si configuras Firebase manualmente.
5. Haz clic en **Ir a la consola**.

---

### Paso 5 — Configurar Firebase en el código (FlutterFire CLI)

Este es el método recomendado. Genera automáticamente `lib/firebase_options.dart`.

```bash
# 1. Inicia sesión en Firebase desde la terminal
firebase login

# 2. Dentro de la raíz del proyecto Attune, ejecuta:
flutterfire configure

# 3. Selecciona tu proyecto de la lista (ej. attune-app-3ea44)
# 4. Marca con barra espaciadora las plataformas que quieres configurar:
#      [x] android
#      [x] web
#      [x] windows
# 5. Presiona Enter — el CLI genera los archivos automáticamente
```

**Archivos que se generan / actualizan:**

| Archivo | Ubicación | Descripción |
|---------|-----------|-------------|
| `firebase_options.dart` | `lib/` | Claves de conexión por plataforma |
| `google-services.json` | `android/app/` | Credenciales Android |
| `firebase.json` | raíz del proyecto | Configuración del proyecto Firebase |

> Si ya tienes el `google-services.json` descargado del Paso 4, el CLI lo sobreescribirá correctamente. No los mezcles manualmente.

---

### Paso 6 — Habilitar Firebase Cloud Messaging (FCM)

Attune usa FCM para notificaciones push. No requiere configuración adicional en la consola para Android, pero asegúrate de:

1. En la consola → **Messaging** → confirma que el servicio está activo.
2. En Android, el `google-services.json` ya incluye las claves de FCM.
3. En el código, el handler de fondo ya está registrado en `main.dart`:
   ```dart
   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
   await NotificationService.initialize();
   ```

---

### Paso 7 — Configurar las reglas de Firestore

Las reglas actuales del proyecto (`firestore.rules`) permiten lectura y escritura a cualquier usuario autenticado:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() {
      return request.auth != null;
    }

    // Acceso completo solo a usuarios autenticados
    match /{path=**} {
      allow read, write: if isSignedIn();
    }
  }
}
```

Para **desplegar las reglas** a Firebase:

```bash
# Asegúrate de estar en la raíz del proyecto
firebase deploy --only firestore:rules

# Para desplegar solo las reglas de un proyecto específico:
firebase deploy --only firestore:rules --project attune-app-3ea44
```

Para **verificar las reglas** en la consola:
- Ve a **Firestore Database** → pestaña **"Reglas"**.

---

### Paso 8 — Verificar que Firebase funciona

```bash
# Ejecuta la app y verifica los logs de conexión
flutter run

# Si ves este log en consola, Firebase está conectado correctamente:
# [Firebase] Firebase initialized successfully
```

Si hay errores de conexión, verifica:
- Que `google-services.json` está en `android/app/`
- Que `lib/firebase_options.dart` existe y tiene el `projectId` correcto (`attune-app-3ea44`)
- Que el `applicationId` en `android/app/build.gradle` coincide con el registrado en Firebase Console

---

### 3. Habilitar un dispositivo de ejecución

```bash
# Ver dispositivos disponibles
flutter devices

# Iniciar emulador Android (si tienes AVD configurado)
flutter emulators --launch <nombre_del_emulador>

# O ejecutar en Chrome (modo web)
flutter run -d chrome
```

### 4. Ejecutar el proyecto

```bash
# Ejecutar en el dispositivo/emulador detectado automáticamente
flutter run

# Ejecutar en modo release (más rápido, sin debug)
flutter run --release

# Ejecutar especificando dispositivo
flutter run -d <device_id>
```

---

## 🧪 Ejecutar pruebas

```bash
# Ejecutar todas las pruebas
flutter test

# Ejecutar pruebas con cobertura
flutter test --coverage
```

---

## 🏗 Compilar para producción

```bash
# Android (APK)
flutter build apk --release

# Android (App Bundle para Play Store)
flutter build appbundle --release

# Web
flutter build web --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

---

## 🛠 Solución de problemas comunes

| Problema | Solución |
|----------|----------|
| `flutter: command not found` | Verifica que Flutter está en el PATH y reinicia la terminal |
| `Android license status unknown` | Ejecuta `flutter doctor --android-licenses` |
| `Firebase not initialized` | Asegúrate de haber corrido `flutterfire configure` o colocado `google-services.json` |
| `Gradle build failed` | Verifica que tienes JDK 17 instalado y `JAVA_HOME` configurado |
| `No devices available` | Conecta un dispositivo físico o inicia un emulador con `flutter emulators` |
| `pub get failed` | Verifica tu conexión a internet y corre `flutter clean && flutter pub get` |

---

*Para reportar bugs o contribuir al proyecto, abre un Issue o Pull Request en el repositorio.*
