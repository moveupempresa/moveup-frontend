import 'pack.dart';
import 'session.dart';

enum EventType {
  classEvent('class', 'Clase'),
  workshop('workshop', 'Workshop'),
  intensive('intensive', 'Intensivo'),
  training('training', 'Entrenamiento'),
  formation('formation', 'Formación'),
  casting('casting', 'Casting'),
  competition('competition', 'Competición'),
  battle('battle', 'Battle'),
  party('party', 'Fiesta'),
  specialEvent('special_event', 'Evento especial');

  const EventType(this.value, this.label);
  final String value;
  final String label;

  static EventType fromValue(String value) =>
      EventType.values.firstWhere((e) => e.value == value);
}

enum LocationType {
  presential('presential', 'Presencial'),
  online('online', 'Online');

  const LocationType(this.value, this.label);
  final String value;
  final String label;

  static LocationType fromValue(String value) =>
      LocationType.values.firstWhere((e) => e.value == value);
}

enum EventVisibility {
  public('public', 'Público'),
  private('private', 'Privado');

  const EventVisibility(this.value, this.label);
  final String value;
  final String label;

  static EventVisibility fromValue(String value) =>
      EventVisibility.values.firstWhere((e) => e.value == value);
}

enum EventStatus {
  draft('draft', 'Borrador'),
  published('published', 'Publicado'),
  unpublished('unpublished', 'No publicado'),
  cancelled('cancelled', 'Cancelado'),
  archived('archived', 'Archivado');

  const EventStatus(this.value, this.label);
  final String value;
  final String label;

  static EventStatus fromValue(String value) =>
      EventStatus.values.firstWhere((e) => e.value == value);
}

enum CoverMediaType {
  image('image'),
  video('video');

  const CoverMediaType(this.value);
  final String value;

  static CoverMediaType fromValue(String value) =>
      CoverMediaType.values.firstWhere((e) => e.value == value);
}

class Event {
  final String id;
  final String ownerUserId;
  final String title;
  final String description;
  final List<String> style;
  final EventType eventType;
  final String city;
  final String country;
  final LocationType locationType;
  final EventVisibility visibility;
  final bool reservationEnabled;
  final CoverMediaType coverMediaType;
  final String coverMediaUrl;
  final EventStatus status;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Session>? sessions;
  final List<Pack>? packs;
  final String ownerUsername;
  final String ownerDisplayName;

  const Event({
    required this.id,
    required this.ownerUserId,
    required this.title,
    required this.description,
    required this.style,
    required this.eventType,
    required this.city,
    required this.country,
    required this.locationType,
    required this.visibility,
    required this.reservationEnabled,
    required this.coverMediaType,
    required this.coverMediaUrl,
    required this.status,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.sessions,
    this.packs,
    this.ownerUsername = '',
    this.ownerDisplayName = '',
  });

  String get organizerName => ownerDisplayName.isNotEmpty ? ownerDisplayName : ownerUsername;

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as String,
        ownerUserId: json['ownerUserId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        style: (json['style'] as List<dynamic>).cast<String>(),
        eventType: EventType.fromValue(json['eventType'] as String),
        city: json['city'] as String,
        country: json['country'] as String,
        locationType: LocationType.fromValue(json['locationType'] as String),
        visibility: EventVisibility.fromValue(json['visibility'] as String),
        reservationEnabled: json['reservationEnabled'] as bool,
        coverMediaType: CoverMediaType.fromValue(json['coverMediaType'] as String),
        coverMediaUrl: json['coverMediaUrl'] as String,
        status: EventStatus.fromValue(json['status'] as String),
        publishedAt: json['publishedAt'] != null
            ? DateTime.parse(json['publishedAt'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        sessions: json['sessions'] != null
            ? (json['sessions'] as List<dynamic>)
                .map((s) => Session.fromJson(s as Map<String, dynamic>))
                .toList()
            : null,
        packs: json['packs'] != null
            ? (json['packs'] as List<dynamic>)
                .map((p) => Pack.fromJson(p as Map<String, dynamic>))
                .toList()
            : null,
        ownerUsername: json['ownerUsername'] as String? ?? '',
        ownerDisplayName: json['ownerDisplayName'] as String? ?? '',
      );
}
