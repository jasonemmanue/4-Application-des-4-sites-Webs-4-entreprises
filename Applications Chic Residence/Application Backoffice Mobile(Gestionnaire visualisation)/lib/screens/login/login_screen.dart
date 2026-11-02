import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../services/device_registration.dart';
import '../../widgets/ui.dart';

/// Connexion avec les **mêmes identifiants que le backoffice web**.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _hide = true;
  String? _error;
  int _failCount = 0;
  DateTime? _lockedUntil;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final lock = _lockedUntil;
    if (lock != null && DateTime.now().isBefore(lock)) {
      final secs = lock.difference(DateTime.now()).inSeconds;
      setState(() => _error = 'Trop de tentatives. Réessayez dans $secs s.');
      return;
    }

    // Le clavier Android ajoute souvent une espace après l'adresse. Le mot de
    // passe, lui, est envoyé tel quel, comme le fait le site.
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
      final admin =
          await ref.read(authServiceProvider).login(email, password);
      _failCount = 0;
      ref.read(currentAdminProvider.notifier).state = admin;
      DeviceRegistration.register(ref.read(apiClientProvider), 'backoffice');
      if (mounted) context.go('/');
    } on DioException catch (e) {
      // Seul un 401 veut dire « identifiants refusés ». Une coupure réseau ou
      // une panne ne doit pas faire douter du mot de passe.
      if (e.response?.statusCode == 401) {
        _failCount++;
        if (_failCount >= 5) {
          _lockedUntil = DateTime.now().add(const Duration(seconds: 120));
          setState(() =>
              _error = 'Trop de tentatives. Réessayez dans 120 secondes.');
        } else {
          setState(() => _error = 'Email ou mot de passe incorrect.');
        }
      } else {
        setState(() => _error = readableError(e));
      }
    } catch (e) {
      setState(() => _error = readableError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset('assets/branding/logo-full.png',
                          height: 120,
                          semanticLabel: 'Chic Résidence Meublée'),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Administration',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Mêmes identifiants que le backoffice web',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: _hide,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _hide ? 'Afficher' : 'Masquer',
                          onPressed: () => setState(() => _hide = !_hide),
                          icon: Icon(_hide
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!,
                          style: const TextStyle(color: AppColors.error)),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Se connecter'),
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
