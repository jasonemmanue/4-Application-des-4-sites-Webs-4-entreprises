import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/payment.dart';
import '../../providers/providers.dart';
import '../../widgets/payment_logo.dart';

/// Attente du verdict. Le statut ne vient que de l'API.
///
/// - **Wave, carte** : la page du guichet s'ouvre dans le navigateur.
/// - **Orange, MTN** : l'API exécute elle-même la page, le message arrive sur le
///   téléphone. Le client reste ici, guidé par les consignes de l'opérateur.
class PaymentWaitScreen extends ConsumerStatefulWidget {
  const PaymentWaitScreen({
    super.key,
    required this.bookingId,
    required this.attempt,
    required this.channel,
  });

  final String bookingId;
  final PaymentAttempt attempt;
  final PaymentChannel channel;

  @override
  ConsumerState<PaymentWaitScreen> createState() => _PaymentWaitScreenState();
}

class _PaymentWaitScreenState extends ConsumerState<PaymentWaitScreen> {
  late PaymentAttempt _attempt = widget.attempt;
  late DateTime _deadline;
  Timer? _ticker;
  Timer? _poller;
  Duration _remaining = ApiConfig.paymentTimeout;
  bool _resending = false;
  bool _expired = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _deadline = DateTime.now().add(ApiConfig.paymentTimeout);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _poller = Timer.periodic(ApiConfig.paymentPollInterval, (_) => _poll());
    if (!widget.channel.usesPush) _openGuichet();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _poller?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    final r = _deadline.difference(DateTime.now());
    if (r.isNegative) {
      _expire();
      return;
    }
    setState(() => _remaining = r);
  }

  /// Le décompte expire l'attente, jamais le paiement : un encaissement qui
  /// arriverait après reste reconnu côté serveur.
  Future<void> _expire() async {
    _ticker?.cancel();
    _poller?.cancel();
    setState(() {
      _expired = true;
      _remaining = Duration.zero;
    });
    try {
      await ref.read(paymentServiceProvider).cancel(_attempt.reference);
    } catch (_) {}
  }

  Future<void> _poll() async {
    try {
      final a = await ref.read(paymentServiceProvider).status(_attempt.reference);
      if (!mounted) return;
      setState(() => _attempt = a);
      if (a.status != PaymentStatus.pending) {
        _ticker?.cancel();
        _poller?.cancel();
        await _save(a);
      }
    } catch (_) {
      // Coupure réseau : on réessaie au prochain passage. Une panne de lecture
      // n'est pas un échec de paiement.
    }
  }

  Future<void> _save(PaymentAttempt a) async {
    final store = ref.read(bookingHistoryProvider.notifier);
    final record = store.find(widget.bookingId);
    if (record == null) return;
    await store.upsert(record.copyWith(
      paymentReference: a.reference,
      paymentStatus: a.status,
    ));
  }

  Future<void> _openGuichet() async {
    final uri = Uri.tryParse(_attempt.paymentUrl);
    if (uri == null || !uri.hasScheme) {
      setState(() => _notice = 'La page de paiement n\'est pas disponible.');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      setState(() => _notice = 'Impossible d\'ouvrir la page de paiement.');
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _notice = null;
    });
    try {
      final a =
          await ref.read(paymentServiceProvider).resendPush(_attempt.reference);
      if (!mounted) return;
      setState(() => _attempt = a);
      await _save(a);
    } catch (e) {
      if (mounted) setState(() => _notice = e.toString());
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _abandon() async {
    _ticker?.cancel();
    _poller?.cancel();
    try {
      await ref.read(paymentServiceProvider).cancel(_attempt.reference);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final status = _attempt.status;
    return PopScope(
      canPop: status != PaymentStatus.pending || _expired,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Paiement de l\'acompte'),
        ),
        body: status == PaymentStatus.success
            ? _Success(attempt: _attempt)
            : status != PaymentStatus.pending || _expired
                ? _Failure(
                    attempt: _attempt,
                    expired: _expired,
                    onBack: () => Navigator.of(context).pop(),
                  )
                : _waiting(context),
      ),
    );
  }

  Widget _waiting(BuildContext context) {
    final t = context.tokens;
    final push = _attempt.push;
    final mm = _remaining.inMinutes.toString().padLeft(2, '0');
    final ss = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    final steps = widget.channel.steps;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: SizedBox(
                  width: 150,
                  child: PaymentLogoTile(channel: widget.channel, height: 64),
                ),
              ),
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text(
                'En attente de votre validation',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${Money.fcfa(_attempt.amount)} · temps restant $mm:$ss',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: t.textSecondary,
                    ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: t.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: t.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 11,
                              backgroundColor: t.brand,
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(steps[i])),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.channel.usesPush && push != null && push.failed) ...[
                const SizedBox(height: 14),
                const Text(
                  'La demande n\'a pas pu partir. Renvoyez-la, ou ouvrez la page '
                  'de paiement.',
                  style: TextStyle(color: AppColors.error),
                ),
              ],
              if (_notice != null) ...[
                const SizedBox(height: 14),
                Text(_notice!, style: const TextStyle(color: AppColors.error)),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.channel.usesPush || (push?.failed ?? false)) ...[
                  OutlinedButton.icon(
                    onPressed: _openGuichet,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Ouvrir la page de paiement'),
                  ),
                  const SizedBox(height: 8),
                ],
                if (widget.channel.usesPush) ...[
                  OutlinedButton.icon(
                    onPressed:
                        _resending || !(push?.canResend ?? true) ? null : _resend,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      (push?.resendIn ?? 0) > 0
                          ? 'Renvoyer la demande (${push!.resendIn} s)'
                          : 'Renvoyer la demande',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                TextButton(
                  onPressed: _abandon,
                  child: const Text('Changer de moyen de paiement'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.attempt});
  final PaymentAttempt attempt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 84, color: AppColors.successDeep),
          const SizedBox(height: 14),
          Text(
            'Paiement réussi',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Votre réservation est confirmée. Le reçu arrive sur WhatsApp.'
            '${attempt.remaining > 0 ? '\nSolde à régler à l\'arrivée : ${Money.fcfa(attempt.remaining)}.' : ''}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => context.go('/bookings'),
            child: const Text('Voir mes réservations'),
          ),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({
    required this.attempt,
    required this.expired,
    required this.onBack,
  });
  final PaymentAttempt attempt;
  final bool expired;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final title = expired
        ? 'Session expirée'
        : attempt.status == PaymentStatus.cancelled
            ? 'Paiement annulé'
            : 'Paiement échoué';
    final detail = expired
        ? 'Veuillez relancer le paiement. Rien n\'a été débité si vous n\'avez '
            'pas validé.'
        : attempt.failureReason.isNotEmpty
            ? attempt.failureReason
            : 'Vous pouvez réessayer avec le même moyen ou un autre.';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.error_rounded, size: 72, color: AppColors.error),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Relancer le paiement'),
          ),
        ],
      ),
    );
  }
}
