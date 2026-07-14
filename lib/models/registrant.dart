enum RegistrationStatus {
  confirmed('confirmed', 'Confirmado'),
  pending('pending', 'Pendiente de aprobación'),
  waitlisted('waitlisted', 'Lista de espera');

  const RegistrationStatus(this.value, this.label);
  final String value;
  final String label;

  static RegistrationStatus fromValue(String value) =>
      RegistrationStatus.values.firstWhere((e) => e.value == value);
}

class Registrant {
  final String userId;
  final String username;
  final String displayName;
  final String? profileImage;
  final RegistrationStatus status;
  final List<String> selectedSessionIds;
  final DateTime createdAt;

  const Registrant({
    required this.userId,
    required this.username,
    required this.displayName,
    this.profileImage,
    required this.status,
    required this.selectedSessionIds,
    required this.createdAt,
  });

  factory Registrant.fromJson(Map<String, dynamic> json) => Registrant(
        userId: json['userId'] as String,
        username: json['username'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        profileImage: json['profileImage'] as String?,
        status: RegistrationStatus.fromValue(json['status'] as String),
        selectedSessionIds: json['selectedSessionIds'] != null
            ? (json['selectedSessionIds'] as List<dynamic>).cast<String>()
            : const [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
