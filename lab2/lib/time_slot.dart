/// Часовий слот розкладу та домішка з обчисленнями над ним.
library;

import 'settings.dart';
import 'weekday.dart';

/// Об'єкт, що має стабільний рядковий ідентифікатор.
abstract interface class Identifiable {
  /// Унікальний у межах сховища ідентифікатор.
  String get id;
}

/// Щотижневий слот: день тижня та початок у хвилинах від півночі.
abstract class TimeSlot {
  /// Створює слот на [weekday] з початком о [startMinutes].
  const TimeSlot({required this.weekday, required this.startMinutes});

  /// День тижня, у який відбувається подія.
  final Weekday weekday;

  /// Початок події, хвилини від півночі.
  final int startMinutes;
}

/// Обчислення для подій, що повторюються щотижня.
///
/// Обмеження `on TimeSlot` робить дві речі: домішку можна підмішати лише
/// до нащадків [TimeSlot], а в її тілі доступні `weekday` і `startMinutes`.
mixin Schedulable on TimeSlot {
  /// Позиція початку в тижні, хвилини від понеділка 00:00.
  int get weekMinute =>
      (weekday.number - DateTime.monday) * Duration.minutesPerDay +
      startMinutes;

  /// Хвилина закінчення пари (за модулем доби).
  int get finishMinutes =>
      (startMinutes + pairLength.inMinutes) % Duration.minutesPerDay;

  /// Чи перетинається за часом із подією [other] в той самий день.
  bool overlaps(TimeSlot other) =>
      weekday == other.weekday &&
      (startMinutes - other.startMinutes).abs() < pairLength.inMinutes;

  /// Момент найближчого проведення, не раніше за [now].
  ///
  /// Обидва моменти переводяться в хвилини від початку тижня; різниця
  /// за модулем [minutesPerWeek] — скільки хвилин чекати.
  DateTime nextOccurrence(DateTime now) {
    final nowMinute =
        (now.weekday - DateTime.monday) * Duration.minutesPerDay +
        now.hour * Duration.minutesPerHour +
        now.minute;
    final wait = (weekMinute - nowMinute) % minutesPerWeek;
    final base = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    return base.add(Duration(minutes: wait));
  }
}
