/// Parameters passed from the native expense widget via deep link.
/// Used to pre-fill the expense form when opened from the widget.
class ExpenseDeepLinkParams {
  const ExpenseDeepLinkParams({
    this.amount,
    this.categoryId,
    this.autoSubmit = true,
  });

  /// Parse from URI query parameters.
  /// Example: biyuya://expense/new?amount=1250&category_id=3
  factory ExpenseDeepLinkParams.fromUri(Uri uri) {
    final amountParam = uri.queryParameters['amount'];
    final categoryIdParam = uri.queryParameters['category_id'];

    return ExpenseDeepLinkParams(
      amount: amountParam != null ? double.tryParse(amountParam) : null,
      categoryId: categoryIdParam != null
          ? int.tryParse(categoryIdParam)
          : null,
    );
  }

  final double? amount;
  final int? categoryId;
  final bool autoSubmit;

  bool get hasData => amount != null || categoryId != null;
}
