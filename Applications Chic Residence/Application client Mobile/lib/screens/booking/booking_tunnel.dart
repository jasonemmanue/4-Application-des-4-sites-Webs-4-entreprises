import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/booking.dart';
import '../../models/payment.dart';
import '../../models/residence.dart';
import '../../providers/providers.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/state_views.dart';
import '../payment/payment_wait_screen.dart';

/// Tunnel de reservation en 4 etapes : Dates / Infos / Confirmation / Paiement.
class BookingTunnel extends ConsumerStatefulWidget {
  const BookingTunnel({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<BookingTunnel> createState() => _BookingTunnelState();
}

class _BookingTunnelState extends ConsumerState<BookingTunnel> {
  int step = 0;

  DateTime? checkIn;
  DateTime? checkOut;
  int guests = 1;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  BookingPriceBreakdown? price;
  bool computing = false;
  String? errorMsg;

  PaymentChannel channel = PaymentChannel.wave;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool _canNext(Residence r) {
    switch (step) {
      case 0:
        return checkIn != null &&
            checkOut != null &&
            checkOut!.isAfter(checkIn!) &&
            guests > 0 &&
            guests <= r.capacity;
      case 1:
        return _nameCtrl.text.trim().length >= 2 &&
            _emailCtrl.text.contains('@') &&
            _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length >= 8;
      case 2:
        return price != null;
      case 3:
        final phone = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
        if (channel == PaymentChannel.wave) return phone.length >= 8;
        return phone.startsWith(channel.prefix);
      default:
        return false;
    }
  }

  Future<void> _computePrice(String residenceId) async {
    setState(() {
      computing = true;
      errorMsg = null;
    });
    try {
      final svc = ref.read(bookingServiceProvider);
      final p = await svc.calculatePrice(
        residenceId: residenceId,
        checkIn: checkIn!,
        checkOut: checkOut!,
      );
      setState(() => price = p);
    } catch (e) {
      setState(() => errorMsg = e.toString());
    } finally {
      setState(() => computing = false);
    }
  }

  Future<void> _submitAndPay(Residence r) async {
    setState(() {
      computing = true;
      errorMsg = null;
    });
    try {
      final booking = await ref.read(bookingServiceProvider).create(
            residenceId: r.id,
            checkIn: checkIn!,
            checkOut: checkOut!,
            guests: guests,
            guestName: _nameCtrl.text.trim(),
            guestPhone: _phoneCtrl.text.trim(),
            notes:
                _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );

      // Pas de compte : le nom de la dernière réservation personnalise le
      // Profil.
      final name = _nameCtrl.text.trim();
      if (name.isNotEmpty) {
        await ref.read(sessionServiceProvider).setGuestName(name);
        ref.read(guestNameProvider.notifier).state = name;
      }

      final init = await ref.read(paymentServiceProvider).init(
            bookingId: booking.id,
            channel: channel,
            phone: _phoneCtrl.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PaymentWaitScreen(
          reference: init.reference,
          bookingReference: booking.reference,
          amount: init.amount,
          channel: channel,
          checkoutUrl: init.checkoutUrl,
        ),
      ));
    } catch (e) {
      setState(() => errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => computing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(residenceDetailProvider(widget.slug));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (step + 1) / 4,
            minHeight: 4,
            backgroundColor: context.tokens.surfaceSunken,
            valueColor: AlwaysStoppedAnimation(context.tokens.brand),
          ),
        ),
      ),
      body: async.when(
        loading: () => const LoadingCards(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (r) => Column(
          children: [
            Expanded(child: _buildStep(r)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: computing
                              ? null
                              : () => setState(() => step -= 1),
                          child: const Text('Retour'),
                        ),
                      ),
                    if (step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: !_canNext(r) || computing
                            ? null
                            : () async {
                                if (step == 1) {
                                  await _computePrice(r.id);
                                  if (price != null) {
                                    setState(() => step += 1);
                                  }
                                } else if (step == 3) {
                                  await _submitAndPay(r);
                                } else {
                                  setState(() => step += 1);
                                }
                              },
                        child: computing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(step == 3 ? 'Payer le depot' : 'Continuer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(Residence r) {
    switch (step) {
      case 0:
        return _DatesStep(
          residence: r,
          checkIn: checkIn,
          checkOut: checkOut,
          guests: guests,
          onCheckIn: (d) => setState(() {
            checkIn = d;
            if (checkOut != null && !checkOut!.isAfter(d)) checkOut = null;
          }),
          onCheckOut: (d) => setState(() => checkOut = d),
          onGuests: (n) => setState(() => guests = n),
        );
      case 1:
        return _InfoStep(
          nameCtrl: _nameCtrl,
          emailCtrl: _emailCtrl,
          phoneCtrl: _phoneCtrl,
          notesCtrl: _notesCtrl,
          onChanged: () => setState(() {}),
        );
      case 2:
        return _ConfirmStep(
          residence: r,
          checkIn: checkIn!,
          checkOut: checkOut!,
          guests: guests,
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          phone: _phoneCtrl.text,
          price: price,
          error: errorMsg,
        );
      case 3:
        return _PaymentStep(
          channel: channel,
          onChannel: (c) => setState(() => channel = c),
          phoneCtrl: _phoneCtrl,
          amount: price?.depositAmount ?? 0,
          error: errorMsg,
          onChanged: () => setState(() {}),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _DatesStep extends StatelessWidget {
  const _DatesStep({
    required this.residence,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.onGuests,
  });

  final Residence residence;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int guests;
  final ValueChanged<DateTime> onCheckIn;
  final ValueChanged<DateTime> onCheckOut;
  final ValueChanged<int> onGuests;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(residence.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Selectionnez vos dates',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.tokens.textSecondary,
                )),
        const SizedBox(height: 16),
        TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: checkIn ?? DateTime.now(),
          rangeStartDay: checkIn,
          rangeEndDay: checkOut,
          rangeSelectionMode: RangeSelectionMode.enforced,
          calendarFormat: CalendarFormat.month,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: CalendarStyle(
            rangeHighlightColor: AppColors.primary600.withOpacity(0.15),
            rangeStartDecoration: const BoxDecoration(
              color: AppColors.primary600,
              shape: BoxShape.circle,
            ),
            rangeEndDecoration: const BoxDecoration(
              color: AppColors.primary600,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: context.tokens.surfaceSunken,
              shape: BoxShape.circle,
            ),
          ),
          onRangeSelected: (start, end, _) {
            if (start != null) onCheckIn(start);
            if (end != null) onCheckOut(end);
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _DateChip(
                label: 'Arrivee',
                value: checkIn == null ? 'Choisir' : Dates.short(checkIn!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateChip(
                label: 'Depart',
                value: checkOut == null ? 'Choisir' : Dates.short(checkOut!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Nombre de voyageurs',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.outlined(
              onPressed: guests > 1 ? () => onGuests(guests - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 16),
            Text('$guests', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(width: 16),
            IconButton.outlined(
              onPressed: guests < residence.capacity
                  ? () => onGuests(guests + 1)
                  : null,
              icon: const Icon(Icons.add),
            ),
            const SizedBox(width: 12),
            Text('sur ${residence.capacity} max',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.tokens.textSecondary,
                    )),
          ],
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: context.tokens.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.tokens.textSecondary,
                  )),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: value == 'Choisir'
                        ? context.tokens.textSecondary
                        : context.tokens.textPrimary,
                  )),
        ],
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  const _InfoStep({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.notesCtrl,
    required this.onChanged,
  });

  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController notesCtrl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Vos informations', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Nous confirmerons la reservation par WhatsApp au numero fourni.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.tokens.textSecondary),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: nameCtrl,
          onChanged: (_) => onChanged(),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nom complet',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: emailCtrl,
          onChanged: (_) => onChanged(),
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phoneCtrl,
          onChanged: (_) => onChanged(),
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Telephone (WhatsApp)',
            prefixIcon: Icon(Icons.call_outlined),
            hintText: '+225 07 XX XX XX XX',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notesCtrl,
          onChanged: (_) => onChanged(),
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notes (facultatif)',
            hintText: 'Heures d\'arrivee, demandes speciales...',
          ),
        ),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    required this.residence,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.name,
    required this.email,
    required this.phone,
    required this.price,
    this.error,
  });

  final Residence residence;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final String name;
  final String email;
  final String phone;
  final BookingPriceBreakdown? price;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final nights = Dates.nightsBetween(checkIn, checkOut);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Recapitulatif', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _Row(label: 'Residence', value: residence.name),
        _Row(label: 'Arrivee', value: Dates.short(checkIn)),
        _Row(label: 'Depart', value: Dates.short(checkOut)),
        _Row(label: 'Voyageurs', value: '$guests personne(s)'),
        _Row(label: 'Nuits', value: '$nights'),
        const Divider(height: 32),
        _Row(label: 'Nom', value: name),
        _Row(label: 'Email', value: email),
        _Row(label: 'Telephone', value: phone),
        const Divider(height: 32),
        if (price != null) ...[
          _Row(
            label: '$nights nuits',
            value: Money.fcfa(price!.nightsTotal),
          ),
          _Row(
            label: 'Frais de service (5%)',
            value: Money.fcfa(price!.serviceFee),
          ),
          _Row(
            label: 'Total',
            value: Money.fcfa(price!.totalAmount),
            bold: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary600.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary600.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined,
                    color: AppColors.primary600),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Depot 50% a payer maintenant',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        Money.fcfa(price!.depositAmount),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: AppColors.error)),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textSecondary,
                  ),
            ),
          ),
          Text(
            value,
            style: bold
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PaymentStep extends StatelessWidget {
  const _PaymentStep({
    required this.channel,
    required this.onChannel,
    required this.phoneCtrl,
    required this.amount,
    required this.onChanged,
    this.error,
  });

  final PaymentChannel channel;
  final ValueChanged<PaymentChannel> onChannel;
  final TextEditingController phoneCtrl;
  final int amount;
  final VoidCallback onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Depot 50%', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Montant : ${Money.fcfa(amount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary600,
                )),
        const SizedBox(height: 20),
        Text('Choisissez votre operateur',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final c in PaymentChannel.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ChannelCard(
                    channel: c,
                    selected: channel == c,
                    onTap: () => onChannel(c),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: phoneCtrl,
          onChanged: (_) => onChanged(),
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Numero ${channel.label}',
            hintText: channel.prefix.isEmpty
                ? '+225 ...'
                : '${channel.prefix}XXXXXXXX',
            prefixIcon: const Icon(Icons.call_outlined),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.tokens.surfaceSunken,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Comment ca marche ?',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              const _BulletLine(
                  text: 'Wave : ouverture d\'une page de paiement securisee'),
              const _BulletLine(
                  text: 'Orange / MTN : notification USSD sur votre telephone'),
              const _BulletLine(
                  text: 'Depot bloque pendant 30 min — le solde sur place'),
              const _BulletLine(
                  text: 'Confirmation par WhatsApp des reception du paiement'),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => WhatsAppService.send(
            'Bonjour, j\'ai besoin d\'aide pour finaliser mon paiement de reservation Chic Residence.',
          ),
          icon: const Icon(Icons.support_agent_outlined, size: 18),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Besoin d\'aide ? Contactez-nous sur WhatsApp',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.selected,
    required this.onTap,
  });
  final PaymentChannel channel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary600 : context.tokens.border,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? AppColors.primary600.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              channel == PaymentChannel.wave
                  ? Icons.waves_rounded
                  : channel == PaymentChannel.orange
                      ? Icons.circle
                      : Icons.stars_rounded,
              size: 28,
              color: channel == PaymentChannel.wave
                  ? const Color(0xFF1BC8F1)
                  : channel == PaymentChannel.orange
                      ? const Color(0xFFFF6600)
                      : const Color(0xFFFFCC00),
            ),
            const SizedBox(height: 6),
            Text(
              channel.label.split(' ').first,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
