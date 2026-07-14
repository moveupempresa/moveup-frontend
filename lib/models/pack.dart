enum PaymentType {
  online('online', 'Pago en la app'),
  offline('offline', 'Pago en efectivo'),
  free('free', 'Gratis');

  const PaymentType(this.value, this.label);
  final String value;
  final String label;

  static PaymentType fromValue(String value) =>
      PaymentType.values.firstWhere((e) => e.value == value);
}

enum PackType {
  fixed('fixed', 'Fijo'),
  customizable('customizable', 'Personalizable');

  const PackType(this.value, this.label);
  final String value;
  final String label;

  static PackType fromValue(String value) =>
      PackType.values.firstWhere((e) => e.value == value);
}

enum ApprovalMode {
  automatic('automatic', 'Automático'),
  manual('manual', 'Manual');

  const ApprovalMode(this.value, this.label);
  final String value;
  final String label;

  static ApprovalMode fromValue(String value) =>
      ApprovalMode.values.firstWhere((e) => e.value == value);
}

class Pack {
  final String id;
  final String eventId;
  final String name;
  final String? description;
  final double price;
  final PaymentType paymentType;
  final PackType packType;
  final ApprovalMode approvalMode;
  final int? maxSelectableSessions;
  final bool isUnlimitedCapacity;
  final int? capacity;
  final List<String> sessionIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int confirmedCount;
  final bool isSignedUp;
  final bool isWaitlisted;

  const Pack({
    required this.id,
    required this.eventId,
    required this.name,
    this.description,
    required this.price,
    required this.paymentType,
    required this.packType,
    required this.approvalMode,
    this.maxSelectableSessions,
    required this.isUnlimitedCapacity,
    this.capacity,
    required this.sessionIds,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedCount = 0,
    this.isSignedUp = false,
    this.isWaitlisted = false,
  });

  bool get isFull => !isUnlimitedCapacity && capacity != null && confirmedCount >= capacity!;

  factory Pack.fromJson(Map<String, dynamic> json) => Pack(
        id: json['id'] as String,
        eventId: json['eventId'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num).toDouble(),
        paymentType: PaymentType.fromValue(json['paymentType'] as String),
        packType: PackType.fromValue(json['packType'] as String),
        approvalMode: ApprovalMode.fromValue(json['approvalMode'] as String),
        maxSelectableSessions: json['maxSelectableSessions'] as int?,
        isUnlimitedCapacity: json['isUnlimitedCapacity'] as bool,
        capacity: json['capacity'] as int?,
        sessionIds: json['sessionIds'] != null
            ? (json['sessionIds'] as List<dynamic>).cast<String>()
            : const [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        confirmedCount: (json['confirmedCount'] as num?)?.toInt() ?? 0,
        isSignedUp: json['isSignedUp'] as bool? ?? false,
        isWaitlisted: json['isWaitlisted'] as bool? ?? false,
      );
}
