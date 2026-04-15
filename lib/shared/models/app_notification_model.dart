class AppNotificationModel {
  final int id;
  final String userId;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.data,
    this.readAt,
  });

  factory AppNotificationModel.fromMap(Map<String, dynamic> map) {
    return AppNotificationModel(
      id: map['id'] as int,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      data: (map['data'] as Map?)?.cast<String, dynamic>(),
      createdAt: DateTime.parse(map['created_at'] as String),
      readAt: map['read_at'] != null
          ? DateTime.tryParse(map['read_at'] as String)
          : null,
    );
  }

  bool get isRead => readAt != null;
}
