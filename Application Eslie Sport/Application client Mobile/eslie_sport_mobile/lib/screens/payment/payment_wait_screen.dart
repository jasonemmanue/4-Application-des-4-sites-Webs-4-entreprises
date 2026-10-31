import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/payment.dart';
import '../../services/api_client.dart';
import '../../services/payment_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/countdown_timer.dart';

/// Attente du verdict. Rend le statut final a l'appelant, et la reference a
/// jour (le renvoi du message USSD en ouvre une nouvelle).
class PaymentWaitScreen extends ConsumerStatefulWidget {
  final String reference;
  final PaymentOperator operator;
  final int amount;
  final int? expiresIn;
  final String? paymentUrl;

  const PaymentWaitScreen({
    super.key,
    required this.reference,
    required this.operator,
    required this.amount,
    this.expiresIn,
    this.paymentUrl,
  });

  @override
  ConsumerState<PaymentWaitScreen> createState() => _PaymentWaitScreenState();
}

class _PaymentWaitScreenState extends ConsumerState<PaymentWaitScreen>
    with WidgetsBindingObserver {
  StreamSubscription<PaymentStatusResponse>? _sub;
  late String _reference = widget.reference;
  late int _sessionSeconds =
      widget.expiresIn ?? PaymentService.defaultSessionSeconds;
  late String? _paymentUrl = widget.paymentUrl;
  int _countdownKey = 0;

  PaymentStatus _status = PaymentStatus.pending;
  bool _provisionalFailure = false;
  String? _message;
  bool _pollEnded = false;
  bool _resending = false;
  bool _closing = false;

  PaymentService get _service => ref.read(paymentServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    _pollEnded = false;
    _sub = _service
        .pollStatus(
          _reference,
          isCard: widget.operator.isCard,
          expiresIn: _sessionSeconds,
        )
        .listen(
          _onStatus,
          onDone: () {
            if (mounted) setState(() => _pollEnded = true);
          },
        );
  }

  // Retour du navigateur (Wave, carte) : on relit tout de suite le verdict,
  // sans attendre le prochain tour de boucle.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkNow();
  }

  Future<void> _checkNow() async {
    try {
      _onStatus(await _service.refresh(_reference));
    } on ApiException catch (e) {
      if (mounted) setState(() => _message = e.message);
    }
  }

  void _onStatus(PaymentStatusResponse s) {
    if (!mounted || _closing) return;
    setState(() {
      _status = s.status;
      _message = s.error;
      _provisionalFailure = s.provisionalFailure;
      _paymentUrl = s.paymentUrl ?? _paymentUrl;
    });
    if (_service.isTerminal(s)) {
      _closing = true;
      final result = s.expired && s.status == PaymentStatus.pending
          ? PaymentStatus.expired
          : s.status;
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _close(result);
      });
    }
  }

  void _close(PaymentStatus status) {
    Navigator.of(context).pop(PaymentOutcome(status, _reference));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    _closing = true;
    await _sub?.cancel();
    try {
      await _service.cancel(_reference);
    } on ApiException catch (_) {
      // Abandon local quand meme : un « completed » ulterieur reste honore.
    }
    if (mounted) _close(PaymentStatus.cancelled);
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final next = await _service.resendPush(_reference);
      if (!mounted) return;
      setState(() {
        _reference = next.reference;
        _sessionSeconds = next.expiresIn ?? _sessionSeconds;
        _status = next.status;
        _message = null;
        _provisionalFailure = false;
        _countdownKey++;
      });
      _listen();
      _snack('Nouvelle demande envoyée sur votre téléphone.');
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final op = widget.operator;
    final ussd = op.allowedPrefixes.isNotEmpty;
    final (title, subtitle) = op.isCard
        ? (
            'Finalisez le paiement par carte',
            'Saisissez votre carte sur la page sécurisée ouverte dans votre navigateur, puis revenez ici.',
          )
        : ussd
            ? (
                'Confirmez sur votre téléphone',
                'Vous allez recevoir une demande ${op.label}. Saisissez votre code secret pour valider.',
              )
            : (
                'Finalisez le paiement Wave',
                'Validez le paiement sur la page Wave, puis revenez ici. Nous détectons le règlement automatiquement.',
              );

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _operatorLogo(op),
                const SizedBox(height: 24),
                CountdownTimer(
                  key: ValueKey(_countdownKey),
                  duration: Duration(seconds: _sessionSeconds),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _row('Montant', formatFcfa(widget.amount)),
                      _row('Moyen', op.label),
                      _row('Statut', _statusLabel()),
                      _row('Référence', _reference),
                    ],
                  ),
                ),
                if (_provisionalFailure) ...[
                  const SizedBox(height: 12),
                  const _Notice(
                    'L\'opérateur n\'a pas encore confirmé. Si vous n\'avez rien reçu, renvoyez la demande. Si vous avez validé, patientez un instant.',
                  ),
                ] else if (_message != null) ...[
                  const SizedBox(height: 12),
                  _Notice(_message!),
                ],
                if (_pollEnded) ...[
                  const SizedBox(height: 12),
                  const _Notice(
                    'Aucune confirmation pour le moment. Si vous avez payé, vérifiez à nouveau : le règlement reste pris en compte.',
                  ),
                ],
                const SizedBox(height: 20),
                if (_paymentUrl != null && !ussd)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _service.openCheckoutUrl(_paymentUrl),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(op.isCard
                          ? 'Rouvrir la page de paiement'
                          : 'Rouvrir la page Wave'),
                    ),
                  ),
                if (ussd)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _resending ? null : _resend,
                      icon: const Icon(Icons.replay),
                      label: Text(_resending
                          ? 'Envoi...'
                          : 'Renvoyer la demande'),
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _checkNow,
                  child: const Text('J\'ai payé, vérifier maintenant'),
                ),
                TextButton(
                  onPressed: _cancel,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text('Annuler le paiement'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _operatorLogo(PaymentOperator op) {
    final asset = op.logoAsset;
    if (asset == null) {
      return SizedBox(
        height: 40,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final logo in PaymentOperatorX.cardLogos)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Image.asset(logo, height: 28),
              ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Image.asset(asset, width: 64, height: 64),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(k,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            Expanded(
              child: Text(v,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
      );

  String _statusLabel() => switch (_status) {
        PaymentStatus.pending => 'En attente',
        PaymentStatus.processing => 'En cours',
        PaymentStatus.completed => 'Réussi',
        PaymentStatus.failed => 'Échec',
        PaymentStatus.cancelled => 'Annulé',
        PaymentStatus.expired => 'Délai dépassé',
      };
}

class _Notice extends StatelessWidget {
  final String text;
  const _Notice(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}
