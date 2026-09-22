import 'package:flutter/material.dart';

import '../config/theme.dart';

class BookingCustomerForm extends StatelessWidget {
  const BookingCustomerForm({
    super.key,
    required this.formKey,
    required this.name,
    required this.phone,
    required this.email,
    required this.notes,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController notes;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Vos informations',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextFormField(
            controller: name,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Nom complet'),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Nom requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Telephone'),
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
              return digits.length < 8 ? 'Telephone invalide' : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration:
                const InputDecoration(labelText: 'Email (facultatif)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: notes,
            maxLines: 3,
            decoration:
                const InputDecoration(labelText: 'Notes / demandes speciales'),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FloraColors.darkLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FloraColors.grayWarm),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.info_outline, color: FloraColors.lime),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Un depot de 50 % est demande pour confirmer la reservation. '
                    'Le solde se paie au salon.',
                    style: TextStyle(color: FloraColors.cream),
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
