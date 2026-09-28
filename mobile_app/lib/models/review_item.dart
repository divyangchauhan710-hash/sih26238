class ReviewQueueItem {
  final String id;
  final String verificationCheckId;
  final String checkType;
  final String sourceSystem;
  final String studentName;
  final String schemeName;
  final String status;
  final String? notes;
  final double confidenceScore;
  final String createdAt;

  ReviewQueueItem({
    required this.id,
    required this.verificationCheckId,
    required this.checkType,
    required this.sourceSystem,
    required this.studentName,
    required this.schemeName,
    required this.status,
    this.notes,
    required this.confidenceScore,
    required this.createdAt,
  });

  factory ReviewQueueItem.fromJson(Map<String, dynamic> json) {
    final vCheck = json['verificationCheck'] ?? {};
    final app = vCheck['application'] ?? {};
    final student = app['student'] ?? {};
    final scheme = app['scheme'] ?? {};

    return ReviewQueueItem(
      id: json['id'] ?? '',
      verificationCheckId: json['verificationCheckId'] ?? '',
      checkType: vCheck['checkType'] ?? 'VERIFICATION',
      sourceSystem: vCheck['sourceSystem'] ?? 'SOURCE_SYSTEM',
      studentName: student['name'] ?? 'Student Beneficiary',
      schemeName: scheme['name'] ?? 'ST Scholarship Scheme',
      status: json['status'] ?? 'PENDING',
      notes: json['notes'],
      confidenceScore: (vCheck['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] ?? '',
    );
  }
}
