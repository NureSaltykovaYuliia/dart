/// Модель заняття: запечатана ієрархія з трьома підтипами.
///
/// Усі підтипи оголошено в цій бібліотеці, тому компілятор знає повний
/// перелік і перевіряє `switch` без гілки `default` на вичерпність.
library;

import 'clock.dart';
import 'settings.dart';
import 'time_slot.dart';
import 'weekday.dart';

/// Помилка розбору рядка розкладу.
class LessonFormatException extends FormatException {
  /// Створює помилку з описом [message] для рядка [row].
  const LessonFormatException(super.message, [super.source]);
}

/// Незмінне заняття розкладу групи.
sealed class Lesson extends TimeSlot with Schedulable implements Identifiable {
  /// Створює заняття; поля незмінні, тому конструктор константний.
  const Lesson({
    required this.subject,
    required this.lecturer,
    required super.weekday,
    required super.startMinutes,
    required this.room,
    required this.pairs,
    required this.addedOn,
  });

  /// Розбирає рядок CSV; для пошкодженого рядка кидає
  /// [LessonFormatException].
  factory Lesson.fromCsv(String row) => switch (_decode(row)) {
    (final lesson?, _) => lesson,
    (_, final error) => throw LessonFormatException(
      error ?? 'невідома помилка',
      row,
    ),
  };

  /// Розбирає рядок CSV із кешуванням: однаковий рядок дає той самий
  /// об'єкт, а повторний розбір не виконується.
  factory Lesson.cached(String row) => _cache[row] ??= Lesson.fromCsv(row);

  /// Розбирає рядок CSV або повертає `null`, якщо рядок пошкоджений.
  static Lesson? tryParse(String row) => _decode(row).$1;

  static final Map<String, Lesson> _cache = {};

  /// Назва дисципліни.
  final String subject;

  /// Викладач у форматі `Прізвище І.Б.`.
  final String lecturer;

  /// Номер аудиторії з необов'язковою літерою корпусу.
  final String room;

  /// Кількість пар за семестр.
  final int pairs;

  /// Дата внесення запису до розкладу (UTC).
  final DateTime addedOn;

  /// Тип заняття в тому вигляді, у якому він записується у вхідних даних.
  String get kind;

  /// Скільки місць потрібно в аудиторії для групи з [groupSize] студентів.
  int seatsNeeded(int groupSize);

  @override
  String get id => '$subject/${weekday.label}/${hhmm(startMinutes)}';

  /// Академічні години за семестр.
  int get academicHours => pairs * hoursPerPair;

  /// Початок заняття у вигляді `ГГ:ХХ`.
  String get time => hhmm(startMinutes);

  @override
  bool operator ==(Object other) =>
      other is Lesson &&
      runtimeType == other.runtimeType &&
      subject == other.subject &&
      lecturer == other.lecturer &&
      weekday == other.weekday &&
      startMinutes == other.startMinutes &&
      room == other.room &&
      pairs == other.pairs &&
      addedOn == other.addedOn;

  @override
  int get hashCode => Object.hash(
    runtimeType,
    subject,
    lecturer,
    weekday,
    startMinutes,
    room,
    pairs,
    addedOn,
  );

  @override
  String toString() =>
      '$runtimeType(${weekday.label} $time $subject, $lecturer, ауд.$room)';
}

/// Лекція: слухає вся група.
final class Lecture extends Lesson {
  /// Створює лекцію.
  const Lecture({
    required super.subject,
    required super.lecturer,
    required super.weekday,
    required super.startMinutes,
    required super.room,
    required super.pairs,
    required super.addedOn,
  });

  @override
  String get kind => kindLecture;

  @override
  int seatsNeeded(int groupSize) => groupSize;
}

/// Практичне заняття: працює вся група.
final class Practice extends Lesson {
  /// Створює практичне заняття.
  const Practice({
    required super.subject,
    required super.lecturer,
    required super.weekday,
    required super.startMinutes,
    required super.room,
    required super.pairs,
    required super.addedOn,
  });

  @override
  String get kind => kindPractice;

  @override
  int seatsNeeded(int groupSize) => groupSize;
}

/// Лабораторна робота: група ділиться навпіл на підгрупи.
final class LabWork extends Lesson {
  /// Створює лабораторну роботу.
  const LabWork({
    required super.subject,
    required super.lecturer,
    required super.weekday,
    required super.startMinutes,
    required super.room,
    required super.pairs,
    required super.addedOn,
  });

  @override
  String get kind => kindLab;

  @override
  int seatsNeeded(int groupSize) => (groupSize / 2).ceil();
}

/// Розбирає рядок: `(заняття, null)` або `(null, причина)`.
(Lesson?, String?) _decode(String row) {
  final cells = [for (final cell in row.split(cellDelimiter)) cell.trim()];
  if (cells.length != columns.length) {
    return (
      null,
      'очікувалось ${columns.length} полів, отримано ${cells.length}',
    );
  }
  final blank = cells.indexWhere((cell) => cell.isEmpty);
  if (blank != -1) return (null, 'порожнє поле «${columns[blank]}»');

  final [subject, lecturer, kind, day, time, room, pairs, added] = cells;

  return switch ((
    int.tryParse(day),
    readClock(time),
    int.tryParse(pairs),
    readIsoDate(added),
  )) {
    (null, _, _, _) => (null, 'день тижня "$day" не є числом'),
    (_, null, _, _) => (null, 'некоректний час початку "$time"'),
    (_, _, null, _) => (null, 'кількість пар "$pairs" не є числом'),
    (_, _, _, null) => (null, 'некоректна дата внесення "$added"'),
    (final dayNumber?, final start?, final count?, final addedOn?) => switch ((
      Weekday.fromNumber(dayNumber),
      kind,
    )) {
      (null, _) => (null, 'день тижня $dayNumber не існує'),
      (final weekday?, kindLecture) => (
        Lecture(
          subject: subject,
          lecturer: lecturer,
          weekday: weekday,
          startMinutes: start,
          room: room,
          pairs: count,
          addedOn: addedOn,
        ),
        null,
      ),
      (final weekday?, kindPractice) => (
        Practice(
          subject: subject,
          lecturer: lecturer,
          weekday: weekday,
          startMinutes: start,
          room: room,
          pairs: count,
          addedOn: addedOn,
        ),
        null,
      ),
      (final weekday?, kindLab) => (
        LabWork(
          subject: subject,
          lecturer: lecturer,
          weekday: weekday,
          startMinutes: start,
          room: room,
          pairs: count,
          addedOn: addedOn,
        ),
        null,
      ),
      _ => (null, 'невідомий тип заняття "$kind"'),
    },
  };
}
