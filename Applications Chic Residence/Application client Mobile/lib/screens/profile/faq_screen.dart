import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/other_models.dart';
import '../../providers/providers.dart';
import '../../widgets/state_views.dart';

/// Questions fréquentes, rédigées dans l'administration (`GET /faq`).
final faqProvider = FutureProvider.autoDispose<List<FaqItem>>((ref) async {
  final res = await ref.watch(apiClientProvider).dio.get('/faq');
  final data = res.data;
  final items = (data is Map ? data['items'] : data) as List? ?? const [];
  return items
      .map((e) => FaqItem.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
});

class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final async = ref.watch(faqProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Questions fréquentes')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(faqProvider),
        ),
        data: (list) => list.isEmpty
            ? const EmptyView(title: 'Aucune question pour le moment')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => Container(
                  decoration: BoxDecoration(
                    color: t.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: t.border),
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: t.brand,
                      collapsedIconColor: t.textSecondary,
                      title: Text(list[i].question,
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: t.textPrimary)),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      children: [
                        Text(list[i].answer,
                            style: TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: t.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
