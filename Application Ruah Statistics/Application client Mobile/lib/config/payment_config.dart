class PaymentConfig {
  PaymentConfig._();

  static const String apiKey =
      String.fromEnvironment('CINETPAY_API_KEY');

  static final int siteId = int.tryParse(
        const String.fromEnvironment('CINETPAY_SITE_ID'),
      ) ??
      0;

  static const String notifyUrl =
      String.fromEnvironment('CINETPAY_NOTIFY_URL');

  static const String mode =
      String.fromEnvironment('CINETPAY_MODE', defaultValue: 'PRODUCTION');

  static const String currency = 'XOF';
  static const int minAmount = 100;
  static const int maxAmount = 1500000;

  static bool get isConfigured => apiKey.isNotEmpty && siteId > 0;

  static const String companyBank = 'Societe Generale CI';
  static const String companyIban = 'CI93 CI05 0001 0000 0000 0047 6590 10';
  static const String companyBic = 'SGCIDICIXXX';
  static const String companyAccountName = 'RUAH-STATISTICS SARL';
}
