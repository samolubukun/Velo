

enum TransactionType { expense, income, transfer }
enum TransactionStatus { voided, pending, reconciled, unreconciled }

class LocationData {
  final double latitude;
  final double longitude;
  final String address;

  const LocationData({
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.address = '',
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
  };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    latitude: (json['latitude'] ?? 0.0).toDouble(),
    longitude: (json['longitude'] ?? 0.0).toDouble(),
    address: json['address'] ?? '',
  );
}

class RecurrencyRule {
  final String periodicity; // 'daily', 'weekly', 'monthly', 'yearly'
  final int intervalCount;
  final int remainingOccurrences;

  const RecurrencyRule({
    this.periodicity = 'monthly',
    this.intervalCount = 1,
    this.remainingOccurrences = 0,
  });

  Map<String, dynamic> toJson() => {
    'periodicity': periodicity,
    'intervalCount': intervalCount,
    'remainingOccurrences': remainingOccurrences,
  };

  factory RecurrencyRule.fromJson(Map<String, dynamic> json) => RecurrencyRule(
    periodicity: json['periodicity'] ?? 'monthly',
    intervalCount: json['intervalCount'] ?? 1,
    remainingOccurrences: json['remainingOccurrences'] ?? 0,
  );
}

class Category {
  final String id;
  final String name;
  final String type; // 'E' (expense), 'I' (income), 'B' (balance/both)
  final int colorValue;
  final String iconName;
  final String? parentId;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.colorValue = 0xFFC87D55,
    this.iconName = 'payment',
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'colorValue': colorValue,
    'iconName': iconName,
    'parentId': parentId,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    type: json['type'] ?? 'E',
    colorValue: json['colorValue'] ?? 0xFFC87D55,
    iconName: json['iconName'] ?? 'payment',
    parentId: json['parentId'],
  );
}

class TransactionRecord {
  final String id;
  final double value;
  final String title;
  final String notes;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime date;
  final String categoryId;
  final String accountId;
  final String? targetAccountId; // used for transfers
  final List<String> tagIds;
  final String imagePath; // Receipt image if scanned
  final LocationData location;
  final RecurrencyRule recurrency;

  const TransactionRecord({
    required this.id,
    required this.value,
    required this.title,
    this.notes = '',
    required this.type,
    this.status = TransactionStatus.reconciled,
    required this.date,
    required this.categoryId,
    required this.accountId,
    this.targetAccountId,
    this.tagIds = const [],
    this.imagePath = '',
    this.location = const LocationData(),
    this.recurrency = const RecurrencyRule(),
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'value': value,
    'title': title,
    'notes': notes,
    'type': type.name,
    'status': status.name,
    'date': date.toIso8601String(),
    'categoryId': categoryId,
    'accountId': accountId,
    'targetAccountId': targetAccountId,
    'tagIds': tagIds,
    'imagePath': imagePath,
    'location': location.toJson(),
    'recurrency': recurrency.toJson(),
  };

  factory TransactionRecord.fromJson(Map<String, dynamic> json) => TransactionRecord(
    id: json['id'] ?? '',
    value: (json['value'] ?? 0.0).toDouble(),
    title: json['title'] ?? '',
    notes: json['notes'] ?? '',
    type: TransactionType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => TransactionType.expense,
    ),
    status: TransactionStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => TransactionStatus.reconciled,
    ),
    date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    categoryId: json['categoryId'] ?? '',
    accountId: json['accountId'] ?? '',
    targetAccountId: json['targetAccountId'],
    tagIds: List<String>.from(json['tagIds'] ?? []),
    imagePath: json['imagePath'] ?? '',
    location: json['location'] != null
        ? LocationData.fromJson(json['location'])
        : const LocationData(),
    recurrency: json['recurrency'] != null
        ? RecurrencyRule.fromJson(json['recurrency'])
        : const RecurrencyRule(),
  );

  TransactionRecord copyWith({
    String? id,
    double? value,
    String? title,
    String? notes,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? date,
    String? categoryId,
    String? accountId,
    String? targetAccountId,
    List<String>? tagIds,
    String? imagePath,
    LocationData? location,
    RecurrencyRule? recurrency,
  }) => TransactionRecord(
    id: id ?? this.id,
    value: value ?? this.value,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    type: type ?? this.type,
    status: status ?? this.status,
    date: date ?? this.date,
    categoryId: categoryId ?? this.categoryId,
    accountId: accountId ?? this.accountId,
    targetAccountId: targetAccountId ?? this.targetAccountId,
    tagIds: tagIds ?? this.tagIds,
    imagePath: imagePath ?? this.imagePath,
    location: location ?? this.location,
    recurrency: recurrency ?? this.recurrency,
  );
}
