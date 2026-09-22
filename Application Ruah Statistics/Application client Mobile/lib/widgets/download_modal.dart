import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/article.dart';
import '../providers/providers.dart';
import '../services/whatsapp_service.dart';

class DownloadModal extends ConsumerStatefulWidget {
  final Article article;

  const DownloadModal({super.key, required this.article});

  static Future<void> show(BuildContext context, Article article) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DownloadModal(article: article),
    );
  }

  @override
  ConsumerState<DownloadModal> createState() => _DownloadModalState();
}

class _DownloadModalState extends ConsumerState<DownloadModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _whatsappCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final response =
          await ref.read(apiClientProvider).requestWhitepaperDownload(
                articleId: widget.article.id,
                whatsappNumber: _whatsappCtrl.text.trim(),
                fullName: _nameCtrl.text.trim().isEmpty
                    ? null
                    : _nameCtrl.text.trim(),
                company: _companyCtrl.text.trim().isEmpty
                    ? null
                    : _companyCtrl.text.trim(),
              );
      final String? downloadUrl = response['file_url'] as String? ??
          response['download_url'] as String? ??
          widget.article.downloadUrl;
      if (!mounted) return;
      Navigator.of(context).pop();
      if (downloadUrl != null) {
        await const WhatsAppService().openExternalUrl(downloadUrl);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Merci ! Le lien vous sera envoye par WhatsApp.'),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Telecharger le livre blanc',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Renseignez vos coordonnees pour recevoir "${widget.article.title}"',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom complet'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _whatsappCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numero WhatsApp *',
                  hintText: '+225 ...',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  if (v.trim().length < 8) return 'Numero invalide';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _companyCtrl,
                decoration:
                    const InputDecoration(labelText: 'Entreprise (optionnel)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download),
                  label: const Text('Recevoir le document'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
