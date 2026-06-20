/// A calendar event (mapped to the backend `/v1/calendar/events` response).
class CalendarEvent {
  final String id;
  final String provider;
  final String? title;
  final String? description;
  final String? location;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isAllDay;

  const CalendarEvent({
    required this.id,
    required this.provider,
    this.title,
    this.description,
    this.location,
    this.startsAt,
    this.endsAt,
    this.isAllDay = false,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id']?.toString() ?? '',
        provider: json['provider']?.toString() ?? '',
        title: json['title']?.toString(),
        description: json['description']?.toString(),
        location: json['location']?.toString(),
        startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? ''),
        endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? ''),
        isAllDay: json['is_all_day'] == true,
      );

  /// "5:00 PM" (local) or "" for all-day / unknown.
  String get timeLabel {
    final s = startsAt;
    if (s == null || isAllDay) return '';
    final local = s.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ap = local.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }
}
