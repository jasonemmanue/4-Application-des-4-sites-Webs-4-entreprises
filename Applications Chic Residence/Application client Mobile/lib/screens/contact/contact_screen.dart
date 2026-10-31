import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../config/format.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../services/whatsapp_service.dart';

/// Contact. Le message part vraiment (`POST /contact`) et arrive dans « Messages »
/// de l'administration ; l'ancien bouton n'affichait qu'un faux accusé.
class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  late final _name =
      TextEditingController(text: ref.read(guestNameProvider) ?? '');
  final _phone = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().length >= 2 &&
      _phone.text.replaceAll(RegExp(r'\D'), '').length >= 8 &&
      _message.text.trim().length >= 10;

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).dio.post('/contact', data: {
        'name': _name.text.trim(),
        'phone': Phones.toApi(_phone.text),
        'message': _message.text.trim(),
      });
      if (!mounted) return;
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Message envoyé. Nous vous répondrons rapidement.')),
      );
      setState(() {});
    } catch (e) {
      final s = e.toString();
      setState(() => _error = s.startsWith('DioException')
          ? 'L\'envoi a échoué. Vérifiez votre connexion.'
          : s);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final info = ref.watch(publicInfoProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Nous contacter')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              border: t.isDark ? Border.all(color: t.border) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chic Résidence',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _ContactRow(
                  icon: Icons.place_outlined,
                  text: info?.address.isNotEmpty == true
                      ? info!.address
                      : ApiConfig.companyAddress,
                ),
                _ContactRow(
                  icon: Icons.call_outlined,
                  text: info?.phone.isNotEmpty == true
                      ? info!.phone
                      : ApiConfig.contactPhone,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => WhatsAppService.send(
                            'Bonjour CHIC RESIDENCE,'),
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: WhatsAppService.call,
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('Appeler'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Envoyer un message',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nom',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phone,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              hintText: '07 00 00 00 00',
              prefixIcon: Icon(Icons.call_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _message,
            onChanged: (_) => setState(() {}),
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Votre message (10 caractères minimum)',
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: !_valid || _sending ? null : _send,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.tokens.brand),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }
}
