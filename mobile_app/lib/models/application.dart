class VerificationItem {
  final String id;
  final String checkType;
  final String sourceSystem;
  final String status; // PENDING, VERIFIED, MISMATCH, MANUAL_REVIEW
  final double confidenceScore;
  final String? checkedAt;

  VerificationItem({
    required this.id,
    required this.checkType,
    required this.sourceSystem,
    required this.status,
    required this.confidenceScore,
    this.checkedAt,
  });

  factory VerificationItem.fromJson(Map<String, dynamic> json) {
    return VerificationItem(
      id: json['id'] ?? '',
      checkType: json['checkType'] ?? '',
      sourceSystem: json['sourceSystem'] ?? '',
      status: json['status'] ?? 'PENDING',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      checkedAt: json['checkedAt'],
    );
  }
}

class ApplicationDetail {
  final String id;
  final String studentId;
  final String schemeId;
  final String schemeName;
  final String status;
  final String academicYear;
  final String? submittedAt;
  final List<VerificationItem> verifications;
  final double sanctionedAmount;
  final double disbursedAmount;
  final String? dbtRef;

  ApplicationDetail({
    required this.id,
    required this.studentId,
    required this.schemeId,
    required this.schemeName,
    required this.status,
    required this.academicYear,
    this.submittedAt,
    required this.verifications,
    required this.sanctionedAmount,
    required this.disbursedAmount,
    this.dbtRef,
  });

  factory ApplicationDetail.fromJson(Map<String, dynamic> json) {
    var verList = <VerificationItem>[];
    if (json['verifications'] != null) {
      verList = (json['verifications'] as List)
          .map((v) => VerificationItem.fromJson(v))
          .toList();
    }

    double sanc = 0.0;
    double disb = 0.0;
    String? dbt = null;

    if (json['sanctions'] != null && (json['sanctions'] as List).isNotEmpty) {
      final s = json['sanctions'][0];
      sanc = (s['amount'] as num?)?.toDouble() ?? 0.0;
      if (s['disbursements'] != null && (s['disbursements'] as List).isNotEmpty) {
        final d = s['disbursements'][0];
        disb = (d['amount'] as num?)?.toDouble() ?? 0.0;
        dbt = d['dbtTransactionRef'];
      }
    }

    return ApplicationDetail(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      schemeId: json['schemeId'] ?? '',
      schemeName: json['scheme']?['name'] ?? 'Scholarship Scheme',
      status: json['status'] ?? 'DRAFT',
      academicYear: json['academicYear'] ?? '2025-2026',
      submittedAt: json['submittedAt'],
      verifications: verList,
      sanctionedAmount: sanc,
      disbursedAmount: disb,
      dbtRef: dbt,
    );
  }
}
