import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffListProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStaffForm(context, ref),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Ajouter'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(staffListProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = list[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        s.role == StaffRole.controller
                            ? AppColors.info.withOpacity(0.2)
                            : AppColors.primary.withOpacity(0.15),
                    child: Icon(
                      s.role == StaffRole.controller
                          ? Icons.verified_user_outlined
                          : Icons.cleaning_services_outlined,
                      color: s.role == StaffRole.controller
                          ? AppColors.info
                          : AppColors.primary,
                    ),
                  ),
                  title: Text(s.fullName),
                  subtitle: Text('${s.role.label} • ${s.phone}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'deactivate') {
                        await ref.read(staffServiceProvider).deactivate(s.id);
                        ref.invalidate(staffListProvider);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                          value: 'deactivate', child: Text('Desactiver')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showStaffForm(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final pin = TextEditingController();
    var role = StaffRole.agent;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nouveau membre',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nom complet'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telephone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                    labelText: 'Code PIN', counterText: ''),
              ),
              const SizedBox(height: 8),
              SegmentedButton<StaffRole>(
                segments: const [
                  ButtonSegment(
                      value: StaffRole.agent, label: Text('Agent')),
                  ButtonSegment(
                      value: StaffRole.controller, label: Text('Controleur')),
                ],
                selected: {role},
                onSelectionChanged: (s) => setState(() => role = s.first),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  try {
                    await ref.read(staffServiceProvider).create(
                          fullName: name.text.trim(),
                          phone: phone.text.trim(),
                          pin: pin.text.trim(),
                          role: role,
                        );
                    if (context.mounted) Navigator.of(context).pop(true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
                child: const Text('Creer'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) ref.invalidate(staffListProvider);
  }
}
