import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

const _labels = {
  'succeeded': 'Réussi',
  'pending': 'En attente',
  'failed': 'Échoué',
  'cancelled': 'Annulé',
};

Color _color(String s) {
  switch (s) {
    case 'succeeded':
      return AppColors.success;
    case 'failed':
      return AppColors.error;
    case 'cancelled':
      return AppColors.textMuted;
    default:
      return AppColors.warning;
  }
}

/// Journal de toutes les tentatives. Une ligne par essai : c'est ici qu'on
/// répond à « le client dit avoir payé, est-ce vrai ? ».
class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(paymentFilterProvider);
    final async = ref.watch(paymentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Paiements')),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final e in {null: 'Tous', ..._labels}.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        e.value,
                        style: TextStyle(
                            color: filter == e.key ? Colors.white : null),
                      ),
                      selected: filter == e.key,
                      showCheckmark: false,
                      onSelected: (_) => ref
                          .read(paymentFilterProvider.notifier)
                          .state = e.key,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(paymentsProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.payments_outlined,
                    title: 'Aucun paiement',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(paymentsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: page.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _Tile(payment: page.items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fcfa(p.amount),
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              StatusPill(
                label: _labels[p.status] ?? p.status,
                color: _color(p.status),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            [
              p.channelLabel,
              if (p.customerPhone.isNotEmpty) p.customerPhone,
              if (p.mode == 'sandbox') 'test',
            ].join(' · '),
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            '${p.reference}${p.createdAt == null ? '' : ' · ${dateTime(p.createdAt!)}'}',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          if (p.failureReason.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(p.failureReason,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}
