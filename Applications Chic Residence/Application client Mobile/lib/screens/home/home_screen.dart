import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/other_models.dart';
import '../../models/residence.dart';
import '../../providers/providers.dart';
import '../../services/residence_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/fees_notice.dart';
import '../../widgets/residence_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/stay_calendar.dart';

/// Accueil (maquette du 2026-10-31) : logo en haut à gauche sur une photo qui se
/// fond dans le crème, « Bonjour ! », carte de recherche, catégories en photo,
/// coups de cœur.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final async = ref.watch(allResidencesProvider);
    final pillVisible = ref.watch(feesNoticeVisibleProvider);

    return Scaffold(
      backgroundColor: t.surface,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => ref.invalidate(allResidencesProvider),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    photo: async.valueOrNull?.isNotEmpty == true
                        ? _featured(async.value!).first.mainPhoto
                        : null,
                  ),
                ),
                const SliverToBoxAdapter(child: _SearchCard()),
                async.when(
                  loading: () => const SliverToBoxAdapter(
                    child: SizedBox(height: 420, child: LoadingCards(count: 2)),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(allResidencesProvider),
                    ),
                  ),
                  data: (list) => list.isEmpty
                      ? const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyView(title: 'Aucun logement pour le moment'),
                        )
                      : SliverToBoxAdapter(child: _Content(list: list)),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: pillVisible ? 76 : 20),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: const Center(child: FeesNoticePill()),
          ),
        ],
      ),
    );
  }

  static List<Residence> _featured(List<Residence> list) => [...list]
    ..sort((a, b) {
      final f = (b.isFeatured ? 1 : 0) - (a.isFeatured ? 1 : 0);
      return f != 0 ? f : b.rating.compareTo(a.rating);
    });
}

class _Header extends StatelessWidget {
  const _Header({this.photo});
  final String? photo;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final top = MediaQuery.viewPaddingOf(context).top;
    return SizedBox(
      height: top + 196,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo != null)
            Align(
              alignment: Alignment.topRight,
              child: FractionallySizedBox(
                widthFactor: 0.72,
                heightFactor: 1,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Colors.black, Colors.black, Colors.transparent],
                    stops: [0, 0.45, 1],
                  ).createShader(r),
                  child: ResidencePhoto(url: photo!),
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  t.surface.withValues(alpha: 0.25),
                  t.surface.withValues(alpha: 0.35),
                  t.surface,
                ],
                stops: const [0, 0.6, 1],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Logo de l'application, gardé tel quel (fond blanc d'origine
                    // posé dans une tuile pour rester propre en mode sombre).
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: t.shadow,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/branding/logo-full.png',
                        height: 54,
                        semanticLabel: 'Chic Résidence Meublée',
                      ),
                    ),
                    const Spacer(),
                    _RoundButton(
                      icon: Icons.notifications_none_rounded,
                      tooltip: 'Notifications',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Vos confirmations et rappels arrivent sur WhatsApp.'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Bonjour !',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Trouvez le logement idéal\npour votre séjour à Abidjan',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: t.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: t.surfaceElevated,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: t.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// « Où souhaitez-vous séjourner ? » + ville, dates, invités + Rechercher.
class _SearchCard extends ConsumerStatefulWidget {
  const _SearchCard();

  @override
  ConsumerState<_SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends ConsumerState<_SearchCard> {
  final _query = TextEditingController();
  String? _city;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search() {
    final draft = ref.read(stayDraftProvider);
    ref.read(filtersProvider.notifier).update((f) => f.copyWith(
          query: _query.text.trim(),
          city: _city,
          clearCity: _city == null,
          capacity: draft.guests > 1 ? draft.guests : null,
          clearCapacity: draft.guests <= 1,
        ));
    context.go('/explore');
  }

  Future<void> _pickCity() async {
    final list = ref.read(allResidencesProvider).valueOrNull ?? const [];
    final cities = list.map((r) => r.city).toSet().toList()..sort();
    final picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Toutes les villes'),
              onTap: () => Navigator.of(context, rootNavigator: true).pop(''),
            ),
            for (final c in cities)
              ListTile(
                title: Text(c),
                onTap: () => Navigator.of(context, rootNavigator: true).pop(c),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _city = picked.isEmpty ? null : picked);
  }

  Future<void> _pickDates() async {
    final draft = ref.read(stayDraftProvider);
    DateTime? a = draft.checkIn;
    DateTime? b = draft.checkOut;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Vos dates',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              StayCalendar(
                checkIn: a,
                checkOut: b,
                onChanged: (x, y) => setSheet(() {
                  a = x;
                  b = y;
                }),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Valider'),
              ),
            ],
          ),
        ),
      ),
    );
    ref.read(stayDraftProvider.notifier).state = StayDraft(
      checkIn: a,
      checkOut: b,
      guests: draft.guests,
    );
  }

  Future<void> _pickGuests() async {
    final draft = ref.read(stayDraftProvider);
    var n = draft.guests;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Nombre d\'invités',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.outlined(
                      onPressed: n > 1 ? () => setSheet(() => n--) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text('$n',
                          textAlign: TextAlign.center,
                          style: Theme.of(ctx).textTheme.headlineSmall),
                    ),
                    IconButton.outlined(
                      onPressed: n < 20 ? () => setSheet(() => n++) : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Valider'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    ref.read(stayDraftProvider.notifier).state = StayDraft(
      checkIn: draft.checkIn,
      checkOut: draft.checkOut,
      guests: n,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final draft = ref.watch(stayDraftProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: t.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: t.shadow,
                  blurRadius: 18,
                  spreadRadius: -6,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Où souhaitez-vous séjourner ?',
                hintStyle: TextStyle(fontSize: 14.5, color: t.textPrimary),
                prefixIcon: Icon(Icons.search_rounded, color: t.textPrimary),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Selector(
                  icon: Icons.place_outlined,
                  label: _city ?? 'Abidjan',
                  onTap: _pickCity,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Selector(
                  icon: Icons.calendar_month_outlined,
                  label: draft.hasDates
                      ? '${Dates.dayMonth(draft.checkIn!)} - ${Dates.dayMonth(draft.checkOut!)}'
                      : 'Dates',
                  onTap: _pickDates,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Selector(
                  icon: Icons.person_outline_rounded,
                  label: '${draft.guests} invité${draft.guests > 1 ? 's' : ''}',
                  onTap: _pickGuests,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  const _Selector({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: t.textPrimary),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 15, color: t.textPrimary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.list});
  final List<Residence> list;

  void _openType(BuildContext context, WidgetRef ref, ResidenceType? type) {
    ref.read(filtersProvider.notifier).state =
        type == null ? const ResidenceFilters() : ResidenceFilters(type: type);
    context.go('/explore');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorted = HomeScreen._featured(list);
    final types = <ResidenceType>[
      for (final type in ResidenceType.values)
        if (list.any((r) => r.type == type)) type,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        _Heading(
          title: 'Nos catégories',
          onSeeAll: () => _openType(context, ref, null),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: types.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _CategoryTile(
              type: types[i],
              photo: sorted.firstWhere((r) => r.type == types[i]).mainPhoto,
              onTap: () => _openType(context, ref, types[i]),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Heading(
          title: 'Nos coups de cœur',
          onSeeAll: () => _openType(context, ref, null),
        ),
        SizedBox(
          height: 272,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            itemCount: sorted.length.clamp(0, 8),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => ResidenceCard(
              residence: sorted[i],
              width: 268,
              onTap: () => context.push('/residence/${sorted[i].slug}'),
            ),
          ),
        ),
        const _ReviewsSection(),
        const SizedBox(height: 16),
        const _ProposeCard(),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: t.textPrimary,
                visualDensity: VisualDensity.compact,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Voir tout', style: TextStyle(fontSize: 12.5)),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded, size: 15),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.type,
    required this.photo,
    required this.onTap,
  });
  final ResidenceType type;
  final String photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 90,
                width: 100,
                child: ResidencePhoto(url: photo),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              type.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Masqué tant qu'il n'y a aucun avis publié : section vide = pas de bruit.
class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(topReviewsProvider).valueOrNull ?? const <Review>[];
    if (reviews.isEmpty) return const SizedBox.shrink();
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const _Heading(title: 'Avis de nos voyageurs'),
        SizedBox(
          height: 142,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final r = reviews[i];
              return Container(
                width: 260,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (var s = 0; s < 5; s++)
                          Icon(
                            s < r.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 15,
                            color: AppColors.star,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        r.comment,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, height: 1.35),
                      ),
                    ),
                    Text(
                      r.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProposeCard extends StatelessWidget {
  const _ProposeCard();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surfaceSunken,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Proposer votre logement',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text(
                    'Confiez votre bien meublé à CHIC RESIDENCE. On en parle '
                    'sur WhatsApp.',
                    style: TextStyle(fontSize: 12.5, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              tooltip: 'Discuter sur WhatsApp',
              style: IconButton.styleFrom(backgroundColor: t.brand),
              onPressed: () => WhatsAppService.send(
                'Bonjour CHIC RESIDENCE, je souhaite proposer mon logement '
                'meublé à la location.',
              ),
              icon: const Icon(Icons.chat_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
