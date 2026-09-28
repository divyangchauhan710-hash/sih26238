class Student {
  final String id;
  final String name;
  final String dob;
  final String gender;
  final String phone;
  final String email;
  final String state;
  final String district;
  final String stCertificateRef;
  final String aadhaarMasked;
  final String bankAccountMasked;

  Student({
    required this.id,
    required this.name,
    required this.dob,
    required this.gender,
    required this.phone,
    required this.email,
    required this.state,
    required this.district,
    required this.stCertificateRef,
    required this.aadhaarMasked,
    required this.bankAccountMasked,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      stCertificateRef: json['stCertificateRef'] ?? '',
      aadhaarMasked: json['aadhaarMasked'] ?? 'XXXX-XXXX-XXXX',
      bankAccountMasked: json['bankAccountMasked'] ?? 'XXXX',
    );
  }
}
