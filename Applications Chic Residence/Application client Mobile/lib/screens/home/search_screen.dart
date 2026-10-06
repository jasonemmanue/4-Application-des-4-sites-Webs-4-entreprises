import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/residence_card.dart';
import '../../widgets/state_views.dart';

/// Recherche avec **autocomplétion en dropdown sous la barre**.
///
/// Les suggestions viennent de `GET /residences/suggestions?q=` (fuzzy
/// Levenshtein côté backend). Le catalogue en dessous se met à jour en
/// parallèle, avec un debounce de 300 ms partagé.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<String> _suggestions = const [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() =>
          _showSuggestions = _focus.hasFocus && _suggestions.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      final svc = ref.read(residenceServiceProvider);
      ref
          .read(filtersProvider.notifier)
          .update((s) => s.copyWith(query: q, page: 1));

      if (q.trim().isEmpty) {
        setState(() {
          _suggestions = const [];
          _showSuggestions = false;
        });
        return;
      }
      try {
        final s = await svc.suggestions(q);
        if (!mounted) return;
        setState(() {
          _suggestions = s;
          _showSuggestions = _focus.hasFocus && s.isNotEmpty;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _suggestions = const [];
          _showSuggestions = false;
        });
      }
    });
  }

  void _pickSuggestion(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    setState(() => _showSuggestions = false);
    ref
        .read(filtersProvider.notifier)
        .update((s) => s.copyWith(query: value, page: 1));
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final async = ref.watch(residencesProvider);

    return Scaffold(
      backgroundColor: t.surface,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: t.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: _InlineSearchField(
          controller: _controller,
          focusNode: _focus,
          onChanged: _onChanged,
          onClear: () {
            _controller.clear();
            _onChanged('');
          },
        ),
      ),
      body: Column(
        children: [
          if (_showSuggestions)
            Material(
              elevation: 0,
              color: t.surfaceElevated,
              child: Column(
                children: [
                  for (final s in _suggestions.take(6))
                    InkWell(
                      onTap: () => _pickSuggestion(s),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: t.surfaceSunken,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: t.border, width: 1.2),
                              ),
                              child: Icon(Icons.search_rounded,
                                  size: 20, color: t.textPrimary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                s,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: t.textPrimary,
                                ),
                              ),
                            ),
                            Icon(Icons.north_west_rounded,
                                size: 18, color: t.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  Divider(height: 1, color: t.border),
                ],
              ),
            ),
          Expanded(
            child: async.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyView(
                    title: 'Rien trouvé',
                    description:
                        'Modifiez votre recherche ou explorez toutes les résidences.',
                  );
                }
                return ListView.separated(
                  padding:
                      EdgeInsets.fromLTRB(16, 12, 16, context.bottomInset()),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 24),
                  itemBuilder: (context, i) => ResidenceCard(
                    residence: list[i],
                    onTap: () => context.push('/residence/${list[i].slug}'),
                  ),
                );
              },
              loading: () => const LoadingCards(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(residencesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineSearchField extends StatelessWidget {
  const _InlineSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: t.surfaceSunken,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, color: t.textPrimary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                cursorColor: t.textPrimary,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher une résidence, une ville…',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: t.textSecondary,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, v, _) {
                if (v.text.isEmpty) return const SizedBox(width: 14);
                return IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: t.textSecondary,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
