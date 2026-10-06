import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/project.dart';
import '../../models/service.dart';
import '../../providers/providers.dart';
import '../../services/api_client.dart' show PagedResult;
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/quote_notice.dart';

/// Categorie active dans les chips « Tout / Services / Realisations » — pilote
/// ce qui est visible dans le feed d'accueil (Airbnb-like).
enum _HomeCategory { all, services, projects }

/// Ecran d'accueil, refondu facon Airbnb : barre pill de recherche en tete,
/// chips categories, sections « Titre → » avec grille horizontale de cartes
/// carrees, pill flottante d'appel a l'action, tout en gardant la palette
/// cyan / charcoal de la marque Ruah.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _HomeCategory _category = _HomeCategory.all;

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final projects = ref.watch(projectsProvider(const ProjectFilter()));
    final themeMode = ref.watch(themeModeProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? AppColors.charcoal900 : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(servicesProvider);
              ref.invalidate(projectsProvider);
              ref.invalidate(keyFiguresProvider);
              ref.invalidate(testimonialsProvider);
            },
            child: CustomScrollView(
              slivers: [
                _SearchAppBar(
                  isDark: isDark,
                  themeMode: themeMode,
                  onToggleTheme: () =>
                      ref.read(themeModeProvider.notifier).state =
                          themeMode == ThemeMode.dark
                              ? ThemeMode.light
                              : ThemeMode.dark,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: _CategoryChips(
                      current: _category,
                      onChanged: (c) => setState(() => _category = c),
                    ),
                  ),
                ),
                if (_category != _HomeCategory.projects)
                  SliverToBoxAdapter(
                    child: _ServicesSection(
                      isDark: isDark,
                      services: services,
                    ),
                  ),
                if (_category != _HomeCategory.services)
                  SliverToBoxAdapter(
                    child: _ProjectsSection(
                      isDark: isDark,
                      projects: projects,
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 96),
                ),
              ],
            ),
          ),
          // Pastille flottante — pendant du « Les prix comprennent tous les
          // frais » d'Airbnb. Un tap ouvre le pop-up explicatif, qui mène au
          // devis : le principal levier de conversion d'un site vitrine.
          const Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Center(child: QuoteNoticePill()),
          ),
        ],
      ),
    );
  }
}

class _SearchAppBar extends StatelessWidget {
  final bool isDark;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const _SearchAppBar({
    required this.isDark,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isDark ? AppColors.charcoal900 : AppColors.lightBg;
    final Color pillBg = isDark ? AppColors.charcoal800 : Colors.white;
    final Color pillFg = isDark ? Colors.white : AppColors.charcoal900;
    final Color hint = isDark ? Colors.white54 : Colors.black45;

    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: false,
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 78,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Material(
                color: pillBg,
                borderRadius: BorderRadius.circular(999),
                elevation: 0,
                shadowColor: Colors.black26,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => context.push(AppRoutes.search),
                  child: Container(
                    height: 56,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: pillFg, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Que recherchez-vous ?',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: pillFg,
                                ),
                              ),
                              Text(
                                'Services, realisations, publications',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: pillFg,
              ),
              onPressed: onToggleTheme,
              tooltip: 'Basculer le theme',
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final _HomeCategory current;
  final ValueChanged<_HomeCategory> onChanged;

  const _CategoryChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
          label: 'Tout',
          emoji: '🌍',
          active: current == _HomeCategory.all,
          onTap: () => onChanged(_HomeCategory.all),
        ),
        const SizedBox(width: AppSpacing.sm),
        _Chip(
          label: 'Services',
          emoji: '🎯',
          active: current == _HomeCategory.services,
          onTap: () => onChanged(_HomeCategory.services),
        ),
        const SizedBox(width: AppSpacing.sm),
        _Chip(
          label: 'Realisations',
          emoji: '📊',
          active: current == _HomeCategory.projects,
          onTap: () => onChanged(_HomeCategory.projects),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool active;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.emoji,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = active
        ? (isDark ? Colors.white : AppColors.charcoal900)
        : (isDark ? AppColors.charcoal800 : Colors.white);
    final Color fg = active
        ? (isDark ? AppColors.charcoal900 : Colors.white)
        : (isDark ? Colors.white : AppColors.charcoal900);
    final Color border = active
        ? bg
        : (isDark ? AppColors.charcoal700 : const Color(0xFFE5E7EB));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onSeeAll;
  final bool isDark;

  const _SectionTitle({
    required this.title,
    this.subtitle,
    required this.onSeeAll,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.charcoal900,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Material(
            color: isDark ? AppColors.charcoal800 : Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSeeAll,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.charcoal700
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: isDark ? Colors.white : AppColors.charcoal900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  final bool isDark;
  final AsyncValue<List<Service>> services;

  const _ServicesSection({required this.isDark, required this.services});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Nos services phares',
          subtitle:
              'Etudes, conseil, formation, audit — savoir-faire de reference.',
          onSeeAll: () => context.go(AppRoutes.services),
          isDark: isDark,
        ),
        services.when(
          loading: () => const LoadingState(itemCount: 1),
          error: (e, _) => ErrorState(message: e.toString(), onRetry: () {}),
          data: (items) {
            if (items.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (_, i) {
                  final s = items[i];
                  return _AirbnbCard(
                    isDark: isDark,
                    imageUrl: s.coverImage,
                    badge: i == 0 ? "Coup de coeur" : null,
                    title: s.title,
                    subtitle: (s.description ?? '').split('.').first.trim(),
                    onTap: () =>
                        context.push('${AppRoutes.services}/${s.slug}'),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProjectsSection extends StatelessWidget {
  final bool isDark;
  final AsyncValue<PagedResult<Project>> projects;

  const _ProjectsSection({required this.isDark, required this.projects});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Realisations recentes',
          subtitle: 'Projets menes en Afrique de l\'Ouest et du Centre.',
          onSeeAll: () => context.go(AppRoutes.projects),
          isDark: isDark,
        ),
        projects.when(
          loading: () => const LoadingState(itemCount: 1),
          error: (e, _) => ErrorState(message: e.toString(), onRetry: () {}),
          data: (page) {
            if (page.items.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: page.items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (_, i) {
                  final p = page.items[i];
                  return _AirbnbCard(
                    isDark: isDark,
                    imageUrl: p.coverImage,
                    badge: p.isFeatured ? "A la une" : null,
                    title: p.title,
                    subtitle: <String>[
                      p.sector ?? '',
                      p.country ?? '',
                      if (p.year != null) '${p.year}',
                    ].where((s) => s.isNotEmpty).join(' · '),
                    onTap: () =>
                        context.push('${AppRoutes.projects}/${p.slug}'),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Carte carree coins 24 px, cover en haut, badge coin haut-gauche, cœur
/// favori en haut-droite, titre gras + sous-titre gris en bas. C'est la
/// brique visuelle de reprise du feed Airbnb, adaptee au cabinet.
class _AirbnbCard extends StatefulWidget {
  final bool isDark;
  final String? imageUrl;
  final String? badge;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AirbnbCard({
    required this.isDark,
    required this.imageUrl,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_AirbnbCard> createState() => _AirbnbCardState();
}

class _AirbnbCardState extends State<_AirbnbCard> {
  bool _fav = false;

  @override
  Widget build(BuildContext context) {
    final Color cardBg = widget.isDark ? AppColors.charcoal800 : Colors.white;
    final Color titleFg = widget.isDark ? Colors.white : AppColors.charcoal900;
    final Color subFg = widget.isDark ? Colors.white70 : Colors.black54;

    return SizedBox(
      width: 240,
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.large),
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _cover(),
                      ),
                      if (widget.badge != null)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.badge!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.charcoal900,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () => setState(() => _fav = !_fav),
                          customBorder: const CircleBorder(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              _fav ? Icons.favorite : Icons.favorite_border,
                              color: _fav ? AppColors.brand400 : Colors.white,
                              size: 26,
                              shadows: const [
                                Shadow(color: Colors.black45, blurRadius: 6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: titleFg,
                        height: 1.2,
                      ),
                    ),
                    if (widget.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: subFg,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cover() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.ctaGradient,
      ),
      alignment: Alignment.center,
      child:
          const Icon(Icons.insights_outlined, color: Colors.white70, size: 42),
    );
  }
}
