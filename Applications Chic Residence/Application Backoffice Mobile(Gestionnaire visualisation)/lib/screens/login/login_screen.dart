import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  int _failCount = 0;
  DateTime? _lockedUntil;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _isLocked =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  Future<void> _submit() async {
    if (_isLocked) {
      final secs = _lockedUntil!.difference(DateTime.now()).inSeconds;
      setState(() => _error = 'Trop de tentatives. Reessayez dans $secs s.');
      return;
    }

    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Adresse email invalide.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Mot de passe requis.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final admin = await ref
          .read(authServiceProvider)
          .login(email, password);
      _failCount = 0;
      ref.read(currentAdminProvider.notifier).state = admin;
      if (mounted) context.go('/');
    } catch (e) {
      _failCount++;
      if (_failCount >= 5) {
        _lockedUntil = DateTime.now().add(const Duration(seconds: 120));
        setState(() =>
            _error = 'Trop de tentatives. Reessayez dans 120 secondes.');
      } else {
        setState(() => _error = 'Identifiant ou mot de passe incorrect.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Backoffice',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text('Chic Residence',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(_error!,
                          style: const TextStyle(color: AppColors.error)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.login_rounded),
                      label: const Text('Se connecter'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
