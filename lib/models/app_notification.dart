enum NotificationType {
  followedUser('followed_user'),
  followedUserNewEvent('followed_user_new_event');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromValue(String value) =>
      NotificationType.values.firstWhere((e) => e.value == value);
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String message;
  final String? relatedUserId;
  final String? relatedEventId;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    this.relatedUserId,
    this.relatedEventId,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: NotificationType.fromValue(json['type'] as String),
        message: json['message'] as String,
        relatedUserId: json['relatedUserId'] as String?,
        relatedEventId: json['relatedEventId'] as String?,
        read: json['read'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
