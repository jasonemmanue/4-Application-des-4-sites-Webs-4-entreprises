import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _whatsapp = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).sendContact(
            name: _name.text.trim(),
            whatsapp: _whatsapp.text.trim(),
            subject: _subject.text.trim(),
            message: _message.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message envoye. Merci !')),
      );
      _formKey.currentState!.reset();
      _name.clear();
      _whatsapp.clear();
      _subject.clear();
      _message.clear();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contactez-nous',
                    style: TextStyle(
                        color: AppColors.dark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                _quick(Icons.phone, ApiConfig.contactPhoneDisplay,
                    () => launchUrl(Uri.parse('tel:${ApiConfig.contactPhone}'))),
                _quick(Icons.chat, 'WhatsApp',
                    () => launchUrl(Uri.parse(
                        'https://wa.me/${ApiConfig.whatsappNumber}'))),
                _quick(Icons.location_on, ApiConfig.gymLocation, null),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _whatsapp,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().length < 8) return 'Min 8 chiffres';
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Numero WhatsApp',
                    prefixText: '+225 ',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _subject,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  decoration: const InputDecoration(labelText: 'Sujet'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _message,
                  minLines: 4,
                  maxLines: 6,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: const Icon(Icons.send),
                    label: Text(_busy ? 'Envoi...' : 'Envoyer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quick(IconData icon, String text, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.dark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
