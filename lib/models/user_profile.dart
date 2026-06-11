class UserProfile {
  final String name;
  final String baseCurrency;
  final double monthlySavingsGoal;
  final bool isPrivateMode;
  final bool onboardingComplete;

  const UserProfile({
    required this.name,
    this.baseCurrency = 'USD',
    this.monthlySavingsGoal = 500.0,
    this.isPrivateMode = false,
    this.onboardingComplete = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'baseCurrency': baseCurrency,
    'monthlySavingsGoal': monthlySavingsGoal,
    'isPrivateMode': isPrivateMode,
    'onboardingComplete': onboardingComplete,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] ?? '',
    baseCurrency: json['baseCurrency'] ?? 'USD',
    monthlySavingsGoal: (json['monthlySavingsGoal'] ?? 500.0).toDouble(),
    isPrivateMode: json['isPrivateMode'] ?? false,
    onboardingComplete: json['onboardingComplete'] ?? false,
  );

  UserProfile copyWith({
    String? name,
    String? baseCurrency,
    double? monthlySavingsGoal,
    bool? isPrivateMode,
    bool? onboardingComplete,
  }) => UserProfile(
    name: name ?? this.name,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    monthlySavingsGoal: monthlySavingsGoal ?? this.monthlySavingsGoal,
    isPrivateMode: isPrivateMode ?? this.isPrivateMode,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
  );
}
