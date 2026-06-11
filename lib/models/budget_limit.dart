class BudgetLimit {
  final String id;
  final String title;
  final double limitAmount;
  final double currentAmount;
  final bool isRecurring;
  final String period; // 'daily', 'weekly', 'monthly', 'yearly'
  final List<String> categoryIds; // Scoped categories
  final List<String> accountIds;  // Scoped accounts

  const BudgetLimit({
    required this.id,
    required this.title,
    required this.limitAmount,
    required this.currentAmount,
    this.isRecurring = true,
    this.period = 'monthly',
    this.categoryIds = const [],
    this.accountIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'limitAmount': limitAmount,
    'currentAmount': currentAmount,
    'isRecurring': isRecurring,
    'period': period,
    'categoryIds': categoryIds,
    'accountIds': accountIds,
  };

  factory BudgetLimit.fromJson(Map<String, dynamic> json) => BudgetLimit(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    limitAmount: (json['limitAmount'] ?? 0.0).toDouble(),
    currentAmount: (json['currentAmount'] ?? 0.0).toDouble(),
    isRecurring: json['isRecurring'] ?? true,
    period: json['period'] ?? 'monthly',
    categoryIds: List<String>.from(json['categoryIds'] ?? []),
    accountIds: List<String>.from(json['accountIds'] ?? []),
  );

  BudgetLimit copyWith({
    String? id,
    String? title,
    double? limitAmount,
    double? currentAmount,
    bool? isRecurring,
    String? period,
    List<String>? categoryIds,
    List<String>? accountIds,
  }) => BudgetLimit(
    id: id ?? this.id,
    title: title ?? this.title,
    limitAmount: limitAmount ?? this.limitAmount,
    currentAmount: currentAmount ?? this.currentAmount,
    isRecurring: isRecurring ?? this.isRecurring,
    period: period ?? this.period,
    categoryIds: categoryIds ?? this.categoryIds,
    accountIds: accountIds ?? this.accountIds,
  );
}
