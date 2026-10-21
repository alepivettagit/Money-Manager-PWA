import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';

class AccountProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Account> _accounts = [];
  Account? _selectedAccount;
  bool _isLoading = true;

  List<Account> get accounts => _accounts;
  Account? get selectedAccount => _selectedAccount;
  bool get isLoading => _isLoading;

  Future<void> loadAccounts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _accounts = await _dbHelper.getAccounts();
      if (_accounts.isNotEmpty && _selectedAccount == null) {
        _selectedAccount = _accounts.first;
      } else if (_accounts.isNotEmpty && _selectedAccount != null) {
        final found = _accounts.where((a) => a.id == _selectedAccount!.id);
        if (found.isNotEmpty) {
          _selectedAccount = found.first;
        } else {
          _selectedAccount = _accounts.first;
        }
      } else {
        _selectedAccount = null;
      }
    } catch (e) {
      debugPrint('Errore caricamento account da Firestore: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectAccount(Account account) {
    _selectedAccount = account;
    notifyListeners();
  }

  Future<Account> createAccount(String name, double initialBalance) async {
    final newAccount = Account(
      id: const Uuid().v4(),
      name: name,
      initialBalance: initialBalance,
      createdAt: DateTime.now(),
    );
    await _dbHelper.insertAccount(newAccount);
    _accounts.add(newAccount);
    _selectedAccount = newAccount;
    notifyListeners();
    return newAccount;
  }

  Future<void> deleteAccount(String accountId) async {
    await _dbHelper.deleteAccount(accountId);
    _accounts.removeWhere((a) => a.id == accountId);
    if (_selectedAccount?.id == accountId) {
      _selectedAccount = _accounts.isNotEmpty ? _accounts.first : null;
    }
    notifyListeners();
  }

  void clear() {
    _accounts = [];
    _selectedAccount = null;
    _isLoading = false;
    notifyListeners();
  }

  double calculateCurrentBalance(
    Account account,
    List<Transaction> transactions,
  ) {
    final totalIncome = transactions
        .where(
          (t) => t.accountId == account.id && t.type == TransactionType.income,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = transactions
        .where(
          (t) => t.accountId == account.id && t.type == TransactionType.expense,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    return account.initialBalance + totalIncome - totalExpense;
  }
}
