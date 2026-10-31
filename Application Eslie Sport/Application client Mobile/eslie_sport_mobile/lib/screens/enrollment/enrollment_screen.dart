import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../models/enrollment.dart';
import '../../models/payment.dart';
import '../../models/schedule_slot.dart';
import '../../services/api_client.dart';
import '../../services/member_profile.dart';
import '../../services/payment_service.dart';
import '../../services/providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/checkout_section.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

/// Reservation en 3 etapes : infos, seance (date + formule), paiement.
///
/// La formule (`payment_type`) est obligatoire : c'est d'elle que le serveur
/// deduit l'acompte. Sans elle la reservation prendrait une place sans paiement
/// et `POST /payments/init` repondrait 409.
class EnrollmentScreen extends ConsumerStatefulWidget {
  final String? slotId;
  final DateTime? date;

  const EnrollmentScreen({super.key, this.slotId, this.date});

  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  int _step = 0;
  final _formStep1 = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _whatsapp = TextEditingController();
  final _feedback = TextEditingController();
  final _payerPhone = TextEditingController();

  DateTime? _date;
  EnrollmentFormula _formula = EnrollmentFormula.session;
  String _sessionType = 'Collectif';
  PaymentOperator? _operator;
  bool _submitting = false;

  // Reservation deja enregistree pour ces memes choix : un second essai de
  // paiement la reutilise au lieu de creer un doublon au back-office.
  Enrollment? _enrollment;
  String? _enrollmentKey;

  @override
  void dispose() {
    _name.dispose();
    _whatsapp.dispose();
    _feedback.dispose();
    _payerPhone.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Dates reservables : uniquement le jour de semaine du creneau.
  List<DateTime> _datesFor(ScheduleSlot slot) {
    if (slot.specificDate != null) return [slot.specificDate!];
    final first = nextDateForWeekday(slot.dayOfWeek);
    return [for (var i = 0; i < 6; i++) first.add(Duration(days: 7 * i))];
  }

  DateTime _selectedDate(ScheduleSlot slot) {
    final dates = _datesFor(slot);
    final wanted = _date ?? widget.date;
    if (wanted != null) {
      for (final d in dates) {
        if (d.year == wanted.year &&
            d.month == wanted.month &&
            d.day == wanted.day) {
          return d;
        }
      }
    }
    return dates.first;
  }

  int _price() {
    final catalog = ref.read(subscriptionsProvider).valueOrNull ?? const [];
    for (final s in catalog) {
      if (s.name == _formula.catalogName) return s.price.round();
    }
    return _formula.fallbackPrice;
  }

  int get _deposit =>
      (_price() * ApiConfig.depositPercent / 100).round();

  Future<void> _submit(ScheduleSlot slot) async {
    final op = _operator;
    final paymentsOpen =
        ref.read(paymentConfigProvider).valueOrNull?.enabled ?? true;
    final ps = ref.read(paymentServiceProvider);
    if (paymentsOpen) {
      if (op == null) {
        _snack('Choisissez un moyen de paiement.');
        return;
      }
      if (op.needsPhone) {
        final error = ps.phoneError(op, _payerPhone.text);
        if (error != null) {
          _snack(error);
          return;
        }
      }
    }

    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      final date = _selectedDate(slot);
      final whatsapp = ps.normalizePhone(_whatsapp.text);
      final key = [
        slot.id,
        formatIso(date),
        _formula.apiValue,
        _sessionType,
        _name.text.trim(),
        whatsapp,
      ].join('|');
      if (_enrollment == null || _enrollmentKey != key) {
        _enrollment = await api.createEnrollment(EnrollmentRequest(
          userName: _name.text.trim(),
          userWhatsapp: whatsapp,
          slotId: slot.id,
          specificDate: date,
          sessionType: _sessionType,
          paymentType: _formula.apiValue,
          feedback: _feedback.text.trim().isEmpty ? null : _feedback.text.trim(),
        ));
        _enrollmentKey = key;
      }
      final enrollment = _enrollment!;
      await ref.read(memberNameProvider.notifier).save(_name.text);

      if (!mounted) return;
      // Guichet coupe cote serveur : la place est prise, l'acompte se regle
      // a la salle. Rien a payer ici.
      if (!enrollment.awaitsPayment) {
        final waitlisted = enrollment.status == 'waitlisted';
        context.pushReplacement('/payment/result', extra: {
          'reference': '',
          'success': true,
          'title': waitlisted ? 'Vous êtes sur liste d\'attente' : 'Place réservée !',
          'message': waitlisted
              ? 'Ce cours est complet. La salle vous contactera dès qu\'une place se libère.'
              : 'Votre place est réservée le ${formatDate(date)}. Le règlement se fait à la salle.',
        });
        return;
      }

      final init = await ps.initiate(
        enrollmentId: enrollment.id,
        operator: op!,
        paymentPhone: op.needsPhone ? ps.normalizePhone(_payerPhone.text) : '',
      );
      if (!mounted) return;
      await runCheckout(
        context: context,
        ref: ref,
        init: init,
        operator: op,
        successMessage:
            'Acompte de ${formatFcfa(init.amount)} reçu. Votre place est réservée le ${formatDate(date)}, le reste se règle à la salle.',
      );
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider);
    // Precharge le tarif et les moyens de paiement avant l'etape 3.
    ref.watch(subscriptionsProvider);
    ref.watch(paymentConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Réservation')),
      body: schedule.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(scheduleProvider),
        ),
        data: (slots) {
          final matches = slots.where((s) => s.id == widget.slotId);
          if (matches.isEmpty) {
            return EmptyState(
              icon: Icons.event_busy,
              title: 'Créneau introuvable',
              subtitle: 'Choisissez un cours depuis le planning.',
              action: ElevatedButton(
                onPressed: () => context.go('/schedule'),
                child: const Text('Voir le planning'),
              ),
            );
          }
          final slot = matches.first;
          return Column(
            children: [
              _stepIndicator(),
              Expanded(
                child: IndexedStack(
                  index: _step,
                  children: [
                    _stepInfos(),
                    _stepDetails(slot),
                    _stepPayment(slot),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stepIndicator() {
    const labels = ['Vos infos', 'Séance', 'Paiement'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                child: Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color:
                            i <= _step ? AppColors.accent : AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: TextStyle(
                        color: i == _step
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight:
                            i == _step ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nom requis';
                if (v.trim().length < 2) return 'Nom trop court';
                return null;
              },
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _whatsapp,
              keyboardType: TextInputType.phone,
              maxLength: 15,
              validator: (v) {
                if (v == null || v.trim().length < 8) {
                  return 'Minimum 8 chiffres';
                }
                if (!RegExp(r'^[0-9\s\-+]+$').hasMatch(v.trim())) {
                  return 'Chiffres uniquement';
                }
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'Numéro WhatsApp',
                prefixText: '+225 ',
                helperText: 'La salle vous confirme la réservation sur WhatsApp',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formStep1.currentState?.validate() ?? false) {
                    setState(() => _step = 1);
                  }
                },
                child: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepDetails(ScheduleSlot slot) {
    final selected = _selectedDate(slot);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.activityName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${weekDayName(slot.dayOfWeek)} · ${slot.startTime} – ${slot.endTime}'
                  '${slot.coachName != null ? ' · Coach ${slot.coachName}' : ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _label('Date de la séance'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in _datesFor(slot))
                _choice(
                  '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
                  d == selected,
                  () => setState(() => _date = d),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Type de séance'),
          Wrap(
            spacing: 8,
            children: [
              for (final type in const ['Collectif', 'Individuel'])
                _choice(type, _sessionType == type,
                    () => setState(() => _sessionType = type)),
            ],
          ),
          const SizedBox(height: 16),
          _label('Votre formule'),
          for (final f in EnrollmentFormula.values)
            _formulaTile(f),
          const SizedBox(height: 6),
          TextField(
            controller: _feedback,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Note (facultatif)'),
          ),
          const SizedBox(height: 12),
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
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => setState(() => _step = 2),
                  child: const Text('Passer au paiement'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formulaTile(EnrollmentFormula f) {
    final active = f == _formula;
    final catalog = ref.watch(subscriptionsProvider).valueOrNull ?? const [];
    final price = catalog
        .where((s) => s.name == f.catalogName)
        .map((s) => s.price.round())
        .firstOrNull ?? f.fallbackPrice;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: active ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => setState(() => _formula = f),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
                width: active ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    f.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  formatFcfa(price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepPayment(ScheduleSlot slot) {
    final config = ref.watch(paymentConfigProvider).valueOrNull;
    final paymentsOpen = config?.enabled ?? true;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${slot.activityName} · ${formatDate(_selectedDate(slot))}',
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatFcfa(_deposit),
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Acompte de 50 % sur ${formatFcfa(_price())}. Le reste se règle à la salle.',
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (paymentsOpen)
            CheckoutSection(
              selected: _operator,
              phone: _payerPhone,
              onSelect: (op) => setState(() {
                _operator = op;
                if (op.needsPhone && _payerPhone.text.isEmpty) {
                  _payerPhone.text = _whatsapp.text;
                }
              }),
            )
          else
            _card(const Text(
              'Le paiement en ligne est momentanément indisponible. Votre place sera réservée et vous réglerez à la salle.',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            )),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _submitting ? null : () => setState(() => _step = 1),
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : () => _submit(slot),
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : Icon(paymentsOpen ? Icons.lock : Icons.check),
                  label: Text(
                    _submitting
                        ? 'Traitement...'
                        : paymentsOpen
                            ? 'Payer ${formatFcfa(_deposit)}'
                            : 'Réserver',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );

  Widget _choice(String label, bool active, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.full),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.onPrimary : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
