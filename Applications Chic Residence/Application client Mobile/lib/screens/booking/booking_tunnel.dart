import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/booking.dart';
import '../../models/residence.dart';
import '../../providers/providers.dart';
import '../../services/booking_history.dart';
import '../../widgets/residence_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/stay_calendar.dart';
import '../payment/pay_deposit_screen.dart';

/// Réservation en deux écrans (maquette) : séjour et tarif, puis coordonnées.
/// Le paiement vit dans [PayDepositScreen], partagé avec « Mes réservations ».
///
/// Pas d'email : le reçu et les confirmations partent sur WhatsApp, l'API n'en
/// prend plus depuis 2026-09-13. L'ancien champ bloquait le tunnel pour rien.
class BookingTunnel extends ConsumerStatefulWidget {
  const BookingTunnel({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<BookingTunnel> createState() => _BookingTunnelState();
}

class _BookingTunnelState extends ConsumerState<BookingTunnel> {
  int _step = 0;
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guests = 1;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();

  BookingPriceBreakdown? _price;
  bool _computing = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(stayDraftProvider);
    _checkIn = draft.checkIn;
    _checkOut = draft.checkOut;
    _guests = draft.guests;
    _name.text = ref.read(guestNameProvider) ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _hasDates =>
      _checkIn != null && _checkOut != null && _checkOut!.isAfter(_checkIn!);

  Future<void> _computePrice(String residenceId) async {
    if (!_hasDates) {
      setState(() => _price = null);
      return;
    }
    setState(() {
      _computing = true;
      _error = null;
    });
    try {
      final p = await ref.read(bookingServiceProvider).calculatePrice(
            residenceId: residenceId,
            checkIn: _checkIn!,
            checkOut: _checkOut!,
          );
      if (mounted) setState(() => _price = p);
    } catch (e) {
      if (mounted) {
        setState(() {
          _price = null;
          _error = _message(e);
        });
      }
    } finally {
      if (mounted) setState(() => _computing = false);
    }
  }

  static String _message(Object e) {
    final s = e.toString();
    return s.startsWith('DioException') ? 'Une erreur est survenue.' : s;
  }

  bool get _contactValid =>
      _name.text.trim().length >= 2 &&
      _phone.text.replaceAll(RegExp(r'\D'), '').length >= 8;

  Future<void> _submit(Residence r) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final phone = Phones.toApi(_phone.text);
      final booking = await ref.read(bookingServiceProvider).create(
            residenceId: r.id,
            checkIn: _checkIn!,
            checkOut: _checkOut!,
            guests: _guests,
            guestName: _name.text.trim(),
            guestPhone: phone,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );

      // Pas de compte : le nom de la dernière réservation personnalise le
      // Profil.
      final name = _name.text.trim();
      await ref.read(sessionServiceProvider).setGuestName(name);
      ref.read(guestNameProvider.notifier).state = name;

      await ref.read(bookingHistoryProvider.notifier).upsert(BookingRecord(
            bookingId: booking.id,
            residenceSlug: r.slug,
            residenceName: r.name,
            city: r.city,
            photo: r.mainPhoto,
            checkIn: _checkIn!,
            checkOut: _checkOut!,
            guests: _guests,
            total: _price?.totalAmount ?? booking.price.totalAmount,
            deposit: booking.deposit,
            guestPhone: phone,
          ));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => PayDepositScreen(bookingId: booking.id),
      ));
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(residenceDetailProvider(widget.slug));
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = 0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_step == 0 ? 'Réservation' : 'Vos coordonnées'),
          centerTitle: true,
        ),
        body: async.when(
          loading: () => const LoadingCards(count: 2),
          error: (e, _) => ErrorView(message: e.toString()),
          data: (r) => Column(
            children: [
              Expanded(child: _step == 0 ? _stayStep(r) : _contactStep()),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _step == 0
                      ? FilledButton(
                          onPressed: _price == null || _computing
                              ? null
                              : () => setState(() {
                                    _step = 1;
                                    _error = null;
                                  }),
                          child: const Text('Continuer'),
                        )
                      : FilledButton(
                          onPressed: !_contactValid || _submitting
                              ? null
                              : () => _submit(r),
                          child: _submitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Confirmer la réservation'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stayStep(Residence r) {
    final t = context.tokens;
    final blocked =
        ref.watch(blockedDaysProvider(r.id)).valueOrNull ?? const <DateTime>{};
    // Les dates reprises de l'accueil n'ont pas encore de tarif.
    if (_hasDates && _price == null && !_computing && _error == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _computePrice(r.id));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: t.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: t.isDark ? Border.all(color: t.border) : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 130,
                width: double.infinity,
                child: ResidencePhoto(url: r.mainPhoto),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.place_outlined,
                            size: 15, color: t.textSecondary),
                        const SizedBox(width: 3),
                        Text(r.city,
                            style: TextStyle(
                                fontSize: 13, color: t.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _Title('Sélectionnez vos dates'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DateBox(label: 'Arrivée', date: _checkIn),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateBox(label: 'Départ', date: _checkOut),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StayCalendar(
          checkIn: _checkIn,
          checkOut: _checkOut,
          blocked: blocked,
          onChanged: (a, b) {
            setState(() {
              _checkIn = a;
              _checkOut = b;
              _price = null;
              _error = null;
            });
            if (a != null && b != null) _computePrice(r.id);
          },
        ),
        const SizedBox(height: 14),
        const _Title('Nombre d\'invités'),
        const SizedBox(height: 8),
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: t.surfaceSunken,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Moins',
                onPressed: _guests > 1 ? () => setState(() => _guests--) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text(
                  '$_guests invité${_guests > 1 ? 's' : ''} (${r.capacity} max.)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Plus',
                onPressed: _guests < r.capacity
                    ? () => setState(() => _guests++)
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_computing)
          const Center(child: CircularProgressIndicator())
        else if (_price != null)
          _PriceCard(price: _price!, perNight: r.pricePerNight),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
      ],
    );
  }

  Widget _contactStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Nous confirmons la réservation et envoyons le reçu sur WhatsApp, à '
          'ce numéro.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nom complet',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Téléphone (WhatsApp)',
            hintText: '07 00 00 00 00',
            prefixIcon: Icon(Icons.call_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notes (facultatif)',
            hintText: 'Heure d\'arrivée, demandes particulières...',
            alignLabelWithHint: true,
          ),
        ),
        if (_price != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.tokens.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'À l\'étape suivante : acompte de ${Money.fcfa(_price!.depositAmount)}. '
              'Le solde se règle à l\'arrivée. Les dates sont à vous dès le '
              'paiement de l\'acompte.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      );
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.label, required this.date});
  final String label;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined, size: 20, color: t.textPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: t.textSecondary)),
                Text(
                  date == null ? 'Choisir' : Dates.dayMonthYear(date!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.price, required this.perNight});
  final BookingPriceBreakdown price;
  final int perNight;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Title('Détail du tarif'),
          const SizedBox(height: 8),
          _Line(
            '${price.nights} nuit${price.nights > 1 ? 's' : ''}',
            Money.fcfa(price.nightsTotal),
          ),
          _Line('Frais de service', Money.fcfa(price.serviceFee)),
          const Divider(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text('Total',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              Text(
                Money.fcfa(price.totalAmount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: t.brand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Line('Acompte à la réservation', Money.fcfa(price.depositAmount)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
