import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = <_MoreTile>[
      const _MoreTile('Notre equipe', Icons.groups_outlined, '/team'),
      const _MoreTile('Articles beaute', Icons.menu_book_outlined, '/articles'),
      const _MoreTile('Videos', Icons.play_circle_outline, '/videos'),
      const _MoreTile('Avis clients', Icons.star_outline, '/reviews'),
      const _MoreTile(
          'Devis photo', Icons.camera_alt_outlined, '/quote'),
      const _MoreTile(
          'Formations', Icons.school_outlined, '/training'),
      const _MoreTile(
          'Contact & WhatsApp', Icons.chat_bubble_outline, '/contact'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Plus')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final t = tiles[i];
          return Container(
            decoration: BoxDecoration(
              color: FloraColors.charcoal,
              border: Border.all(color: FloraColors.grayWarm),
              borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
            ),
            child: ListTile(
              leading: Icon(t.icon, color: FloraColors.lime),
              title: Text(t.label),
              trailing: const Icon(Icons.chevron_right,
                  color: FloraColors.lime),
              onTap: () => context.push(t.route),
            ),
          );
        },
      ),
    );
  }
}

class _MoreTile {
  const _MoreTile(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}
