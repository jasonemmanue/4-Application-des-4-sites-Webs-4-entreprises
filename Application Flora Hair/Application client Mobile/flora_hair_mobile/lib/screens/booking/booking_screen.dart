import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/booking.dart';
import '../../models/category.dart';
import '../../models/payment.dart';
import '../../models/service.dart';
import '../../models/team_member.dart';
import '../../services/api_client.dart';
import '../../services/appointments.dart';
import '../../services/client_profile.dart';
import '../../services/payment_service.dart';
import '../../services/providers.dart';
import '../../services/push_notification_service.dart';
import '../../widgets/booking_form.dart';
import '../../widgets/flora_ui.dart';
import '../../widgets/operator_grid.dart';
import '../../widgets/payment_sheet.dart';
import '../../widgets/state_widgets.dart';
import 'booking_state.dart';

/// Réservation en trois étapes : prestation et expert·e, créneau, confirmation.
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _payPhoneCtrl = TextEditingController();

  PaymentOperator? _operator;
  List<String> _slots = <String>[];
  bool _loadingSlots = false;
  bool _submitting = false;

  /// Réservation déjà créée pour ce créneau. Sans elle, réessayer après un refus
  /// de paiement recréerait le rendez-vous : le backend répondrait « créneau
  /// déjà réservé », à cause de la demande de la cliente elle-même.
  String? _createdBookingId;
  String? _createdSignature;

  @override
  void initState() {
    super.initState();
    final known = ref.read(clientNameProvider);
    if (known != null) _nameCtrl.text = known;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    _payPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    final draft = ref.read(bookingDraftProvider);
    if (draft.service == null ||
        draft.teamMember == null ||
        draft.date == null) {
      return;
    }
    setState(() => _loadingSlots = true);
    try {
      final slots = await ref.read(apiClientProvider).fetchAvailableSlots(
            serviceId: draft.service!.id,
            teamMemberId: draft.teamMember!.id,
            date: draft.date!,
          );
      if (!mounted) return;
      setState(() => _slots = _futureOnly(slots, draft.date!));
    } catch (_) {
      if (!mounted) return;
      setState(() => _slots = <String>[]);
      _snack('Impossible de charger les créneaux.');
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  /// L'API ne connaît que les réservations : aujourd'hui, les heures déjà
  /// passées lui paraissent libres.
  List<String> _futureOnly(List<String> slots, DateTime date) {
    final now = DateTime.now();
    if (date.year != now.year || date.month != now.month || date.day != now.day) {
      return slots;
    }
    final current = now.hour * 60 + now.minute;
    return slots.where((s) {
      final parts = s.split(':');
      if (parts.length != 2) return false;
      return int.parse(parts[0]) * 60 + int.parse(parts[1]) > current;
    }).toList();
  }

  /// Ouverture sur le premier jour ouvré : les créneaux sont visibles d'emblée.
  void _enterSlotStep() {
    final notifier = ref.read(bookingDraftProvider.notifier);
    if (ref.read(bookingDraftProvider).date == null) {
      var day = DateTime.now();
      day = DateTime(day.year, day.month, day.day);
      if (day.weekday == DateTime.sunday) {
        day = day.add(const Duration(days: 1));
      }
      notifier.setDate(day);
    }
    _loadSlots();
  }

  Future<void> _submit(PaymentConfig config) async {
    if (!_formKey.currentState!.validate()) return;
    final online = config.configured && config.operators.isNotEmpty;
    final op = _operator;
    if (online) {
      if (op == null) {
        _snack('Choisissez un moyen de paiement.');
        return;
      }
      if (op.needsPhone) {
        final problem = PaymentService.validatePhone(_payPhoneCtrl.text);
        if (problem != null) {
          _snack(problem);
          return;
        }
      }
    }

    final notifier = ref.read(bookingDraftProvider.notifier);
    notifier.setCustomer(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );
    final draft = ref.read(bookingDraftProvider);
    setState(() => _submitting = true);
    try {
      final bookingId = await _ensureBooking(draft, online);
      if (!online) {
        // Paiement en ligne coupé dans le back-office : acompte réglé au salon.
        _finishDraft();
        if (!mounted) return;
        _snack("Rendez-vous enregistré. L'acompte se règle au salon.");
        context.go('/appointments');
        return;
      }
      final init = await ref.read(paymentServiceProvider).initPayment(
            bookingId: bookingId,
            operator: op!,
            phone: op.needsPhone
                ? PaymentService.toInternational(_payPhoneCtrl.text)
                : null,
          );
      await ref
          .read(appointmentsProvider.notifier)
          .attachPayment(bookingId, init.reference);
      _finishDraft();
      if (!mounted) return;
      await continueToPayment(context, init, op);
    } catch (e) {
      if (mounted) {
        _snack(e is ApiException ? e.message : 'Une erreur est survenue.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<String> _ensureBooking(BookingDraft draft, bool online) async {
    final signature = '${draft.service!.id}|${draft.teamMember!.id}|'
        '${draft.date}|${draft.startTime}';
    if (_createdBookingId != null && _createdSignature == signature) {
      return _createdBookingId!;
    }
    final created = await ref.read(apiClientProvider).createBooking(
          Booking(
            serviceId: draft.service!.id,
            teamMemberId: draft.teamMember!.id,
            date: draft.date!,
            timeSlot: draft.startTime!,
            customerName: draft.customerName,
            customerPhone: draft.customerPhone,
            customerEmail:
                draft.customerEmail.isEmpty ? null : draft.customerEmail,
            notes: draft.notes.isEmpty ? null : draft.notes,
            paymentMethod: online ? Booking.onlinePayment : Booking.cashPayment,
            pushToken: PushNotificationService.instance.fcmToken,
          ),
        );
    final bookingId = created.id ?? '';
    _createdBookingId = bookingId;
    _createdSignature = signature;
    await ref.read(clientNameProvider.notifier).save(draft.customerName);
    await ref.read(appointmentsProvider.notifier).add(
          LocalAppointment(
            bookingId: bookingId,
            serviceName: draft.service!.name,
            memberName: draft.teamMember!.name,
            date: Booking.dateOnly(draft.date!),
            time: draft.startTime!,
            imageUrl: draft.service!.imageUrl,
            status: created.status ?? 'pending',
            depositStatus: created.depositStatus ?? 'unpaid',
            depositAmount: created.depositAmount,
          ),
        );
    return bookingId;
  }

  void _finishDraft() {
    ref.read(bookingDraftProvider.notifier).reset();
    ref.read(bookingStepProvider.notifier).state = 0;
    _createdBookingId = null;
    _createdSignature = null;
  }

  void _next(int step, BookingDraft draft, PaymentConfig? config) {
    final stepNotifier = ref.read(bookingStepProvider.notifier);
    switch (step) {
      case 0:
        if (draft.service == null) {
          _snack('Sélectionnez une prestation');
          return;
        }
        if (draft.teamMember == null) {
          _snack('Sélectionnez votre expert·e');
          return;
        }
        stepNotifier.state = 1;
        _enterSlotStep();
        break;
      case 1:
        if (draft.startTime == null) {
          _snack('Sélectionnez un créneau');
          return;
        }
        stepNotifier.state = 2;
        break;
      case 2:
        if (config == null) {
          _snack('Moyens de paiement indisponibles. Réessayez.');
          ref.invalidate(paymentConfigProvider);
          return;
        }
        _submit(config);
        break;
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(bookingStepProvider);
    final draft = ref.watch(bookingDraftProvider);
    final configAsync = ref.watch(paymentConfigProvider);
    final config = configAsync.valueOrNull;
    final online = config != null &&
        config.configured &&
        config.operators.isNotEmpty;
    final deposit = draft.service == null
        ? 0
        : (draft.service!.priceMin * (config?.depositPercent ?? 50) / 100)
            .round();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Votre rendez-vous'),
        leading: step == 0
            ? null
            : IconButton(
                tooltip: 'Étape précédente',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () =>
                    ref.read(bookingStepProvider.notifier).state = step - 1,
              ),
      ),
      body: Column(
        children: <Widget>[
          _Stepper(step: step),
          Expanded(child: _buildStep(step, draft, configAsync, deposit)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _submitting ? null : () => _next(step, draft, config),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(step < 2
                          ? 'Continuer'
                          : online
                              ? 'Payer ${formatFcfa(deposit)}'
                              : 'Confirmer mon rendez-vous'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    int step,
    BookingDraft draft,
    AsyncValue<PaymentConfig> configAsync,
    int deposit,
  ) {
    switch (step) {
      case 0:
        return _StepPrestation(draft: draft);
      case 1:
        return _StepSlot(
          draft: draft,
          slots: _slots,
          loading: _loadingSlots,
          notes: _notesCtrl,
          onDate: (d) {
            ref.read(bookingDraftProvider.notifier).setDate(d);
            _loadSlots();
          },
          onSlot: (t) => ref.read(bookingDraftProvider.notifier).setTime(t),
        );
      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Recap(draft: draft),
              const SizedBox(height: 18),
              BookingCustomerForm(
                formKey: _formKey,
                name: _nameCtrl,
                phone: _phoneCtrl,
                email: _emailCtrl,
              ),
              const SizedBox(height: 20),
              configAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => ErrorState(
                  message: 'Impossible de charger les moyens de paiement.',
                  onRetry: () => ref.invalidate(paymentConfigProvider),
                ),
                data: (config) => _paymentBlock(draft, config, deposit),
              ),
            ],
          ),
        );
    }
  }

  Widget _paymentBlock(BookingDraft draft, PaymentConfig config, int deposit) {
    if (!config.configured || config.operators.isEmpty) {
      return const FloraCard(
        child: Row(
          children: <Widget>[
            Icon(Icons.storefront_outlined, color: FloraColors.burgundy),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Le paiement en ligne n'est pas ouvert pour le moment : "
                "l'acompte se règle au salon.",
                style: TextStyle(color: FloraColors.textPrimary),
              ),
            ),
          ],
        ),
      );
    }
    final total = draft.service?.priceMin ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Acompte de ${config.depositPercent} %',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: FloraColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${formatFcfa(deposit)} maintenant, le reste '
          '(${formatFcfa(total - deposit)}) au salon.',
          style: const TextStyle(color: FloraColors.textSecondary),
        ),
        const SizedBox(height: 12),
        OperatorGrid(
          operators: config.operators,
          selected: _operator,
          onSelect: (op) => setState(() {
            _operator = op;
            if (op.needsPhone && _payPhoneCtrl.text.isEmpty) {
              _payPhoneCtrl.text = _phoneCtrl.text;
            }
          }),
        ),
        if (_operator != null && _operator!.needsPhone) ...<Widget>[
          const SizedBox(height: 12),
          TextField(
            controller: _payPhoneCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: 'Numéro ${_operator!.label} à débiter',
              hintText: '07 07 07 07 07',
              counterText: '',
            ),
          ),
        ],
        if (_operator != null) ...<Widget>[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.lock_outline,
                  size: 16, color: FloraColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _operator == PaymentOperator.card
                      ? 'Carte Visa ou Mastercard saisie sur la page sécurisée '
                          'Stripe, ouverte dans votre navigateur.'
                      : _operator == PaymentOperator.wave
                          ? "L'application Wave s'ouvre pour valider le paiement."
                          : 'Une demande de validation arrive sur votre '
                              'téléphone : saisissez votre code secret.',
                  style: const TextStyle(
                      fontSize: 12, color: FloraColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step});
  final int step;

  static const _labels = <String>['Prestation', 'Créneau', 'Confirmation'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < _labels.length; i++) ...<Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: i == 0
                            ? const SizedBox.shrink()
                            : Container(
                                height: 2,
                                color: i <= step
                                    ? FloraColors.burgundy
                                    : FloraColors.blush,
                              ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= step
                              ? FloraColors.burgundy
                              : FloraColors.blushLight,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: i <= step
                                ? Colors.white
                                : FloraColors.burgundy,
                          ),
                        ),
                      ),
                      Expanded(
                        child: i == _labels.length - 1
                            ? const SizedBox.shrink()
                            : Container(
                                height: 2,
                                color: i < step
                                    ? FloraColors.burgundy
                                    : FloraColors.blush,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: i == step ? FontWeight.w700 : FontWeight.w500,
                      color: i == step
                          ? FloraColors.burgundy
                          : FloraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepPrestation extends ConsumerStatefulWidget {
  const _StepPrestation({required this.draft});
  final BookingDraft draft;

  @override
  ConsumerState<_StepPrestation> createState() => _StepPrestationState();
}

class _StepPrestationState extends ConsumerState<_StepPrestation> {
  String? _categoryId;
  bool _changing = false;

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final team = ref.watch(teamProvider);
    final showList = draft.service == null || _changing;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
      children: <Widget>[
        if (!showList)
          FloraCard(
            padding: const EdgeInsets.all(10),
            onTap: () => setState(() => _changing = true),
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: FloraImage(
                      url: draft.service!.imageUrl,
                      label: draft.service!.name,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        draft.service!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: FloraColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${draft.service!.formattedDuration} · '
                        '${draft.service!.shortPrice}',
                        style: const TextStyle(
                            fontSize: 13, color: FloraColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Changer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FloraColors.burgundy,
                  ),
                ),
              ],
            ),
          )
        else
          _servicePicker(),
        const FloraSectionHeader(
          title: 'Choisir mon expert·e',
          padding: EdgeInsets.fromLTRB(0, 20, 0, 10),
        ),
        team.when(
          data: (members) => SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _MemberChoice(
                member: members[i],
                selected: draft.teamMember?.id == members[i].id,
                onTap: () => ref
                    .read(bookingDraftProvider.notifier)
                    .setTeamMember(members[i]),
              ),
            ),
          ),
          loading: () => const SizedBox(
            height: 112,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => ErrorState(
            message: "Impossible de charger l'équipe.",
            onRetry: () => ref.refresh(teamProvider),
          ),
        ),
      ],
    );
  }

  Widget _servicePicker() {
    final services = ref.watch(servicesProvider);
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    return services.when(
      loading: () => const SizedBox(height: 200, child: LoadingState()),
      error: (_, __) => ErrorState(
        message: 'Impossible de charger les prestations.',
        onRetry: () => ref.refresh(servicesProvider),
      ),
      data: (list) {
        final filtered = _categoryId == null
            ? list
            : list.where((s) => s.categoryId == _categoryId).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Choisir ma prestation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: FloraColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  FloraFilterChip(
                    label: 'Tout',
                    active: _categoryId == null,
                    onTap: () => setState(() => _categoryId = null),
                  ),
                  for (final c in categories)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FloraFilterChip(
                        label: c.name,
                        active: _categoryId == c.id,
                        onTap: () => setState(() => _categoryId = c.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            for (final s in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ServiceChoice(
                  service: s,
                  selected: widget.draft.service?.id == s.id,
                  onTap: () {
                    ref.read(bookingDraftProvider.notifier).setService(s);
                    setState(() => _changing = false);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ServiceChoice extends StatelessWidget {
  const _ServiceChoice({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final Service service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloraCard(
      padding: const EdgeInsets.all(8),
      onTap: onTap,
      borderColor: selected ? FloraColors.burgundy : null,
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: FloraImage(url: service.imageUrl, label: service.name),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  service.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: FloraColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${service.formattedDuration} · ${service.shortPrice}',
                  style: const TextStyle(
                      fontSize: 13, color: FloraColors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? FloraColors.burgundy : FloraColors.blush,
          ),
        ],
      ),
    );
  }
}

class _MemberChoice extends StatelessWidget {
  const _MemberChoice({
    required this.member,
    required this.selected,
    required this.onTap,
  });

  final TeamMember member;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: member.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 82,
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        selected ? FloraColors.burgundy : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 62,
                    height: 62,
                    child: FloraImage(
                      url: member.photoUrl,
                      icon: Icons.person_outline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                member.name.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: FloraColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepSlot extends StatelessWidget {
  const _StepSlot({
    required this.draft,
    required this.slots,
    required this.loading,
    required this.notes,
    required this.onDate,
    required this.onSlot,
  });

  final BookingDraft draft;
  final List<String> slots;
  final bool loading;
  final TextEditingController notes;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<String> onSlot;

  /// Le salon réserve jusqu'à deux mois à l'avance ; le dimanche est fermé.
  static const _daysAhead = 60;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = draft.date;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
      children: <Widget>[
        const Text(
          'Sélectionner une date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: FloraColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _daysAhead,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final day = DateTime(today.year, today.month, today.day + i);
              return _DayCell(
                day: day,
                selected: selected != null &&
                    selected.year == day.year &&
                    selected.month == day.month &&
                    selected.day == day.day,
                closed: day.weekday == DateTime.sunday,
                onTap: () => onDate(day),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Choisir un créneau',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: FloraColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (slots.isEmpty)
          const Text(
            'Aucun créneau libre ce jour-là. Essayez une autre date.',
            style: TextStyle(color: FloraColors.textSecondary),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final s in slots)
                _SlotChip(
                  label: s,
                  selected: draft.startTime == s,
                  onTap: () => onSlot(s),
                ),
            ],
          ),
        const SizedBox(height: 20),
        TextField(
          controller: notes,
          maxLines: 2,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Ajouter une note (optionnel)',
            hintText: 'Ex : allergie, demande spéciale…',
            alignLabelWithHint: true,
            counterText: '',
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Total estimé',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: FloraColors.textPrimary,
                ),
              ),
            ),
            Text(
              draft.service?.formattedPrice() ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: FloraColors.burgundy,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.closed,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool closed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : closed
            ? FloraColors.textMuted.withValues(alpha: 0.6)
            : FloraColors.textPrimary;
    return Semantics(
      button: !closed,
      selected: selected,
      label: closed ? '${frLongDate(day)}, fermé' : frLongDate(day),
      child: Material(
        color: selected ? FloraColors.burgundy : FloraColors.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: closed ? null : onTap,
          child: SizedBox(
            width: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(frWeekday(day), style: TextStyle(fontSize: 12, color: fg)),
                Text(
                  day.day.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
                Text(frMonth(day), style: TextStyle(fontSize: 11, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? FloraColors.burgundy : FloraColors.surface,
        borderRadius: BorderRadius.circular(FloraTheme.pillRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 72, minHeight: 44),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FloraTheme.pillRadius),
              border: Border.all(
                color: selected ? FloraColors.burgundy : FloraColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : FloraColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Recap extends StatelessWidget {
  const _Recap({required this.draft});
  final BookingDraft draft;

  @override
  Widget build(BuildContext context) {
    final date = draft.date;
    return FloraCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: FloraImage(
                url: draft.service?.imageUrl,
                label: draft.service?.name,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  draft.service?.name ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: FloraColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date == null ? '' : frLongDate(date)} · ${draft.startTime ?? ''}',
                  style: const TextStyle(
                      fontSize: 13, color: FloraColors.textSecondary),
                ),
                Text(
                  'avec ${draft.teamMember?.name ?? ''}',
                  style: const TextStyle(
                      fontSize: 13, color: FloraColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
