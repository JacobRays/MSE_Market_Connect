class BrokerModel {
  final String id;
  final String name;

  final String? phone;
  final String? altPhone;
  final String? whatsapp;

  final String? email;
  final String? altEmail;

  final String? website;
  final String? address;

  final String? bankInstructions;
  final double feeRate;
  final bool isActive;

  const BrokerModel({
    required this.id,
    required this.name,
    this.phone,
    this.altPhone,
    this.whatsapp,
    this.email,
    this.altEmail,
    this.website,
    this.address,
    this.bankInstructions,
    required this.feeRate,
    required this.isActive,
  });

  factory BrokerModel.fromMap(Map<String, dynamic> map) {
    return BrokerModel(
      id: map['id'] as String,
      name: (map['name'] ?? '').toString(),
      phone: map['phone'] as String?,
      altPhone: map['alt_phone'] as String?,
      whatsapp: map['whatsapp'] as String?,
      email: map['email'] as String?,
      altEmail: map['alt_email'] as String?,
      website: map['website'] as String?,
      address: map['address'] as String?,
      bankInstructions: map['bank_instructions'] as String?,
      feeRate: (map['fee_rate'] as num?)?.toDouble() ?? 0.02,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
