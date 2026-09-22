import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../models/contact_message.dart';
import '../../providers/providers.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _whatsapp = TextEditingController();
  final _company = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_name, _whatsapp, _company, _subject, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final message = ContactMessage(
      name: _name.text.trim(),
      whatsappNumber: _whatsapp.text.trim(),
      message: _message.text.trim(),
      subject: _subject.text.trim().isEmpty ? null : _subject.text.trim(),
      company: _company.text.trim().isEmpty ? null : _company.text.trim(),
    );
    try {
      await ref.read(apiClientProvider).submitContactMessage(message);
      if (!mounted) return;
      await _offerWhatsApp(message);
      _resetForm();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message envoye. Nous vous repondrons vite.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _offerWhatsApp(ContactMessage message) async {
    final bool? go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer via WhatsApp ?'),
        content: const Text(
          "Nous pouvons ouvrir WhatsApp avec un recapitulatif "
          "pour une reponse plus rapide.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non, merci'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ouvrir WhatsApp'),
          ),
        ],
      ),
    );
    if (go == true) {
      await ref
          .read(whatsAppServiceProvider)
          .sendPreFilledMessage(message.whatsappSummary);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    for (final c in [_name, _whatsapp, _company, _subject, _message]) {
      c.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ws = ref.watch(whatsAppServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nous contacter')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _infoRow(Icons.call, ApiConfig.companyPhone,
                        () => ws.callPhone(ApiConfig.companyPhone)),
                    const Divider(height: 1),
                    _infoRow(
                        Icons.chat_bubble_outline,
                        'WhatsApp : ${ApiConfig.companyPhone}',
                        () => ws.sendPreFilledMessage(
                            'Bonjour, je souhaite en savoir plus.')),
                    const Divider(height: 1),
                    _infoRow(Icons.location_on_outlined,
                        ApiConfig.companyAddress, null),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Envoyez-nous un message',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Nom complet *'),
                    validator: _required,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _whatsapp,
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
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _company,
                    decoration:
                        const InputDecoration(labelText: 'Entreprise'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _subject,
                    decoration: const InputDecoration(labelText: 'Objet'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _message,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Message *'),
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? '10 caracteres minimum'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                          : const Icon(Icons.send),
                      label: const Text('Envoyer'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.brand500),
      title: Text(value),
      trailing:
          onTap != null ? const Icon(Icons.arrow_forward_ios, size: 14) : null,
      onTap: onTap,
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Requis' : null;
}
