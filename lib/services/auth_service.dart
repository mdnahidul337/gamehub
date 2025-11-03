import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/app_user.dart';
import 'db_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  AppUser? currentUser;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  final DBService _dbService = DBService();

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      currentUser = null;
      notifyListeners();
      return;
    }
    final event = await _db.child('users/${user.uid}').once();
    if (event.snapshot.value != null) {
      currentUser = AppUser.fromMap(
          user.uid, Map<String, dynamic>.from(event.snapshot.value as Map));
    } else {
      // In case DB entry missing, create default user
      currentUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          role: 'user',
          coins: 0,
          banned: false);
      await _db.child('users/${user.uid}').set(currentUser!.toMap());
    }
    notifyListeners();
  }

  Future<String?> registerWithEmail(String email, String password,
      {String? adminCode}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final uid = cred.user!.uid;
      final role = (adminCode != null && adminCode == AuthService.adminCode)
          ? 'admin'
          : 'user';
      final user =
          AppUser(uid: uid, email: email, role: role, coins: 5, banned: false);
      await _db.child('users/$uid').set(user.toMap());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Refresh user data from Realtime Database (coins, role, banned flag)
  Future<void> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final event = await _db.child('users/${user.uid}').once();
    if (event.snapshot.value != null) {
      currentUser = AppUser.fromMap(
          user.uid, Map<String, dynamic>.from(event.snapshot.value as Map));
      notifyListeners();
    }
  }

  /// Award coins to the currently signed-in user and refresh local user state.
  Future<void> awardCoinsToCurrentUser(int amount) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _dbService.incrementUserCoins(user.uid, amount);
    await refreshCurrentUser();
  }

  static const String adminCode = 'ADMIN123'; // TODO: move to secure config
}
