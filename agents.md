# Biyuya — AI Assistant Guide

## 1. Project Overview

- **Platform:** Flutter Mobile (Android/iOS)
- **Backend:** Supabase (NOT Dio/REST API)
- **State:** Riverpod 3.x with `@riverpod` code generation
- **Architecture:** Clean Architecture (feature-first)

## 2. Key Clarifications

### HTTP Client: Supabase (NOT Dio)

The project uses `supabase_flutter`. Do not reach for Dio.

- Repository implementations use `SupabaseClient`, not `Dio`
- Error type is `supabase.AuthException`, not `DioException`
- No `CancelToken` pattern — Supabase handles cancellation differently
- All HTTP/data access goes through Supabase SDK methods

### State Management

- Riverpod with `@riverpod` annotations (code generation)
- `AsyncValue<T>` for async state — no manual loading flags
- `keepAlive: true` ONLY for global state (auth session)
- Auto-dispose for all feature-scoped state

### Navigation

- GoRouter with Riverpod integration
- Abstract `NavigatorBase` interface for testability
- Redirect logic handles auth flow (unauthenticated → login)

### Error Handling

- `multiple_result` package — `Result<T, Failure>` pattern
- Typed failures per feature (e.g., `AuthFailure`, `ProfileFailure`)
- Catch exceptions at repository boundary, wrap in typed Failure
- Controllers never catch — they propagate Result to UI

### Testing

- `mocktail` for mocking (dev dependency)
- Test repositories with mocked `SupabaseClient`
- Test widgets with `ProviderScope` overrides
- Test controllers with overridden providers

## 3. File Structure

```
lib/src/
├── core/
│   ├── data/models/      # Models extending entities
│   ├── domain/entities/  # Pure business entities (Equatable)
│   └── ...
├── features/
│   └── [feature]/
│       ├── data/repositories/  # Repository implementations
│       ├── domain/
│       │   ├── entities/       # Feature entities
│       │   ├── models/         # Feature models
│       │   └── repositories/   # Abstract repository interfaces
│       └── presentation/
│           ├── controllers/    # Riverpod notifiers
│           └── views/          # UI screens
└── navigation/
    ├── data/services/    # GoRouterNavigator
    ├── domain/service/   # NavigatorBase
    └── provider/         # Router provider
```

## 4. Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files | `snake_case.dart` | `auth_repository_impl.dart` |
| Classes | `PascalCase` | `AuthRepositoryImpl` |
| Providers | `camelCaseProvider` (generated) | `authProvider` |
| Repository interfaces | `<Feature>RepositoryBase` | `AuthRepositoryBase` |
| Repository implementations | `<Feature>RepositoryImpl` | `AuthRepositoryImpl` |

## 5. Common Patterns

### Entity/Model Pattern

- **Entity:** pure business object, extends `Equatable`, no serialization
- **Model:** extends entity, adds `fromJson`/`toJson`
- JSON keys: `snake_case` (API) → `camelCase` (Dart fields)

### Repository Pattern

- Interface in `domain/repositories/` — returns `Result<T, Failure>`
- Implementation in `data/repositories/` — catches exceptions, wraps in Failure
- Controllers call repository, pattern-match on Result

### Provider Pattern

- Simple dependencies: functional providers (`@riverpod` on a function)
- Complex state: class-based notifiers with `AsyncNotifier`/`Notifier`
- Global state: `@Riverpod(keepAlive: true)`
- Feature state: `@riverpod` (auto-dispose, default)
