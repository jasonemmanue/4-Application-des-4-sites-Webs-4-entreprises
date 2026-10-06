import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/payment.dart';
import '../../providers/providers.dart';
import '../../services/whatsapp_service.dart';

/// Ecran d'attente du paiement (Wave = navigateur externe, Orange/MTN = USSD).
class PaymentWaitScreen extends ConsumerStatefulWidget {
  const PaymentWaitScreen({
    super.key,
    required this.reference,
    required this.bookingReference,
    required this.amount,
    required this.channel,
    this.checkoutUrl,
  });

  final String reference;
  final String bookingReference;
  final int amount;
  final PaymentChannel channel;
  final String? checkoutUrl;

  @override
  ConsumerState<PaymentWaitScreen> createState() =>
      _PaymentWaitScreenState();
}

class _PaymentWaitScreenState extends ConsumerState<PaymentWaitScreen> {
  late final DateTime _deadline;
  Timer? _countdown;
  Duration _remaining = ApiConfig.paymentTimeout;
  StreamSubscription<PaymentStatus>? _sub;
  PaymentStatus _status = PaymentStatus.pending;

  @override
  void initState() {
    super.initState();
    _deadline = DateTime.now().add(ApiConfig.paymentTimeout);
    _launchIfNeeded();
    _startPolling();
    _startCountdown();
  }

  Future<void> _launchIfNeeded() async {
    if (widget.channel == PaymentChannel.wave && widget.checkoutUrl != null) {
      final uri = Uri.tryParse(widget.checkoutUrl!);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _startPolling() {
    final svc = ref.read(paymentServiceProvider);
    _sub = svc.pollStatus(widget.reference).listen((s) {
      if (!mounted) return;
      setState(() => _status = s);
      if (s == PaymentStatus.success) {
        _onSuccess();
      }
    });
  }

  void _startCountdown() {
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = _deadline.difference(DateTime.now());
      if (!mounted) return;
      setState(() => _remaining = r.isNegative ? Duration.zero : r);
    });
  }

  Future<void> _onSuccess() async {
    _countdown?.cancel();
    _sub?.cancel();
    // Notification WhatsApp
    await WhatsAppService.send(
      'Bonjour Chic Residence, je viens de payer le depot pour ma reservation ${widget.bookingReference} (${Money.fcfa(widget.amount)}). Merci de confirmer.',
    );
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement en cours')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusHeader(status: _status, remaining: _remaining),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reservation ${widget.bookingReference}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Montant : ${Money.fcfa(widget.amount)}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text('Reference : ${widget.reference}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: context.tokens.textSecondary)),
                    Text('Operateur : ${widget.channel.label}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (widget.channel != PaymentChannel.wave)
              const _InstructionBanner(
                text:
                    'Regardez votre telephone : une notification USSD est arrivee. Composez votre code secret pour confirmer.',
              ),
            if (widget.channel == PaymentChannel.wave)
              const _InstructionBanner(
                text:
                    'Wave s\'est ouvert dans votre navigateur. Finalisez le paiement puis revenez ici.',
              ),
            const Spacer(),
            if (_status == PaymentStatus.failed ||
                _status == PaymentStatus.cancelled ||
                _remaining == Duration.zero)
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Essayer un autre operateur'),
              )
            else if (_status == PaymentStatus.success)
              FilledButton.icon(
                onPressed: () => Navigator.of(context)
                    .popUntil((r) => r.isFirst),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Retour a l\'accueil'),
              )
            else
              OutlinedButton.icon(
                onPressed: _cancel,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Annuler le paiement'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    try {
      await ref.read(paymentServiceProvider).cancel(widget.reference);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.status, required this.remaining});
  final PaymentStatus status;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      PaymentStatus.pending => 'En attente de confirmation...',
      PaymentStatus.processing => 'Traitement...',
      PaymentStatus.success => 'Paiement reussi',
      PaymentStatus.failed => 'Paiement echoue',
      PaymentStatus.cancelled => 'Paiement annule',
      PaymentStatus.expired => 'Delai depasse',
    };
    final icon = switch (status) {
      PaymentStatus.success => Icons.check_circle_rounded,
      PaymentStatus.failed || PaymentStatus.expired => Icons.error_rounded,
      PaymentStatus.cancelled => Icons.cancel_rounded,
      _ => Icons.hourglass_top_rounded,
    };
    final color = switch (status) {
      PaymentStatus.success => AppColors.success,
      PaymentStatus.failed || PaymentStatus.expired || PaymentStatus.cancelled =>
        AppColors.error,
      _ => AppColors.primary600,
    };

    final mm = remaining.inMinutes.toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        Icon(icon, size: 72, color: color),
        const SizedBox(height: 12),
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (status == PaymentStatus.pending ||
            status == PaymentStatus.processing)
          Text('Temps restant : $mm:$ss',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textSecondary,
                  )),
      ],
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  const _InstructionBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tokens.surfaceSunken,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: context.tokens.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
