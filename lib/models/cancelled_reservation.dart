enum CancelledBy {
  self('self'),
  organizer('organizer'),
  eventDeleted('event_deleted');

  const CancelledBy(this.value);
  final String value;

  static CancelledBy fromValue(String value) =>
      CancelledBy.values.firstWhere((e) => e.value == value);
}

class CancelledReservation {
  final String id;
  final String eventId;
  final String eventTitle;
  final String? eventCoverMediaUrl;
  final String targetType;
  final String targetName;
  final DateTime? sessionDate;
  final CancelledBy cancelledBy;
  final DateTime cancelledAt;

  const CancelledReservation({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    this.eventCoverMediaUrl,
    required this.targetType,
    required this.targetName,
    this.sessionDate,
    required this.cancelledBy,
    required this.cancelledAt,
  });

  factory CancelledReservation.fromJson(Map<String, dynamic> json) =>
      CancelledReservation(
        id: json['id'] as String,
        eventId: json['eventId'] as String,
        eventTitle: json['eventTitle'] as String,
        eventCoverMediaUrl: json['eventCoverMediaUrl'] as String?,
        targetType: json['targetType'] as String,
        targetName: json['targetName'] as String,
        sessionDate: json['sessionDate'] != null
            ? DateTime.parse(json['sessionDate'] as String)
            : null,
        cancelledBy: CancelledBy.fromValue(json['cancelledBy'] as String),
        cancelledAt: DateTime.parse(json['cancelledAt'] as String),
      );
}
