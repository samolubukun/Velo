import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/account.dart';
import '../services/local_db_service.dart';

class OnboardingViewModel extends ChangeNotifier {
  final LocalDbService _db;
  int _currentStep = 0;
  String _name = '';
  String _baseCurrency = 'USD';
  double _monthlySavingsGoal = 500.0;
  String _initialAccountName = 'Current Account';
  double _initialAccountBalance = 1000.0;

  OnboardingViewModel(this._db);

  int get currentStep => _currentStep;
  String get name => _name;
  String get baseCurrency => _baseCurrency;
  double get monthlySavingsGoal => _monthlySavingsGoal;
  String get initialAccountName => _initialAccountName;
  double get initialAccountBalance => _initialAccountBalance;
  int get totalSteps => 4;

  void setName(String v) { _name = v; notifyListeners(); }
  void setBaseCurrency(String v) { _baseCurrency = v; notifyListeners(); }
  void setMonthlySavingsGoal(double v) { _monthlySavingsGoal = v; notifyListeners(); }
  void setInitialAccountName(String v) { _initialAccountName = v; notifyListeners(); }
  void setInitialAccountBalance(double v) { _initialAccountBalance = v; notifyListeners(); }

  void setStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    // 1. Save User Profile
    final profile = UserProfile(
      name: _name,
      baseCurrency: _baseCurrency,
      monthlySavingsGoal: _monthlySavingsGoal,
      isPrivateMode: false,
      onboardingComplete: true,
    );
    await _db.saveProfile(profile);

    // 2. Initialize Seed Databases (categories, exchange rates)
    await _db.initializeDatabase();

    // 3. Save Initial Account
    final newAccount = Account(
      id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
      name: _initialAccountName.trim().isEmpty ? 'Current Account' : _initialAccountName.trim(),
      initialValue: _initialAccountBalance,
      currentValue: _initialAccountBalance,
      type: 'normal',
      currency: _baseCurrency,
    );
    await _db.saveAccount(newAccount);
  }
}
