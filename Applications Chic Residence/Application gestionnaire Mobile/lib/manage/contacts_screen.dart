import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'format.dart';
import '../config/theme.dart';
import 'providers.dart';
import '../widgets/ui.dart';

/// Messages envoyés depuis l'application cliente et le site.
class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contactsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(contactsProvider),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return const EmptyState(
              icon: Icons.mail_outline_rounded,
              title: 'Aucun message',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(contactsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              itemCount: page.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final m = page.items[i];
                return Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(m.name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (!m.isRead)
                            const StatusPill(
                                label: 'Non lu', color: AppColors.primary),
                        ],
                      ),
                      GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: m.phone));
                          showMessage(context, 'Numéro copié.');
                        },
                        child: Text(m.phone,
                            style: const TextStyle(
                                fontSize: 12.5, color: AppColors.textMuted)),
                      ),
                      const SizedBox(height: 5),
                      Text(m.message,
                          style:
                              const TextStyle(fontSize: 13.5, height: 1.35)),
                      Row(
                        children: [
                          if (m.createdAt != null)
                            Expanded(
                              child: Text(dateTime(m.createdAt!),
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textMuted)),
                            )
                          else
                            const Spacer(),
                          if (!m.isRead)
                            TextButton(
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(adminApiProvider)
                                      .markRead(m.id);
                                  ref.invalidate(contactsProvider);
                                  ref.invalidate(dashboardStatsProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    showMessage(context, readableError(e));
                                  }
                                }
                              },
                              child: const Text('Marquer comme lu'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
