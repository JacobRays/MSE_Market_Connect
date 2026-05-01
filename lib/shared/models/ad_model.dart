class AdModel {
  final int id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? actionUrl;

  const AdModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.actionUrl,
  });

  factory AdModel.fromMap(Map<String, dynamic> map) {
    return AdModel(
      id: (map['id'] as num).toInt(),
      title: map['title'] as String,
      subtitle: map['subtitle'] as String?,
      imageUrl: map['image_url'] as String?,
      actionUrl: map['action_url'] as String?,
    );
  }
}
