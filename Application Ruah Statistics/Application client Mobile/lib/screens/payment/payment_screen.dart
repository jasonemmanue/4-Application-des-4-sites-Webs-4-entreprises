import 'dart:math';

import 'package:cinetpay/cinetpay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/payment_config.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../services/input_sanitizer.dart';

class PaymentScreen extends StatefulWidget {
  final int? initialAmount;
  final String? reference;

  const PaymentScreen({super.key, this.initialAmount, this.reference});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  _PayMethod _selected = _PayMethod.all;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.initialAmount?.toString() ?? '',
    );
    _descCtrl = TextEditingController(
      text: widget.reference != null
          ? 'Ref: ${widget.reference}'
          : '',
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _transactionId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final r = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'RUAH_${ts}_$r';
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    if (!PaymentConfig.isConfigured) {
      _showError('Le paiement en ligne n\'est pas encore active. '
          'Contactez le cabinet.');
      return;
    }

    final amount = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'\D'), ''));
    if (amount == null || amount < PaymentConfig.minAmount) {
      _showError('Montant minimum : ${PaymentConfig.minAmount} FCFA');
      return;
    }

    setState(() => _processing = true);

    try {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => CinetPayCheckout(
            title: 'Paiement RUAH-STATISTICS',
            titleStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            titleBackgroundColor: AppColors.brand700,
            configData: <String, dynamic>{
              'apikey': PaymentConfig.apiKey,
              'site_id': PaymentConfig.siteId,
              'notify_url': PaymentConfig.notifyUrl,
              'mode': PaymentConfig.mode,
            },
            paymentData: <String, dynamic>{
              'transaction_id': _transactionId(),
              'amount': amount,
              'currency': PaymentConfig.currency,
              'channels': _selected.channel,
              'description': InputSanitizer.sanitize(
                _descCtrl.text.isEmpty
                    ? 'Paiement prestation RUAH-STATISTICS'
                    : _descCtrl.text,
                maxLength: 200,
              ),
            },
            waitResponse: (data) {
              if (mounted) Navigator.pop(context, data as Map<String, dynamic>?);
            },
            onError: (data) {
              if (mounted) Navigator.pop(context, data as Map<String, dynamic>?);
            },
          ),
        ),
      );

      if (!mounted) return;

      if (result != null && result['status'] == 'ACCEPTED') {
        context.go(
          AppRoutes.paymentResult,
          extra: {
            'success': true,
            'amount': amount,
            'transactionId': result['transaction_id']?.toString() ?? '',
            'method': result['payment_method']?.toString() ?? '',
          },
        );
      } else {
        context.go(
          AppRoutes.paymentResult,
          extra: {
            'success': false,
            'amount': amount,
            'message': result?['message']?.toString() ?? 'Paiement non abouti.',
          },
        );
      }
    } catch (e) {
      if (mounted) _showError(InputSanitizer.safeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showBankDetails() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Virement bancaire',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _bankRow('Banque', PaymentConfig.companyBank),
            _bankRow('Titulaire', PaymentConfig.companyAccountName),
            _bankRow('IBAN', PaymentConfig.companyIban),
            _bankRow('BIC/SWIFT', PaymentConfig.companyBic),
            const SizedBox(height: 16),
            Text(
              'Indiquez votre reference de devis dans le motif du virement.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: SelectableText(value,
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Payer une prestation')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.ctaGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.lock_rounded, color: Colors.white, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Paiement securise',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Vos transactions sont protegees par CinetPay.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Montant (FCFA)',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Ex: 150000',
                    prefixIcon: Icon(Icons.payments_outlined),
                    suffixText: 'FCFA',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    final n = int.tryParse(v.replaceAll(RegExp(r'\D'), ''));
                    if (n == null || n < PaymentConfig.minAmount) {
                      return 'Minimum ${PaymentConfig.minAmount} FCFA';
                    }
                    if (n > PaymentConfig.maxAmount) {
                      return 'Maximum ${PaymentConfig.maxAmount} FCFA';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Text('Description / Reference',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Etude de marche - Ref DV2024-042',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: InputSanitizer.validateOptionalText,
                ),
                const SizedBox(height: 24),

                Text('Moyen de paiement',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),

                _MethodGrid(
                  isDark: isDark,
                  selected: _selected,
                  onSelect: (m) => setState(() => _selected = m),
                  onBankTransfer: _showBankDetails,
                ),

                const SizedBox(height: 32),

                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _processing ? null : _pay,
                    icon: _processing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.lock_rounded),
                    label: Text(
                      _processing ? 'Traitement...' : 'Proceder au paiement',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PayMethod {
  all('ALL', 'Tous les moyens', Icons.account_balance_wallet_rounded),
  mobileMoney('MOBILE_MONEY', 'Mobile Money', Icons.phone_android_rounded),
  card('CREDIT_CARD', 'Carte bancaire', Icons.credit_card_rounded);

  const _PayMethod(this.channel, this.label, this.icon);
  final String channel;
  final String label;
  final IconData icon;
}

class _MethodGrid extends StatelessWidget {
  final bool isDark;
  final _PayMethod selected;
  final ValueChanged<_PayMethod> onSelect;
  final VoidCallback onBankTransfer;

  const _MethodGrid({
    required this.isDark,
    required this.selected,
    required this.onSelect,
    required this.onBankTransfer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MethodCard(
                isDark: isDark,
                method: _PayMethod.mobileMoney,
                selected: selected == _PayMethod.mobileMoney,
                onTap: () => onSelect(_PayMethod.mobileMoney),
                subtitle: 'Orange, MTN, Moov, Wave',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MethodCard(
                isDark: isDark,
                method: _PayMethod.card,
                selected: selected == _PayMethod.card,
                onTap: () => onSelect(_PayMethod.card),
                subtitle: 'Visa, Mastercard',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MethodCard(
                isDark: isDark,
                method: _PayMethod.all,
                selected: selected == _PayMethod.all,
                onTap: () => onSelect(_PayMethod.all),
                subtitle: 'Mobile + Carte',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BankTransferCard(
                isDark: isDark,
                onTap: onBankTransfer,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final bool isDark;
  final _PayMethod method;
  final bool selected;
  final VoidCallback onTap;
  final String subtitle;

  const _MethodCard({
    required this.isDark,
    required this.method,
    required this.selected,
    required this.onTap,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? Border.all(color: AppColors.brand500, width: 2)
        : Border.all(
            color: isDark ? AppColors.charcoal700 : const Color(0xFFE5E7EB));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brand500.withValues(alpha: isDark ? 0.15 : 0.08)
              : (isDark ? AppColors.charcoal800 : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: border,
        ),
        child: Column(
          children: [
            Icon(method.icon,
                size: 32,
                color: selected ? AppColors.brand500 : (isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(height: 8),
            Text(
              method.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? AppColors.brand500 : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankTransferCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _BankTransferCard({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoal800 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? AppColors.charcoal700 : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(Icons.account_balance_rounded,
                size: 32, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(height: 8),
            const Text(
              'Virement bancaire',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              'Voir les coordonnees',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
