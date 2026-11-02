import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../services/notification_inbox.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ruah_ui.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  /// Messages non lus à l'ouverture : ils restent mis en avant pendant la
  /// lecture, puis tout passe en lu.
  Set<String> _fresh = const {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final notifier = ref.read(inboxProvider.notifier);
      await notifier.reload();
      if (!mounted) return;
      setState(() {
        _fresh = {
          for (final e in ref.read(inboxProvider))
            if (!e.read) e.id,
        };
      });
      await notifier.markAllRead();
    });
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider les notifications ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(inboxProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inboxProvider);
    final DateFormat fmt = DateFormat("d MMM yyyy 'à' HH:mm", 'fr');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Vider',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
              title: 'Aucune notification',
              subtitle:
                  'Les actualités du cabinet apparaîtront ici. Vos demandes de '
                  'devis reçoivent leur réponse sur WhatsApp.',
              icon: Icons.notifications_none_rounded,
            )
          : RefreshIndicator(
              onRefresh: ref.read(inboxProvider.notifier).reload,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final e = items[i];
                  final bool fresh = _fresh.contains(e.id);
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: softCard(context, radius: 16).copyWith(
                      border: fresh
                          ? Border.all(color: AppColors.brand500, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (e.title.isNotEmpty)
                          Text(
                            e.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: fgOf(context),
                            ),
                          ),
                        if (e.body.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(e.body,
                              style: TextStyle(
                                  height: 1.35, color: fgOf(context))),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          fmt.format(e.receivedAt.toLocal()),
                          style:
                              TextStyle(fontSize: 12, color: mutedOf(context)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
