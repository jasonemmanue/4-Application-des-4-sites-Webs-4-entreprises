import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

const bookingLabels = {
  'pending': 'En attente',
  'confirmed': 'Confirmée',
  'completed': 'Terminée',
  'cancelled': 'Annulée',
};

Color bookingColor(String s) {
  switch (s) {
    case 'confirmed':
      return AppColors.success;
    case 'completed':
      return AppColors.info;
    case 'cancelled':
      return AppColors.error;
    default:
      return AppColors.warning;
  }
}

/// Réservations faites depuis l'application, le site ou saisies ici : une seule
/// base, donc une seule liste.
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(bookingFilterProvider);
    final async = ref.watch(bookingsProvider);
    final titles = ref.watch(residenceTitlesProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('Réservations')),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip(ref, filter, null, 'Toutes'),
                for (final e in bookingLabels.entries)
                  _chip(ref, filter, e.key, e.value),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(bookingsProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'Aucune réservation',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(bookingsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: page.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => BookingTile(
                      booking: page.items[i],
                      residence:
                          titles[page.items[i].residenceId] ?? 'Logement',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(WidgetRef ref, String? current, String? value, String label) {
    final selected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(color: selected ? Colors.white : null)),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) =>
            ref.read(bookingFilterProvider.notifier).state = value,
      ),
    );
  }
}

class BookingTile extends ConsumerWidget {
  const BookingTile({super.key, required this.booking, required this.residence});
  final Booking booking;
  final String residence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = booking;
    return Panel(
      onTap: () => _openSheet(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  residence,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ),
              StatusPill(
                label: bookingLabels[b.status] ?? b.status,
                color: bookingColor(b.status),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${b.guestName} · ${dayMonth(b.checkIn)} au ${dayMonth(b.checkOut)}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                fcfa(b.total),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: b.depositPaid ? 'Acompte réglé' : 'Acompte non réglé',
                color: b.depositPaid ? AppColors.success : AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref) {
    final b = booking;
    Future<void> set(BuildContext ctx, String status) async {
      try {
        await ref.read(adminApiProvider).setBookingStatus(b.id, status);
        ref.invalidate(bookingsProvider);
        ref.invalidate(dashboardStatsProvider);
        // Fin de séjour : le backend crée la tâche de préparation.
        if (status == 'completed') ref.invalidate(tasksProvider);
        if (ctx.mounted) Navigator.of(ctx).pop();
      } catch (e) {
        if (context.mounted) showMessage(context, readableError(e));
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(residence,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _Fact('Client', b.guestName),
              GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: b.guestPhone));
                  showMessage(context, 'Numéro copié.');
                },
                child: _Fact('Téléphone', b.guestPhone),
              ),
              _Fact('Séjour',
                  '${dayMonthYear(b.checkIn)} au ${dayMonthYear(b.checkOut)}'),
              _Fact('Occupants', '${b.guests}'),
              _Fact('Total', fcfa(b.total)),
              _Fact(
                'Acompte',
                '${fcfa(b.deposit)} (${b.depositPaid ? 'réglé' : 'non réglé'})',
              ),
              if (b.notes.isNotEmpty) _Fact('Notes', b.notes),
              const SizedBox(height: 14),
              if (b.status == 'pending')
                FilledButton(
                  onPressed: () => set(ctx, 'confirmed'),
                  child: const Text('Confirmer'),
                ),
              if (b.status == 'confirmed')
                FilledButton(
                  onPressed: () => set(ctx, 'completed'),
                  child: const Text('Marquer le séjour terminé'),
                ),
              if (b.status == 'pending' || b.status == 'confirmed') ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: ctx,
                      builder: (d) => AlertDialog(
                        title: const Text('Annuler cette réservation ?'),
                        content: Text(b.depositPaid
                            ? 'L\'acompte est réglé : pensez au remboursement.'
                            : 'Les dates seront libérées.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(d).pop(false),
                            child: const Text('Non'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(d).pop(true),
                            child: const Text('Oui, annuler'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && ctx.mounted) await set(ctx, 'cancelled');
                  },
                  child: const Text('Annuler la réservation'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }
}
