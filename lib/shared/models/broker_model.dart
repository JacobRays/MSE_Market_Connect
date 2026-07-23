class BrokerModel {
  final String id;
  final String name;

  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? website;

  final String? address;
  final String? officeHours;
  final String? licenseNo;

  final String? bankInstructions;
  final double feeRate;
  final bool isActive;

  const BrokerModel({
    required this.id,
    required this.name,
    this.phone,
    this.whatsapp,
    this.email,
    this.website,
    this.address,
    this.officeHours,
    this.licenseNo,
    this.bankInstructions,
    required this.feeRate,
    required this.isActive,
  });

  factory BrokerModel.fromMap(Map<String, dynamic> map) {
    return BrokerModel(
      id: map['id'] as String,
      name: (map['name'] ?? '').toString(),
      phone: map['phone'] as String?,
      whatsapp: map['whatsapp'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      address: map['address'] as String?,
      officeHours: map['office_hours'] as String?,
      licenseNo: map['license_no'] as String?,
      bankInstructions: map['bank_instructions'] as String?,
      feeRate: (map['fee_rate'] as num?)?.toDouble() ?? 0.02,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
