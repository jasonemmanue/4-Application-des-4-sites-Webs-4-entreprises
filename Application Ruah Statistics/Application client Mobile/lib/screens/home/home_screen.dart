import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/key_figure.dart';
import '../../models/project.dart';
import '../../models/service.dart';
import '../../providers/providers.dart';
import '../../services/client_profile.dart';
import '../../services/input_sanitizer.dart';
import '../../services/notification_inbox.dart';
import '../../widgets/animated_counter.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/ruah_ui.dart';

class _Category {
  const _Category(this.label, this.icon, this.keyword);
  final String label;
  final IconData? icon;

  /// Fragment recherché dans le titre du service, sans accent.
  final String? keyword;
}

const List<_Category> _categories = [
  _Category('Tout', null, null),
  _Category('Études', Icons.school_outlined, 'etude'),
  _Category('Stratégie', Icons.show_chart_rounded, 'strateg'),
  _Category('Impact', Icons.public_rounded, 'impact'),
  _Category('Audit', Icons.balance_rounded, 'audit'),
  _Category('Formation', Icons.groups_outlined, 'formation'),
];

String _plain(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[àâ]'), 'a')
    .replaceAll(RegExp('[îï]'), 'i')
    .replaceAll(RegExp('[ôö]'), 'o')
    .replaceAll(RegExp('[ùûü]'), 'u');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _Category _category = _categories.first;

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final projects = ref.watch(projectsProvider(const ProjectFilter()));
    final figures = ref.watch(keyFiguresProvider);
    final String? name = ref.watch(clientProfileProvider).name;
    final String? firstName = name?.split(RegExp(r'\s+')).first;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(servicesProvider);
          ref.invalidate(projectsProvider);
          ref.invalidate(keyFiguresProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            RuahHeader(
              actions: [
                RoundAction(
                  icon: Icons.notifications_none_rounded,
                  tooltip: 'Notifications',
                  badge: ref.watch(inboxUnreadProvider),
                  onTap: () => context.push(AppRoutes.notifications),
                ),
                RoundAction(
                  icon: Icons.person_outline_rounded,
                  tooltip: 'Profil',
                  onTap: () => context.push(AppRoutes.more),
                ),
              ],
            ),
            PageTitle(
              title: firstName == null ? 'Bonjour 👋' : 'Bonjour $firstName 👋',
              subtitle: 'Ensemble, donnons de la valeur à vos projets.',
              accent: false,
            ),
            const SizedBox(height: 16),
            const _SearchPill(),
            const SizedBox(height: 14),
            _CategoryChips(
              current: _category,
              onChanged: (c) => setState(() => _category = c),
            ),
            SectionHeading(
              title: 'Nos expertises',
              onSeeAll: () => context.go(AppRoutes.services),
            ),
            services.when(
              loading: () => const SizedBox(
                  height: 170, child: LoadingState(itemCount: 1)),
              error: (e, _) => ErrorState(
                message: InputSanitizer.safeErrorMessage(e),
                onRetry: () => ref.invalidate(servicesProvider),
              ),
              data: _expertises,
            ),
            const SizedBox(height: AppSpacing.md),
            projects.when(
              loading: () => const SizedBox(
                  height: 280, child: LoadingState(itemCount: 1)),
              error: (e, _) => ErrorState(
                message: InputSanitizer.safeErrorMessage(e),
                onRetry: () => ref.invalidate(projectsProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) return const SizedBox.shrink();
                final Project featured = page.items.firstWhere(
                  (p) => p.isFeatured,
                  orElse: () => page.items.first,
                );
                return _FeaturedProject(project: featured);
              },
            ),
            figures.maybeWhen(
              data: (items) => items.isEmpty
                  ? const SizedBox.shrink()
                  : _KeyFigures(items: items),
              orElse: () => const SizedBox.shrink(),
            ),
            const SectionHeading(title: 'Explorer'),
            const _ExploreGrid(),
          ],
        ),
      ),
    );
  }

  Widget _expertises(List<Service> items) {
    final String? keyword = _category.keyword;
    final List<Service> visible = keyword == null
        ? items.take(4).toList()
        : items.where((s) => _plain(s.title).contains(keyword)).toList();
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('Aucune expertise dans cette catégorie.',
            style: TextStyle(color: mutedOf(context))),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, box) {
          final double width = (box.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final s in visible)
                SizedBox(width: width, child: _ExpertiseTile(service: s)),
            ],
          );
        },
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Semantics(
        button: true,
        label: 'Rechercher un accompagnement',
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: softCard(context, radius: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push(AppRoutes.search),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: fgOf(context)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'De quel accompagnement avez-vous besoin ?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14, color: mutedOf(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.current, required this.onChanged});
  final _Category current;
  final ValueChanged<_Category> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool dark = isDarkOf(context);
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final _Category c = _categories[i];
          final bool active = c == current;
          final Color fg = active ? Colors.white : fgOf(context);
          return Semantics(
            button: true,
            selected: active,
            child: Material(
              color: active
                  ? AppColors.brand500
                  : (dark ? AppColors.charcoal800 : Colors.white),
              borderRadius: BorderRadius.circular(99),
              child: InkWell(
                borderRadius: BorderRadius.circular(99),
                onTap: () => onChanged(c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: active
                          ? AppColors.brand500
                          : (dark
                              ? AppColors.charcoal700
                              : AppColors.lightBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (c.icon != null) ...[
                        Icon(c.icon, size: 16, color: fg),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        c.label,
                        style: TextStyle(
                          color: fg,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExpertiseTile extends StatelessWidget {
  const _ExpertiseTile({required this.service});
  final Service service;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 78,
        decoration: softCard(context),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('${AppRoutes.services}/${service.slug}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ExpertiseBadge(title: service.title, size: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    service.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: fgOf(context),
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

class _FeaturedProject extends StatelessWidget {
  const _FeaturedProject({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Semantics(
        button: true,
        label: 'Projet à la une : ${project.title}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.push('${AppRoutes.projects}/${project.slug}'),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 70),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: RemoteImage(
                      url: project.coverImage,
                      semanticLabel: project.title,
                      fallbackIcon: Icons.folder_special_rounded,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent500,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Projet à la une',
                    style: TextStyle(
                      color: AppColors.charcoal900,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                  decoration: softCard(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: fgOf(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Voir le projet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDarkOf(context)
                                  ? Colors.white
                                  : AppColors.brand600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: isDarkOf(context)
                                ? Colors.white
                                : AppColors.brand600,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyFigures extends StatelessWidget {
  const _KeyFigures({required this.items});
  final List<KeyFigure> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final f in items.take(4))
              Expanded(
                child: Column(
                  children: [
                    AnimatedCounter(
                      end: f.value,
                      suffix: f.suffix,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid();

  @override
  Widget build(BuildContext context) {
    final List<(IconData, String, String)> entries = [
      (Icons.menu_book_rounded, 'Publications', AppRoutes.publications),
      (Icons.rate_review_rounded, 'Témoignages', AppRoutes.testimonials),
      (Icons.groups_rounded, 'Notre équipe', AppRoutes.team),
      (Icons.play_circle_rounded, 'Vidéos', AppRoutes.videos),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.9,
        children: [
          for (final (icon, label, route) in entries)
            Material(
              color: Colors.transparent,
              child: Ink(
                decoration: softCard(context, radius: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push(route),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(icon,
                            size: 22,
                            color: isDarkOf(context)
                                ? Colors.white
                                : AppColors.brand600),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: fgOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
