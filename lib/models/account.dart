class Account {
  final String id;
  final String name;
  final double initialValue;
  final double currentValue;
  final String type; // 'normal' or 'saving'
  final String currency;
  final int colorValue; // ARGB representation
  final String iban;
  final String swift;

  const Account({
    required this.id,
    required this.name,
    required this.initialValue,
    required this.currentValue,
    required this.type,
    this.currency = 'USD',
    this.colorValue = 0xFFC87D55,
    this.iban = '',
    this.swift = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'initialValue': initialValue,
    'currentValue': currentValue,
    'type': type,
    'currency': currency,
    'colorValue': colorValue,
    'iban': iban,
    'swift': swift,
  };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    initialValue: (json['initialValue'] ?? 0.0).toDouble(),
    currentValue: (json['currentValue'] ?? 0.0).toDouble(),
    type: json['type'] ?? 'normal',
    currency: json['currency'] ?? 'USD',
    colorValue: json['colorValue'] ?? 0xFFC87D55,
    iban: json['iban'] ?? '',
    swift: json['swift'] ?? '',
  );

  Account copyWith({
    String? id,
    String? name,
    double? initialValue,
    double? currentValue,
    String? type,
    String? currency,
    int? colorValue,
    String? iban,
    String? swift,
  }) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    initialValue: initialValue ?? this.initialValue,
    currentValue: currentValue ?? this.currentValue,
    type: type ?? this.type,
    currency: currency ?? this.currency,
    colorValue: colorValue ?? this.colorValue,
    iban: iban ?? this.iban,
    swift: swift ?? this.swift,
  );
}
