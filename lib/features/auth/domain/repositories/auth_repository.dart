import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<AppUser> register({
    required String email,
    required String password,
    String? displayName,
  });

  Future<AppUser> continueWithoutAccount();

  Future<void> signOut();

  Future<void> updateDisplayName(String displayName);

  Future<void> resetPassword(String email);

  Future<void> deleteAccount({String? password});
}
