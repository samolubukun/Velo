import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/transaction_record.dart';

class FinanceHealthService {
  static final FinanceHealthService instance = FinanceHealthService._();
  FinanceHealthService._();

  /// Calculates the savings percentage: ((Income - Expenses) / Income) * 100
  double calculateSavingsPercentage(double income, double expenses) {
    if (income <= 0) return 0.0;
    final pct = ((income - expenses) / income) * 100;
    return pct < 0 ? 0.0 : pct;
  }

  /// Calculates the survival index: total assets / average monthly expenses
  double calculateSurvivalIndex(List<Account> accounts, List<TransactionRecord> transactions) {
    // 1. Total assets is the sum of account values
    double totalAssets = accounts.fold(0.0, (sum, acc) => sum + acc.currentValue);
    if (totalAssets < 0) totalAssets = 0.0;

    // 2. Average monthly expenses
    final expensesList = transactions.where((t) => t.type == TransactionType.expense).toList();
    if (expensesList.isEmpty) return 99.0; // Infinite survival

    // Group expenses by year-month to find number of months
    final months = expensesList.map((e) => '${e.date.year}-${e.date.month}').toSet();
    final monthsCount = months.isEmpty ? 1 : months.length;

    double totalExpenses = expensesList.fold(0.0, (sum, t) => sum + t.value);
    double avgMonthlyExpenses = totalExpenses / monthsCount;

    if (avgMonthlyExpenses <= 0) return 99.0;

    return totalAssets / avgMonthlyExpenses;
  }

  /// Calculates a weighted financial healthy score from 0 to 100
  /// 50% Savings Rate weight, 50% Survival Index weight
  double calculateWeightedHealthScore(double savingsPercentage, double survivalIndex) {
    // Savings percentage score: 0% to 50% target maps to 0 to 100
    double savingsScore = savingsPercentage * 2.0;
    if (savingsScore > 100) savingsScore = 100.0;
    if (savingsScore < 0) savingsScore = 0.0;

    // Survival index score: 0 to 6 months maps to 0 to 100
    double survivalScore = survivalIndex * (100.0 / 6.0);
    if (survivalScore > 100) survivalScore = 100.0;
    if (survivalScore < 0) survivalScore = 0.0;

    return (0.5 * savingsScore) + (0.5 * survivalScore);
  }

  /// Returns a Color dynamically mapped from red (0, low score) to green (120, high score) using HSL
  Color getHealthColor(double score) {
    final clamped = score.clamp(0.0, 100.0);
    // Hue from 0 (Red) to 120 (Green)
    final hue = clamped * 1.2; 
    return HSLColor.fromAHSL(1.0, hue, 0.85, 0.45).toColor();
  }
}
