import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/appointments.dart';
import '../../services/inbox.dart';
import '../../widgets/flora_ui.dart';

/// Boîte de notifications : décisions du salon sur les rendez-vous et
/// messages push. Ouvrir l'écran marque tout comme lu.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      await ref.read(appointmentsProvider.notifier).refresh();
      await ref.read(inboxProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inboxProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: <Widget>[
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Tout effacer',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => ref.read(inboxProvider.notifier).clear(),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(appointmentsProvider.notifier).refresh(),
        child: items.isEmpty
            ? ListView(
                padding: const EdgeInsets.fromLTRB(32, 80, 32, 0),
                children: const <Widget>[
                  Icon(Icons.notifications_none_rounded,
                      size: 56, color: FloraColors.blush),
                  SizedBox(height: 14),
                  Text(
                    'Aucune notification',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: FloraColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'La confirmation de vos rendez-vous par le salon et nos '
                    'messages apparaîtront ici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: FloraColors.textSecondary),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return FloraCard(
                    onTap: item.route == null
                        ? null
                        : () => context.push(item.route!),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: FloraColors.blushLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_rounded,
                              color: FloraColors.burgundy, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: item.read
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                  color: FloraColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: FloraColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${frLongDate(item.receivedAt)} · '
                                '${item.receivedAt.hour.toString().padLeft(2, '0')}:'
                                '${item.receivedAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: FloraColors.textMuted,
                                ),
                              ),
                            ],
                          ),
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
