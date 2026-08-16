class CalendarNote {
  final String id;
  final String date;
  final int? hour;
  final String text;
  final String? title;
  final String? address;
  final int? endHour;

  const CalendarNote({
    required this.id,
    required this.date,
    this.hour,
    required this.text,
    this.title,
    this.address,
    this.endHour,
  });

  /// An hour-anchored note is a lightweight personal event (title + optional
  /// address + start/end hour) rather than a plain block of text.
  bool get isEvent => title != null && title!.isNotEmpty;

  factory CalendarNote.fromJson(Map<String, dynamic> json) => CalendarNote(
    id: json['id'] as String,
    date: json['date'] as String,
    hour: json['hour'] as int?,
    text: json['text'] as String? ?? '',
    title: json['title'] as String?,
    address: json['address'] as String?,
    endHour: json['endHour'] as int?,
  );
}
