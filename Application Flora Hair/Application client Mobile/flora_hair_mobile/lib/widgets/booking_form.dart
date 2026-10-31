import 'package:flutter/material.dart';

class BookingCustomerForm extends StatelessWidget {
  const BookingCustomerForm({
    super.key,
    required this.formKey,
    required this.name,
    required this.phone,
    required this.email,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;

  // Le backend valide l'adresse (`EmailStr`) : mieux vaut le dire au champ
  // qu'afficher une erreur générique après coup.
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

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
            textCapitalization: TextCapitalization.words,
            autofillHints: const <String>[AutofillHints.name],
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Nom complet',
              counterText: '',
            ),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Nom requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.telephoneNumber],
            maxLength: 20,
            decoration: const InputDecoration(
              labelText: 'Téléphone (WhatsApp)',
              counterText: '',
            ),
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
              return digits.length < 8 ? 'Téléphone invalide' : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.email],
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Email (facultatif)',
              counterText: '',
            ),
            validator: (v) {
              final value = (v ?? '').trim();
              return value.isEmpty || _emailPattern.hasMatch(value)
                  ? null
                  : 'Adresse email invalide';
            },
          ),
        ],
      ),
    );
  }
}
