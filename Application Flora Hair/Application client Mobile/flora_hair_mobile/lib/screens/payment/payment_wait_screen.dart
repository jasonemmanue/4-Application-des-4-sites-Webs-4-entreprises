import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../models/payment.dart';
import '../../models/service.dart' show formatFcfa;
import '../../services/api_client.dart';
import '../../services/payment_service.dart';
import '../../widgets/payment_countdown.dart';

/// Attente du verdict : l'API interroge la passerelle, on interroge l'API.
class PaymentWaitScreen extends ConsumerStatefulWidget {
  const PaymentWaitScreen({
    super.key,
    required this.reference,
    this.operator,
  });
  final String reference;
  final PaymentOperator? operator;

  @override
  ConsumerState<PaymentWaitScreen> createState() => _PaymentWaitScreenState();
}

class _PaymentWaitScreenState extends ConsumerState<PaymentWaitScreen>
    with WidgetsBindingObserver {
  StreamSubscription<PaymentStatusResponse>? _sub;
  PaymentStatusResponse? _last;
  bool _left = false;
  bool _busy = false;

  /// Page externe (Wave, carte) : saisie et 3-D Secure demandent plus de temps
  /// qu'une validation Mobile Money.
  int get _seconds => (widget.operator?.opensExternally ?? false)
      ? ApiConfig.paymentTimeoutSeconds * 3
      : ApiConfig.paymentTimeoutSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = ref
        .read(paymentServiceProvider)
        .pollStatus(widget.reference, timeout: Duration(seconds: _seconds))
        .listen(_onStatus);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  /// Au retour du navigateur ou de l'application Wave, sans attendre le tick.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref
        .read(paymentServiceProvider)
        .checkStatus(widget.reference)
        .then(_onStatus)
        .catchError((Object _) {});
  }

  void _onStatus(PaymentStatusResponse status) {
    if (!mounted) return;
    setState(() => _last = status);
    if (status.status.isFinal) _toResult();
  }

  void _toResult() {
    if (_left || !mounted) return;
    _left = true;
    context.go('/payment/result?ref=${widget.reference}');
  }

  Future<void> _resendPush() async {
    setState(() => _busy = true);
    try {
      await ref.read(paymentServiceProvider).resendPush(widget.reference);
      _snack('Demande renvoyée sur votre téléphone.');
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Une erreur est survenue.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reopenPage() async {
    final url = _last?.paymentUrl;
    if (url == null || url.isEmpty) {
      _snack('La page de paiement se charge, réessayez dans un instant.');
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler le paiement ?'),
        content: const Text(
            'Votre demande de rendez-vous reste enregistrée. Vous pourrez '
            "régler l'acompte depuis « Mes rendez-vous ».",),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuer à payer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Annuler le paiement'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(paymentServiceProvider).cancel(widget.reference);
    } catch (_) {
      // L'écran de résultat relit de toute façon l'état réel.
    }
    _toResult();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final op = widget.operator;
    final amount = _last?.amount;
    final external = op?.opensExternally ?? false;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (op != null)
                    Center(
                      child: Container(
                        width: 180,
                        height: 92,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                              FloraTheme.cardRadius),
                          boxShadow: floraCardShadow,
                        ),
                        child: Image.asset(op.logoAsset,
                            fit: BoxFit.contain, semanticLabel: op.label),
                      ),
                    ),
                  const SizedBox(height: 22),
                  const Text(
                    'Paiement en cours',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: FloraColors.textPrimary,
                    ),
                  ),
                  if (amount != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      formatFcfa(amount),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: FloraColors.burgundy,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    external
                        ? 'Finalisez le paiement sur la page qui vient de '
                            "s'ouvrir, puis revenez ici : cet écran se met à "
                            'jour tout seul.'
                        : 'Validez la demande reçue sur votre téléphone en '
                            'saisissant votre code secret.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: FloraColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: PaymentCountdown(
                      totalSeconds: _seconds,
                      onExpired: _toResult,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : (external ? _reopenPage : _resendPush),
                    child: Text(external
                        ? 'Rouvrir la page de paiement'
                        : 'Renvoyer la demande'),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _cancel,
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Le salon ne voit jamais votre code secret ni votre '
                    'numéro de carte.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: FloraColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
