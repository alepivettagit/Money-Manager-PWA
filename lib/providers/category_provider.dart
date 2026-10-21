import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/transaction.dart';

class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CategoryItem> _expenseCategories = List.from(
    TransactionCategories.expenseCategories,
  );
  List<CategoryItem> _incomeCategories = List.from(
    TransactionCategories.incomeCategories,
  );
  bool _isLoading = false;
  String? _loadedUid;

  List<CategoryItem> get expenseCategories =>
      List.unmodifiable(_expenseCategories);
  List<CategoryItem> get incomeCategories =>
      List.unmodifiable(_incomeCategories);
  bool get isLoading => _isLoading;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? _categoriesDoc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('categories');
  }

  Future<void> loadCategories({bool forceRefresh = false}) async {
    final uid = _currentUid;
    if (uid == null) {
      _expenseCategories = List.from(TransactionCategories.expenseCategories);
      _incomeCategories = List.from(TransactionCategories.incomeCategories);
      _loadedUid = null;
      notifyListeners();
      return;
    }

    if (!forceRefresh && _loadedUid == uid) return;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _categoriesDoc(uid)!.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['expenses'] is List) {
          final expList = (data['expenses'] as List)
              .map(
                (e) =>
                    CategoryItem.fromMap(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
          if (expList.isNotEmpty) {
            _expenseCategories = expList;
          }
        }
        if (data['incomes'] is List) {
          final incList = (data['incomes'] as List)
              .map(
                (e) =>
                    CategoryItem.fromMap(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
          if (incList.isNotEmpty) {
            _incomeCategories = incList;
          }
        }
      }
      _loadedUid = uid;
    } catch (e) {
      debugPrint('Errore caricamento categorie da Firestore: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToFirestore() async {
    final uid = _currentUid;
    if (uid == null) return;

    try {
      await _categoriesDoc(uid)!.set({
        'expenses': _expenseCategories.map((c) => c.toMap()).toList(),
        'incomes': _incomeCategories.map((c) => c.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Errore salvataggio categorie su Firestore: $e');
    }
  }

  Future<void> addCategory(
    CategoryItem newCategory,
    TransactionType type,
  ) async {
    final targetList = type == TransactionType.expense
        ? _expenseCategories
        : _incomeCategories;

    // Controllo duplicati case-insensitive
    final exists = targetList.any(
      (c) =>
          c.name.trim().toLowerCase() == newCategory.name.trim().toLowerCase(),
    );
    if (exists) {
      throw Exception('Una categoria con questo nome esiste già');
    }

    if (type == TransactionType.expense) {
      _expenseCategories.add(newCategory);
    } else {
      _incomeCategories.add(newCategory);
    }

    notifyListeners();
    await _saveToFirestore();
  }

  Future<void> deleteCategory(String categoryName, TransactionType type) async {
    final targetList = type == TransactionType.expense
        ? _expenseCategories
        : _incomeCategories;

    if (targetList.length <= 1) {
      throw Exception('Deve rimanere almeno una categoria');
    }

    if (type == TransactionType.expense) {
      _expenseCategories.removeWhere((c) => c.name == categoryName);
    } else {
      _incomeCategories.removeWhere((c) => c.name == categoryName);
    }

    notifyListeners();
    await _saveToFirestore();
  }

  CategoryItem getCategory(String name, TransactionType type) {
    final list = type == TransactionType.expense
        ? _expenseCategories
        : _incomeCategories;
    final found = list.where((c) => c.name.toLowerCase() == name.toLowerCase());
    if (found.isNotEmpty) return found.first;

    // Cerca anche nell'altra lista se non trovata
    final otherList = type == TransactionType.expense
        ? _incomeCategories
        : _expenseCategories;
    final otherFound = otherList.where(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );
    if (otherFound.isNotEmpty) return otherFound.first;

    // Fallback pulito
    return CategoryItem(
      name: name,
      icon: type == TransactionType.expense
          ? Icons.money_off_rounded
          : Icons.attach_money_rounded,
      color: type == TransactionType.expense
          ? const Color(0xFFEF4444)
          : const Color(0xFF10B981),
    );
  }

  List<CategoryItem> getCategories(TransactionType type) {
    return type == TransactionType.expense
        ? expenseCategories
        : incomeCategories;
  }

  List<String> getCategoryNames(TransactionType type) {
    return getCategories(type).map((c) => c.name).toList();
  }
}
