class WalletDocument {
  final String id;
  final String docType;
  final String digilockerUri;
  final String uploadedAt;
  final String? reusedFromApplicationId;
  final String? reusedSchemeName;

  WalletDocument({
    required this.id,
    required this.docType,
    required this.digilockerUri,
    required this.uploadedAt,
    this.reusedFromApplicationId,
    this.reusedSchemeName,
  });

  factory WalletDocument.fromJson(Map<String, dynamic> json) {
    return WalletDocument(
      id: json['id'] ?? '',
      docType: json['docType'] ?? '',
      digilockerUri: json['digilockerUri'] ?? '',
      uploadedAt: json['uploadedAt'] ?? '',
      reusedFromApplicationId: json['reusedFromApplicationId'],
      reusedSchemeName: json['reusedFromApplication']?['scheme']?['name'],
    );
  }
}
