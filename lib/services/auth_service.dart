import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> initPersistence() async {
    if (kIsWeb) {
      try {
        await _auth.setPersistence(Persistence.LOCAL);
      } catch (e) {
        debugPrint('Errore impostazione persistenza auth: $e');
      }
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _translateAuthError(e.code);
    } catch (_) {
      throw 'Si è verificato un errore imprevisto durante l\'accesso.';
    }
  }

  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _translateAuthError(e.code);
    } catch (_) {
      throw 'Si è verificato un errore imprevisto durante la registrazione.';
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _translateAuthError(e.code);
    } catch (_) {
      throw 'Impossibile inviare l\'email di recupero password.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _translateAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'L\'indirizzo email inserito non è valido.';
      case 'user-disabled':
        return 'Questo account è stato disabilitato.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email o password non corretti. Riprova.';
      case 'email-already-in-use':
        return 'Questa email è già registrata. Prova ad accedere.';
      case 'weak-password':
        return 'La password è troppo debole (usa almeno 6 caratteri).';
      case 'too-many-requests':
        return 'Troppi tentativi ravvicinati. Attendi qualche minuto e riprova.';
      case 'network-request-failed':
        return 'Errore di connessione. Controlla la tua rete internet.';
      default:
        return 'Errore di autenticazione ($code). Riprova.';
    }
  }
}
