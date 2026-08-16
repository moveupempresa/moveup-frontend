class CalendarNote {
  final String id;
  final String date;
  final int? hour;
  final String text;
  final String? title;
  final String? address;
  final int? startMinute;
  final int? endHour;
  final int? endMinute;

  const CalendarNote({
    required this.id,
    required this.date,
    this.hour,
    required this.text,
    this.title,
    this.address,
    this.startMinute,
    this.endHour,
    this.endMinute,
  });

  /// An hour-anchored note is a lightweight personal event (title + optional
  /// address + start/end time) rather than a plain block of text.
  bool get isEvent => title != null && title!.isNotEmpty;

  factory CalendarNote.fromJson(Map<String, dynamic> json) => CalendarNote(
    id: json['id'] as String,
    date: json['date'] as String,
    hour: json['hour'] as int?,
    text: json['text'] as String? ?? '',
    title: json['title'] as String?,
    address: json['address'] as String?,
    startMinute: json['startMinute'] as int?,
    endHour: json['endHour'] as int?,
    endMinute: json['endMinute'] as int?,
  );
}
