import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/lead.dart';
import '../../providers/providers.dart';
import '../../services/client_profile.dart';

class QuoteFlowScreen extends ConsumerStatefulWidget {
  const QuoteFlowScreen({super.key});

  @override
  ConsumerState<QuoteFlowScreen> createState() => _QuoteFlowScreenState();
}

class _QuoteFlowScreenState extends ConsumerState<QuoteFlowScreen> {
  int _step = 0;
  bool _submitting = false;

  MissionType? _mission;
  final _timeline = TextEditingController();
  final _description = TextEditingController();
  BudgetRange? _budget;

  final _name = TextEditingController();
  final _whatsapp = TextEditingController();
  final _company = TextEditingController();

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  @override
  void dispose() {
    for (final c in [_timeline, _description, _name, _whatsapp, _company]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _next() async {
    if (_step == 0 && _mission == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selectionnez un type de mission')),
      );
      return;
    }
    if (_step == 1 && !(_step1Key.currentState?.validate() ?? false)) return;
    if (_step == 2 && !(_step2Key.currentState?.validate() ?? false)) return;
    setState(() => _step = (_step + 1).clamp(0, 3));
  }

  void _back() => setState(() => _step = (_step - 1).clamp(0, 3));

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final lead = QuoteLead(
      name: _name.text.trim(),
      whatsappNumber: _whatsapp.text.trim(),
      message: _description.text.trim(),
      company: _company.text.trim().isEmpty ? null : _company.text.trim(),
      missionType: _mission,
      budgetRange: _budget,
      timeline: _timeline.text.trim().isEmpty ? null : _timeline.text.trim(),
    );

    try {
      final Map<String, dynamic> resp =
          await ref.read(apiClientProvider).submitQuoteRequest(lead);
      // Pas de compte : le nom de la dernière demande personnalise le
      // Profil.
      await ref
          .read(clientProfileProvider.notifier)
          .save(name: lead.name, company: lead.company);
      if (!mounted) return;
      await ref
          .read(whatsAppServiceProvider)
          .sendPreFilledMessage(lead.whatsappSummary);
      if (!mounted) return;
      final String reference =
          resp['reference']?.toString() ?? resp['id']?.toString() ?? '';
      context.go(AppRoutes.quoteConfirmation, extra: reference);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demande de devis'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 4,
            backgroundColor: AppColors.charcoal700,
            valueColor: const AlwaysStoppedAnimation(AppColors.brand500),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Expanded(child: _buildStep()),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _buildMissionStep(),
      1 => _buildProjectStep(),
      2 => _buildContactStep(),
      _ => _buildSummaryStep(),
    };
  }

  Widget _buildMissionStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type de mission',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          const Text('Selectionnez la nature de votre besoin.'),
          const SizedBox(height: AppSpacing.lg),
          for (final m in MissionType.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _MissionTile(
                mission: m,
                selected: _mission == m,
                onTap: () => setState(() => _mission = m),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectStep() {
    return SingleChildScrollView(
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details du projet',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _description,
              maxLines: 5,
              decoration:
                  const InputDecoration(labelText: 'Description du besoin *'),
              validator: (v) => (v == null || v.trim().length < 20)
                  ? '20 caracteres minimum'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _timeline,
              decoration: const InputDecoration(labelText: 'Delais souhaites'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Budget indicatif',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in BudgetRange.values)
                  ChoiceChip(
                    label: Text(b.label),
                    selected: _budget == b,
                    onSelected: (_) => setState(() => _budget = b),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactStep() {
    return SingleChildScrollView(
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vos coordonnees',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nom complet *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
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
              decoration: const InputDecoration(labelText: 'Entreprise'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recapitulatif',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          _summaryRow('Mission', _mission?.label ?? '-'),
          _summaryRow('Budget', _budget?.label ?? '-'),
          _summaryRow('Delais',
              _timeline.text.trim().isEmpty ? '-' : _timeline.text.trim()),
          _summaryRow('Description', _description.text.trim()),
          const Divider(height: 32),
          _summaryRow('Contact', _name.text.trim()),
          _summaryRow('WhatsApp', _whatsapp.text.trim()),
          _summaryRow('Entreprise',
              _company.text.trim().isEmpty ? '-' : _company.text.trim()),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.brand400)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final bool isLast = _step == 3;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : _back,
                  child: const Text('Retour'),
                ),
              ),
            if (_step > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton(
                onPressed: _submitting ? null : (isLast ? _submit : _next),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isLast ? 'Envoyer la demande' : 'Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  final MissionType mission;
  final bool selected;
  final VoidCallback onTap;

  const _MissionTile({
    required this.mission,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brand500.withValues(alpha: 0.15)
              : Theme.of(context).cardColor,
          border: Border.all(
            color: selected ? AppColors.brand500 : AppColors.charcoal700,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Icon(
              _iconFor(mission),
              color: selected ? AppColors.brand400 : AppColors.brand600,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mission.label,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(mission.description,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.brand400 : AppColors.charcoal600,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(MissionType m) => switch (m) {
        MissionType.study => Icons.analytics_outlined,
        MissionType.consulting => Icons.psychology_outlined,
        MissionType.training => Icons.school_outlined,
        MissionType.audit => Icons.fact_check_outlined,
        MissionType.other => Icons.more_horiz,
      };
}
