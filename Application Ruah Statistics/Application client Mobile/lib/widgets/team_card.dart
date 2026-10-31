import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/team_member.dart';
import 'ruah_ui.dart';

class TeamCard extends StatelessWidget {
  final TeamMember member;
  final VoidCallback? onTap;

  const TeamCard({super.key, required this.member, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              RemoteAvatar(url: member.photo, name: member.name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (member.role != null)
                      Text(member.role!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.brand400)),
                    if (member.specialties.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        member.specialties.join(' - '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
