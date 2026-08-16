enum NotificationType {
  followedUser('followed_user'),
  followedUserNewEvent('followed_user_new_event'),
  newFollower('new_follower'),
  signedUp('signed_up'),
  waitlisted('waitlisted'),
  spotAvailable('spot_available'),
  targetUpdated('target_updated'),
  newRegistration('new_registration'),
  signupRequest('signup_request'),
  signupApproved('signup_approved'),
  signupRejected('signup_rejected'),
  packPaid('pack_paid'),
  registrationRevoked('registration_revoked'),
  paymentRequired('payment_required'),
  registrantCancelled('registrant_cancelled'),
  selfCancelConfirmed('self_cancel_confirmed'),
  capacityFull('capacity_full'),
  spotFreed('spot_freed'),
  eventCancelled('event_cancelled'),
  savedEventCapacityLow('saved_event_capacity_low'),
  savedEventCapacityFull('saved_event_capacity_full'),
  savedEventSpotFreed('saved_event_spot_freed'),
  eventReminderOrganizerDay('event_reminder_organizer_day'),
  eventReminderOrganizerHours('event_reminder_organizer_hours'),
  eventReminderStudent('event_reminder_student'),
  savedEventReminder('saved_event_reminder'),
  phoneNumberRequired('phone_number_required');

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
  final String? organizerPhone;
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
    this.organizerPhone,
    required this.read,
    required this.createdAt,
    this.isPending,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: NotificationType.fromValue(json['type'] as String),
        message: json['message'] as String,
        relatedUserId: json['relatedUserId'] as String?,
        relatedEventId: json['relatedEventId'] as String?,
        relatedTargetType: json['relatedTargetType'] as String?,
        relatedTargetId: json['relatedTargetId'] as String?,
        organizerPhone: json['organizerPhone'] as String?,
        read: json['read'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isPending: json['isPending'] as bool?,
      );
}
