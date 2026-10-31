import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/payment.dart';
import '../../providers/providers.dart';
import '../../services/booking_history.dart';
import '../../widgets/residence_card.dart';
import '../../widgets/state_views.dart';
import '../payment/pay_deposit_screen.dart';

/// Réservations faites depuis cet appareil, avec l'état de l'acompte relu sur
/// l'API : un paiement validé après avoir quitté l'application s'affiche ici.
class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final store = ref.read(bookingHistoryProvider.notifier);
    final svc = ref.read(paymentServiceProvider);
    for (final r in ref.read(bookingHistoryProvider)) {
      final reference = r.paymentReference;
      if (reference == null || r.isPaid || r.cancelled) continue;
      try {
        final a = await svc.status(reference);
        await store.upsert(r.copyWith(paymentStatus: a.status));
      } catch (_) {
        // Hors réseau : on garde le dernier état connu.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(bookingHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes réservations')),
      body: list.isEmpty
          ? const EmptyView(
              icon: Icons.calendar_month_outlined,
              title: 'Aucune réservation pour l\'instant',
              description:
                  'Vos réservations faites sur ce téléphone apparaîtront ici. '
                  'Confirmations et rappels arrivent sur WhatsApp.',
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _BookingCard(record: list[i]),
              ),
            ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.record});
  final BookingRecord record;

  (String, Color, Color) _status() {
    if (record.cancelled) {
      return ('Annulée', AppColors.error, AppColors.error.withValues(alpha: 0.12));
    }
    if (record.isPaid) {
      return ('Confirmée', AppColors.successDeep, AppColors.successSoft);
    }
    return (
      'Acompte à régler',
      AppColors.warning,
      AppColors.warning.withValues(alpha: 0.14),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler cette réservation ?'),
        content: const Text('Votre demande sera annulée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(bookingServiceProvider)
          .cancel(record.bookingId, phone: record.guestPhone);
      await ref
          .read(bookingHistoryProvider.notifier)
          .upsert(record.copyWith(cancelled: true));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final (label, fg, bg) = _status();
    final payable = !record.isPaid &&
        !record.cancelled &&
        record.checkIn.isAfter(DateTime.now()) &&
        record.paymentStatus != PaymentStatus.success;
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: t.isDark ? Border.all(color: t.border) : null,
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 14,
            spreadRadius: -6,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          InkWell(
            onTap: () => context.push('/residence/${record.residenceSlug}'),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: ResidencePhoto(url: record.photo),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.residenceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(record.city,
                          style: TextStyle(
                              fontSize: 12.5, color: t.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${Dates.short(record.checkIn)} au ${Dates.short(record.checkOut)}',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                color: fg,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (payable) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () => _cancel(context, ref),
                  child: const Text('Annuler'),
                ),
                const Spacer(),
                SizedBox(
                  height: 42,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          PayDepositScreen(bookingId: record.bookingId),
                    )),
                    child: Text('Payer ${Money.fcfa(record.deposit)}',
                        style: const TextStyle(fontSize: 13.5)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
