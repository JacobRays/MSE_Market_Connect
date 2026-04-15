class BrokerModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? bankInstructions;
  final double feeRate;
  final bool isActive;

  const BrokerModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.bankInstructions,
    required this.feeRate,
    required this.isActive,
  });

  factory BrokerModel.fromMap(Map<String, dynamic> map) {
    return BrokerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      bankInstructions: map['bank_instructions'] as String?,
      feeRate: (map['fee_rate'] as num?)?.toDouble() ?? 0.02,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
