enum NotificationType {
  followedUser('followed_user'),
  followedUserNewEvent('followed_user_new_event'),
  signedUp('signed_up'),
  waitlisted('waitlisted'),
  spotAvailable('spot_available'),
  targetUpdated('target_updated'),
  newRegistration('new_registration'),
  signupRequest('signup_request'),
  signupApproved('signup_approved'),
  signupRejected('signup_rejected');

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
  final String? relatedTargetType;
  final String? relatedTargetId;
  final bool read;
  final DateTime createdAt;
  final bool? isPending;

  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    this.relatedUserId,
    this.relatedEventId,
    this.relatedTargetType,
    this.relatedTargetId,
    required this.read,
    required this.createdAt,
    this.isPending,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: NotificationType.fromValue(json['type'] as String),
        message: json['message'] as String,
        relatedUserId: json['relatedUserId'] as String?,
        relatedEventId: json['relatedEventId'] as String?,
        relatedTargetType: json['relatedTargetType'] as String?,
        relatedTargetId: json['relatedTargetId'] as String?,
        read: json['read'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isPending: json['isPending'] as bool?,
      );
}
