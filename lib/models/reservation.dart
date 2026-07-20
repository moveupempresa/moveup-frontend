import 'event.dart';

class Reservation {
  final String id;
  final String targetType;
  final String targetId;
  final String targetName;
  final String status;
  final bool hasPaid;
  final DateTime? sessionDate;
  final bool isPast;
  final double? price;
  final String? paymentType;
  final Event event;

  const Reservation({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.status,
    required this.hasPaid,
    this.sessionDate,
    required this.isPast,
    this.price,
    this.paymentType,
    required this.event,
  });

  bool get isSession => targetType == 'session';

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'] as String,
        targetType: json['targetType'] as String,
        targetId: json['targetId'] as String,
        targetName: json['targetName'] as String,
        status: json['status'] as String,
        hasPaid: json['hasPaid'] as bool,
        sessionDate:
            json['sessionDate'] != null ? DateTime.parse(json['sessionDate'] as String) : null,
        isPast: json['isPast'] as bool,
        price: (json['price'] as num?)?.toDouble(),
        paymentType: json['paymentType'] as String?,
        event: Event.fromJson(json['event'] as Map<String, dynamic>),
      );
}
