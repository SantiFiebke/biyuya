# 💰 Biyuya - Cuentas claras

Aplicación móvil para el seguimiento de los gastos compartidos de un hogar.

<p>
  <img src="https://img.shields.io/badge/Flutter-3.47.2-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Supabase-2.16.0-3FCF8E?logo=supabase" alt="Supabase">
  <a href="LICENSE"><img src="https://img.shields.io/badge/Licencia-MIT-green" alt="Licencia MIT"></a>
  <img src="https://img.shields.io/badge/tests-495-blue" alt="Tests">
</p>

**Biyuya - Cuentas claras** es un tracker de gastos para el hogar. Los usuarios crean o se unen a un hogar mediante un código de invitación, registran gastos por categoría y consultan reportes mensuales. Incluye captura offline (los gastos se guardan en una cola local y se sincronizan al recuperar la conexión) y presupuestos por categoría.

---

## ✨ Funcionalidades

- **Autenticación** — Login y registro con email y contraseña (Supabase Auth) y sesión persistente.
- **Onboarding** — Crear un hogar nuevo (el creador queda como `owner`) o unirse con un código de invitación.
- **Gastos** — CRUD completo, listado con filtros por categoría, miembro y rango de fechas, vista de detalle y detección de duplicados (informativa).
- **Categorías** — CRUD, presupuesto mensual por categoría, bandera `is_expense` (excluye categorías no-gasto como *Ahorro* de los totales) y categorías por defecto sembradas al crear el hogar (Alimentos, Transporte, Vivienda, Servicios, Salud, Ocio, Educación, Otros).
- **Reportes** — Desglose mensual del gasto por categoría e insights que comparan cada categoría contra el mes anterior.
- **Home** — Dashboard con tarjeta de balance del mes, últimos gastos, acciones rápidas, checklist de primeros pasos (descartable) y tarjeta de proyección de gasto de fin de mes (según preferencia).
- **Liquidación de deudas** — Cálculo de transferencias entre miembros para saldar el mes (algoritmo *min-cash-flow*), activable por preferencia.
- **Perfil y ajustes** — Modo oscuro, activación de liquidación de deudas y proyección mensual, gestión del hogar (salir/eliminar), eliminación de cuenta, enlaces legales y cierre de sesión.
- **Modo offline** — Outbox local de gastos pendientes y sincronización idempotente.
- **Widget nativo** — Widget de Android con el total gastado hoy y accesos rápidos a categorías frecuentes.
- **Deep links** — Esquema `biyuya://expense/new` para abrir el formulario de gasto.
- **Aceptación de términos** — Checkbox obligatorio en el registro, con registro inmutable en la base de datos.

---

## 📸 Capturas

Capturas pendientes de agregar en `docs/screenshots/`.

---

## 🏗️ Arquitectura

### Clean Architecture por feature

El proyecto sigue **Clean Architecture** organizado por *feature*. Cada funcionalidad separa responsabilidades en tres capas:

```
┌──────────────────────────────────────────────┐
│               presentation                    │
│     Widgets, Views, Controllers (Riverpod)    │
├──────────────────────────────────────────────┤
│                 domain                        │
│   Entidades, contratos (*_repository_base)    │
├──────────────────────────────────────────────┤
│                  data                         │
│   Repositorios impl., data sources, modelos   │
└──────────────────────────────────────────────┘
                     ↕
                 Supabase
```

### Principios clave

| Concepto | Implementación |
|---|---|
| **State management** | Riverpod 3.x con code generation (`@riverpod`) |
| **Navegación** | GoRouter 18.x con `redirect` basado en el estado de autenticación |
| **Manejo de errores** | `Result<T, Failure>` con `multiple_result` en los repositorios |
| **Entidades** | Extienden `Equatable` para comparación por valor |
| **Backend** | Supabase (Auth + PostgreSQL) |

### Repository Pattern

Cada feature expone un contrato en `domain/repositories/` con el sufijo `*_repository_base.dart`, y una implementación en `data/repositories/`. Los métodos retornan `Result<T, Failure>` para forzar el manejo explícito de errores.

```dart
// Contrato: lib/src/features/expenses/domain/repositories/expense_repository_base.dart
abstract class ExpenseRepositoryBase {
  Future<Result<List<Expense>, ExpenseFailure>> getExpenses({
    required int householdId,
  });

  Future<Result<Expense, ExpenseFailure>> createExpense({
    required double amount,
    required DateTime date,
    required int householdId,
    required int categoryId,
    required String userUuid,
    String? description,
    String? clientId,
  });

  Future<Result<void, ExpenseFailure>> deleteExpense({required int id});
}

// Implementación: lib/src/features/expenses/data/repositories/expense_repository_impl.dart
class ExpenseRepositoryImpl implements ExpenseRepositoryBase { ... }
```

### Riverpod Code Generation

Los providers se definen con la anotación `@riverpod` y se generan con `riverpod_generator`.

```dart
@riverpod
ExpenseRepositoryBase expenseRepository(Ref ref) {
  return ExpenseRepositoryImpl(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
}

@Riverpod(keepAlive: true)
class ExpenseController extends _$ExpenseController {
  @override
  Future<List<Expense>> build() async { ... }
}
```

---

## 🛠️ Tecnologías

### Core

| Tecnología | Versión | Propósito |
|---|---|---|
| Flutter | 3.47.2 | Framework multiplataforma |
| Dart SDK | ^3.12.2 | Lenguaje (`environment.sdk` en `pubspec.yaml`) |

### State Management

| Tecnología | Versión | Propósito |
|---|---|---|
| flutter_riverpod | ^3.0.0 | State management |
| riverpod_annotation | ^4.0.0 | Anotaciones para code generation |
| riverpod_generator | ^4.0.0+1 | Generador de providers |

### Backend

| Tecnología | Versión | Propósito |
|---|---|---|
| supabase_flutter | ^2.16.0 | Auth y base de datos (BaaS) |
| shared_preferences | ^2.5.2 | Persistencia local ligera y outbox offline |
| connectivity_plus | ^7.0.0 | Detección de conectividad para la sincronización |

### Navegación

| Tecnología | Versión | Propósito |
|---|---|---|
| go_router | ^18.0.1 | Routing declarativo con redirects |
| app_links | ^7.0.0 | Deep links (`biyuya://expense/new`) |

### UI & Utilidades

| Tecnología | Versión | Propósito |
|---|---|---|
| material_ui | ^1.2.0 | Componentes Material |
| google_fonts | ^8.0.1 | Tipografías personalizadas |
| intl | ^0.20.2 | Formateo de fechas y monedas |
| skeletonizer | ^2.1.3 | Skeleton loaders |
| flutter_native_splash | ^2.4.5 | Splash screen nativo |
| equatable | ^2.0.7 | Comparación por valor |
| multiple_result | ^5.1.0 | Manejo de errores `Result<T, Failure>` |
| uuid | ^4.6.0 | Generación de `client_id` (uuid v4) |
| url_launcher | ^6.3.2 | Apertura de enlaces legales externos |
| logger | ^2.2.0 | Logging en desarrollo |

### Testing & Quality

| Tecnología | Versión | Propósito |
|---|---|---|
| flutter_test | SDK | Framework de tests |
| mocktail | ^1.0.4 | Mocking |
| fake_async | ^1.3.3 | Control de tiempos asíncronos |
| build_runner | ^2.15.0 | Code generation |
| very_good_analysis | ^11.0.0 | Reglas estrictas de análisis estático |

---

## 📂 Estructura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada, Supabase, deep links, tema
├── theme/
│   ├── theme.dart                     # Tema claro/oscuro
│   └── theme_builder.dart             # Builder del tema con Google Fonts
└── src/
    ├── constants/                     # Constantes globales
    ├── utils/                         # Utilidades generales
    ├── core/
    │   ├── config/                    # EnvironmentConfig, LegalConfig
    │   ├── constants/                 # Constantes de la app
    │   ├── data/                      # Modelos y sync del widget
    │   ├── domain/entities/           # Entidades compartidas
    │   ├── network/                   # Timeout y conectividad
    │   ├── provider/                  # Providers globales (tema)
    │   └── presentation/              # Widgets, dialogs, pages y utils compartidos
    ├── navigation/
    │   ├── domain/service/            # Interfaz del servicio de navegación
    │   ├── data/services/             # Implementación
    │   ├── provider/                  # routerProvider, pendingDeepLink
    │   ├── routes/                    # AppRoute (rutas centralizadas)
    │   └── presentation/              # MainShell (bottom navbar)
    └── features/
        ├── auth/                      # Login, registro, sesión, onboarding
        ├── categories/                # CRUD de categorías y presupuestos
        ├── expenses/                  # CRUD de gastos, sync, duplicados, deudas
        ├── home/                      # Dashboard, checklist, proyección
        ├── reports/                   # Reporte mensual e insights
        ├── settings/                  # Preferencias del usuario
        └── profile/                   # Perfil y ajustes
```

Cada feature con capas completas (`auth`, `categories`, `expenses`, `reports`, `settings`) usa `data/`, `domain/` y `presentation/`; `home` y `profile` son principalmente `presentation/`.

---

## 🚀 Instalación y Configuración

### Prerrequisitos

- **Flutter SDK** 3.47.2 o compatible (Dart `^3.12.2`).
- **Cuenta en Supabase** ([supabase.com](https://supabase.com)).
- **Android Studio** o **Xcode** para ejecutar en emulador o dispositivo.

### 1. Clonar el repositorio

```bash
git clone https://github.com/SantiFiebke/biyuya.git
cd biyuya
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Setup de Supabase

Biyuya **requiere su propio backend en Supabase**. No hay backend compartido: cada usuario/instalación debe crear **su propio proyecto** de Supabase.

#### Paso 1 — Crear el proyecto

1. Entrar a [supabase.com](https://supabase.com) y crear una cuenta (o iniciar sesión).
2. Click en **New project**.
3. Elegir organización, **nombre**, **contraseña de base de datos** y **región**.
4. Esperar a que termine el aprovisionamiento.

#### Paso 2 — Instalar el Supabase CLI

```bash
brew install supabase/tap/supabase
# o con npm:
npm install -g supabase
```

Ver la [documentación oficial del CLI](https://supabase.com/docs/guides/cli).

#### Paso 3 — Vincular el proyecto

```bash
supabase login
supabase link --project-ref <TU_PROJECT_REF>
```

El `<TU_PROJECT_REF>` es el identificador del proyecto y aparece en la URL del panel (`https://supabase.com/dashboard/project/<TU_PROJECT_REF>`).

#### Paso 4 — Aplicar las migraciones

```bash
supabase db push
```

Crea las tablas, políticas RLS, RPCs y triggers definidos en `supabase/migrations/`.

#### Paso 5 — Deployar la Edge Function

```bash
supabase functions deploy delete-account
```

Necesario para la eliminación de cuenta desde la app.

#### Paso 6 — Obtener las credenciales

En el panel: **Settings → API** → copiar **Project URL** y **anon public key**. Ver [Variables de Entorno](#-variables-de-entorno).

> ⚠️ **Sin estas credenciales la app falla al arrancar**, porque `EnvironmentConfig.validate()` lanza una excepción si falta `SUPABASE_URL` o `SUPABASE_ANON_KEY`.

### 4. Configurar las credenciales

Las credenciales se inyectan con `--dart-define` (no hay archivo `.env`). Ver [Variables de Entorno](#-variables-de-entorno).

### 5. Generar código

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 6. Ejecutar la app

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://TU-Proyecto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=tu-anon-key-aqui
```

---

## 🔧 Desarrollo

### Hot reload

```bash
flutter run
# 'r' hot reload · 'R' hot restart
```

### Code generation

Regenerar tras modificar providers anotados con `@riverpod`:

```bash
dart run build_runner build --delete-conflicting-outputs
# o en modo watch:
dart run build_runner watch
```

### Análisis estático

```bash
flutter analyze
```

El proyecto usa `very_good_analysis`. No debe haber warnings antes de commitear.

### Formateo

```bash
dart format .
```

---

## 🧪 Pruebas

### Ejecutar los tests

```bash
flutter test
flutter test --reporter compact
```

### Cobertura

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html   # requiere lcov
```

### Estado actual

- **56 archivos** de test, **495 tests** en total.
- La carpeta `test/` espeja `lib/src/`.

### Mocking

Se usa `mocktail` para mocks y `fake_async` para control de tiempos. Los helpers compartidos (`wrapTest`, `waitForLoad`, factories `makeCategory` / `makeExpense` / `makeReport`) viven en `test/helpers/test_helpers.dart`.

Convenciones, patrones de `ProviderContainer` y overrides de Riverpod están documentados en **[`test/README.md`](test/README.md)**.

---

## 📦 Build

### Android (APK)

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
# Salida: build/app/outputs/flutter-apk/app-release.apk
```

### Android (App Bundle)

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
# Salida: build/app/outputs/bundle/release/app-release.aab
```

### iOS

```bash
flutter build ios --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
# Luego abrir Xcode para configurar la firma.
```

---

## 🔐 Variables de Entorno

Las variables se inyectan **en tiempo de compilación** con `--dart-define` (`String.fromEnvironment`) y se leen desde `EnvironmentConfig` (`lib/src/core/config/enviroment_config.dart`).

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://TU-Proyecto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=tu-anon-key-aqui
```

> ⚠️ **No se usa `dotenv` ni archivos `.env`.** Al ser `String.fromEnvironment`, los valores quedan **embebidos en el binario compilado**. Para builds, repetir los `--dart-define` en cada comando.

`EnvironmentConfig.validate()` corre al inicio de `main.dart` y lanza una excepción si falta alguna variable:

```dart
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

1. Entrar a [app.supabase.com](https://app.supabase.com) y seleccionar el proyecto.
2. Ir a **Settings → API**.
3. Copiar **Project URL** → `SUPABASE_URL`.
4. Copiar la **anon public key** → `SUPABASE_ANON_KEY`.

Para crear el proyecto, vincularlo y aplicar migraciones, ver [Setup de Supabase](#setup-de-supabase).

> ℹ️ **`config.json` (opcional):** archivo de conveniencia local para guardar `SUPABASE_URL` y `SUPABASE_ANON_KEY` durante el desarrollo. Está **gitignoreado** y no es necesario: los valores reales se inyectan con `--dart-define`.

---

## 📊 Base de Datos

Backend en **Supabase PostgreSQL**. Todas las tablas tienen **Row Level Security (RLS)** habilitado.

### `profiles` — Perfiles de usuario

| Columna | Tipo | Descripción |
|---|---|---|
| `id` | uuid (PK) | Referencia a `auth.users` |
| `name` | text | Nombre |
| `last_name` | text | Apellido |
| `household_id` | bigint (FK) | Hogar al que pertenece |
| `role` | text | `owner` o `member` |
| `created_at` | timestamptz | Alta |
| `updated_at` | date | Última actualización |
| `last_modified_at` | timestamptz | Última modificación |

### `households` — Hogares

| Columna | Tipo | Descripción |
|---|---|---|
| `id` | bigint (PK) | Identificador |
| `name` | text | Nombre del hogar |
| `invite_code` | text (unique) | Código de invitación |
| `created_at` | timestamptz | Alta |

### `expenses` — Gastos

| Columna | Tipo | Descripción |
|---|---|---|
| `id` | bigint (PK) | Identificador |
| `amount` | numeric(10,2) | Monto (> 0) |
| `date` | timestamp | Fecha del gasto |
| `description` | text | Descripción (≤ 200 caracteres) |
| `household_id` | bigint (FK) | Hogar |
| `category_id` | bigint (FK) | Categoría |
| `user_uuid` | uuid (FK) | Usuario que registró el gasto |
| `client_id` | uuid (unique) | Idempotencia de sincronización offline |
| `created_at` | timestamptz | Alta |
| `last_modified_at` | timestamptz | Última modificación |

### `categories` — Categorías

| Columna | Tipo | Descripción |
|---|---|---|
| `id` | bigint (PK) | Identificador |
| `name` | text | Nombre (1–50 caracteres) |
| `color` | text | Color hexadecimal |
| `icon` | text | CodePoint del ícono Material |
| `household_id` | bigint (FK) | Hogar |
| `budget_amount` | numeric(10,2) | Presupuesto mensual (opcional, > 0) |
| `is_expense` | boolean | `false` excluye la categoría de los totales |
| `created_at` | timestamptz | Alta |
| `last_modified_at` | timestamptz | Última modificación |

### `user_settings` — Preferencias

| Columna | Tipo | Descripción |
|---|---|---|
| `user_id` | uuid (PK) | Referencia a `auth.users` |
| `debt_settlement_enabled` | boolean | Liquidación de deudas (default `false`) |
| `month_projection_enabled` | boolean | Proyección mensual (default `false`) |
| `debt_settlement_explainer_seen` | boolean | Explicador visto |
| `month_projection_explainer_seen` | boolean | Explicador visto |
| `first_steps_dismissed` | boolean | Checklist de primeros pasos descartado |
| `created_at` / `updated_at` | timestamptz | Auditoría |

### `terms_acceptances` — Aceptación de términos

| Columna | Tipo | Descripción |
|---|---|---|
| `id` | uuid (PK) | Identificador |
| `user_id` | uuid (FK) | Referencia a `auth.users` |
| `accepted` | boolean | Aceptado |
| `accepted_at` | timestamptz | Fecha de aceptación |
| `terms_version` | text | Versión aceptada |

> Registro inmutable: el usuario solo puede leer su propia fila. La inserción la hace el trigger `handle_new_user` a partir de los metadatos del registro.

### Diagrama de relaciones

```
┌──────────────┐         ┌──────────────┐
│   profiles   │         │  households  │
├──────────────┤         ├──────────────┤
│ id      (PK) │──┐   ┌──│ id      (PK) │
│ name         │  │   │  │ name         │
│ last_name    │  └──►│  │ invite_code  │
│ household_id │      │  └──────┬───────┘
│ role         │      │         │
└──────────────┘      │   ┌─────┴──────┐
                      │   │            │
               ┌──────┴──────┐  ┌─────┴────────┐
               │  expenses   │  │  categories  │
               ├─────────────┤  ├──────────────┤
               │ id     (PK) │  │ id     (PK)  │
               │ amount      │  │ name         │
               │ date        │  │ color        │
               │ description │  │ icon         │
               │ household_id│  │ household_id │
               │ category_id │─►│ budget_amount│
               │ user_uuid   │  │ is_expense   │
               │ client_id   │  └──────────────┘
               └─────────────┘

  user_settings ──► auth.users
  terms_acceptances ──► auth.users
```

### Migraciones

Los cambios de esquema viven en `supabase/migrations/`:

| Migración | Contenido |
|---|---|
| `20260918203245_remote_schema.sql` | Esquema remoto inicial (RLS incluido) |
| `20260918211000_add_performance_indexes.sql` | Índices de rendimiento |
| `20260918212000_add_profiles_household_index.sql` | Índice de `profiles.household_id` |
| `20260918213000_create_household_rpc.sql` | RPC `create_household` |
| `20260918214000_join_household_rpc.sql` | RPC `join_household` |
| `20260918215000_add_input_constraints.sql` | Constraints de entrada |
| `20260918216000_household_ownership.sql` | Rol y RPC `leave_household` / `delete_household` |
| `20260922000000_add_category_budget.sql` | Presupuesto por categoría |
| `20260923000000_add_expense_client_id.sql` | `client_id` para idempotencia offline |
| `20260924120000_user_settings.sql` | Tabla `user_settings` |
| `20260925130000_add_category_is_expense.sql` | Bandera `is_expense` |
| `20260925140000_user_settings_feature_flags.sql` | Feature flags de preferencias |
| `20260925150000_user_settings_first_steps.sql` | Flag del checklist de primeros pasos |
| `20260926120000_terms_acceptances.sql` | Tabla `terms_acceptances` y trigger |

Aplicar al proyecto remoto:

```bash
supabase db push
```

---

## 📴 Modo Offline

- **Outbox local:** los gastos creados sin conexión se guardan en `PendingExpenseStore` (`shared_preferences`) y se muestran de forma optimista con el badge **"pendiente"**.
- **Idempotencia:** cada gasto pendiente lleva un `client_id` (uuid v4). Al sincronizar se hace `upsert` con `onConflict: 'client_id'`, por lo que los reintentos no generan filas duplicadas.
- **Disparadores de sincronización:** al recuperar conectividad (`connectivity_plus`), al reanudar la app y con el botón manual **"Reintentar sync"**.
- **Re-entrancy guard:** `ExpenseSyncService.flush()` no arranca un nuevo flush si ya hay uno en curso.
- **Arranque offline:** se cachean categorías y perfil para no depender de la red al iniciar.
- **Timeouts:** las llamadas de red usan `kNetworkTimeout` (5 s) y caen a la caché si no responden.

---

## 🔁 Detección de Duplicados

Detector *content-only* (`findDuplicateExpenseIds`): agrupa los gastos por la clave `householdId | amount | día | categoryId | descripción normalizada`. No incluye `user_uuid`, por lo que detecta duplicados aunque los haya cargado otro miembro del hogar. Los gastos repetidos se marcan con el badge **"posible duplicado"** en la lista y en el home. La marca es informativa y **no bloquea** el registro.

---

## 📱 Widget Nativo

- **Android:** `ExpenseWidget` (`AppWidgetProvider`) muestra el total gastado hoy y chips de categorías frecuentes. Se alimenta de `SharedPreferences` y de un `MethodChannel` (`biyuya/widget`).
- **Refresco:** on-demand desde la app y por `updatePeriodMillis` (30 min). El reset a medianoche es pasivo: al leer, compara la fecha y descarta el total del día anterior.
- **Configuración por instancia:** cada widget puede mostrar u ocultar categorías y elegir cuántas (1–4).
- **iOS:** **no tiene widget** — el proyecto no incluye una extensión WidgetKit.

Documentación detallada en [`docs/WIDGET.md`](docs/WIDGET.md).

---

## 🔗 Deep Links

- **Esquema:** `biyuya://expense/new` (con `?categoryId=<id>` opcional para preseleccionar la categoría).
- **Android:** cableado. `DeepLinkHandlerActivity` está registrada en el `AndroidManifest.xml` y reenvía el `ACTION_VIEW` a la app.
- **iOS:** **no cableado**. El `Info.plist` no registra ningún `CFBundleURLTypes`/URL scheme, por lo que el deep link no funciona en iOS.
- **Robustez:** dedupe de 800 ms y un `pendingDeepLinkProvider` que conserva el destino hasta que la sesión se resuelve, para que el deep link sobreviva al login/onboarding en un arranque en frío.

---

## 🔄 Flujo de Autenticación

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

### Lógica de redirect en GoRouter

`routerProvider` evalúa el `AsyncValue` de `authSessionControllerProvider` en cada navegación:

- **`loading`** → Splash.
- **Sin sesión** → Login (o Registro, si ya está en esa pantalla).
- **Sesión sin hogar** → Onboarding.
- **Sesión con hogar** → Home; consume el deep link pendiente si existe.

### Persistencia de sesión

- Supabase maneja la persistencia de tokens automáticamente.
- `authSessionControllerProvider` (keepAlive) mantiene el estado de sesión durante toda la vida de la app y escucha el stream de auth para detectar cambios.

---

## ⚠️ Limitaciones Conocidas

- **iOS:** sin widget nativo y sin deep links cableados (no hay URL scheme registrado en `Info.plist`).
- **Internacionalización:** la app solo soporta `es-ES`; no hay sistema de i18n multi-idioma.
- **CI/CD:** no hay pipelines configurados.
- **Analytics / crash reporting:** no integrados.

---

## 🤝 Contribuir

### Flujo de trabajo

1. Clonar el repositorio.
2. Crear una rama para la feature o el fix:
   ```bash
   git checkout -b feature/nueva-feature
   ```
3. Hacer cambios y commitear con mensajes descriptivos.
4. Push y crear un Pull Request.

### Convenciones de commits

```
feat: agregar filtro de fechas en reportes
fix: corregir redirect cuando el hogar es null
refactor: extraer ExpenseFormWidget
chore: actualizar dependencias
docs: actualizar README
```

### Reglas

- `flutter analyze` sin warnings antes de commitear.
- `dart format .` para mantener consistencia.
- Preferir commits pequeños y descriptivos.

---

## 📄 Licencia

Este proyecto está bajo la licencia **[MIT](LICENSE)**.

---

## 👥 Equipo / Contacto

### Desarrollador

- **sfiebke** — [GitHub](https://github.com/SantiFiebke)

### Contacto

- **Issues:** [GitHub Issues](https://github.com/SantiFiebke/biyuya/issues)
- **Email:** stfiebke@outlook.es

---

<p align="center">
  <sub>Hecho con ❤️ en Argentina 🇦🇷</sub>
</p>