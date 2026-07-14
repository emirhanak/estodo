import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialError});

  final String? initialError;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _isRegistering = false;
  var _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.initialError;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      if (_isRegistering) {
        await repository.register(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );
      } else {
        await repository.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _error = _authMessage(error));
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _authMessage(FirebaseAuthException error) {
    final l10n = AppLocalizations.of(context);
    return switch (error.code) {
      'invalid-email' => l10n.authErrorInvalidEmail,
      'user-disabled' => l10n.authErrorUserDisabled,
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        l10n.authErrorWrongPassword,
      'email-already-in-use' => l10n.authErrorEmailInUse,
      'weak-password' => l10n.authErrorWeakPassword,
      'requires-recent-login' => l10n.authErrorRecentLoginRequired,
      _ => error.message ?? l10n.authErrorDefault,
    };
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final l10n = AppLocalizations.of(context);
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = l10n.authErrorInvalidEmail);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.passwordResetSent)),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _continueWithoutAccount() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).continueWithoutAccount();
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authMessage(error));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Form(
                  key: _formKey,
                  child: Column(
                    key: ValueKey(_isRegistering),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SvgPicture.asset(
                        'assets/branding/estodo.svg',
                        height: 72,
                        placeholderBuilder: (_) => Icon(
                          Icons.check_circle_rounded,
                          color: scheme.primary,
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isRegistering
                            ? l10n.createYourAccount
                            : l10n.welcomeBack,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isTr
                            ? 'Gününü planla, listelerini takip et, hatırlatıcıları senkronla.'
                            : 'Plan the day, track lists, and keep reminders in sync.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 28),
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                            value: false,
                            label: Text(l10n.loginTabTitle),
                            icon: const Icon(Icons.login_rounded),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(l10n.register),
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                          ),
                        ],
                        selected: {_isRegistering},
                        onSelectionChanged: (value) {
                          setState(() {
                            _isRegistering = value.first;
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_isRegistering) ...[
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.name,
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: l10n.email,
                          prefixIcon: const Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (!text.contains('@')) {
                            return isTr
                                ? 'E-posta adresini gir.'
                                : 'Enter your email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) {
                          if ((value ?? '').length < 6) {
                            return isTr
                                ? 'En az 6 karakter kullan.'
                                : 'Use at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        child: _error == null
                            ? const SizedBox(height: 20)
                            : Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Material(
                                  color: scheme.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                        color: scheme.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      if (!_isRegistering)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isSubmitting ? null : _resetPassword,
                            child: Text(l10n.forgotPassword),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _isRegistering
                                    ? Icons.person_add_alt_1_rounded
                                    : Icons.login_rounded,
                              ),
                        label: Text(_isRegistering
                            ? l10n.createAccount
                            : l10n.loginTabTitle),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(isTr ? 'veya' : 'or'),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed:
                            _isSubmitting ? null : _continueWithoutAccount,
                        icon: const Icon(Icons.person_outline_rounded),
                        label: Text(
                          isTr
                              ? 'Hesap oluşturmadan devam et'
                              : 'Continue without an account',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
