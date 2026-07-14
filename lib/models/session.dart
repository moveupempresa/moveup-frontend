class Session {
  final String id;
  final String eventId;
  final String name;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String? address;
  final String? accessUrl;
  final int? capacity;
  final bool isUnlimitedCapacity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int confirmedCount;
  final bool isSignedUp;
  final bool isWaitlisted;

  const Session({
    required this.id,
    required this.eventId,
    required this.name,
    required this.startDatetime,
    required this.endDatetime,
    this.address,
    this.accessUrl,
    this.capacity,
    required this.isUnlimitedCapacity,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedCount = 0,
    this.isSignedUp = false,
    this.isWaitlisted = false,
  });

  bool get isFull => !isUnlimitedCapacity && capacity != null && confirmedCount >= capacity!;

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as String,
        eventId: json['eventId'] as String,
        name: json['name'] as String,
        startDatetime: DateTime.parse(json['startDatetime'] as String),
        endDatetime: DateTime.parse(json['endDatetime'] as String),
        address: json['address'] as String?,
        accessUrl: json['accessUrl'] as String?,
        capacity: json['capacity'] as int?,
        isUnlimitedCapacity: json['isUnlimitedCapacity'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        confirmedCount: (json['confirmedCount'] as num?)?.toInt() ?? 0,
        isSignedUp: json['isSignedUp'] as bool? ?? false,
        isWaitlisted: json['isWaitlisted'] as bool? ?? false,
      );
}
