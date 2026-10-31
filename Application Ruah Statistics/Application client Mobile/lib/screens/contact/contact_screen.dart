import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../models/contact_message.dart';
import '../../providers/providers.dart';
import '../../services/input_sanitizer.dart';

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
      name: InputSanitizer.sanitize(_name.text, maxLength: 100),
      whatsappNumber: _whatsapp.text.trim(),
      message: InputSanitizer.sanitize(_message.text, maxLength: 2000),
      subject: _subject.text.trim().isEmpty
          ? null
          : InputSanitizer.sanitize(_subject.text, maxLength: 200),
      company: _company.text.trim().isEmpty
          ? null
          : InputSanitizer.sanitize(_company.text, maxLength: 100),
    );
    try {
      await ref.read(apiClientProvider).submitContactMessage(message);
      if (!mounted) return;
      await _offerWhatsApp(message);
      _resetForm();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message envoyé. Nous vous répondrons vite.')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = InputSanitizer.safeErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
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
          "Nous pouvons ouvrir WhatsApp avec un récapitulatif "
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
      appBar: AppBar(title: const Text('Écrire au cabinet')),
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
                    maxLength: 100,
                    decoration: const InputDecoration(labelText: 'Nom complet *'),
                    validator: InputSanitizer.validateName,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _whatsapp,
                    keyboardType: TextInputType.phone,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'Numéro WhatsApp *',
                      hintText: '+225 ...',
                    ),
                    validator: InputSanitizer.validatePhone,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _company,
                    maxLength: 100,
                    decoration:
                        const InputDecoration(labelText: 'Entreprise'),
                    validator: (v) => InputSanitizer.validateOptionalText(v, max: 100),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _subject,
                    maxLength: 200,
                    decoration: const InputDecoration(labelText: 'Objet'),
                    validator: (v) => InputSanitizer.validateOptionalText(v, max: 200),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _message,
                    maxLines: 5,
                    maxLength: 2000,
                    decoration: const InputDecoration(labelText: 'Message *'),
                    validator: InputSanitizer.validateMessage,
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

}
