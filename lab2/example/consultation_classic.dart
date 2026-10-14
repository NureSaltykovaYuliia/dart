// Той самий клас Consultation, записаний без первинного конструктора.
// Порівняйте обсяг із lib/consultation.dart.
// ignore_for_file: public_member_api_docs

import 'package:group_schedule_oop/group_schedule_oop.dart';

class ClassicConsultation extends TimeSlot
    with Schedulable
    implements Identifiable {
  const ClassicConsultation({
    required this.lecturer,
    required super.weekday,
    required super.startMinutes,
    required this.room,
  });

  final String lecturer;
  final String room;

  @override
  String get id => 'consultation/$lecturer/${weekday.label}';

  @override
  String toString() =>
      'Consultation($lecturer, ${weekday.label} ${hhmm(startMinutes)}, '
      'ауд.$room)';
}

void main() {
  const classic = ClassicConsultation(
    lecturer: 'Петренко О.В.',
    weekday: Weekday.monday,
    startMinutes: 585,
    room: '287',
  );
  const primary = Consultation(
    lecturer: 'Петренко О.В.',
    weekday: Weekday.monday,
    startMinutes: 585,
    room: '287',
  );
  print(classic);
  print(primary);
  print('Однаковий вивід: ${classic.toString() == primary.toString()}');
  print('Однакові id: ${classic.id == primary.id}');
}
