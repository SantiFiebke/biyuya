# 💰 Biyuya - Cuentas claras

<!-- Logo placeholder - reemplazar con el logo real de la app -->
<!-- <p align="center"><img src="docs/logo.png" width="150" alt="Biyuya - Cuentas claras Logo"/></p> -->

<p align="center">
  <strong>App móvil para el seguimiento de gastos de un hogar</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.12.2-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Supabase-2.16.0-3FCF8E?logo=supabase" alt="Supabase">
  <img src="https://img.shields.io/badge/Licencia-MIT-green" alt="License MIT">
</p>

<p align="center">
  Modelo familiar/compartido: los usuarios crean o se unen a un <em>hogar</em> mediante código de invitación,
  registran gastos por categoría, y visualizan reportes mensuales con desglose por categoría.
</p>

---

## 📋 Tabla de Contenidos

1. [🎯 Objetivos](#-objetivos)
2. [📸 Capturas](#-capturas)
3. [🏗️ Arquitectura](#️-arquitectura)
4. [🛠️ Tecnologías Utilizadas](#️-tecnologías-utilizadas)
5. [📂 Estructura del Proyecto](#-estructura-del-proyecto)
6. [🚀 Instalación y Configuración](#-instalación-y-configuración)
7. [🔧 Desarrollo](#-desarrollo)
8. [🧪 Pruebas](#-pruebas)
9. [📦 Build](#-build)
10. [🔐 Variables de Entorno](#-variables-de-entorno)
11. [📊 Base de Datos](#-base-de-datos)
12. [📴 Modo Offline (outbox + sync)](#-modo-offline-outbox--sync)
13. [🔁 Detección de duplicados](#-detección-de-duplicados)
14. [📱 Widget nativo](#-widget-nativo)
15. [🔄 Flujo de Autenticación](#-flujo-de-autenticación)
16. [🤝 Contribuir](#-contribuir)
17. [📄 Licencia](#-licencia)
18. [👥 Equipo / Contacto](#-equipo--contacto)

---

## 🎯 Objetivos

### Propósito de la Aplicación

**Biyuya - Cuentas claras** es una aplicación móvil diseñada para simplificar el control de gastos domésticos. Permite que múltiples miembros de un mismo hogar registren, compartan y visualicen los gastos del hogar de forma colaborativa y ordenada.

### Usuarios Objetivo

- **Familias** que buscan organizar sus finanzas domésticas de forma compartida.
- **Compañeros de roommate** que necesitan dividir y rastrear gastos comunes.
- **Parejas** que desean llevar un registro transparente de sus gastos compartidos.

### Propuesta de Valor

| Problemática | Solución |
|---|---|
| Gastos domésticos descontrolados | Registro rápido por categoría con filtros mensuales |
| Falta de transparencia entre miembros | Modelo compartido: todos ven los mismos datos en tiempo real |
| Difícil identificar áreas de mayor gasto | Reportes mensuales con desglose por categoría |
| Sin código de invitación → unirse a un hogar es sencillo | Código de invitación compartible al instante |

---

## 📸 Capturas

> **TODO:** Agregar capturas de pantalla de la app. Sugerencias de screenshots:
>
> - **Login / Registro** — Pantalla de autenticación con email y contraseña.
> - **Onboarding** — Flujo de creación o unión a un hogar.
> - **Dashboard** — Lista de últimos gastos, nombre del hogar y código de invitación.
> - **Crear Gasto** — Formulario de registro de gasto con categoría y monto.
> - **Reportes** — Vista de reporte mensual con desglose por categoría.
> - **Perfil** — Vista del perfil del usuario.

<!-- Sugerencia de implementación:
```markdown
| Dashboard | Reportes | Crear Gasto |
|:---------:|:--------:|:-----------:|
| <img src="docs/screenshots/home.png" width="250"/> | <img src="docs/screenshots/reports.png" width="250"/> | <img src="docs/screenshots/expense.png" width="250"/> |
```
-->

---

## 🏗️ Arquitectura

### Clean Architecture por Feature

El proyecto sigue **Clean Architecture** organizado por *feature*, separando responsabilidades en tres capas por cada funcionalidad:

```
┌─────────────────────────────────────────────┐
│            presentation (UI)                │
│   Widgets, Pages, Controllers (Riverpod)   │
├─────────────────────────────────────────────┤
│              domain (lógica)                │
│      Entities, Repository interfaces       │
├─────────────────────────────────────────────┤
│               data (implementación)         │
│    Repository impl, DataSources, Models    │
└─────────────────────────────────────────────┘
         ↕           ↕            ↕
    Supabase     Supabase     Supabase
      API          API          API
```

### Principios Clave

| Concepto | Implementación |
|---|---|
| **State Management** | Riverpod 3.x con code generation (`@riverpod` annotations) |
| **Navegación** | GoRouter 18.x con redirect basado en estado de autenticación |
| **Error Handling** | `Result<T, Failure>` con `multiple_result` en repositorios |
| **Entidades** | Todas extienden `Equatable` para comparación por valor |
| **Backend** | Supabase (BaaS): Auth, Database, Realtime |

### Repository Pattern

Cada feature expone un **repositorio** como contrato (interface en `domain/`) y una implementación en `data/`. El repository retorna `Result<T, Failure>` para forzar manejo explícito de errores.

```dart
// Ejemplo: contrato en domain
abstract class ExpenseRepository {
  Future<Result<List<Expense>, Failure>> getExpenses({
    required String householdId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Result<void, Failure>> createExpense(Expense expense);
  Future<Result<void, Failure>> deleteExpense(String expenseId);
}

// Implementación en data — llama a Supabase
class ExpenseRepositoryImpl implements ExpenseRepository { ... }
```

### Riverpod Code Generation

Se usa `@riverpod` annotation + `riverpod_generator` para evitar boilerplate:

```dart
// Provider de repositorio (functional)
@riverpod
ExpenseRepository expenseRepository(ExpenseRepositoryRef ref) {
  return ExpenseRepositoryImpl(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
}

// Controller de estado (keepAlive para persistir durante la sesión)
@Riverpod(keepAlive: true)
class ExpenseController extends _$ExpenseController {
  @override
  Future<List<Expense>> build() async { ... }
  Future<void> create(Expense expense) async { ... }
  Future<void> delete(String id) async { ... }
}
```

### Providers Principales

| Provider | Tipo | Alcance |
|---|---|---|
| `supabaseClient` | functional | Global |
| `authRepository` | functional | Global |
| `authSessionControllerProvider` | keepAlive | Global — sesión activa |
| `householdNameProvider` | keepAlive | Global — nombre del hogar |
| `expenseRepository` | functional | Feature expenses |
| `expenseControllerProvider` | keepAlive | Feature expenses |
| `categoryRepository` | functional | Feature categories |
| `categoryControllerProvider` | keepAlive | Feature categories |
| `reportRepository` | functional | Feature reports |
| `reportControllerProvider` | keepAlive | Feature reports |
| `routerProvider` | functional | Navigation |

---

## 🛠️ Tecnologías Utilizadas

### Core

| Tecnología | Versión | Propósito |
|---|---|---|
| Flutter SDK | ^3.12.2 | Framework multiplataforma |
| Dart SDK | ^3.12.2 | Lenguaje de programación (`environment.sdk` en `pubspec.yaml`) |

### State Management

| Tecnología | Versión | Propósito |
|---|---|---|
| flutter_riverpod | ^3.0.0 | State management basado en providers |
| riverpod_annotation | ^4.0.0 | Anotaciones para code generation |
| riverpod_generator | ^4.0.0+1 | Generador de código Riverpod |

### Backend

| Tecnología | Versión | Propósito |
|---|---|---|
| supabase_flutter | ^2.16.0 | Backend as a Service (Auth, DB, Realtime) |

### Navegación

| Tecnología | Versión | Propósito |
|---|---|---|
| go_router | ^18.0.1 | Declarative routing con redirects |

### UI & Utilidades

| Tecnología | Versión | Propósito |
|---|---|---|
| google_fonts | ^8.0.1 | Tipografías personalizadas |
| intl | ^0.20.2 | Formateo de fechas, monedas y localización |
| skeletonizer | ^2.1.3 | Skeleton loaders para carga de datos |
| flutter_native_splash | ^2.4.5 | Splash screen nativo |
| equatable | ^2.0.7 | Comparación por valor de entidades |
| multiple_result | ^5.1.0 | Manejo de errores con Result<T, Failure> |
| shared_preferences | ^2.5.2 | Persistencia local ligera y outbox offline |
| connectivity_plus | ^7.0.0 | Detección de conectividad para sync |
| uuid | ^4.6.0 | Generación de `client_id` (uuid v4) |
| app_links | ^7.0.0 | Deep links (`biyuya://expense/new`) |
| logger | ^2.2.0 | Logging en desarrollo |

### Testing & Quality

| Tecnología | Versión | Propósito |
|---|---|---|
| build_runner | ^2.15.0 | Code generation runner |
| very_good_analysis | ^11.0.0 | Reglas estrictas de análisis estático |
| flutter_lints | ^6.0.0 | Reglas base de lint |
| mocktail | ^1.0.4 | Mocking para tests |
| fake_async | ^1.3.3 | Control de tiempos/async en tests |
| flutter_test | SDK | Testing framework nativo |

---

## 📂 Estructura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada, inicialización de Supabase
├── theme/
│   ├── theme.dart                     # Definición de tema claro/oscuro
│   └── theme_builder.dart             # Builder del tema con Google Fonts
└── src/
    ├── constants/                     # Constantes globales de la app
    ├── utils/                         # Utilidades generales
    ├── core/
    │   ├── config/                    # Configuración de Supabase y entorno
    │   ├── data/models/               # Modelos de datos (DTOs)
    │   ├── domain/entities/           # Entidades del dominio (Equatable)
    │   ├── network/                   # Cliente HTTP y configuración de red
    │   └── presentation/              # Widgets compartidos (botones, dialogs, etc.)
    ├── navigation/
    │   ├── domain/service/            # Interfaz del servicio de navegación
    │   ├── data/services/             # Implementación del servicio de navegación
    │   ├── provider/                  # Providers de navegación (routerProvider)
    │   └── routes/                    # Definición de rutas GoRouter
    └── features/
        ├── auth/                      # Login, registro, sesión
        │   ├── data/                  # Repository impl, datasources
        │   ├── domain/                # Entities, repository interface
        │   └── presentation/          # LoginView, RegisterView, AuthController
        ├── expenses/                  # CRUD de gastos
        │   ├── data/
        │   ├── domain/
        │   └── presentation/          # ExpensesListView, ExpenseFormView, ExpenseController
        ├── categories/                # CRUD de categorías
        │   ├── data/
        │   ├── domain/
        │   └── presentation/          # CategoriesListView, CategoryFormView, CategoryController
        ├── reports/                   # Reportes mensuales
        │   ├── data/
        │   ├── domain/
        │   └── presentation/          # ReportsView, ReportController
        ├── home/                      # Dashboard principal
        │   ├── data/
        │   ├── domain/
        │   └── presentation/          # HomeView, ExpenseCard, HomeProvider
        └── profile/                   # Perfil del usuario
            ├── data/
            ├── domain/
            └── presentation/          # ProfileView, ProfileProvider
```

### Convenciones de Carpetas

- **`data/`** — Implementación de repositorios, data sources, modelos de red, mappers.
- **`domain/`** — Contratos (interfaces), entidades de negocio, casos de uso.
- **`presentation/`** — Widgets, pantallas, controllers/providers Riverpod.
- Los controllers se definen en la capa de presentación y consumen repositorios del dominio.

---

## 🚀 Instalación y Configuración

### Prerrequisitos

- **Flutter SDK** >= 3.12.2 ([instalación](https://docs.flutter.dev/get-started/install))
- **Dart SDK** >= 3.12.2
- **Cuenta en Supabase** ([supabase.com](https://supabase.com))
- **Android Studio / Xcode** para emuladores

### Paso 1 — Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/biyuya.git
cd biyuya
```

### Paso 2 — Instalar dependencias

```bash
flutter pub get
```

### Paso 3 — Configurar variables de entorno

Las credenciales se pasan con `--dart-define` al ejecutar la app (no hay archivo `.env`). Ver [Variables de Entorno](#-variables-de-entorno).

### Paso 4 — Ejecutar code generation

```bash
dart run build_runner build
```

### Paso 5 — Ejecutar la app

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://TU-Proyecto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=tu-anon-key-aqui
```

---

## 🔧 Desarrollo

### Hot Reload

```bash
flutter run
# En la consola presiona 'r' para hot reload, 'R' para hot restart
```

### Code Generation

Los providers con `@riverpod` requieren regeneración. Ejecutar después de cambios en providers:

```bash
# Build completo
dart run build_runner build

# Modo watch (regenera automáticamente al guardar)
dart run build_runner watch
```

### Análisis Estático

```bash
flutter analyze
```

El proyecto usa `very_good_analysis` con reglas estrictas. Verificar que no haya warnings antes de commitear.

### Formateo de Código

```bash
dart format .
```

---

## 🧪 Pruebas

### Ejecutar todos los tests

```bash
flutter test

# Salida compacta (una línea por test)
flutter test --reporter compact
```

### Ejecutar tests con cobertura

```bash
flutter test --coverage
# Abrir reporte: genhtml coverage/lcov.info -o coverage/html
```

### Estado Actual

> ✅ **Suite activa:** 37 archivos de test que pasan **304 tests** con `flutter test`.
>
> La carpeta `test/` espeja `lib/src/`. Convenciones, mocks con `mocktail` y patrones de `ProviderContainer` / overrides de Riverpod están documentados en **[`test/README.md`](test/README.md)**.

### Mocking

Se usa `mocktail` para mocks en tests:

```dart
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
```

---

## 📦 Build

### Android (APK)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android (App Bundle)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS

```bash
flutter build ios --release
# Abrir Xcode para configurar firma y publicar
```

---

## 🔐 Variables de Entorno

Las variables se inyectan **en tiempo de compilación** con `--dart-define` (`String.fromEnvironment`) y se leen desde `EnvironmentConfig` (`lib/src/core/config/enviroment_config.dart`).

### Definir las variables

Pasar `SUPABASE_URL` y `SUPABASE_ANON_KEY` al ejecutar o compilar:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://TU-Proyecto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=tu-anon-key-aqui
```

> ⚠️ **No se usa `dotenv` ni archivos `.env`.** Al ser `String.fromEnvironment`, los valores quedan embebidos en el binario. Para builds, repetir los `--dart-define`:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

### Validación en la App

`EnvironmentConfig.validate()` corre al inicio de `main.dart` y lanza excepción si falta alguna variable:

```dart
// lib/src/core/config/enviroment_config.dart
class EnvironmentConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Faltan variables de entorno esenciales.');
    }
  }
}
```

### Obtener las credenciales

1. Ir a [app.supabase.com](https://app.supabase.com)
2. Seleccionar el proyecto
3. Ir a **Settings > API**
4. Copiar `Project URL` → `SUPABASE_URL`
5. Copiar `anon public` key → `SUPABASE_ANON_KEY`

---

## 📊 Base de Datos

### Modelo de Datos (Supabase)

El backend utiliza **Supabase PostgreSQL** con las siguientes tablas:

### Migraciones

Los cambios de esquema viven en `supabase/migrations/`:

| Migración | Contenido |
|---|---|
| `20260918203245_remote_schema.sql` | Esquema remoto inicial |
| `20260918211000_add_performance_indexes.sql` | Índices de rendimiento |
| `20260918212000_add_profiles_household_index.sql` | Índice de `profiles.household_id` |
| `20260918213000_create_household_rpc.sql` | RPC para crear hogar |
| `20260918214000_join_household_rpc.sql` | RPC para unirse a un hogar |
| `20260918215000_add_input_constraints.sql` | Constraints de entrada |
| `20260918216000_household_ownership.sql` | Propiedad del hogar |
| `20260922000000_add_category_budget.sql` | Presupuesto por categoría |
| `20260923000000_add_expense_client_id.sql` | `client_id` para idempotencia offline |

Aplicar al proyecto remoto:

```bash
supabase db push
```

> ⚠️ `20260922000000_add_category_budget.sql` y `20260923000000_add_expense_client_id.sql` **deben aplicarse** o la app falla en runtime: el presupuesto por categoría y la idempotencia del modo offline dependen de esas columnas.

---

#### `profiles` — Perfiles de usuario

| Columna | Tipo | Descripción |
|---|---|---|
| `id` | uuid (PK) | ID del usuario (referencia a auth.users) |
| `name` | text | Nombre del usuario |
| `last_name` | text | Apellido del usuario |
| `household_id` | uuid (FK) | Referencia al hogar al que pertenece |

---

#### `households` — Hogares

| Columna | Tipo | Descripción |
|---|---|---|
| `id` | uuid (PK) | ID del hogar |
| `name` | text | Nombre del hogar (ej: "Casa Martínez") |
| `invite_code` | text (unique) | Código de invitación de 6 caracteres |

---

#### `expenses` — Gastos

| Columna | Tipo | Descripción |
|---|---|---|
| `id` | uuid (PK) | ID del gasto |
| `amount` | numeric | Monto del gasto |
| `date` | date | Fecha del gasto |
| `description` | text | Descripción breve |
| `household_id` | uuid (FK) | Hogar al que pertenece el gasto |
| `category_id` | uuid (FK) | Categoría del gasto |
| `user_uuid` | uuid (FK) | Usuario que registró el gasto |
| `created_at` | timestamptz | Fecha de creación (auto) |
| `last_modified_at` | timestamptz | Última modificación |

---

#### `categories` — Categorías

| Columna | Tipo | Descripción |
|---|---|---|
| `id` | uuid (PK) | ID de la categoría |
| `name` | text | Nombre de la categoría |
| `color` | text | Color hexadecimal (ej: `#FF5722`) |
| `icon` | text | Nombre del ícono Material |
| `household_id` | uuid (FK) | Hogar al que pertenece |
| `created_at` | timestamptz | Fecha de creación (auto) |

---

### Diagrama de Relaciones

```
┌──────────────┐     ┌──────────────┐
│   profiles   │     │  households  │
├──────────────┤     ├──────────────┤
│ id      (PK) │◄────│ id      (PK) │
│ name         │     │ name         │
│ last_name    │     │ invite_code  │
│ household_id │────►│              │
└──────────────┘     └──────┬───────┘
                            │
                     ┌──────┴───────┐
                     │              │
              ┌──────┴──────┐ ┌─────┴────────┐
              │  expenses   │ │  categories  │
              ├─────────────┤ ├──────────────┤
              │ id     (PK) │ │ id     (PK)  │
              │ amount      │ │ name         │
              │ date        │ │ color        │
              │ description │ │ icon         │
              │ household_id│─│ household_id │
              │ category_id │─│              │
              │ user_uuid   │ │ created_at   │
              │ created_at  │ └──────────────┘
              │ last_modified_at │
              └─────────────┘
```

---

## 📴 Modo Offline (outbox + sync)

La app permite registrar gastos sin conexión y sincronizarlos luego.

- **Outbox local:** los gastos creados sin red se guardan en `PendingExpenseStore` (`shared_preferences`) y se muestran de forma **optimista** con el badge **"pendiente"**.
- **Idempotencia:** cada gasto pendiente lleva un `client_id` (uuid v4). Al sincronizar se hace `upsert` con `onConflict: 'client_id'`, así los reintentos no generan filas duplicadas.
- **Disparadores de sync:** al recuperar conectividad (`connectivity_plus`), al reanudar la app y con el botón manual **"Reintentar sync"**.
- **`ExpenseSyncService.flush()`** vacía la outbox; tiene guard de **re-entrancy** (si ya hay un flush en curso, no arranca otro).
- **Arranque offline:** se cachean categorías y perfil para no depender de la red al iniciar.
- **Timeouts:** las llamadas de red usan `kNetworkTimeout` (5 s) y caen a la caché si no responden.
- El total del **widget nativo** incluye los gastos pendientes.

---

## 🔁 Detección de duplicados

Detector *content-only* `findDuplicateExpenseIds`: agrupa los gastos por la clave `householdId|amount|día|categoryId|description normalizada` (**sin `user_uuid`**, para detectar duplicados aunque los cargue otro miembro). Los gastos repetidos se marcan con el badge **"posible duplicado"** en la lista y en el home; la marca es informativa y **no bloquea** el registro.

---

## 📱 Widget nativo

- **Android:** `ExpenseWidget` (`AppWidgetProvider`) muestra el total gastado hoy. Se alimenta de `SharedPreferences` y de un `MethodChannel` (`biyuya/widget`).
- **Refresco:** on-demand desde la app y por `updatePeriodMillis` (24 h). El reset a medianoche es pasivo: al leer, compara la fecha y descarta el total de ayer.
- **iOS:** **no tiene widget** — no existe extensión WidgetKit en el proyecto.

---

## 🔄 Flujo de Autenticación

### Diagrama de Flujo

```
    ┌───────────┐
    │  Splash   │
    └─────┬─────┘
          │ Inicializar Supabase
          ▼
    ┌───────────┐
    │   Login   │ ◄──── Sin sesión
    └─────┬─────┘
          │ Login exitoso
          ▼
    ┌─────────────┐
    │ Onboarding  │ ◄──── Sesión activa pero sin household_id
    │ (Crear /    │
    │  Unirse)    │
    └─────┬───────┘
          │ Hogar asignado
          ▼
    ┌───────────┐
    │   Home    │ ◄──── Sesión activa + household_id
    └───────────┘
```

### Lógica de Redirect en GoRouter

El router evalúa el estado de autenticación en cada navegación:

```dart
// router.dart — lógica de redirect
GoRouter(
  redirect: (context, state) {
    final session = ref.watch(authSessionControllerProvider);
    final isOnboarding = state.matchedLocation == '/onboarding';

    // Sin sesión → Login
    if (session == null) return '/login';

    // Sesión pero sin hogar → Onboarding
    if (session.householdId == null && !isOnboarding) {
      return '/onboarding';
    }

    // Sesión + hogar, pero en login/onboarding → Home
    if (session.householdId != null &&
        (state.matchedLocation == '/login' ||
         state.matchedLocation == '/onboarding')) {
      return '/home';
    }

    return null; // No redirigir
  },
  // ...
)
```

### Detalle del Flujo

1. **Splash** — Inicializa Supabase, verifica si hay sesión existente.
2. **Login** — Email/password vía `supabase_flutter`. Al autenticarse, se crea el stream de auth que actualiza el profile.
3. **Onboarding** — Si el usuario no tiene `household_id`, debe crear un hogar nuevo o unirse con código de invitación.
4. **Home** — Dashboard con los últimos 15 gastos, nombre del hogar, y código de invitación para compartir.

### Persistencia de Sesión

- Supabase maneja la persistencia de tokens automáticamente.
- El `authSessionControllerProvider` (keepAlive) mantiene el estado de sesión durante toda la vida de la app.
- Se usa un `stream` de auth para detectar cambios (logout desde otro dispositivo, etc.).

---

## 🤝 Contribuir

### Flujo de Trabajo

1. Clonar el repositorio.
2. Crear una rama para la feature/fix:
   ```bash
   git checkout -b feature/nueva-feature
   ```
3. Hacer cambios y commitear con mensajes descriptivos.
4. Push y crear Pull Request.

### Convenciones de Commits

```
feat: agregar filtro de fechas en reportes
fix: corregir redirect cuando household es null
refactor: extraer ExpenseFormWidget
chore: actualizar dependencias
docs: agregar README
```

### Reglas

- Ejecutar `flutter analyze` sin warnings antes de commitear.
- Ejecutar `dart format .` para mantener consistencia.
- Preferir commits pequeños y descriptivos.

---

## 📄 Licencia

Este proyecto está bajo la licencia **MIT**. Ver el archivo [LICENSE](LICENSE) para más detalles.

```
MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 👥 Equipo / Contacto

### Desarrollador

- **sfiebke** — [GitHub](https://github.com/sfiebke)

### Contribuidores

<!-- Agregar miembros del equipo aquí -->

| Nombre | Rol | GitHub |
|---|---|---|
| — | — | — |

### Contacto

- **Issues**: [GitHub Issues](https://github.com/sfiebke/biyuya/issues)
- **Email**: stfiebke@outlook.es

---

<p align="center">
  <sub>Hecho con ❤️ en Argentina 🇦🇷</sub>
</p>
