import 'package:flutter/material.dart';

import '../../widgets/state_views.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes reservations')),
      body: const EmptyView(
        icon: Icons.calendar_month_outlined,
        title: 'Aucune reservation pour l\'instant',
        description:
            'Vos reservations apparaitront ici. Confirmations et rappels sont envoyes sur WhatsApp.',
      ),
    );
  }
}
