class ProfileModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String role;
  final String kycStatus;
  final DateTime? createdAt;

  const ProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    required this.role,
    required this.kycStatus,
    this.createdAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      role: map['role'] as String? ?? 'investor',
      kycStatus: map['kyc_status'] as String? ?? 'pending',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'kyc_status': kycStatus,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
