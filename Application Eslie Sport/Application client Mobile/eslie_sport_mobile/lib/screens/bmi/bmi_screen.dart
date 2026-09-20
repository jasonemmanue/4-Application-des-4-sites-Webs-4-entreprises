import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../widgets/bmi_calculator.dart';

class BmiScreen extends StatelessWidget {
  const BmiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calcul IMC')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Indice de Masse Corporelle',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text(
            'Estimez votre corpulence et decouvrez notre programme adapte.',
            style: TextStyle(color: AppColors.darkMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const BmiCalculator(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rappel',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text(
                  'L\'IMC est un indicateur general. Il ne tient pas compte de la masse musculaire. Consultez votre coach pour un bilan complet.',
                  style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
