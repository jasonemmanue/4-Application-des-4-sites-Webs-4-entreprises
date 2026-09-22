import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/team_member.dart';
import '../utils/media.dart';

/// Carte membre d'équipe — portrait 3:4 rebasé sur `Theme.of(context)`
/// pour rester lisible en mode clair comme en mode sombre.
class TeamCard extends StatelessWidget {
  const TeamCard({super.key, required this.member, this.onTap});

  final TeamMember member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: member.photoUrl != null && member.photoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: mediaUrl(member.photoUrl),
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(color: scheme.surfaceContainerHighest),
                        placeholder: (_, __) =>
                            Container(color: scheme.surfaceContainerHighest),
                      )
                    : Container(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(Icons.person,
                            size: 42, color: scheme.primary),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(member.name, style: theme.textTheme.titleMedium),
            if (member.specialties.isNotEmpty) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                member.specialties.first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
