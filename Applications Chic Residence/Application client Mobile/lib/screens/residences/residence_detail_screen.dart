import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/other_models.dart';
import '../../models/residence.dart';
import '../../providers/providers.dart';
import '../../widgets/residence_card.dart';
import '../../widgets/state_views.dart';

class ResidenceDetailScreen extends ConsumerWidget {
  const ResidenceDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(residenceDetailProvider(slug));
    return Scaffold(
      body: async.when(
        loading: () => const SafeArea(child: LoadingCards(count: 2)),
        error: (e, _) => SafeArea(
          child: ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(residenceDetailProvider(slug)),
          ),
        ),
        data: (r) => _Body(residence: r),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.residence});
  final Residence residence;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  int _page = 0;
  bool _expanded = false;

  void _openGallery(int index) {
    final photos = widget.residence.photos;
    if (photos.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullGallery(photos: photos, initial: index),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final r = widget.residence;
    final isFav = ref.watch(favoritesProvider).contains(r.id);
    final photos = r.photos.isEmpty ? [r.mainPhoto] : r.photos;
    final top = MediaQuery.viewPaddingOf(context).top;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 310 + top,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      itemCount: photos.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _openGallery(i),
                        child: Semantics(
                          label: 'Photo ${i + 1} de ${r.name}',
                          child: ResidencePhoto(url: photos[i]),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: top + 10,
                      child: _CircleAction(
                        tooltip: 'Retour',
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.navy),
                      ),
                    ),
                    Positioned(
                      right: 14,
                      top: top + 10,
                      child: _CircleAction(
                        tooltip:
                            isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
                        onTap: () =>
                            ref.read(favoritesProvider.notifier).toggle(r.id),
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: AppColors.primary600,
                        ),
                      ),
                    ),
                    if (photos.length > 1)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < photos.length && i < 8; i++)
                              Container(
                                width: 7,
                                height: 7,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _page
                                      ? Colors.white
                                      : Colors.white54,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.place_outlined,
                            size: 17, color: t.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            r.address.isNotEmpty
                                ? '${r.city}, ${r.address}'
                                : r.city,
                            style: TextStyle(
                                fontSize: 14, color: t.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    if (r.reviewsCount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 19, color: AppColors.star),
                          const SizedBox(width: 4),
                          Text(
                            '${r.rating.toStringAsFixed(1).replaceAll('.', ',')} '
                            '(${r.reviewsCount} avis)',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                    if (r.availabilityLabel.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _StatusBadge(residence: r),
                    ],
                    const SizedBox(height: 16),
                    _FactsRow(residence: r),
                    if (r.amenities.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _AmenitiesCard(amenities: r.amenities),
                    ],
                    const SizedBox(height: 20),
                    const Text('Description',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      r.description,
                      maxLines: _expanded ? null : 4,
                      overflow: _expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, height: 1.45),
                    ),
                    if (r.description.length > 170)
                      Center(
                        child: TextButton.icon(
                          onPressed: () =>
                              setState(() => _expanded = !_expanded),
                          iconAlignment: IconAlignment.end,
                          icon: Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                          ),
                          label: Text(_expanded ? 'Voir moins' : 'Voir plus'),
                        ),
                      ),
                    _Reviews(residenceId: r.id),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: t.surfaceElevated,
            border: Border(top: BorderSide(color: t.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PriceLine(price: r.pricePerNight, size: 19),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: r.isBookable
                        ? () => context.push('/book/${r.slug}')
                        : null,
                    icon: const Icon(Icons.event_available_rounded),
                    label:
                        Text(r.isBookable ? 'Réserver' : 'Indisponible'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: child),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.residence});
  final Residence residence;

  @override
  Widget build(BuildContext context) {
    final free = residence.availability == AvailabilityStatus.available;
    final color = free
        ? AppColors.successDeep
        : residence.availability == AvailabilityStatus.occupied
            ? AppColors.primary700
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        residence.availabilityLabel,
        style:
            TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FactsRow extends StatelessWidget {
  const _FactsRow({required this.residence});
  final Residence residence;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final r = residence;
    final facts = <(IconData, String)>[
      (Icons.person_outline_rounded, '${r.capacity} pers.'),
      (Icons.bed_outlined, '${r.bedrooms} ch.'),
      (Icons.bathtub_outlined, '${r.bathrooms} sdb'),
      if (r.areaSqm != null) (Icons.square_foot_rounded, '${r.areaSqm} m²'),
    ];
    return Row(
      children: [
        for (final f in facts)
          Expanded(
            child: Column(
              children: [
                Icon(f.$1, size: 22, color: t.textPrimary),
                const SizedBox(height: 3),
                Text(f.$2, style: const TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
      ],
    );
  }
}

class _AmenitiesCard extends StatefulWidget {
  const _AmenitiesCard({required this.amenities});
  final List<String> amenities;

  @override
  State<_AmenitiesCard> createState() => _AmenitiesCardState();
}

class _AmenitiesCardState extends State<_AmenitiesCard> {
  bool _all = false;

  /// Clés stockées en base (`AMENITIES` de l'admin), mêmes libellés que le site.
  static const _labels = {
    'ac': 'Climatisation',
    'wifi': 'Wi-Fi',
    'tv': 'TV',
    'kitchen': 'Cuisine',
    'washer': 'Machine à laver',
    'iron': 'Fer à repasser',
    'hot_water': 'Eau chaude',
    'parking': 'Parking',
    'outdoor_space': 'Extérieur',
    'security': 'Sécurité',
    'linens': 'Linge fourni',
    'toiletries': 'Produits d\'accueil',
    'pool': 'Piscine',
    'generator': 'Groupe électrogène',
    'elevator': 'Ascenseur',
    'furnished': 'Meublé',
    'garden': 'Jardin',
    'balcony': 'Balcon',
    'gym': 'Salle de sport',
  };

  static const _icons = {
    'ac': Icons.ac_unit_rounded,
    'wifi': Icons.wifi_rounded,
    'tv': Icons.tv_rounded,
    'kitchen': Icons.kitchen_rounded,
    'washer': Icons.local_laundry_service_rounded,
    'iron': Icons.iron_rounded,
    'hot_water': Icons.water_drop_outlined,
    'parking': Icons.directions_car_filled_rounded,
    'outdoor_space': Icons.deck_rounded,
    'security': Icons.shield_outlined,
    'linens': Icons.bed_outlined,
    'toiletries': Icons.soap_outlined,
    'pool': Icons.pool_rounded,
    'generator': Icons.bolt_rounded,
    'elevator': Icons.elevator_rounded,
    'furnished': Icons.chair_outlined,
    'garden': Icons.park_rounded,
    'balcony': Icons.balcony_rounded,
    'gym': Icons.fitness_center_rounded,
  };

  static IconData _icon(String a) {
    final known = _icons[a];
    if (known != null) return known;
    final s = a.toLowerCase();
    if (s.contains('wifi') || s.contains('wi-fi')) return Icons.wifi_rounded;
    if (s.contains('clim')) return Icons.ac_unit_rounded;
    if (s.contains('cuisine')) return Icons.kitchen_rounded;
    if (s.contains('parking')) return Icons.directions_car_filled_rounded;
    if (s.contains('tv') || s.contains('télé') || s.contains('tele')) {
      return Icons.tv_rounded;
    }
    if (s.contains('lave') || s.contains('machine')) {
      return Icons.local_laundry_service_rounded;
    }
    if (s.contains('piscine')) return Icons.pool_rounded;
    if (s.contains('sécurité') || s.contains('securite') || s.contains('gardien')) {
      return Icons.shield_outlined;
    }
    if (s.contains('groupe') || s.contains('électrogène')) {
      return Icons.bolt_rounded;
    }
    if (s.contains('ascenseur')) return Icons.elevator_rounded;
    if (s.contains('balcon') || s.contains('terrasse')) return Icons.deck_rounded;
    if (s.contains('jardin')) return Icons.park_rounded;
    if (s.contains('gym') || s.contains('sport')) return Icons.fitness_center_rounded;
    return Icons.check_circle_outline_rounded;
  }

  static String _pretty(String a) =>
      _labels[a] ??
      (a.isEmpty ? a : a[0].toUpperCase() + a.substring(1).replaceAll('_', ' '));

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final list = _all ? widget.amenities : widget.amenities.take(8).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - 24) / 4;
              return Wrap(
                spacing: 8,
                runSpacing: 14,
                children: [
                  for (final a in list)
                    SizedBox(
                      width: w,
                      child: Column(
                        children: [
                          Icon(_icon(a), size: 24, color: t.textPrimary),
                          const SizedBox(height: 5),
                          Text(
                            _pretty(a),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, height: 1.2),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          if (widget.amenities.length > 8)
            TextButton(
              onPressed: () => setState(() => _all = !_all),
              child: Text(_all
                  ? 'Voir moins'
                  : 'Voir les ${widget.amenities.length} équipements'),
            ),
        ],
      ),
    );
  }
}

class _Reviews extends ConsumerWidget {
  const _Reviews({required this.residenceId});
  final String residenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(residenceReviewsProvider(residenceId)).valueOrNull ??
        const <Review>[];
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text('Avis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            TextButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                builder: (_) => _ReviewSheet(residenceId: residenceId),
              ),
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('Laisser un avis'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final r in list.take(3))
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(r.author,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    const Icon(Icons.star_rounded,
                        size: 15, color: AppColors.star),
                    Text(' ${r.rating.round()}',
                        style: const TextStyle(fontSize: 12.5)),
                  ],
                ),
                if (r.comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(r.comment,
                      style: const TextStyle(fontSize: 13, height: 1.35)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Formulaire d'avis. L'avis part en modération dans l'administration.
class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.residenceId});
  final String residenceId;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  late final _name =
      TextEditingController(text: ref.read(guestNameProvider) ?? '');
  final _comment = TextEditingController();
  int _rating = 5;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(residenceServiceProvider).submitReview(
            residenceId: widget.residenceId,
            author: _name.text.trim(),
            rating: _rating,
            comment: _comment.text.trim(),
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Merci ! Votre avis sera publié après validation.'),
      ));
    } catch (e) {
      final s = e.toString();
      if (mounted) {
        setState(() => _error =
            s.startsWith('DioException') ? 'L\'envoi a échoué.' : s);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Votre avis', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i sur 5',
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 34,
                    color: AppColors.star,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Votre nom'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _comment,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Votre commentaire',
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed:
                _name.text.trim().length < 2 || _sending ? null : _send,
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}

class _FullGallery extends StatelessWidget {
  const _FullGallery({required this.photos, required this.initial});
  final List<String> photos;
  final int initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: photos.length,
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: ResidencePhoto(url: photos[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
