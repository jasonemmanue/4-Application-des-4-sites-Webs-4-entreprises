import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/testimonial.dart';

class TestimonialCard extends StatelessWidget {
  final Testimonial testimonial;

  const TestimonialCard({super.key, required this.testimonial});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.format_quote,
                color: AppColors.brand400, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(
              testimonial.message,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.charcoal700,
                  backgroundImage: testimonial.photo != null
                      ? CachedNetworkImageProvider(testimonial.photo!)
                      : null,
                  child: testimonial.photo == null
                      ? const Icon(Icons.person,
                          color: Colors.white70, size: 18)
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(testimonial.author,
                          style: Theme.of(context).textTheme.titleSmall),
                      if (testimonial.role != null || testimonial.company != null)
                        Text(
                          [
                            testimonial.role,
                            testimonial.company,
                          ].whereType<String>().join(' - '),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
                if (testimonial.rating != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < testimonial.rating!
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.accent500,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
