# Documentación — Widget del Home Screen (Android)

Widget nativo de Android que muestra el **total gastado hoy** y accesos rápidos a
categorías de gasto frecuentes, con configuración por instancia.

---

## 1. Qué hace

- Muestra el **total gastado hoy** (`$X.XXX`).
- Muestra hasta N **chips de categorías destacadas** (las más repetidas de los últimos 7 días).
- Botón **"+ Nuevo gasto"** que abre el formulario de gasto (deep link, sin categoría).
- Cada chip abre el formulario con esa categoría **preseleccionada**.
- Se **auto-actualiza a medianoche** (vuelve a `$0`).
- Config editable **por instancia**: mostrar/ocultar categorías y cuántas (1–4).

---

## 2. Arquitectura

El widget es **100% nativo** (Kotlin/XML). Flutter solo le "empuja" datos a
`SharedPreferences` y le pide un refresh vía `MethodChannel`. La comunicación es
unidireccional, salvo el refresh:

```
┌──────────────────────────── FLUTTER (Dart) ─────────────────────────────┐
│                                                                          │
│  expense_controller._emitExpenses()                                       │
│    ├── suma gastos de hoy ──────────────► WidgetDailyTotalSync.syncTotal  │
│    └── _syncFeaturedCategories()                                           │
│           topCategoryIdsLastWeek() ──► WidgetDailyTotalSync                │
│                                              .syncFeaturedCategories      │
│                                                                          │
│  WidgetDailyTotalSync  ── escribe ──►  SharedPreferences (FlutterShared…)  │
│                        ── invokeMethod('refresh') ──► MethodChannel       │
└──────────────────────────────────────────────────────────────────────────┘
                                   │
                    MethodChannel "biyuya/widget"
                                   ▼
┌──────────────────────────── ANDROID (Kotlin) ────────────────────────────┐
│                                                                          │
│  MainActivity (MethodChannel handler)                                     │
│    └── ExpenseWidget.refreshAll()                                         │
│                                                                          │
│  ExpenseWidget : AppWidgetProvider                                        │
│    └── renderWidget() ◄── lee SharedPreferences                           │
│         ├── loadDailyTotal()           (total de hoy / 0 si cambió el día)│
│         ├── loadFeaturedCategories()   (JSON → lista)                     │
│         ├── renderIconBitmap()         (glifo MaterialIcons → Bitmap)     │
│         ├── PendingIntent deep links   (biyuya://expense/new?categoryId=) │
│         └── appWidgetManager.updateAppWidget()                            │
│                                                                          │
│  WidgetConfigActivity + WidgetConfigPrefs  (config por appWidgetId)       │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Puente de datos: `SharedPreferences`

Clave del mecanismo: `SharedPreferences` es el **único** canal de datos Flutter → nativo.
Dart escribe con `shared_preferences`; Android lee del archivo `FlutterSharedPreferences`.
El plugin antepone el prefijo **`flutter.`** a cada clave, por eso:

| Escrito por Dart (`prefs.setString(...)`) | Leído por Kotlin (`context.getSharedPreferences("FlutterSharedPreferences", ...)`) |
|---|---|
| `widget_daily_total` | `flutter.widget_daily_total` |
| `widget_daily_date` | `flutter.widget_daily_date` |
| `widget_featured_categories` | `flutter.widget_featured_categories` |

> ⚠️ Los valores numéricos se guardan como **String** (no `float`/`int`), porque
> `FlutterSharedPreferences` guarda todo como `Long`/`String` y `getFloat`/`getInt` fallarían.
> Kotlin los parsea con `toDoubleOrNull()` / `optInt`.

La config **por instancia** del widget NO vive acá: usa un archivo propio, `widget_config`
(solo nativo), ver §7.

---

## 4. Lado Dart (Flutter)

### 4.1 `lib/src/core/data/widget_daily_total_sync.dart`
Único punto que escribe los datos del widget. Métodos:

- `syncTotal(double total)`: guarda el total de hoy + la fecha (`yyyy-MM-dd`) y pide refresh.
- `clearTotal()`: borra el total (ej. logout) y pide refresh.
- `syncFeaturedCategories(List<Category>)`: serializa hasta `kFeaturedCategoryCount` categorías
  a JSON y pide refresh. JSON: `[{"id":int,"name":string,"color":"#RRGGBB","icon":int}]`.
- `_refreshWidget()`: `MethodChannel('biyuya/widget').invokeMethod('refresh')`.

### 4.2 `lib/src/features/expenses/presentation/controllers/expense_controller.dart`
- `_emitExpenses(expenses)`: **único punto de salida** del estado de gastos. Además de setear el
  estado, calcula el total de hoy (`syncTotal`) y llama a `_syncFeaturedCategories`.
- `_syncFeaturedCategories(expenses)`: pide los ids más frecuentes a la calculadora, los resuelve
  contra `categoryControllerProvider` (las categorías cargadas) y los sincroniza. Si resuelve
  menos de 2, cae a **fallback**: las primeras `kFeaturedCategoryCount` categorías cargadas.
  Se invoca también desde `build()` con `ref.listen` cuando las categorías terminan de cargar
  (fix de **cold start**: si no, se escribiría una lista vacía).

### 4.3 `lib/src/features/expenses/domain/services/featured_categories_calculator.dart`
Función **pura** `topCategoryIdsLastWeek(expenses, now, {limit})`:
ventana inclusiva `now - 7 días <= date <= now`; ordena por **frecuencia DESC**, luego **fecha más
reciente DESC**, luego **id ASC**. Sin I/O → 100% testeable.

### 4.4 `lib/src/core/constants/app_constants.dart`
`const int kFeaturedCategoryCount = 4;` — fuente de verdad de la cantidad destacada en Dart.

### 4.5 Deep links (categoría preseleccionada)
- `lib/main.dart` → `_handleDeepLink(uri)`: valida `scheme=biyuya`, `host=expense`, `path=/new`.
  Lee `?categoryId=` y navega a `/expenses/new?categoryId=N`. Tiene **dedupe** de 800 ms
  (cold start puede entregar el mismo URI dos veces: `getInitialLink` + `uriLinkStream`).
  Guarda el target en `pendingDeepLinkProvider` antes de navegar.
- `lib/src/navigation/provider/router_provider.dart`:
  - `PendingDeepLink` (Riverpod `keepAlive`): guarda el target hasta que la sesión resuelva.
  - El `redirect` **consume** el pending cuando ya hay usuario + hogar → así el deep link
    **sobrevive el login/onboarding** (arregla el cold start que terminaba en Home).
  - La ruta `new` lee `state.uri.queryParameters['categoryId']` y lo pasa como `initialCategoryId`.

---

## 5. Lado Kotlin — `ExpenseWidget.kt` (`AppWidgetProvider`)

### 5.1 Ciclo de vida
- `onUpdate(...)`: lo llama Android cuando hay que (re)dibujar. Itera los ids y llama `renderWidget`.
- `onReceive(context, intent)`: **siempre** llama `super`. Además intercepta
  `ACTION_DATE_CHANGED`, `ACTION_TIME_CHANGED` (=`TIME_SET`), `ACTION_TIMEZONE_CHANGED` → `refreshAll()`.
  Esto es lo que dispara el **reset a medianoche**.
- `onDeleted(context, appWidgetIds)`: limpia la config por instancia (`WidgetConfigPrefs.clear`).
  > Firma real: **2 args** `(Context, IntArray)`. (Un intento con 3 args no compila.)

### 5.2 `renderWidget(context, appWidgetManager, appWidgetId)` — el corazón
1. Infla `R.layout.widget_expense` en un `RemoteViews`.
2. `loadDailyTotal()` → `formatCurrency()` → `setTextViewText(R.id.widget_amount, ...)`.
3. **Chips por instancia**: lee `WidgetConfigPrefs(context)`:
   - `chipLimit = showCategories(id) ? min(MAX_CHIPS, count(id)) : 0`.
   - `views.removeAllViews(R.id.widget_category_row)` (limpia) y agrega un chip por categoría.
4. Botón "+ Nuevo gasto": `setOnClickPendingIntent(R.id.widget_add_button, ...)`.
5. `appWidgetManager.updateAppWidget(appWidgetId, views)` (aplica los cambios atómicamente).

### 5.3 `loadDailyTotal()` — consistencia de "hoy"
Lee `flutter.widget_daily_date`. Si **coincide con hoy** devuelve el total; si no, **`0.0`**.
Por eso a las 00:00 (vía el broadcast de fecha) el widget muestra `$0`.
> Usa `SimpleDateFormat("yyyy-MM-dd", Locale.US)` en vez de `java.time.LocalDate`:
> esa API requiere **API 26** y `minSdk` es 24 → `NoClassDefFoundError` (que es `Error`, no `Exception`).
> El formato debe ser idéntico al que escribe Dart (`toIso8601String().substring(0,10)`).

### 5.4 `formatCurrency()` — moneda
`NumberFormat.getCurrencyInstance(Locale.forLanguageTag("es-AR"))` → `$1.234,56`.
`forLanguageTag` evita el constructor `Locale(String, String)` (deprecado) manteniendo el formato.

### 5.5 Chips: parseo, color, ícono
- `loadFeaturedCategories(context, limit)`: lee `flutter.widget_featured_categories` (JSON),
  parsea con `org.json.JSONArray` en try/catch → `[]` si falla. Descarta `id <= 0`,
  corta a `limit`.
- **Color de fondo**: `setColorStateList(id, "setBackgroundTintList", ColorStateList.valueOf(color))`
  en **API 31+**; en API < 31 cae a `setInt(..., "setBackgroundColor", color)` (pierde el
  redondeo — limitación de RemoteViews).
- **Ícono**: RemoteViews **no permite** `setTypeface` sobre un `TextView`. Por eso
  `renderIconBitmap()` dibuja el glifo con `Canvas`+`Paint` usando el font **MaterialIcons**
  (el mismo de Flutter) y lo pone en un `ImageView` con `setImageViewBitmap`.
  - Typeface cacheado (`@Volatile`), cargado de
    `assets/flutter_assets/fonts/MaterialIcons-Regular.otf` (el font que Flutter empaqueta en el APK).
  - Glifo: `String(Character.toChars(category.icon))`, tamaño `size * 0.62`.
  - **Fallback**: si no hay ícono o falla el typeface → inicial del nombre en `Typeface.DEFAULT_BOLD`.
- `setContentDescription(id, name)`: accesibilidad.

### 5.6 PendingIntents y deep links
- Cada chip: `Intent.ACTION_VIEW` con `data = biyuya://expense/new?categoryId=<id>`,
  `setClassName(..., "com.sdx.biyuya.DeepLinkHandlerActivity")`,
  flags `FLAG_ACTIVITY_NEW_TASK or FLAG_ACTIVITY_CLEAR_TOP`,
  `PendingIntent.getActivity(context, requestCode = index, ..., FLAG_UPDATE_CURRENT or FLAG_IMMUTABLE)`.
- Botón: mismo patrón con `data = biyuya://expense/new` y `requestCode = 100`.
- **requestCode distinto** por chip (índice) y por botón (100) para no pisarse.

---

## 6. `MainActivity.kt` y `DeepLinkHandlerActivity.kt`

- **`MainActivity`**:
  - Método `refresh` del `MethodChannel("biyuya/widget")` → `ExpenseWidget.refreshAll(this)`.
  - `override fun getInitialRoute(): String? = null`: evita que Flutter use el URI del
    `ACTION_VIEW` como initial route (rompía GoRouter y duplicaba navegación con `app_links`).
- **`DeepLinkHandlerActivity`**: recibe el `ACTION_VIEW` del widget y lo reenvía a `MainActivity`
  (con `data` intacto) y se cierra. Es un punto de entrada liviano para el deep link.
- **`flutter_deeplinking_enabled=false`** (meta-data en `MainActivity`): desactiva el deep linking
  nativo de Flutter para que **`app_links` sea el único handler**. Sin esto, el engine empujaba el
  URI crudo a GoRouter **y** `app_links` lo navegaba → `Duplicate GlobalKey` del shell.

---

## 7. Configuración por instancia (patrón `android:configure`)

Permite que **cada widget** en pantalla tenga su propia config (mostrar/ocultar y cantidad).

### Piezas
- **`expense_widget_info.xml`**:
  - `android:configure="com.sdx.biyuya.widget.WidgetConfigActivity"` → Android abre esa Activity
    al agregar el widget.
  - `android:widgetFeatures="reconfigurable"` → habilita "Reconfigurar" (long-press) en Android 9+.
- **`WidgetConfigActivity.kt`** (Activity nativa, tema diálogo):
  - Obtiene `appWidgetId` de `AppWidgetManager.EXTRA_APPWIDGET_ID`.
  - Arranca con `setResult(RESULT_CANCELED)`: si el usuario cancela/atrás, **el widget no se agrega**.
  - Carga valores actuales, y al "Guardar": `prefs.save(...)` + `refreshAll()` +
    `setResult(RESULT_OK, Intent().putExtra(EXTRA_APPWIDGET_ID, appWidgetId))` + `finish()`.
    La `EXTRA_APPWIDGET_ID` en el result es **obligatoria** para que el widget quede colocado.
- **`WidgetConfigPrefs.kt`** — prefs propias (`widget_config`, solo nativo, por `appWidgetId`):
  - `show_categories_<id>` (bool, default `true`)
  - `count_<id>` (int, default `DEFAULT_COUNT=4`, clamps `1..MAX_COUNT` con `MAX_COUNT=4`)
  - `clear(ids)` desde `onDeleted`.
- **`AndroidManifest.xml`**: la Activity exportada con
  `<intent-filter><action android:name="android.appwidget.action.APPWIDGET_CONFIGURE"/></intent-filter>`.
- **`ExpenseWidget.renderWidget`** lee la config por id (ver §5.2).

---

## 8. Layouts y drawables

| Archivo | Qué es |
|---|---|
| `res/layout/widget_expense.xml` | Layout principal del widget: fila superior (label + monto + botón "+ Nuevo gasto") y fila de chips dinámica (`widget_category_row`). Fondo `widget_background`. |
| `res/layout/widget_category_chip.xml` | Un chip: `FrameLayout` 40dp (fondo `widget_button_bg`) + `ImageView` 24dp centrado para el ícono. |
| `res/layout/widget_config.xml` | Pantalla de config: `Switch` + `RadioGroup` (1–4) + botón "Guardar". |
| `res/drawable/widget_background.xml` | Fondo redondeado verde oscuro (`#0F2D18`, radio 24dp). |
| `res/drawable/widget_button_bg.xml` | Fondo redondeado verde (`#2E7D32`, radio 16dp) con ripple. Usado por botón y chips. |
| `res/drawable/ic_add.xml` | Vector "+" (quedó sin uso tras mover el botón a texto). |
| `res/xml/expense_widget_info.xml` | Metadatos del widget (tamaño, `updatePeriodMillis`, configure, etc.). |

---

## 9. Disparadores de actualización

| Evento | Qué dispara |
|---|---|
| El usuario abre la app / carga gastos | Dart `syncTotal` + `syncFeaturedCategories` → MethodChannel `refresh` → `refreshAll` |
| Android: `APPWIDGET_UPDATE` | `onUpdate` (cada `updatePeriodMillis` = **30 min**) |
| Medianoche / cambio de hora / timezone | `onReceive` de `DATE_CHANGED`/`TIME_SET`/`TIMEZONE_CHANGED` → `refreshAll` (total vuelve a `$0`) |
| Guardar en la pantalla de config | `refreshAll` |
| Se borra el widget | `onDeleted` limpia prefs |

---

## 10. Constantes y cómo cambiar cosas

| Qué | Dónde | Nota |
|---|---|---|
| Cantidad destacada (Dart) | `kFeaturedCategoryCount` (`app_constants.dart`) | Se escribe al JSON del widget |
| Tope de chips (Kotlin) | `MAX_CHIPS` (`ExpenseWidget.kt`) | `// keep in sync with kFeaturedCategoryCount` |
| Tope por instancia (Kotlin) | `WidgetConfigPrefs.MAX_COUNT` | Clamp 1..4 |
| Default por instancia | `WidgetConfigPrefs.DEFAULT_COUNT` | 4 |
| Intervalo de update | `updatePeriodMillis` (`expense_widget_info.xml`) | Mínimo Android = 30 min |

> Para mostrar **más** de 4 categorías: subí `kFeaturedCategoryCount` **y** `MAX_CHIPS`
> **y** `MAX_COUNT`. Ojo con el ancho del widget (`targetCellWidth`): los chips se clipean.

---

## 11. Gotchas / decisiones

- **API 24-safe**: nada de `java.time` (API 26). Se usa `SimpleDateFormat`.
- **RemoteViews es limitado**: no hay `setTypeface`, ni `ScrollView`, ni custom views.
  Por eso los íconos se dibujan como `Bitmap`.
- **Color de chips**: `setBackgroundTintList` solo API 31+; fallback pierde el redondeo.
- **Deep link doble**: por eso `flutter_deeplinking_enabled=false` + dedupe 800 ms + pending deep link.
- **Cold start del deep link**: el redirect de GoRouter manda a splash mientras la sesión está
  `loading`; `pendingDeepLinkProvider` reemite el target al resolverse.
- **requestCode** de PendingIntents único para evitar colisiones.
- **Firma de `onDeleted`**: `(Context, IntArray)` (2 args).

---

## 12. Cómo probar manualmente

1. Build + instalar el APK debug.
2. Agregar el widget al home → debe abrir `WidgetConfigActivity`.
3. Probar: ocultar categorías → Guardar; reconfigurar (long-press) → mostrar 2 → Guardar.
4. Cargar 3–4 gastos en categorías distintas en la app → reabrir → los chips se actualizan.
5. Tocar un chip → abre el form con esa categoría preseleccionada.
6. Tocar "+ Nuevo gasto" → abre el form sin categoría.
7. Cambiar la fecha del dispositivo a mañana → el total vuelve a `$0`.
8. Borrar el widget: verificar que se limpió `widget_config`:
   `adb shell run-as com.sdx.biyuya cat /data/data/com.sdx.biyuya/shared_prefs/widget_config.xml`
