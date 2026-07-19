enum RegistrationStatus {
  confirmed('confirmed', 'Confirmado'),
  pending('pending', 'Pendiente de aprobación'),
  waitlisted('waitlisted', 'Lista de espera'),
  awaitingPayment('awaiting_payment', 'Esperando pago');

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
  final bool hasPaid;
  final String? viaPack;
  final bool attended;
  final DateTime createdAt;

  const Registrant({
    required this.userId,
    required this.username,
    required this.displayName,
    this.profileImage,
    required this.status,
    required this.selectedSessionIds,
    required this.hasPaid,
    this.viaPack,
    this.attended = false,
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
        hasPaid: json['hasPaid'] as bool? ?? false,
        viaPack: json['viaPack'] as String?,
        attended: json['attended'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Registrant copyWith({bool? hasPaid, bool? attended}) => Registrant(
        userId: userId,
        username: username,
        displayName: displayName,
        profileImage: profileImage,
        status: status,
        selectedSessionIds: selectedSessionIds,
        hasPaid: hasPaid ?? this.hasPaid,
        viaPack: viaPack,
        attended: attended ?? this.attended,
        createdAt: createdAt,
      );
}
