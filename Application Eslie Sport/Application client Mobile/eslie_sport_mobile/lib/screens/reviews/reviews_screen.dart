import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../services/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reviewsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Avis clients')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReviewSheet(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.dark,
        icon: const Icon(Icons.edit_note),
        label: const Text('Laisser un avis'),
      ),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.reviews_outlined,
              title: 'Aucun avis',
              subtitle: 'Soyez le premier a partager votre experience.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final r = list[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(r.authorName,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Row(
                          children: List.generate(
                            5,
                            (j) => Icon(
                              Icons.star,
                              color: j < r.rating
                                  ? AppColors.primary
                                  : AppColors.darkBorder,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (r.comment != null && r.comment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(r.comment!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.5)),
                    ],
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(reviewsProvider),
        ),
      ),
    );
  }

  void _openReviewSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _ReviewForm(onSubmitted: () {
        ref.invalidate(reviewsProvider);
      }),
    );
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  final VoidCallback onSubmitted;
  const _ReviewForm({required this.onSubmitted});

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  final _name = TextEditingController();
  final _comment = TextEditingController();
  int _rating = 5;
  bool _busy = false;

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).submitReview(
            authorName: _name.text.trim(),
            rating: _rating,
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
          );
      if (!mounted) return;
      widget.onSubmitted();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Merci ! Votre avis sera publie apres validation.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Laisser un avis',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Votre nom'),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.star,
                    color: i < _rating
                        ? AppColors.primary
                        : AppColors.darkBorder,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            minLines: 3,
            maxLines: 5,
            decoration:
                const InputDecoration(labelText: 'Votre experience (optionnel)'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Envoyer'),
            ),
          ),
        ],
      ),
    );
  }
}
