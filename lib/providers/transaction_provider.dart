import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/database_helper.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _currentAccountId;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get currentAccountId => _currentAccountId;

  Future<void> loadTransactions(String accountId) async {
    _currentAccountId = accountId;
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _dbHelper.getTransactionsByAccount(accountId);
    } catch (e) {
      debugPrint('Errore caricamento transazioni da Firestore: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction tx) async {
    await _dbHelper.insertTransaction(tx);
    if (tx.accountId == _currentAccountId) {
      _transactions.insert(0, tx);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  Future<void> updateTransaction(Transaction tx) async {
    await _dbHelper.updateTransaction(tx);
    final index = _transactions.indexWhere((t) => t.id == tx.id);
    if (index != -1) {
      _transactions[index] = tx;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _dbHelper.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void clear() {
    _transactions = [];
    _currentAccountId = null;
    _isLoading = false;
    notifyListeners();
  }

  // --- FILTRI E CALCOLI ---
  List<Transaction> getTransactionsForDay(DateTime day) {
    return _transactions.where((t) {
      return t.date.year == day.year &&
          t.date.month == day.month &&
          t.date.day == day.day;
    }).toList();
  }

  List<Transaction> getTransactionsForMonth(DateTime month) {
    return _transactions.where((t) {
      return t.date.year == month.year && t.date.month == month.month;
    }).toList();
  }

  double getTotalIncomeForMonth(DateTime month) {
    return getTransactionsForMonth(month)
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenseForMonth(DateTime month) {
    return getTransactionsForMonth(month)
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getNetSavingsForMonth(DateTime month) {
    return getTotalIncomeForMonth(month) - getTotalExpenseForMonth(month);
  }

  Map<String, double> getExpenseCategoriesForMonth(DateTime month) {
    final expenses = getTransactionsForMonth(month)
        .where((t) => t.type == TransactionType.expense);
    final Map<String, double> totals = {};
    for (final exp in expenses) {
      totals[exp.category] = (totals[exp.category] ?? 0.0) + exp.amount;
    }
    return totals;
  }
}
