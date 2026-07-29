import 'package:estodo/features/auth/domain/entities/app_user.dart';
import 'package:estodo/features/auth/domain/repositories/auth_repository.dart';
import 'package:estodo/features/auth/presentation/providers/auth_providers.dart';
import 'package:estodo/features/auth/presentation/screens/auth_screen.dart';
import 'package:estodo/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guest sign-in never exposes Firebase administrator errors',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeAuthRepository(
      guestError: FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'This operation is restricted to administrators only.',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AuthScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Continue without an account'));
    await tester.pumpAndSettle();

    expect(repository.guestAttempts, 1);
    expect(
      find.text('Guest access is temporarily unavailable. Try again shortly.'),
      findsOneWidget,
    );
    expect(find.textContaining('administrators'), findsNothing);
  });

  testWidgets('guest sign-in reports network failures clearly', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeAuthRepository(
      guestError: FirebaseAuthException(
        code: 'network-request-failed',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AuthScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Continue without an account'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Unable to connect. Check your internet connection and try again.',
      ),
      findsOneWidget,
    );
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.guestError});

  final FirebaseAuthException? guestError;
  var guestAttempts = 0;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(null);

  @override
  Future<AppUser> continueWithoutAccount() async {
    guestAttempts += 1;
    final error = guestError;
    if (error != null) throw error;
    return const AppUser(id: 'guest', email: '', isAnonymous: true);
  }

  @override
  Future<void> deleteAccount({String? password}) async {}

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    String? displayName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateDisplayName(String displayName) async {}
}
