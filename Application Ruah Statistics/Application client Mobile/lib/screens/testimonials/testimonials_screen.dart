import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/contact_message.dart';
import '../../providers/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/testimonial_card.dart';

class TestimonialsScreen extends ConsumerWidget {
  const TestimonialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testimonials = ref.watch(testimonialsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Temoignages')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitSheet(context, ref),
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Laisser un temoignage'),
        backgroundColor: AppColors.brand500,
        foregroundColor: Colors.white,
      ),
      body: testimonials.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(testimonialsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Soyez le premier a temoigner',
              icon: Icons.rate_review_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) => TestimonialCard(testimonial: items[i]),
          );
        },
      ),
    );
  }

  Future<void> _showSubmitSheet(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final author = TextEditingController();
    final whatsapp = TextEditingController();
    final role = TextEditingController();
    final company = TextEditingController();
    final message = TextEditingController();
    int rating = 5;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.large),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Votre temoignage',
                      style: Theme.of(ctx).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Il sera publie apres validation par notre equipe',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: author,
                    decoration: const InputDecoration(labelText: 'Nom *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: whatsapp,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Numero WhatsApp *',
                        hintText: '+225 ...'),
                    validator: (v) => (v == null || v.trim().length < 8)
                        ? 'Numero invalide'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: role,
                    decoration: const InputDecoration(labelText: 'Poste'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: company,
                    decoration:
                        const InputDecoration(labelText: 'Entreprise'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: message,
                    maxLines: 4,
                    decoration:
                        const InputDecoration(labelText: 'Votre message *'),
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? '10 caracteres minimum'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: List.generate(
                      5,
                      (i) => IconButton(
                        icon: Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: AppColors.accent500,
                        ),
                        onPressed: () =>
                            setSheetState(() => rating = i + 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (!(formKey.currentState?.validate() ??
                                  false)) return;
                              setSheetState(() => submitting = true);
                              try {
                                await ref
                                    .read(apiClientProvider)
                                    .submitTestimonial(
                                      TestimonialSubmission(
                                        clientName: author.text.trim(),
                                        clientWhatsapp: whatsapp.text.trim(),
                                        clientPosition:
                                            role.text.trim().isEmpty
                                                ? null
                                                : role.text.trim(),
                                        clientCompany:
                                            company.text.trim().isEmpty
                                                ? null
                                                : company.text.trim(),
                                        quote: message.text.trim(),
                                        rating: rating,
                                      ),
                                    );
                                if (!ctx.mounted) return;
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Merci ! Votre temoignage est en cours de moderation.'),
                                  ),
                                );
                              } catch (e) {
                                setSheetState(() => submitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                      child: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Envoyer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
