class SchemeOverview {
  final String schemeId;
  final String schemeName;
  final String schemeCode;
  final double maxAmount;
  final bool hasApplied;
  final String? applicationId;
  final String status; // NOT_APPLIED, DRAFT, SUBMITTED, UNDER_VERIFICATION, SANCTIONED, DISBURSED, REJECTED
  final String? submittedAt;
  final String academicYear;

  SchemeOverview({
    required this.schemeId,
    required this.schemeName,
    required this.schemeCode,
    required this.maxAmount,
    required this.hasApplied,
    this.applicationId,
    required this.status,
    this.submittedAt,
    required this.academicYear,
  });

  factory SchemeOverview.fromJson(Map<String, dynamic> json) {
    return SchemeOverview(
      schemeId: json['schemeId'] ?? '',
      schemeName: json['schemeName'] ?? '',
      schemeCode: json['schemeCode'] ?? '',
      maxAmount: (json['maxAmount'] as num?)?.toDouble() ?? 0.0,
      hasApplied: json['hasApplied'] ?? false,
      applicationId: json['applicationId'],
      status: json['status'] ?? 'NOT_APPLIED',
      submittedAt: json['submittedAt'],
      academicYear: json['academicYear'] ?? '2025-2026',
    );
  }
}
