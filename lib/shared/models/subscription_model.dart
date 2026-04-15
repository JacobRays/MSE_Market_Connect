class SubscriptionModel {
  final String userId;
  final String plan; // free | premium
  final String status; // active | past_due | canceled
  final DateTime? currentPeriodEnd;

  const SubscriptionModel({
    required this.userId,
    required this.plan,
    required this.status,
    this.currentPeriodEnd,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      userId: map['user_id'] as String,
      plan: (map['plan'] as String?) ?? 'free',
      status: (map['status'] as String?) ?? 'active',
      currentPeriodEnd: map['current_period_end'] != null
          ? DateTime.tryParse(map['current_period_end'] as String)
          : null,
    );
  }

  bool get isPremium {
    if (plan != 'premium') return false;
    if (status != 'active') return false;
    if (currentPeriodEnd == null) return true; // treat as active premium until expiry is used
    return currentPeriodEnd!.isAfter(DateTime.now());
  }
}
