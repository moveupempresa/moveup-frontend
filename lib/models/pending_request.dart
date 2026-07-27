class PendingRequest {
  final String id;
  final String eventId;
  final String eventTitle;
  final String eventCoverMediaUrl;
  final String packId;
  final String packName;
  final String userId;
  final String username;
  final String displayName;
  final String? profileImage;
  final DateTime createdAt;

  const PendingRequest({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.eventCoverMediaUrl,
    required this.packId,
    required this.packName,
    required this.userId,
    required this.username,
    required this.displayName,
    this.profileImage,
    required this.createdAt,
  });

  String get requesterName => displayName.isNotEmpty ? displayName : username;

  factory PendingRequest.fromJson(Map<String, dynamic> json) => PendingRequest(
        id: json['id'] as String,
        eventId: json['eventId'] as String,
        eventTitle: json['eventTitle'] as String,
        eventCoverMediaUrl: json['eventCoverMediaUrl'] as String,
        packId: json['packId'] as String,
        packName: json['packName'] as String,
        userId: json['userId'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String? ?? '',
        profileImage: json['profileImage'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
