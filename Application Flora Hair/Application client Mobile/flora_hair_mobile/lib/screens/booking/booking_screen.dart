import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/client_profile.dart';
import '../../config/theme.dart';
import '../../models/booking.dart';
import '../../models/payment.dart';
import '../../services/api_client.dart';
import '../../services/payment_service.dart';
import '../../services/providers.dart';
import '../../widgets/booking_form.dart';
import '../../widgets/calendar.dart';
import '../../widgets/operator_grid.dart';
import '../../widgets/service_card.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/team_card.dart';
import 'booking_state.dart';

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

  static const _titles = <String>[
    '1. Service',
    '2. Coiffeuse',
    '3. Date & Heure',
    '4. Informations & paiement',
  ];

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
      setState(() => _slots = slots);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur creneaux : $e')));
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_operator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Choisissez un moyen de paiement Mobile Money.')),
      );
      return;
    }
    final phoneError = PaymentService.validatePhoneForOperator(
      _payPhoneCtrl.text,
      _operator!,
    );
    if (phoneError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(phoneError)));
      return;
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
      final booking = Booking(
        serviceId: draft.service!.id,
        teamMemberId: draft.teamMember!.id,
        date: draft.date!,
        timeSlot: draft.startTime!,
        customerName: draft.customerName,
        customerPhone: draft.customerPhone,
        customerEmail: draft.customerEmail.isEmpty ? null : draft.customerEmail,
        notes: draft.notes.isEmpty ? null : draft.notes,
      );
      final created = await ref.read(apiClientProvider).createBooking(booking);
      // Pas de compte : le nom du dernier rendez-vous personnalise le
      // Profil.
      await ref.read(clientNameProvider.notifier).save(draft.customerName);
      final bookingId = created.id ?? created.reference ?? '';
      final init = await ref.read(paymentServiceProvider).initPayment(
            bookingId: bookingId,
            operator: _operator!,
            phone: PaymentService.toInternational(_payPhoneCtrl.text),
          );
      if (!mounted) return;
      context.go('/payment/wait?ref=${init.reference}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(bookingStepProvider);
    final draft = ref.watch(bookingDraftProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[step]),
        leading: step == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    ref.read(bookingStepProvider.notifier).state = step - 1,
              ),
      ),
      body: Column(
        children: <Widget>[
          LinearProgressIndicator(
            value: (step + 1) / 4,
            backgroundColor: FloraColors.darkLight,
            color: FloraColors.lime,
            minHeight: 4,
          ),
          Expanded(child: _buildStep(step, draft)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  if (step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => ref
                            .read(bookingStepProvider.notifier)
                            .state = step - 1,
                        child: const Text('Retour'),
                      ),
                    ),
                  if (step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _next(step, draft),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(step == 3 ? 'Payer le depot' : 'Continuer'),
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

  void _next(int step, BookingDraft draft) {
    final stepNotifier = ref.read(bookingStepProvider.notifier);
    switch (step) {
      case 0:
        if (draft.service == null) {
          _snack('Selectionnez un service');
          return;
        }
        stepNotifier.state = 1;
        break;
      case 1:
        if (draft.teamMember == null) {
          _snack('Selectionnez une coiffeuse');
          return;
        }
        stepNotifier.state = 2;
        _loadSlots();
        break;
      case 2:
        if (draft.date == null) {
          _snack('Selectionnez une date');
          return;
        }
        if (draft.startTime == null) {
          _snack('Selectionnez une heure');
          return;
        }
        stepNotifier.state = 3;
        break;
      case 3:
        _submitBooking();
        break;
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Widget _buildStep(int step, BookingDraft draft) {
    switch (step) {
      case 0:
        return _StepService(
          selectedId: draft.service?.id,
          onSelect: (s) =>
              ref.read(bookingDraftProvider.notifier).setService(s),
        );
      case 1:
        return _StepTeam(
          selectedId: draft.teamMember?.id,
          onSelect: (t) =>
              ref.read(bookingDraftProvider.notifier).setTeamMember(t),
        );
      case 2:
        return _StepDate(
          draft: draft,
          slots: _slots,
          loading: _loadingSlots,
          onDate: (d) {
            ref.read(bookingDraftProvider.notifier).setDate(d);
            _loadSlots();
          },
          onSlot: (t) => ref.read(bookingDraftProvider.notifier).setTime(t),
        );
      case 3:
      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              BookingCustomerForm(
                formKey: _formKey,
                name: _nameCtrl,
                phone: _phoneCtrl,
                email: _emailCtrl,
                notes: _notesCtrl,
              ),
              const SizedBox(height: 20),
              Text('Depot 50 %', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'A regler : ${draft.service?.depositAmount ?? 0} FCFA (sur '
                '${draft.service?.priceMin ?? 0} FCFA)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              OperatorGrid(
                selected: _operator,
                onSelect: (op) => setState(() => _operator = op),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _payPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Numero Mobile Money',
                  hintText: _operator?.expectedPrefix != null
                      ? 'Commence par ${_operator!.expectedPrefix}'
                      : '10 chiffres',
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _StepService extends ConsumerWidget {
  const _StepService({required this.selectedId, required this.onSelect});
  final String? selectedId;
  final void Function(dynamic) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(servicesProvider);
    return async.when(
      data: (list) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final s = list[i];
          final selected = s.id == selectedId;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
              border: Border.all(
                color: selected ? FloraColors.lime : Colors.transparent,
                width: 1.6,
              ),
            ),
            child: ServiceCard(service: s, onTap: () => onSelect(s)),
          );
        },
      ),
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(message: 'Erreur : $e'),
    );
  }
}

class _StepTeam extends ConsumerWidget {
  const _StepTeam({required this.selectedId, required this.onSelect});
  final String? selectedId;
  final void Function(dynamic) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamProvider);
    return async.when(
      data: (list) => GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.66,
        ),
        itemBuilder: (context, i) {
          final t = list[i];
          final selected = t.id == selectedId;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
              border: Border.all(
                color: selected ? FloraColors.lime : Colors.transparent,
                width: 1.6,
              ),
            ),
            child: TeamCard(member: t, onTap: () => onSelect(t)),
          );
        },
      ),
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(message: 'Erreur : $e'),
    );
  }
}

class _StepDate extends StatelessWidget {
  const _StepDate({
    required this.draft,
    required this.slots,
    required this.loading,
    required this.onDate,
    required this.onSlot,
  });

  final BookingDraft draft;
  final List<String> slots;
  final bool loading;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<String> onSlot;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          BookingCalendar(
            selectedDate: draft.date,
            onSelect: onDate,
          ),
          const SizedBox(height: 20),
          Text('Creneaux disponibles',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (draft.date == null)
            Text(
              'Selectionnez une date pour voir les creneaux.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: FloraColors.textMuted),
            )
          else if (slots.isEmpty)
            Text(
              'Aucun creneau disponible pour cette date. Essayez une autre.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: FloraColors.textMuted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((s) {
                final selected = draft.startTime == s;
                return ChoiceChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (_) => onSlot(s),
                  selectedColor: FloraColors.lime,
                  labelStyle: TextStyle(
                    color: selected ? FloraColors.dark : FloraColors.cream,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
