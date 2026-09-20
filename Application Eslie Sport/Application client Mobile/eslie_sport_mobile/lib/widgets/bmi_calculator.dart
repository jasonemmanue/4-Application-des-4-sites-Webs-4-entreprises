import 'package:flutter/material.dart';

import '../config/theme.dart';

class BmiCalculator extends StatefulWidget {
  const BmiCalculator({super.key});

  @override
  State<BmiCalculator> createState() => _BmiCalculatorState();
}

class _BmiCalculatorState extends State<BmiCalculator> {
  final _heightCtrl = TextEditingController(text: '170');
  final _weightCtrl = TextEditingController(text: '70');
  double? _bmi;

  void _compute() {
    final h = double.tryParse(_heightCtrl.text.replaceAll(',', '.'));
    final w = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    if (h == null || w == null || h <= 0) return;
    final meters = h / 100;
    setState(() => _bmi = w / (meters * meters));
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  ({String label, Color color, String advice}) _interpret(double bmi) {
    if (bmi < 18.5) {
      return (
        label: 'Maigreur',
        color: AppColors.warning,
        advice: 'Une prise de masse encadree est recommandee.'
      );
    }
    if (bmi < 25) {
      return (
        label: 'Corpulence normale',
        color: AppColors.success,
        advice: 'Continuez a bouger regulierement.'
      );
    }
    if (bmi < 30) {
      return (
        label: 'Surpoids',
        color: AppColors.warning,
        advice: 'Envisagez un programme cardio + nutrition.'
      );
    }
    return (
      label: 'Obesite',
      color: AppColors.error,
      advice: 'Consultez un coach et un nutritionniste.'
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _heightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Taille (cm)',
                  prefixIcon: Icon(Icons.height),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Poids (kg)',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _compute,
          icon: const Icon(Icons.calculate),
          label: const Text('Calculer mon IMC'),
        ),
        if (_bmi != null) ...[
          const SizedBox(height: 16),
          _Result(bmi: _bmi!, interpret: _interpret(_bmi!)),
        ],
      ],
    );
  }
}

class _Result extends StatelessWidget {
  final double bmi;
  final ({String label, Color color, String advice}) interpret;
  const _Result({required this.bmi, required this.interpret});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: interpret.color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: interpret.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(interpret.label,
                    style: TextStyle(
                        color: interpret.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
              const Spacer(),
              Text(bmi.toStringAsFixed(1),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Text(interpret.advice,
              style: const TextStyle(color: AppColors.darkMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
