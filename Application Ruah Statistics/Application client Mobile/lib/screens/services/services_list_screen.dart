import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/project.dart';
import '../../models/service.dart';
import '../../providers/providers.dart';
import '../../services/input_sanitizer.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/ruah_ui.dart';

class ServicesListScreen extends ConsumerWidget {
  const ServicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    final projects = ref.watch(projectsProvider(const ProjectFilter()));

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(servicesProvider);
          ref.invalidate(projectsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            const RuahHeader(),
            const PageTitle(
              title: 'Nos expertises',
              subtitle: 'Des solutions adaptées à vos enjeux',
            ),
            const SizedBox(height: AppSpacing.md),
            services.when(
              loading: () =>
                  const SizedBox(height: 320, child: LoadingState()),
              error: (e, _) => ErrorState(
                message: InputSanitizer.safeErrorMessage(e),
                onRetry: () => ref.invalidate(servicesProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'Aucun service pour le moment',
                    icon: Icons.grid_view_outlined,
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      for (final s in items) ...[
                        _ServiceRow(service: s),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                );
              },
            ),
            SectionHeading(
              title: 'Nos réalisations',
              onSeeAll: () => context.go(AppRoutes.projects),
            ),
            projects.maybeWhen(
              data: (page) => page.items.isEmpty
                  ? const SizedBox.shrink()
                  : _ProjectThumbs(items: page.items.take(2).toList()),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),
            const _ReachBand(),
          ],
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});
  final Service service;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: softCard(context),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('${AppRoutes.services}/${service.slug}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  ExpertiseBadge(title: service.title, size: 58),
                  const SizedBox(width: 12),
                  VerticalDivider(
                    width: 1,
                    color: isDarkOf(context)
                        ? AppColors.charcoal700
                        : AppColors.lightBorder,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: fgOf(context),
                          ),
                        ),
                        if ((service.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            service.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: mutedOf(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: fgOf(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectThumbs extends StatelessWidget {
  const _ProjectThumbs({required this.items});
  final List<Project> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: _Thumb(project: items[i])),
          ],
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: project.title,
      child: GestureDetector(
        onTap: () => context.push('${AppRoutes.projects}/${project.slug}'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1.2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RemoteImage(
                  url: project.coverImage,
                  semanticLabel: project.title,
                  fallbackIcon: Icons.folder_special_rounded,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC0B2340)],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 9,
                  child: Text(
                    project.sector ?? project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReachBand extends StatelessWidget {
  const _ReachBand();

  @override
  Widget build(BuildContext context) {
    final bool dark = isDarkOf(context);
    final Color fg = dark ? Colors.white : AppColors.charcoal900;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: dark ? AppColors.charcoal700 : AppColors.brandTint,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public_rounded,
                size: 22, color: dark ? Colors.white : AppColors.brand600),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Afrique & international',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
