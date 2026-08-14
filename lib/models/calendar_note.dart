class CalendarNote {
  final String id;
  final String date;
  final int? hour;
  final String text;

  const CalendarNote({
    required this.id,
    required this.date,
    this.hour,
    required this.text,
  });

  factory CalendarNote.fromJson(Map<String, dynamic> json) => CalendarNote(
    id: json['id'] as String,
    date: json['date'] as String,
    hour: json['hour'] as int?,
    text: json['text'] as String,
  );
}
