import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required NotificationService notifications,
  })  : _auth = auth,
        _firestore = firestore,
        _notifications = notifications;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final NotificationService _notifications;

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      await _ensureUserDocument(user);
      return _mapUser(user);
    });
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('No user returned after sign in.');
    }
    await _ensureUserDocument(user);
    return _mapUser(user);
  }

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('No user returned after registration.');
    }
    final cleanName = displayName?.trim();
    if (cleanName != null && cleanName.isNotEmpty) {
      await user.updateDisplayName(cleanName);
      await user.reload();
    }
    await _ensureUserDocument(_auth.currentUser ?? user);
    unawaited((_auth.currentUser ?? user).sendEmailVerification());
    return _mapUser(_auth.currentUser ?? user);
  }

  @override
  Future<AppUser> continueWithoutAccount() async {
    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('No user returned after anonymous sign in.');
    }
    await _ensureUserDocument(user);
    return _mapUser(user);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(displayName.trim());
    await user.reload();
    await _ensureUserDocument(_auth.currentUser ?? user);
  }

  @override
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (!user.isAnonymous &&
        user.providerData
            .any((provider) => provider.providerId == 'password')) {
      final email = user.email;
      if (email == null || password == null || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'requires-recent-login',
        );
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    }

    await _deleteRemoteUserData(user.uid);
    await _deleteLocalUserData(user.uid);
    await _notifications.cancelAllNotifications();
    await user.delete();
  }

  Future<void> _deleteRemoteUserData(String userId) async {
    final userDoc = _firestore.collection('users').doc(userId);
    for (final collection in const [
      'tasks',
      'lists',
      'list_groups',
      'devices',
      'list_memberships',
    ]) {
      await _deleteQuery(userDoc.collection(collection));
    }
    await _deleteQuery(
      _firestore.collection('share_lookup').where('ownerId', isEqualTo: userId),
    );
    await userDoc.delete();
  }

  Future<void> _deleteQuery(Query<Map<String, dynamic>> query) async {
    while (true) {
      final snapshot = await query.limit(400).get();
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteLocalUserData(String userId) async {
    for (final boxName in const [
      AppConstants.tasksBox,
      AppConstants.listsBox,
      AppConstants.groupsBox,
    ]) {
      final box = Hive.box(boxName);
      final keys = box.keys
          .where((key) => key.toString().startsWith('$userId:'))
          .toList(growable: false);
      await box.deleteAll(keys);
    }
  }

  Future<void> _ensureUserDocument(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      await ref.set({
        'id': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    await ref.set({
      'id': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  AppUser _mapUser(User user) {
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      isAnonymous: user.isAnonymous,
      displayName: user.isAnonymous ? 'Guest' : user.displayName,
    );
  }
}
