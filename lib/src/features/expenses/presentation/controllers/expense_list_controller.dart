import 'dart:async';

import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/provider/expense_repository_provider.dart';
import 'package:biyuya/src/features/expenses/provider/expense_sync_providers.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expense_list_controller.g.dart';

/// Estado de la lista paginada de gastos.
class ExpenseListState extends Equatable {
  const ExpenseListState({
    this.items = const <Expense>[],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.error,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.userUuid,
    this.offset = 0,
  });

  /// Gastos cargados: pendientes del outbox primero, luego las páginas.
  final List<Expense> items;

  /// true mientras el servidor pueda tener otra página (fila completa leída).
  final bool hasMore;

  /// true mientras se busca la siguiente página (spinner de fin de lista).
  final bool isLoadingMore;

  /// Último fallo de carga; null cuando no hay error.
  final Object? error;

  /// Filtro server-side: categoría (null = sin filtro).
  final int? categoryId;

  /// Filtro server-side: inicio del rango de fechas (null = sin filtro).
  final DateTime? startDate;

  /// Filtro server-side: fin del rango de fechas, inclusivo (null = sin filtro).
  final DateTime? endDate;

  /// Filtro server-side: uuid del miembro (null = sin filtro).
  final String? userUuid;

  /// Offset de la siguiente página a pedir al servidor.
  final int offset;

  ExpenseListState copyWith({
    List<Expense>? items,
    bool? hasMore,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? userUuid,
    int? offset,
    bool clearCategory = false,
    bool clearDates = false,
    bool clearUser = false,
  }) {
    return ExpenseListState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      // `clear*` gana sobre el valor: así se puede quitar un filtro.
      error: clearError ? null : (error ?? this.error),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      userUuid: clearUser ? null : (userUuid ?? this.userUuid),
      offset: offset ?? this.offset,
    );
  }

  @override
  List<Object?> get props => [
    items,
    hasMore,
    isLoadingMore,
    error,
    categoryId,
    startDate,
    endDate,
    userUuid,
    offset,
  ];
}

/// Lista de gastos con paginación server-side.
///
/// La primera carga (o la posterior a [refresh]/[setFilters]) trae la página 0
/// y antepone los gastos pendientes del outbox, para que lo capturado offline
/// se vea aunque todavía no esté en el servidor. [loadMore] anexa la página
/// siguiente hasta que `hasMore` queda en false.
@Riverpod(keepAlive: true)
class ExpenseListController extends _$ExpenseListController {
  /// Filas por página (server-side).
  static const pageSize = 30;

  bool _loading = false;
  // Invalida respuestas en vuelo: refresh()/setFilters() lo incrementan y una
  // respuesta de un epoch anterior se descarta (evita anexar páginas viejas a
  // una lista ya reiniciada).
  int _epoch = 0;

  @override
  ExpenseListState build() {
    // Estado nuevo en cada build: invalidate resetea filtros y paginación.
    // Solo `_loading` vive fuera del estado (guard de carga en vuelo).
    _loading = false;

    // Sesión que llega después del arranque en frío (o cambio de household):
    // recién ahí hay householdId con el cual cargar.
    ref.listen(authSessionControllerProvider, (previous, next) {
      if (next.value?.householdId != previous?.value?.householdId) {
        unawaited(refresh());
      }
    });
    unawaited(Future.microtask(refresh));
    return const ExpenseListState();
  }

  /// Reinicia la paginación (offset 0, `hasMore` false) y carga la primera
  /// página con los filtros actuales. Sin household en la sesión => estado
  /// vacío.
  Future<void> refresh() async {
    _epoch += 1;
    final epoch = _epoch;
    state = state.copyWith(offset: 0, hasMore: false, isLoadingMore: false);

    final householdId = _householdId();
    if (householdId == null) {
      _loading = false;
      state = state.copyWith(items: const <Expense>[], clearError: true);
      return;
    }

    _loading = true;
    state = state.copyWith(clearError: true);

    final pending = await ref.read(pendingExpenseStoreProvider).load();
    if (epoch != _epoch) {
      return;
    }

    final result = await ref
        .read(expenseRepositoryProvider)
        .getExpensesPage(
          householdId: householdId,
          limit: pageSize,
          offset: 0,
          categoryId: state.categoryId,
          startDate: state.startDate,
          endDate: state.endDate,
          userUuid: state.userUuid,
        );
    if (epoch != _epoch) {
      return;
    }
    _loading = false;

    result.when(
      (page) {
        state = state.copyWith(
          items: _mergePending(pending, page),
          hasMore: page.length == pageSize,
          offset: page.length,
          isLoadingMore: false,
          clearError: true,
        );
      },
      (failure) {
        state = state.copyWith(error: failure, isLoadingMore: false);
      },
    );
  }

  /// Carga la siguiente página y la anexa al final.
  /// No-op si hay una carga en vuelo o no quedan páginas.
  Future<void> loadMore() async {
    if (_loading || !state.hasMore) {
      return;
    }
    final epoch = _epoch;
    _loading = true;
    state = state.copyWith(isLoadingMore: true);

    final householdId = _householdId();
    if (householdId == null) {
      _loading = false;
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    final result = await ref
        .read(expenseRepositoryProvider)
        .getExpensesPage(
          householdId: householdId,
          limit: pageSize,
          offset: state.offset,
          categoryId: state.categoryId,
          startDate: state.startDate,
          endDate: state.endDate,
          userUuid: state.userUuid,
        );
    if (epoch != _epoch) {
      // refresh()/setFilters() reiniciaron la lista: esta página ya no aplica.
      return;
    }
    _loading = false;

    result.when(
      (page) {
        state = state.copyWith(
          items: [...state.items, ...page],
          hasMore: page.length == pageSize,
          offset: state.offset + page.length,
          isLoadingMore: false,
        );
      },
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure);
      },
    );
  }

  /// Actualiza los filtros server-side y recarga desde la página 0.
  ///
  /// Un valor no-nulo reemplaza el filtro; `null` lo deja intacto. Para quitar
  /// un filtro hay que indicarlo con su flag `clear*`:
  ///
  /// - `setFilters(categoryId: 5)` solo cambia la categoría.
  /// - `setFilters(startDate: a, endDate: b)` cambia el rango de fechas.
  /// - `setFilters(clearDates: true)` quita el rango de fechas.
  /// - `setFilters(clearCategory: true, userUuid: u)` quita categoría y pone
  ///   el filtro de usuario.
  Future<void> setFilters({
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? userUuid,
    bool clearCategory = false,
    bool clearDates = false,
    bool clearUser = false,
  }) async {
    state = state.copyWith(
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      userUuid: userUuid,
      clearCategory: clearCategory,
      clearDates: clearDates,
      clearUser: clearUser,
    );
    await refresh();
  }

  /// Quita todos los filtros y recarga la primera página.
  Future<void> clearFilters() {
    return setFilters(clearCategory: true, clearDates: true, clearUser: true);
  }

  /// householdId de la sesión; null si no hay sesión/household (lista vacía).
  int? _householdId() {
    final householdId = ref
        .read(authSessionControllerProvider)
        .value
        ?.householdId;
    if (householdId == null || householdId.isEmpty) {
      return null;
    }
    return int.parse(householdId);
  }

  /// Pendientes (outbox) primero + página del servidor, sin duplicar filas que
  /// ya están en el outbox por `clientId`.
  /// ponytail: los pendientes no pasan por los filtros — mismo criterio que
  /// `ExpenseController._merge`, para que lo offline nunca desaparezca.
  List<Expense> _mergePending(List<Expense> pending, List<Expense> page) {
    final pendingClientIds = pending
        .map((e) => e.clientId)
        .whereType<String>()
        .toSet();
    final synced = page
        .where((e) => !pendingClientIds.contains(e.clientId))
        .toList();
    return [...pending, ...synced];
  }
}
