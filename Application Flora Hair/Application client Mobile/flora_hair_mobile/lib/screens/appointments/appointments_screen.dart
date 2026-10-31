import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/service.dart' show formatFcfa;
import '../../services/api_client.dart';
import '../../services/appointments.dart';
import '../../widgets/flora_ui.dart';
import '../../widgets/payment_sheet.dart';

/// Rendez-vous pris depuis cet appareil. L'état affiché est celui du back-office.
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
        () => ref.read(appointmentsProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(appointmentsProvider);
    final upcoming = all.where((a) => a.isUpcoming).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final past = all.where((a) => !a.isUpcoming).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

    // Atteint par `go` depuis le résultat d'un paiement : la pile est vide, et le
    // bouton retour fermerait l'application au lieu de revenir à l'accueil.
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          title: const Text('Mes rendez-vous'),
          bottom: const TabBar(
            labelColor: FloraColors.burgundy,
            unselectedLabelColor: FloraColors.textSecondary,
            indicatorColor: FloraColors.burgundy,
            tabs: <Widget>[
              Tab(text: 'À venir'),
              Tab(text: 'Historique'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _AppointmentList(
              items: upcoming,
              emptyText: 'Aucun rendez-vous à venir sur cet appareil.',
            ),
            _AppointmentList(
              items: past,
              emptyText: 'Votre historique apparaîtra ici.',
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _AppointmentList extends ConsumerWidget {
  const _AppointmentList({required this.items, required this.emptyText});

  final List<LocalAppointment> items;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(appointmentsProvider.notifier).refresh(),
      child: items.isEmpty
          ? ListView(
              padding: const EdgeInsets.fromLTRB(32, 80, 32, 0),
              children: <Widget>[
                const Icon(Icons.event_available_outlined,
                    size: 56, color: FloraColors.blush),
                const SizedBox(height: 14),
                Text(
                  emptyText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: FloraColors.textSecondary),
                ),
                const SizedBox(height: 18),
                Center(
                  child: ElevatedButton(
                    onPressed: () => context.go('/booking'),
                    child: const Text('Prendre rendez-vous'),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) => AppointmentCard(appointment: items[i]),
            ),
    );
  }
}

/// Carte d'un rendez-vous, avec les seules actions que le backend accepte.
class AppointmentCard extends ConsumerWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.showActions = true,
  });

  final LocalAppointment appointment;
  final bool showActions;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler ce rendez-vous ?'),
        content: Text(
            '${appointment.serviceName}, ${appointment.time}. '
            'Le créneau sera libéré pour une autre cliente.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Garder'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Annuler le rendez-vous'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(appointmentsProvider.notifier).cancel(appointment.bookingId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(e is ApiException ? e.message : 'Une erreur est survenue.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = appointment;
    final date = DateTime.tryParse(a.date);
    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 74,
                  height: 82,
                  child: FloraImage(url: a.imageUrl, label: a.serviceName),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            a.serviceName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: FloraColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        AppointmentStatusBadge(
                          status: a.status,
                          depositPaid: a.isDepositPaid,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _Line(
                      icon: Icons.calendar_today_outlined,
                      text: date == null ? a.date : frLongDate(date),
                    ),
                    _Line(icon: Icons.schedule_rounded, text: a.time),
                    if (a.memberName.isNotEmpty)
                      _Line(icon: Icons.person_outline, text: a.memberName),
                  ],
                ),
              ),
            ],
          ),
          if (showActions && (a.canPayDeposit || a.canCancel)) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                if (a.canCancel)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancel(context, ref),
                      child: const Text('Annuler'),
                    ),
                  ),
                if (a.canCancel && a.canPayDeposit) const SizedBox(width: 10),
                if (a.canPayDeposit)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => showPaymentSheet(
                        context,
                        bookingId: a.bookingId,
                        amount: a.depositAmount,
                      ),
                      child: FittedBox(
                        child: Text('Payer ${formatFcfa(a.depositAmount)}'),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      );
    return showActions ? FloraCard(child: content) : content;
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 14, color: FloraColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: FloraColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
