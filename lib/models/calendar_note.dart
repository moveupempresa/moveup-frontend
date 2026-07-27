class CalendarNote {
  final String id;
  final String date;
  final String text;

  const CalendarNote({required this.id, required this.date, required this.text});

  factory CalendarNote.fromJson(Map<String, dynamic> json) => CalendarNote(
        id: json['id'] as String,
        date: json['date'] as String,
        text: json['text'] as String,
      );
}
