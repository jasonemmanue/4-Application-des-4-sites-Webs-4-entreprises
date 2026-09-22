import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/article.dart';
import '../../models/project.dart';
import '../../models/service.dart';
import '../../providers/providers.dart';

/// Ecran de recherche avec autocompletion en direct sur les services, les
/// realisations et les publications du cabinet. Ouvert au tap sur la pill
/// « Que recherchez-vous ? » de l'accueil.
///
/// L'index est construit une seule fois au premier chargement — chaque item
/// porte son titre et son slug, et les correspondances sont scorees par
/// « startsWith » puis « contains » sur mots normalises.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final projects = ref.watch(projectsProvider(const ProjectFilter()));
    final articles = ref.watch(articlesProvider(null));

    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;
    final Color scaffoldBg =
        isDark ? AppColors.charcoal900 : AppColors.lightBg;
    final Color fieldBg =
        isDark ? AppColors.charcoal800 : Colors.white;
    final Color hint =
        isDark ? Colors.white54 : Colors.black45;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: fieldBg,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: fieldBg,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        onChanged: (v) => setState(() => _query = v),
                        textInputAction: TextInputAction.search,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.charcoal900,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Rechercher',
                          hintStyle: TextStyle(color: hint),
                          prefixIcon: Icon(Icons.search, color: hint),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: Icon(Icons.close, color: hint),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() => _query = '');
                                    _focus.requestFocus();
                                  },
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _query.trim().isEmpty
                  ? _EmptyState(
                      isDark: isDark,
                      onPick: (label) {
                        _controller.text = label;
                        setState(() => _query = label);
                      },
                    )
                  : _Results(
                      query: _query,
                      services: services.valueOrNull ?? const [],
                      projects: projects.valueOrNull?.items ?? const [],
                      articles: articles.valueOrNull?.items ?? const [],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final ValueChanged<String> onPick;
  const _EmptyState({required this.isDark, required this.onPick});

  static const List<String> _suggestions = [
    'Etudes de faisabilite',
    'Conseil en strategie',
    'Formation',
    'Audit',
    'Impact',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      children: [
        Text(
          'Suggestions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _suggestions)
              _SuggestionChip(label: s, isDark: isDark, onTap: () => onPick(s)),
          ],
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _SuggestionChip({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.charcoal800 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: isDark ? AppColors.charcoal700 : const Color(0xFFE5E7EB),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.charcoal900,
            ),
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final String query;
  final List<Service> services;
  final List<Project> projects;
  final List<Article> articles;

  const _Results({
    required this.query,
    required this.services,
    required this.projects,
    required this.articles,
  });

  bool _match(String haystack) {
    final q = query.toLowerCase().trim();
    return haystack.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final svc = services.where((s) => _match(s.title)).toList();
    final proj = projects.where((p) => _match(p.title)).toList();
    final art = articles.where((a) => _match(a.title)).toList();

    final total = svc.length + proj.length + art.length;

    if (total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off,
                  size: 48, color: Theme.of(context).hintColor),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Aucun resultat pour « $query »',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        if (svc.isNotEmpty)
          _ResultsSection(
            title: 'Services',
            items: [
              for (final s in svc)
                _ResultTile(
                  icon: Icons.business_center_outlined,
                  title: s.title,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('${AppRoutes.services}/${s.slug}');
                  },
                ),
            ],
          ),
        if (proj.isNotEmpty)
          _ResultsSection(
            title: 'Realisations',
            items: [
              for (final p in proj)
                _ResultTile(
                  icon: Icons.folder_special_outlined,
                  title: p.title,
                  subtitle: p.sector,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('${AppRoutes.projects}/${p.slug}');
                  },
                ),
            ],
          ),
        if (art.isNotEmpty)
          _ResultsSection(
            title: 'Publications',
            items: [
              for (final a in art)
                _ResultTile(
                  icon: Icons.menu_book_outlined,
                  title: a.title,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('${AppRoutes.publications}/${a.slug}');
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _ResultsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _ResultsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ResultTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.charcoal800 : Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brand500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.brand500),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Theme.of(context).hintColor),
            ],
          ),
        ),
      ),
    );
  }
}
