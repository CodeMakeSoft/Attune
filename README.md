# Attune — Gestión de Recursos Humanos (SaaS)

![Attune Logo](assets/images/logo.png)

**Attune** es una aplicación de gestión de capital humano y operación de negocios (SaaS). Provee una plataforma centralizada para el manejo de equipos de trabajo, perfiles laborales, evaluaciones de desempeño, permisos, vacaciones y jerarquías organizacionales, adaptada a la estructura de PYMES y grandes corporativos.

---

## Tabla de Contenidos

- [Documentación Oficial](#documentación-oficial)
- [Arquitectura y Tecnologías](#arquitectura-y-tecnologías)
- [Características Principales](#características-principales)
- [Instalación y Configuración](#instalación-y-configuración)
  - [Linux](#linux-ubuntu--debian--fedora)
  - [Windows](#windows)
- [Configuración del Proyecto](#configuración-del-proyecto)
- [Configuración de Firebase](#configuración-de-firebase)
- [Ejecución](#ejecución)
- [Pruebas](#pruebas)
- [Compilación para Producción](#compilación-para-producción)
- [Solución de Problemas](#solución-de-problemas)

---

## Documentación Oficial

La documentación completa del proyecto se encuentra compilada en el documento oficial en PDF, disponible en la rama de documentación:

1. **SRS (Especificación de Requisitos de Software):** Historias de usuario, reglas de negocio y restricciones no funcionales (Capítulo 4).
2. **Diseño Arquitectónico:** Patrón Clean Architecture, modelos de datos en Firebase y flujos de interacción (Capítulo 6).
3. **Diseño de Interfaces (UI/UX):** Mapas de navegación, componentes atómicos y paleta cromática (Capítulo 6).
4. **Informe de Hallazgos de Pruebas:** Defectos detectados durante las pruebas y sus resoluciones (Capítulo 9).

---

## Arquitectura y Tecnologías

| Capa | Tecnología |
|------|-----------|
| Frontend / Framework | Flutter (Dart) `>=3.9.2` |
| Backend / Base de Datos | Firebase — Cloud Firestore y Authentication |
| Gestión del Estado | State Management nativo con inyección de dependencias ligera |
| Gráficos e Informes | `fl_chart` para estadísticas de rendimiento |
| Arquitectura | Clean Architecture por roles (Empleado, Administrador, Super Admin) |

---

## Características Principales

- **Dashboard por Roles:** Paneles únicos dependiendo de los privilegios del usuario.
- **Estructura Organizacional:** Creación y asignación de puestos y departamentos en tiempo real.
- **Métricas y Desempeño:** Evaluaciones de desempeño semanales con gráficas interactivas y prevención de duplicidad.
- **Directorio y Equipo:** Panel de empleados con gestión de baja, edición de datos fiscales/contractuales y estatus de nómina.
- **Notificaciones Push:** Integración con Firebase Cloud Messaging (FCM).

---

## Instalación y Configuración

Sigue la guía correspondiente a tu sistema operativo antes de continuar.

---

### Linux (Ubuntu / Debian / Fedora)

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
# Agregar al archivo de configuración del shell
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.bashrc

# Recargar la configuración
source ~/.bashrc

# Verificar instalación
flutter --version
```

> Si usas **Zsh** en lugar de Bash, reemplaza `~/.bashrc` por `~/.zshrc`.

#### 4. Instalar Android Studio

```bash
# Alternativa con snap
sudo snap install android-studio --classic

# Referencia oficial: https://developer.android.com/studio

# Aceptar licencias de Android SDK
flutter doctor --android-licenses
```

#### 5. Instalar Java (requerido por Android SDK)

```bash
# Ubuntu / Debian
sudo apt install -y openjdk-17-jdk

# Fedora
sudo dnf install -y java-17-openjdk

# Verificar
java -version
```

#### 6. Instalar Firebase CLI

```bash
# Instalar Node.js (si no está instalado)
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

# Agregar al PATH
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.bashrc
source ~/.bashrc
```

#### 8. Verificar el entorno

```bash
flutter doctor -v
```

Asegúrate de que todos los checks estén en verde antes de continuar.

---

### Windows

#### 1. Instalar Git

1. Descarga Git desde: https://git-scm.com/download/win
2. Ejecuta el instalador con las opciones predeterminadas.
3. Verifica en PowerShell o CMD:
```powershell
git --version
```

#### 2. Instalar Flutter SDK

```powershell
# Opción A: con winget (recomendado, Windows 10/11)
winget install --id=Google.Flutter -e
```

**Opción B — Manual:**
1. Descarga el ZIP desde https://docs.flutter.dev/get-started/install/windows
2. Extrae el contenido en `C:\flutter`
3. Agrega `C:\flutter\bin` al PATH del sistema:
   - Panel de Control → Variables de entorno → Path → Nuevo → `C:\flutter\bin`

Verifica en una nueva terminal:
```powershell
flutter --version
```

#### 3. Instalar Android Studio

1. Descarga e instala Android Studio desde: https://developer.android.com/studio
2. Durante la instalación, selecciona:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device (AVD)
3. Abre Android Studio → SDK Manager → instala **Android SDK Platform 35** (o la más reciente).

#### 4. Configurar variables de entorno de Android

En PowerShell como Administrador:
```powershell
# Establecer ANDROID_HOME
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

#### 9. Verificar el entorno

```powershell
flutter doctor -v
```

---

## Configuración del Proyecto

Una vez configurado el entorno, sigue estos pasos en cualquier sistema operativo.

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

## Configuración de Firebase

> **Importante:** Este paso es obligatorio. Sin él, la aplicación no podrá conectarse al backend.

### Paso 1 — Crear el proyecto en Firebase Console

1. Ve a https://console.firebase.google.com e inicia sesión con tu cuenta de Google.
2. Haz clic en **Agregar proyecto**.
3. Escribe el nombre del proyecto (ej. `attune-app`) y haz clic en **Continuar**.
4. Activa o desactiva Google Analytics según tu preferencia y haz clic en **Crear proyecto**.
5. Espera a que el proyecto termine de crearse y haz clic en **Continuar**.

---

### Paso 2 — Habilitar Authentication

Attune utiliza **Email/Contraseña** y **Google Sign-In** como proveedores de autenticación.

1. En el menú lateral → **Authentication** → **Comenzar**.
2. Abre la pestaña **Método de inicio de sesión**.
3. Habilita los proveedores requeridos:

**Correo electrónico / Contraseña**
- Selecciona el proveedor → activa la palanca → **Guardar**.

**Google**
- Selecciona Google → activa la palanca.
- Elige un correo de soporte del proyecto.
- Haz clic en **Guardar**.

**Facebook** *(opcional — requiere app en Meta for Developers)*
- Selecciona Facebook → activa la palanca.
- Ingresa el App ID y App Secret de tu app en Meta for Developers.
- Copia la URL de OAuth de Firebase y agrégala en tu app de Meta → **Guardar**.

---

### Paso 3 — Crear la base de datos de Firestore

1. En el menú lateral → **Firestore Database** → **Crear base de datos**.
2. Elige el modo de inicio:
   - **Modo de producción** (recomendado): las reglas deniegan todo por defecto, debes configurarlas manualmente.
   - **Modo de prueba**: permite lectura/escritura pública durante 30 días (solo para desarrollo).
3. Selecciona la ubicación del servidor más cercana a tus usuarios (ej. `us-central`, `southamerica-east1`).
4. Haz clic en **Habilitar**.

---

### Paso 4 — Registrar las aplicaciones en Firebase

Debes registrar cada plataforma que vayas a utilizar.

**Android**

1. En la consola → Configuración del proyecto → **Agregar app** → ícono Android.
2. Nombre del paquete Android: `com.example.attune`
   *(se encuentra en `android/app/build.gradle` en el campo `applicationId`)*
3. Haz clic en **Registrar app**.
4. Descarga `google-services.json` y colócalo en:
   ```
   android/app/google-services.json
   ```
5. Haz clic en **Siguiente** → **Siguiente** → **Ir a la consola** (los SDK ya están declarados en `pubspec.yaml`).

**Web / Windows**

1. En la consola → Configuración del proyecto → **Agregar app** → ícono Web (`</>`).
2. Escribe un apodo (ej. `Attune Web`).
3. Haz clic en **Registrar app**.
4. Conserva la configuración mostrada — la necesitarás si configuras Firebase de forma manual.
5. Haz clic en **Ir a la consola**.

---

### Paso 5 — Configurar Firebase en el código (FlutterFire CLI)

Este es el método recomendado. Genera automáticamente el archivo `lib/firebase_options.dart`.

```bash
# 1. Iniciar sesión en Firebase
firebase login

# 2. Ejecutar desde la raíz del proyecto
flutterfire configure

# 3. Seleccionar el proyecto de la lista (ej. attune-app-3ea44)
# 4. Marcar con barra espaciadora las plataformas a configurar:
#      [x] android
#      [x] web
#      [x] windows
# 5. Presionar Enter — el CLI genera los archivos automáticamente
```

**Archivos generados o actualizados:**

| Archivo | Ubicación | Descripción |
|---------|-----------|-------------|
| `firebase_options.dart` | `lib/` | Claves de conexión por plataforma |
| `google-services.json` | `android/app/` | Credenciales para Android |
| `firebase.json` | raíz del proyecto | Configuración general del proyecto Firebase |

> Si ya descargaste `google-services.json` en el Paso 4, el CLI lo sobreescribirá correctamente. No combines ambos métodos manualmente.

---

### Paso 6 — Firebase Cloud Messaging (FCM)

Attune usa FCM para notificaciones push. No se requiere configuración adicional en la consola para Android. El handler ya está registrado en `main.dart`:

```dart
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
await NotificationService.initialize();
```

Verifica en la consola que el servicio **Messaging** esté activo para tu proyecto.

---

### Paso 7 — Reglas de Firestore

Las reglas de seguridad del proyecto (`firestore.rules`) permiten acceso completo a usuarios autenticados:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() {
      return request.auth != null;
    }

    match /{path=**} {
      allow read, write: if isSignedIn();
    }
  }
}
```

Para desplegar las reglas a Firebase:

```bash
# Desde la raíz del proyecto
firebase deploy --only firestore:rules

# Especificando el proyecto
firebase deploy --only firestore:rules --project attune-app-3ea44
```

Para verificar las reglas activas en la consola:
- Firestore Database → pestaña **Reglas**

---

### Paso 8 — Verificar la conexión con Firebase

```bash
# Ejecutar la app
flutter run

# Si Firebase está correctamente inicializado, verás en consola:
# [Firebase] Firebase initialized successfully
```

Si hay errores de conexión, verifica lo siguiente:

- `google-services.json` está ubicado en `android/app/`
- `lib/firebase_options.dart` existe y contiene el `projectId` correcto (`attune-app-3ea44`)
- El `applicationId` en `android/app/build.gradle` coincide con el registrado en Firebase Console

---

## Ejecución

```bash
# Listar dispositivos disponibles
flutter devices

# Iniciar emulador Android (si tienes un AVD configurado)
flutter emulators --launch <nombre_del_emulador>

# Ejecutar en el dispositivo detectado automáticamente
flutter run

# Ejecutar en modo release
flutter run --release

# Ejecutar en un dispositivo específico
flutter run -d <device_id>

# Ejecutar en navegador (modo web)
flutter run -d chrome
```

---

## Pruebas

```bash
# Ejecutar todas las pruebas
flutter test

# Ejecutar pruebas con reporte de cobertura
flutter test --coverage
```

---

## Compilación para Producción

```bash
# Android — APK
flutter build apk --release

# Android — App Bundle (para Google Play Store)
flutter build appbundle --release

# Web
flutter build web --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

---

## Solución de Problemas

| Error | Solución |
|-------|----------|
| `flutter: command not found` | Verifica que Flutter está en el PATH y reinicia la terminal |
| `Android license status unknown` | Ejecuta `flutter doctor --android-licenses` |
| `Firebase not initialized` | Verifica que `flutterfire configure` fue ejecutado o que `google-services.json` está en su lugar |
| `Gradle build failed` | Verifica que JDK 17 está instalado y que `JAVA_HOME` está configurado |
| `No devices available` | Conecta un dispositivo físico o inicia un emulador con `flutter emulators` |
| `pub get failed` | Verifica tu conexión a internet y ejecuta `flutter clean && flutter pub get` |

---

Para reportar errores o contribuir al proyecto, abre un Issue o Pull Request en el repositorio.
