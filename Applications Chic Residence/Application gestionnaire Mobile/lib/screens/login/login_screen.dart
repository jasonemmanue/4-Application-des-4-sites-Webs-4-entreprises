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
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  bool _loading = false;
  String? _error;
  int _failCount = 0;
  DateTime? _lockedUntil;

  @override
  void dispose() {
    _phone.dispose();
    _pin.dispose();
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

    final phone = _phone.text.trim();
    final pin = _pin.text.trim();

    if (phone.length < 8 || !RegExp(r'^[\d+\s]+$').hasMatch(phone)) {
      setState(() => _error = 'Numero de telephone invalide.');
      return;
    }
    if (pin.length < 4 || pin.length > 6 || !RegExp(r'^\d+$').hasMatch(pin)) {
      setState(() => _error = 'Code PIN invalide (4 a 6 chiffres).');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      final user = await auth.login(phone: phone, pin: pin);
      _failCount = 0;
      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) context.go('/');
    } catch (e) {
      _failCount++;
      if (_failCount >= 5) {
        _lockedUntil = DateTime.now().add(const Duration(seconds: 120));
        setState(() =>
            _error = 'Trop de tentatives. Reessayez dans 120 secondes.');
      } else {
        setState(() => _error = 'Identifiant ou code PIN incorrect.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cleaning_services_rounded,
                    color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text('Chic Residence',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            Text('Gestionnaire',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    )),
            const SizedBox(height: 40),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numero de telephone',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '+225 07 XX XX XX XX',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pin,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Code PIN',
                prefixIcon: Icon(Icons.lock_outline),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.rejected)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.login_rounded),
              label: const Text('Se connecter'),
            ),
            const SizedBox(height: 16),
            Text(
              'Les comptes gestionnaire sont crees par l\'administrateur. '
              'Contactez la direction si vous ne pouvez pas vous connecter.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
