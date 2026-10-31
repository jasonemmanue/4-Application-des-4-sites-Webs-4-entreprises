import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/payment.dart';
import '../../providers/providers.dart';
import '../../services/booking_history.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/payment_logo.dart';
import '../../widgets/state_views.dart';
import 'payment_wait_screen.dart';

/// Choix du moyen de paiement de l'acompte.
///
/// Les moyens viennent de `GET /payments/config`, et non d'une liste écrite ici :
/// ce que l'exploitant retire côté serveur disparaît de l'application.
class PayDepositScreen extends ConsumerStatefulWidget {
  const PayDepositScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<PayDepositScreen> createState() => _PayDepositScreenState();
}

class _PayDepositScreenState extends ConsumerState<PayDepositScreen> {
  PaymentChannel? _channel;
  final _phone = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final r = ref.read(bookingHistoryProvider.notifier).find(widget.bookingId);
    _phone.text = r?.guestPhone ?? '';
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  /// Contrôle avant l'appel réseau. Le numéro doit correspondre à l'opérateur,
  /// sinon le message n'arrive jamais et la passerelle ne dit rien.
  String? _phoneProblem(PaymentOptions o, PaymentChannel c) {
    if (!o.requiresPhone.contains(c)) return null;
    final local = Phones.localDigits(_phone.text);
    if (local.length != 10) return 'Saisissez un numéro à 10 chiffres.';
    final prefixes = o.prefixes[c] ?? const [];
    if (prefixes.isNotEmpty && !prefixes.any(local.startsWith)) {
      return 'Un numéro ${c.label} commence par ${prefixes.join(' ou ')}.';
    }
    return null;
  }

  Future<void> _pay(BookingRecord record, PaymentOptions options) async {
    final channel = _channel;
    if (channel == null) return;
    final problem = _phoneProblem(options, channel);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final attempt = await ref.read(paymentServiceProvider).start(
            bookingId: record.bookingId,
            previousReference: record.paymentReference,
            channel: channel,
            phone: Phones.toApi(_phone.text),
          );
      await ref.read(bookingHistoryProvider.notifier).upsert(record.copyWith(
            paymentReference: attempt.reference,
            paymentStatus: attempt.status,
          ));
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PaymentWaitScreen(
          bookingId: record.bookingId,
          attempt: attempt,
          channel: channel,
        ),
      ));
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _message(Object e) {
    final s = e.toString();
    return s.startsWith('DioException') ? 'Le paiement n\'a pas pu démarrer.' : s;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final history = ref.watch(bookingHistoryProvider);
    final matches = history.where((r) => r.bookingId == widget.bookingId);
    final async = ref.watch(paymentOptionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement de l\'acompte')),
      body: matches.isEmpty
          ? const EmptyView(title: 'Réservation introuvable')
          : async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                message: _message(e),
                onRetry: () => ref.invalidate(paymentOptionsProvider),
              ),
              data: (o) => _body(context, t, matches.first, o),
            ),
    );
  }

  Widget _body(
      BuildContext context, AppTokens t, BookingRecord r, PaymentOptions o) {
    if (!o.enabled || o.channels.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.info_outline_rounded, size: 48, color: t.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Le paiement en ligne n\'est pas disponible pour le moment. '
              'Votre demande est enregistrée : contactez-nous pour régler '
              'l\'acompte.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => WhatsAppService.send(
                'Bonjour CHIC RESIDENCE, je souhaite régler l\'acompte de ma '
                'réservation à ${r.residenceName}.',
              ),
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Nous écrire sur WhatsApp'),
            ),
          ],
        ),
      );
    }

    final mobile = o.channels.where((c) => c != PaymentChannel.card).toList();
    final hasCard = o.channels.contains(PaymentChannel.card);
    final channel = _channel;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (o.mode == 'sandbox') ...[
                _Notice(
                  icon: Icons.science_outlined,
                  text: 'Mode test : aucun argent réel n\'est débité.',
                ),
                const SizedBox(height: 12),
              ],
              _AmountCard(record: r, percent: o.depositPercent),
              const SizedBox(height: 22),
              if (mobile.isNotEmpty) ...[
                const _GroupLabel(
                  icon: Icons.smartphone_rounded,
                  text: 'MOBILE MONEY (CÔTE D\'IVOIRE)',
                ),
                const SizedBox(height: 10),
                _ChannelGrid(
                  channels: mobile,
                  selected: channel,
                  onSelect: _select,
                ),
                const SizedBox(height: 20),
              ],
              if (hasCard) ...[
                const _GroupLabel(
                  icon: Icons.credit_card_rounded,
                  text: 'CARTE BANCAIRE (PARTOUT DANS LE MONDE)',
                ),
                const SizedBox(height: 10),
                _ChannelGrid(
                  channels: const [PaymentChannel.card],
                  selected: channel,
                  onSelect: _select,
                ),
                const SizedBox(height: 20),
              ],
              if (channel != null && o.requiresPhone.contains(channel)) ...[
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: InputDecoration(
                    labelText: 'Numéro ${channel.label}',
                    prefixText: '+225 ',
                    hintText: (o.prefixes[channel] ?? const []).isEmpty
                        ? '07 00 00 00 00'
                        : '${o.prefixes[channel]!.first} 00 00 00 00',
                    prefixIcon: const Icon(Icons.call_outlined),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ce numéro peut être différent de votre numéro WhatsApp.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
              ],
              if (channel != null) _StepsCard(channel: channel),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => WhatsAppService.send(
                  'Bonjour, j\'ai besoin d\'aide pour payer l\'acompte de ma '
                  'réservation à ${r.residenceName}.',
                ),
                icon: const Icon(Icons.support_agent_outlined, size: 18),
                label: const Text('Besoin d\'aide ? WhatsApp'),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              onPressed:
                  channel == null || _busy ? null : () => _pay(r, o),
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(channel == null
                      ? 'Choisissez un moyen de paiement'
                      : 'Payer ${Money.fcfa(r.deposit)}'),
            ),
          ),
        ),
      ],
    );
  }

  void _select(PaymentChannel c) => setState(() {
        _channel = c;
        _error = null;
      });
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Icon(icon, size: 16, color: t.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: t.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChannelGrid extends StatelessWidget {
  const _ChannelGrid({
    required this.channels,
    required this.selected,
    required this.onSelect,
  });
  final List<PaymentChannel> channels;
  final PaymentChannel? selected;
  final ValueChanged<PaymentChannel> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = (box.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final c in channels)
            SizedBox(
              width: w,
              child: PaymentChannelCard(
                channel: c,
                selected: selected == c,
                onTap: () => onSelect(c),
              ),
            ),
        ],
      );
    });
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.record, required this.percent});
  final BookingRecord record;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(record.residenceName,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            '${Dates.short(record.checkIn)} au ${Dates.short(record.checkOut)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('Acompte de $percent % à régler maintenant',
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              Text(
                Money.fcfa(record.deposit),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: t.brand, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text('Solde à régler à l\'arrivée',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              Text(Money.fcfa(record.total - record.deposit),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.channel});
  final PaymentChannel channel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final steps = channel.steps;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comment ça se passe',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text('${i + 1}. ${steps[i]}',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
