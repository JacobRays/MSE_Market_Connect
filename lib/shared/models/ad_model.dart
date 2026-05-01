class AdModel {
  final int id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? actionUrl;
  final bool isActive;
  final int priority;

  const AdModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.actionUrl,
    this.isActive = true,
    this.priority = 0,
  });

  factory AdModel.fromMap(Map<String, dynamic> map) {
    return AdModel(
      id: (map['id'] as num).toInt(),
      title: map['title'] as String,
      subtitle: map['subtitle'] as String?,
      imageUrl: map['image_url'] as String?,
      actionUrl: map['action_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      priority: (map['priority'] as num?)?.toInt() ?? 0,
    );
  }
}
