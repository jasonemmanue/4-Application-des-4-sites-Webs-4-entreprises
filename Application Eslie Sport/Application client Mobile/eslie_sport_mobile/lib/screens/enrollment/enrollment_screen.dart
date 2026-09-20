import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../models/enrollment.dart';
import '../../models/payment.dart';
import '../../models/schedule_slot.dart';
import '../../services/api_client.dart';
import '../../services/payment_service.dart';
import '../../services/providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/payment_method_picker.dart';
import '../payment/payment_wait_screen.dart';

class EnrollmentScreen extends ConsumerStatefulWidget {
  final String? activitySlug;
  final String? slotId;

  const EnrollmentScreen({super.key, this.activitySlug, this.slotId});

  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  int _step = 0;
  final _formStep1 = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _whatsapp = TextEditingController();
  final _feedback = TextEditingController();
  DateTime _specificDate = DateTime.now().add(const Duration(days: 1));

  PaymentOperator? _operator;
  final _payerPhone = TextEditingController();
  bool _submitting = false;

  ScheduleSlot? _slot;

  int _sessionPrice = 3000;
  int get _deposit =>
      (_sessionPrice * ApiConfig.depositPercent / 100).round();

  @override
  void initState() {
    super.initState();
    _payerPhone.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _whatsapp.dispose();
    _feedback.dispose();
    _payerPhone.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    if (_slot != null) return;
    if (widget.slotId != null) {
      final slots = await ref.read(apiClientProvider).getSchedule();
      _slot = slots.firstWhere(
        (s) => s.id == widget.slotId,
        orElse: () => slots.first,
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (_slot == null) {
      _snack('Choisissez un creneau d\'abord.');
      return;
    }
    if (_operator == null) {
      _snack('Choisissez un moyen de paiement.');
      return;
    }
    final normalized =
        ref.read(paymentServiceProvider).normalizePhone(_payerPhone.text);
    if (!ref
        .read(paymentServiceProvider)
        .validatePhoneForOperator(_operator!, normalized)) {
      _snack('Numero incompatible avec ${_operator!.label}.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      final request = EnrollmentRequest(
        userName: _name.text.trim(),
        userWhatsapp: _whatsapp.text.trim(),
        slotId: _slot!.id,
        specificDate: _specificDate,
        feedback: _feedback.text.trim().isEmpty ? null : _feedback.text.trim(),
      );
      final enrollment = await api.createEnrollment(request);
      final init = await ref.read(paymentServiceProvider).initiate(
            enrollmentId: enrollment.id,
            operator: _operator!,
            paymentPhone: normalized,
          );

      if (!mounted) return;
      if (_operator == PaymentOperator.wave && init.paymentUrl.isNotEmpty) {
        await ref
            .read(paymentServiceProvider)
            .openCheckoutUrl(init.paymentUrl);
      }

      final result = await Navigator.of(context).push<PaymentStatus?>(
        MaterialPageRoute(
          builder: (_) => PaymentWaitScreen(
            reference: init.reference,
            operator: _operator!,
            amount: init.amount.round(),
          ),
        ),
      );

      if (!mounted) return;
      final ok = result == PaymentStatus.completed;
      context.pushReplacement(
        '/payment/result',
        extra: {
          'reference': init.reference,
          'success': ok,
          'message': ok
              ? 'Depot recu. Reservation ${enrollment.id.substring(0, 8)} confirmee.'
              : 'Paiement non finalise. Reessayez.',
        },
      );
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateStep1() => _formStep1.currentState?.validate() ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: FutureBuilder(
        future: _loadContext(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              _slot == null &&
              widget.slotId != null) {
            return const LoadingState();
          }
          if (snap.hasError) {
            return ErrorState(
              message: snap.error.toString(),
              onRetry: () => setState(() {}),
            );
          }
          return _buildBody();
        },
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _stepIndicator(),
        Expanded(
          child: IndexedStack(
            index: _step,
            children: [
              _stepInfos(),
              _stepDetails(),
              _stepPayment(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepIndicator() {
    const labels = ['Infos', 'Seance', 'Paiement'];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(3, (i) {
          final active = i == _step;
          final done = i < _step;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
              child: Column(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: (active || done)
                          ? AppColors.primary
                          : AppColors.darkBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(labels[i],
                      style: TextStyle(
                        color:
                            active ? AppColors.primary : AppColors.darkMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _stepInfos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formStep1,
        child: Column(
          children: [
            TextFormField(
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_validateStep1()) setState(() => _step = 1);
                },
                child: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_slot != null) ...[
            _summaryRow('Activite', _slot!.activityName),
            _summaryRow('Jour', weekDayName(_slot!.dayOfWeek)),
            _summaryRow('Horaire', '${_slot!.startTime} - ${_slot!.endTime}'),
            if (_slot!.coachName != null)
              _summaryRow('Coach', _slot!.coachName!),
          ] else
            const Text('Veuillez choisir un creneau via le planning.',
                style: TextStyle(color: AppColors.darkMuted)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date de la seance',
                    style: TextStyle(color: AppColors.darkMuted, fontSize: 13)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                      initialDate: _specificDate,
                    );
                    if (picked != null) {
                      setState(() => _specificDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.darkLighter,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 10),
                        Text(formatDate(_specificDate),
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Text('Prix de la seance',
                        style: TextStyle(color: AppColors.darkMuted, fontSize: 13)),
                    const Spacer(),
                    Text(formatFcfa(_sessionPrice),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feedback,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Note (optionnel)'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _slot == null ? null : () => setState(() => _step = 2),
                  child: const Text('Passer au paiement'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepPayment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.dark),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.dark, fontSize: 13),
                      children: [
                        const TextSpan(
                            text: 'Depot 50% requis : ',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        TextSpan(text: formatFcfa(_deposit)),
                        const TextSpan(text: ' sur '),
                        TextSpan(text: formatFcfa(_sessionPrice)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Moyen de paiement',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 10),
          PaymentMethodPicker(
            selected: _operator,
            onChanged: (op) => setState(() {
              _operator = op;
              if (_payerPhone.text.isEmpty) _payerPhone.text = _whatsapp.text;
            }),
          ),
          if (_operator != null) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _payerPhone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Numero ${_operator!.label}',
                prefixText: '+225 ',
                helperText: _operator!.requiredPrefix != null
                    ? 'Doit commencer par ${_operator!.requiredPrefix}'
                    : null,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => setState(() => _step = 1),
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.dark),
                        )
                      : const Icon(Icons.lock),
                  label: Text(_submitting
                      ? 'Traitement...'
                      : 'Payer ${formatFcfa(_deposit)}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(color: AppColors.darkMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
