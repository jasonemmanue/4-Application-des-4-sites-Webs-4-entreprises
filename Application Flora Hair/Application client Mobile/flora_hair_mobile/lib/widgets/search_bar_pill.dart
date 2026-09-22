import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../models/service.dart';
import '../models/article.dart';
import '../services/providers.dart';

/// Suggestion cliquable dans la liste d'autocomplétion.
///
/// Distinguer un service d'un article dès la donnée évite un test
/// isinstanceof côté rendu, et laisse la route cible portée par l'entrée
/// elle-même — le composant qui affiche est agnostique du modèle.
class _Suggestion {
  const _Suggestion({
    required this.label,
    required this.route,
    required this.category,
    required this.iconData,
  });
  final String label;
  final String route;
  final String category;
  final IconData iconData;
}

/// Barre de recherche « pill » du style catalogue mobile.
///
/// Non éditable en apparence : c'est un bouton pill qui ouvre en modale
/// bottom-sheet une vraie recherche avec `Autocomplete` (Material). Le
/// même geste que dans les grandes apps de catalogue — l'écran d'accueil
/// reste minimaliste, la recherche prend toute la place au moment où on
/// tape.
class SearchBarPill extends ConsumerWidget {
  const SearchBarPill({super.key, this.placeholder = 'Rechercher une prestation, un article…'});

  final String placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openSearch(context, ref),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: FloraColors.surface,
          borderRadius: BorderRadius.circular(FloraTheme.pillRadius),
          border: Border.all(color: FloraColors.border),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.search, size: 22, color: FloraColors.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                placeholder,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: FloraColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearch(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(ref: ref),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Focus automatique au clavier dès l'ouverture — comportement attendu
    // d'une vraie recherche : pas de tap supplémentaire pour commencer à
    // taper.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<_Suggestion> _match(String query) {
    // On combine services + articles publiés en une seule liste
    // ordonnée par pertinence naïve : préférer les libellés qui
    // *commencent* par la requête (matches solides) sur ceux qui la
    // contiennent (matches faibles).
    final servicesAsync = widget.ref.read(servicesProvider);
    final articlesAsync = widget.ref.read(articlesProvider);
    final services = servicesAsync.maybeWhen(
      data: (l) => l,
      orElse: () => const <Service>[],
    );
    final articles = articlesAsync.maybeWhen(
      data: (l) => l,
      orElse: () => const <Article>[],
    );

    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      // Ecran vide = les premières prestations, comme suggestions par défaut.
      return services
          .take(6)
          .map((s) => _Suggestion(
                label: s.name,
                route: '/services/${s.slug}',
                category: 'Prestation',
                iconData: Icons.spa_outlined,
              ))
          .toList();
    }

    final starts = <_Suggestion>[];
    final contains = <_Suggestion>[];

    for (final s in services) {
      final label = s.name.toLowerCase();
      if (label.startsWith(q)) {
        starts.add(_Suggestion(
          label: s.name,
          route: '/services/${s.slug}',
          category: 'Prestation',
          iconData: Icons.spa_outlined,
        ));
      } else if (label.contains(q)) {
        contains.add(_Suggestion(
          label: s.name,
          route: '/services/${s.slug}',
          category: 'Prestation',
          iconData: Icons.spa_outlined,
        ));
      }
    }
    for (final a in articles) {
      final label = a.title.toLowerCase();
      if (label.startsWith(q)) {
        starts.add(_Suggestion(
          label: a.title,
          route: '/articles/${a.slug}',
          category: 'Article',
          iconData: Icons.article_outlined,
        ));
      } else if (label.contains(q)) {
        contains.add(_Suggestion(
          label: a.title,
          route: '/articles/${a.slug}',
          category: 'Article',
          iconData: Icons.article_outlined,
        ));
      }
    }
    return <_Suggestion>[...starts, ...contains].take(12).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Prend presque tout l'écran : la recherche est un mode plein, pas
    // un pop-up compressé qui masquerait le clavier.
    final size = MediaQuery.of(context).size;
    final insets = MediaQuery.of(context).viewInsets;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: Container(
        height: size.height * 0.88,
        decoration: const BoxDecoration(
          color: FloraColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: FloraColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Rechercher une prestation, un article…',
                        prefixIcon: const Icon(Icons.search,
                            color: FloraColors.textPrimary),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {});
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final items = _match(_controller.text);
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Aucun résultat pour « ${_controller.text} »',
            style: const TextStyle(color: FloraColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = items[i];
        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FloraColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(s.iconData, color: FloraColors.textPrimary, size: 22),
          ),
          title: Text(s.label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: FloraColors.textPrimary,
              )),
          subtitle: Text(s.category,
              style: const TextStyle(
                color: FloraColors.textSecondary,
                fontSize: 12,
              )),
          trailing: const Icon(Icons.north_west,
              color: FloraColors.textSecondary, size: 18),
          onTap: () {
            Navigator.of(context).pop();
            context.go(s.route);
          },
        );
      },
    );
  }
}
