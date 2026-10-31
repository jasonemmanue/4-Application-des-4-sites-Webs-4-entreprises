import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/payment.dart';
import '../../models/service.dart' show formatFcfa;
import '../../services/appointments.dart';
import '../../services/payment_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/flora_ui.dart';
import '../../widgets/payment_sheet.dart';

/// Verdict d'un paiement. Il est **relu auprès de l'API** à chaque affichage :
/// une validation Orange arrivée juste après le décompte s'affiche bien comme
/// un succès, et l'acompte n'est jamais présenté à tort comme perdu.
class PaymentResultScreen extends ConsumerStatefulWidget {
  const PaymentResultScreen({super.key, required this.reference});

  final String reference;

  @override
  ConsumerState<PaymentResultScreen> createState() =>
      _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen> {
  late Future<PaymentStatusResponse> _status = _load();

  Future<PaymentStatusResponse> _load() async {
    final status =
        await ref.read(paymentServiceProvider).checkStatus(widget.reference);
    await ref.read(appointmentsProvider.notifier).refresh();
    return status;
  }

  void _reload() => setState(() => _status = _load());

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        body: SafeArea(
          child: FutureBuilder<PaymentStatusResponse>(
            future: _status,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _Message(
                  icon: Icons.wifi_off_rounded,
                  color: FloraColors.warning,
                  title: 'Vérification impossible',
                  text: "Nous n'avons pas pu joindre le serveur. Si vous avez "
                      'validé le paiement, il sera bien pris en compte.',
                  reference: widget.reference,
                  actions: <Widget>[
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Vérifier à nouveau'),
                    ),
                    const _HomeButton(),
                  ],
                );
              }
              final status = snapshot.data!;
              switch (status.status) {
                case PaymentStatus.success:
                  return _success(status);
                case PaymentStatus.pending:
                case PaymentStatus.processing:
                  return _Message(
                    icon: Icons.hourglass_top_rounded,
                    color: FloraColors.warning,
                    title: 'Paiement en attente',
                    text: "Nous n'avons pas encore la réponse de l'opérateur. "
                        'Si vous avez validé, patientez un instant puis '
                        'vérifiez à nouveau.',
                    reference: widget.reference,
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: _reload,
                        child: const Text('Vérifier à nouveau'),
                      ),
                      OutlinedButton(
                        onPressed: () => showPaymentSheet(context,
                            reference: widget.reference,
                            amount: status.amount?.toInt()),
                        child: const Text('Payer autrement'),
                      ),
                      const _HomeButton(),
                    ],
                  );
                default:
                  return _Message(
                    icon: Icons.error_outline_rounded,
                    color: FloraColors.danger,
                    title: 'Paiement non abouti',
                    text: "L'acompte n'a pas été encaissé. Vous pouvez "
                        'réessayer, avec le même moyen ou un autre.',
                    reference: widget.reference,
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: () => showPaymentSheet(context,
                            reference: widget.reference,
                            amount: status.amount?.toInt()),
                        child: const Text('Réessayer le paiement'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go('/appointments'),
                        child: const Text('Mes rendez-vous'),
                      ),
                      const _HomeButton(),
                    ],
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _success(PaymentStatusResponse status) {
    final date = DateTime.tryParse(status.bookingDate ?? '');
    return _Message(
      icon: Icons.check_circle_rounded,
      color: FloraColors.success,
      title: 'Rendez-vous confirmé !',
      text: 'Votre acompte est bien reçu, nous vous attendons avec plaisir.',
      reference: widget.reference,
      details: <(String, String)>[
        if ((status.serviceName ?? '').isNotEmpty)
          ('Prestation', status.serviceName!),
        if (date != null) ('Date', frLongDate(date)),
        if ((status.bookingTime ?? '').isNotEmpty)
          ('Heure', status.bookingTime!),
        if (status.amount != null) ('Acompte payé', formatFcfa(status.amount!)),
        if (status.remainingAmount != null)
          ('Reste à régler au salon', formatFcfa(status.remainingAmount!)),
      ],
      actions: <Widget>[
        ElevatedButton(
          onPressed: () => context.go('/appointments'),
          child: const Text('Voir mes rendez-vous'),
        ),
        OutlinedButton.icon(
          onPressed: () => ref.read(whatsappServiceProvider).openChat(
                message: 'Bonjour Flora Hair, je viens de réserver via '
                    "l'application. Référence : ${widget.reference}.",
              ),
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Écrire au salon'),
        ),
        const _HomeButton(),
      ],
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton();

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => context.go('/home'),
        child: const Text("Retour à l'accueil"),
      );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
    required this.reference,
    required this.actions,
    this.details = const <(String, String)>[],
  });

  final IconData icon;
  final Color color;
  final String title;
  final String text;
  final String reference;
  final List<(String, String)> details;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(icon, color: color, size: 80),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: FloraColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: FloraColors.textSecondary,
              ),
            ),
            if (details.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              FloraCard(
                child: Column(
                  children: <Widget>[
                    for (final d in details)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                d.$1,
                                style: const TextStyle(
                                    color: FloraColors.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                d.$2,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: FloraColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Référence : $reference',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: FloraColors.textMuted),
            ),
            const SizedBox(height: 20),
            for (final a in actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: a,
              ),
          ],
        ),
      ),
    );
  }
}
