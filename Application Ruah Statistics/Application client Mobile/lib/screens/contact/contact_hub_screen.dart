import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/lead.dart';
import '../../providers/providers.dart';
import '../../services/client_profile.dart';
import '../../services/input_sanitizer.dart';
import '../../widgets/ruah_ui.dart';

/// Onglet Contact : demande de devis sur une seule page, envoyée sur
/// `POST /leads/quote-request`. Le lead apparaît dans l'admin avec la source
/// « android ». Le cabinet répond sur WhatsApp : c'est donc le numéro qui est
/// demandé, l'API n'a pas de champ e-mail.
class ContactHubScreen extends ConsumerStatefulWidget {
  const ContactHubScreen({super.key});

  @override
  ConsumerState<ContactHubScreen> createState() => _ContactHubScreenState();
}

class _ContactHubScreenState extends ConsumerState<ContactHubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _whatsapp = TextEditingController();
  final _company = TextEditingController();
  final _message = TextEditingController();
  MissionType? _mission;
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_name, _whatsapp, _company, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final lead = QuoteLead(
      name: InputSanitizer.sanitize(_name.text, maxLength: 100),
      whatsappNumber: _whatsapp.text.trim(),
      message: InputSanitizer.sanitize(_message.text, maxLength: 2000),
      company: _company.text.trim().isEmpty
          ? null
          : InputSanitizer.sanitize(_company.text, maxLength: 100),
      missionType: _mission,
    );
    try {
      final Map<String, dynamic> resp =
          await ref.read(apiClientProvider).submitQuoteRequest(lead);
      await ref
          .read(clientProfileProvider.notifier)
          .save(name: lead.name, company: lead.company);
      if (!mounted) return;
      await ref
          .read(whatsAppServiceProvider)
          .sendPreFilledMessage(lead.whatsappSummary);
      if (!mounted) return;
      _formKey.currentState?.reset();
      for (final c in [_name, _whatsapp, _company, _message]) {
        c.clear();
      }
      setState(() => _mission = null);
      context.push(AppRoutes.quoteConfirmation,
          extra: resp['id']?.toString() ?? '');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(InputSanitizer.safeErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _field(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 22),
        counterText: '',
      );

  @override
  Widget build(BuildContext context) {
    final bool dark = isDarkOf(context);
    final Color outline = dark ? Colors.white : AppColors.brand600;
    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 0,
          child: IgnorePointer(
            child: CustomPaint(
              size: const Size(190, 140),
              painter: _SwooshPainter(),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              const RuahHeader(),
              const PageTitle(
                title: 'Parlons de votre projet',
                subtitle: 'Décrivez votre besoin, notre équipe vous accompagne.',
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        maxLength: 100,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: _field(
                            'Votre nom', Icons.person_outline_rounded),
                        validator: InputSanitizer.validateName,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _whatsapp,
                        maxLength: 20,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: _field('Numéro WhatsApp (+225 ...)',
                            Icons.chat_bubble_outline_rounded),
                        validator: InputSanitizer.validatePhone,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _company,
                        maxLength: 100,
                        textInputAction: TextInputAction.next,
                        decoration:
                            _field('Organisation', Icons.apartment_rounded),
                        validator: (v) =>
                            InputSanitizer.validateOptionalText(v, max: 100),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<MissionType>(
                        initialValue: _mission,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        decoration: _field(
                            'Type de besoin', Icons.format_list_bulleted_rounded),
                        items: [
                          for (final m in MissionType.values)
                            DropdownMenuItem(value: m, child: Text(m.label)),
                        ],
                        onChanged: (m) => setState(() => _mission = m),
                        validator: (m) =>
                            m == null ? 'Choisissez un type de besoin' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _message,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 2000,
                        decoration: _field('Décrivez votre projet...',
                            Icons.chat_outlined),
                        validator: InputSanitizer.validateMessage,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 20),
                          label: const Text('Demander un devis'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: outline,
                            backgroundColor: dark
                                ? Colors.transparent
                                : AppColors.brandTint.withValues(alpha: 0.55),
                            side: BorderSide(color: outline),
                          ),
                          onPressed: () => ref
                              .read(whatsAppServiceProvider)
                              .sendPreFilledMessage(
                                'Bonjour, je souhaite echanger avec '
                                '${ApiConfig.companyName}.',
                              ),
                          icon: const Icon(Icons.chat_rounded, size: 20),
                          label: const Text('Échanger sur WhatsApp'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const _TrustRow(),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.message),
                  child: const Text('Une simple question ? Écrire au cabinet'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    final bool dark = isDarkOf(context);
    final Color border = dark ? AppColors.charcoal700 : AppColors.lightBorder;
    Widget item(IconData icon, String label) => Expanded(
          child: Column(
            children: [
              Icon(icon,
                  size: 30, color: dark ? Colors.white : AppColors.brand600),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: fgOf(context),
                ),
              ),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            item(Icons.verified_user_rounded, 'Confidentialité'),
            VerticalDivider(width: 1, color: border),
            item(Icons.groups_rounded, 'Équipe pluridisciplinaire'),
            VerticalDivider(width: 1, color: border),
            item(Icons.handshake_rounded, 'Approche sur mesure'),
          ],
        ),
      ),
    );
  }
}

class _SwooshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    void band(Color color, double start, double end) {
      final path = Path()
        ..moveTo(w * start, 0)
        ..quadraticBezierTo(w * (start + 0.1), h * end * 0.72, w, h * end)
        ..lineTo(w, 0)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    band(AppColors.brandTint, 0.2, 1);
    band(AppColors.accent500, 0.48, 0.9);
    band(AppColors.navy, 0.58, 0.72);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
