enum MissionType { study, consulting, training, audit, other }

extension MissionTypeX on MissionType {
  String get apiValue => switch (this) {
        MissionType.study => 'etude',
        MissionType.consulting => 'conseil',
        MissionType.training => 'formation',
        MissionType.audit => 'audit',
        MissionType.other => 'autre',
      };

  String get label => switch (this) {
        MissionType.study => 'Etude',
        MissionType.consulting => 'Conseil',
        MissionType.training => 'Formation',
        MissionType.audit => 'Audit',
        MissionType.other => 'Autre',
      };

  String get description => switch (this) {
        MissionType.study =>
          "Etude quantitative, qualitative, sectorielle, de marche",
        MissionType.consulting =>
          "Accompagnement strategique, organisationnel, operationnel",
        MissionType.training => "Renforcement de capacites, seminaires, coaching",
        MissionType.audit => "Audit institutionnel, evaluation de programmes",
        MissionType.other => "Autre besoin d'expertise",
      };
}

enum BudgetRange {
  under5M,
  from5To15M,
  from15To30M,
  from30To65M,
  over65M,
}

extension BudgetRangeX on BudgetRange {
  String get apiValue => switch (this) {
        BudgetRange.under5M => '<5M',
        BudgetRange.from5To15M => '5-15M',
        BudgetRange.from15To30M => '15-30M',
        BudgetRange.from30To65M => '30-65M',
        BudgetRange.over65M => '>65M',
      };

  String get label => switch (this) {
        BudgetRange.under5M => 'Moins de 5 000 000 FCFA',
        BudgetRange.from5To15M => '5 000 000 - 15 000 000 FCFA',
        BudgetRange.from15To30M => '15 000 000 - 30 000 000 FCFA',
        BudgetRange.from30To65M => '30 000 000 - 65 000 000 FCFA',
        BudgetRange.over65M => 'Plus de 65 000 000 FCFA',
      };
}

class QuoteLead {
  final String name;
  final String whatsappNumber;
  final String message;
  final String? company;
  final MissionType? missionType;
  final BudgetRange? budgetRange;
  final String? timeline;

  const QuoteLead({
    required this.name,
    required this.whatsappNumber,
    required this.message,
    this.company,
    this.missionType,
    this.budgetRange,
    this.timeline,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'whatsapp_number': whatsappNumber,
        if (message.isNotEmpty) 'message': message,
        if (company != null && company!.isNotEmpty) 'company': company,
        if (missionType != null) 'mission_type': missionType!.apiValue,
        if (budgetRange != null) 'budget_range': budgetRange!.apiValue,
        if (timeline != null && timeline!.isNotEmpty) 'timeline': timeline,
      };

  String get whatsappSummary {
    final StringBuffer buf = StringBuffer()
      ..writeln('Demande de devis - RUAH STATISTICS')
      ..writeln('');
    if (missionType != null) buf.writeln('Mission: ${missionType!.label}');
    if (budgetRange != null) buf.writeln('Budget: ${budgetRange!.label}');
    if (timeline != null && timeline!.isNotEmpty) {
      buf.writeln('Delais: $timeline');
    }
    buf
      ..writeln('')
      ..writeln('Description:')
      ..writeln(message)
      ..writeln('')
      ..writeln('Contact: $name')
      ..writeln('WhatsApp: $whatsappNumber');
    if (company != null && company!.isNotEmpty) {
      buf.writeln('Entreprise: $company');
    }
    return buf.toString();
  }
}
