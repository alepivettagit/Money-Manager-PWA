import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/account.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DatabaseHelper._init();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _accountsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('accounts');
  }

  CollectionReference<Map<String, dynamic>> _transactionsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('transactions');
  }

  // --- ACCOUNTS CRUD (Cloud Firestore) ---
  Future<List<Account>> getAccounts() async {
    final uid = _uid;
    if (uid == null) return [];

    final snapshot = await _accountsRef(uid).get();
    final accounts =
        snapshot.docs.map((doc) => Account.fromMap(doc.data())).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return accounts;
  }

  Future<void> insertAccount(Account account) async {
    final uid = _uid;
    if (uid == null) return;

    await _accountsRef(uid).doc(account.id).set(account.toMap());
  }

  Future<void> updateAccount(Account account) async {
    final uid = _uid;
    if (uid == null) return;

    await _accountsRef(uid).doc(account.id).update(account.toMap());
  }

  Future<void> deleteAccount(String accountId) async {
    final uid = _uid;
    if (uid == null) return;

    await _accountsRef(uid).doc(accountId).delete();

    // Elimina anche tutte le transazioni associate a questo conto
    final txSnapshot = await _transactionsRef(uid)
        .where('accountId', isEqualTo: accountId)
        .get();
    final batch = _firestore.batch();
    for (final doc in txSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- TRANSACTIONS CRUD (Cloud Firestore) ---
  Future<List<Transaction>> getTransactionsByAccount(String accountId) async {
    final uid = _uid;
    if (uid == null) return [];

    final snapshot = await _transactionsRef(uid)
        .where('accountId', isEqualTo: accountId)
        .get();

    final transactions =
        snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  Future<void> insertTransaction(Transaction transaction) async {
    final uid = _uid;
    if (uid == null) return;

    await _transactionsRef(uid).doc(transaction.id).set(transaction.toMap());
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final uid = _uid;
    if (uid == null) return;

    await _transactionsRef(uid).doc(transaction.id).update(transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    final uid = _uid;
    if (uid == null) return;

    await _transactionsRef(uid).doc(id).delete();
  }
}
