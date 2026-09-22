import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/review.dart';
import '../services/api_client.dart';

class ReviewForm extends ConsumerStatefulWidget {
  const ReviewForm({super.key, this.onSubmitted});
  final VoidCallback? onSubmitted;

  @override
  ConsumerState<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _authorCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _authorCtrl.dispose();
    _emailCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).submitReview(
            ReviewSubmission(
              author: _authorCtrl.text.trim(),
              rating: _rating,
              comment: _commentCtrl.text.trim(),
              email: _emailCtrl.text.trim().isEmpty
                  ? null
                  : _emailCtrl.text.trim(),
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Merci ! Votre avis est en cours de moderation.'),
        ),
      );
      widget.onSubmitted?.call();
      _authorCtrl.clear();
      _emailCtrl.clear();
      _commentCtrl.clear();
      setState(() => _rating = 5);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Laissez un avis',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: List<Widget>.generate(5, (i) {
              return IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  i < _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: FloraColors.lime,
                  size: 32,
                ),
              );
            }),
          ),
          TextFormField(
            controller: _authorCtrl,
            decoration: const InputDecoration(labelText: 'Nom'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration:
                const InputDecoration(labelText: 'Email (facultatif)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Votre message'),
            validator: (v) =>
                (v == null || v.trim().length < 5) ? 'Message trop court' : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Envoyer l\'avis'),
            ),
          ),
        ],
      ),
    );
  }
}
