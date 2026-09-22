import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  static const _modules = <_Module>[
    _Module(
      'Coiffure professionnelle',
      Icons.content_cut,
      'Coupe, brushing, tissage, tresses, coiffures evenementielles.',
    ),
    _Module(
      'Maquillage & beaute',
      Icons.brush_outlined,
      'Techniques day-to-day, mariee, artistique et longue tenue.',
    ),
    _Module(
      'Diplome & attestation',
      Icons.school,
      'Programme certifiant a la fin de chaque cycle.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Nos formations Flora Hair sont animees par nos experts. '
            'Pour connaitre les prix, dates et modalites, contactez notre '
            'infoline dediee :',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          for (final m in _modules) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FloraColors.charcoal,
                border: Border.all(color: FloraColors.grayWarm),
                borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(m.icon, color: FloraColors.lime, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(m.title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(m.desc,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: FloraColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('tel:${ApiConfig.salonInfoline}'),
            ),
            icon: const Icon(Icons.phone),
            label: const Text('Appeler l\'infoline ${ApiConfig.salonInfoline}'),
          ),
        ],
      ),
    );
  }
}

class _Module {
  const _Module(this.title, this.icon, this.desc);
  final String title;
  final IconData icon;
  final String desc;
}
