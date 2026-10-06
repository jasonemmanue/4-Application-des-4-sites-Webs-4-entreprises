/// Barre de recherche flottante inspiree d'Airbnb, avec autocompletion sur
/// activites, coachs et articles. Un tap ouvre `SearchScreen` (une feuille
/// modale plein ecran qui affiche les suggestions au fil de la frappe).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../models/activity.dart';
import '../models/article.dart';
import '../models/coach.dart';
import '../services/providers.dart';

/// Version "read-only" : un tap ouvre l'ecran de recherche complet.
/// C'est ce que l'ecran d'accueil affiche.
class SearchPillTrigger extends StatelessWidget {
  final String hint;
  const SearchPillTrigger({super.key, this.hint = 'Commencez votre recherche'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.full),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const SearchScreen(),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.pill,
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppColors.textPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hint,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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

/// Feuille de recherche plein ecran — input actif, resultats live.
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
    _controller.addListener(() {
      final q = _controller.text.trim();
      if (q != _query) setState(() => _query = q);
    });
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Chercher une activite, un coach, un article',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(Icons.search,
                  size: 20, color: AppColors.textPrimary),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _controller.clear(),
                    ),
              filled: true,
              fillColor: AppColors.surfaceSubtle,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                borderSide: const BorderSide(color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? const _EmptyHints()
          : _SuggestionsList(query: _query),
    );
  }
}

class _EmptyHints extends StatelessWidget {
  const _EmptyHints();

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      ('Musculation', Icons.fitness_center),
      ('Kung-Fu Wushu', Icons.sports_martial_arts),
      ('Boxe', Icons.sports_mma),
      ('Yoga', Icons.self_improvement),
      ('HIIT Cardio', Icons.directions_run),
      ('Planning', Icons.calendar_today),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 12, left: 4),
          child: Text('Suggestions populaires',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
        ),
        for (final (label, icon) in suggestions)
          _HintTile(label: label, icon: icon),
      ],
    );
  }
}

class _HintTile extends StatelessWidget {
  final String label;
  final IconData icon;
  const _HintTile({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
      title: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 15)),
      onTap: () {
        final state = context.findAncestorStateOfType<_SearchScreenState>();
        state?._controller.text = label;
      },
    );
  }
}

class _SuggestionsList extends ConsumerWidget {
  final String query;
  const _SuggestionsList({required this.query});

  bool _matches(String haystack) =>
      haystack.toLowerCase().contains(query.toLowerCase());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities =
        ref.watch(activitiesProvider((category: null, level: null)));
    final coaches = ref.watch(coachesProvider);
    final articles = ref.watch(articlesProvider);

    final actMatches = activities.maybeWhen(
      data: (list) => list.where((a) => _matches(a.name)).take(5).toList(),
      orElse: () => const <Activity>[],
    );
    final coachMatches = coaches.maybeWhen(
      data: (list) => list.where((c) => _matches(c.name)).take(5).toList(),
      orElse: () => const <Coach>[],
    );
    final articleMatches = articles.maybeWhen(
      data: (list) => list.where((a) => _matches(a.title)).take(5).toList(),
      orElse: () => const <Article>[],
    );

    if (actMatches.isEmpty && coachMatches.isEmpty && articleMatches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Aucun resultat pour "$query".',
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (actMatches.isNotEmpty)
          _Section(
            title: 'Activites',
            children: actMatches
                .map((a) => _ResultTile(
                      icon: Icons.fitness_center,
                      title: a.name,
                      subtitle: a.category,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/activities/${a.slug}');
                      },
                    ))
                .toList(),
          ),
        if (coachMatches.isNotEmpty)
          _Section(
            title: 'Coachs',
            children: coachMatches
                .map((c) => _ResultTile(
                      icon: Icons.person,
                      title: c.name,
                      subtitle: c.specialties.join(', '),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/more');
                      },
                    ))
                .toList(),
          ),
        if (articleMatches.isNotEmpty)
          _Section(
            title: 'Articles',
            children: articleMatches
                .map((a) => _ResultTile(
                      icon: Icons.article_outlined,
                      title: a.title,
                      subtitle: a.excerpt ?? '',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/articles/${a.slug}');
                      },
                    ))
                .toList(),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4)),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ResultTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
      title: Text(title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 15)),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      onTap: onTap,
    );
  }
}
