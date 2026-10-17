/// Модель заняття: запечатана ієрархія, розбір CSV та JSON.
library;

import 'clock.dart';
import 'settings.dart';
import 'time_slot.dart';
import 'weekday.dart';

/// Помилка розбору рядка розкладу або JSON.
class LessonFormatException extends FormatException {
  /// Створює помилку з описом [message] і необов'язковим джерелом.
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

  /// Розбирає рядок CSV; для пошкодженого кидає [LessonFormatException].
  factory Lesson.fromCsv(String row) => switch (_decode(row)) {
    (final lesson?, _) => lesson,
    (_, final error) => throw LessonFormatException(
      error ?? 'невідома помилка',
      row,
    ),
  };

  /// Будує заняття з JSON-об'єкта; кожне поле приводиться до типу явно.
  ///
  /// Для відсутнього поля чи значення неочікуваного типу кидає
  /// [LessonFormatException].
  factory Lesson.fromJson(Map<String, Object?> json) {
    final day = Weekday.fromNumber(_field<int>(json, 'weekday'));
    final start = readClock(_field<String>(json, 'time'));
    final added = readIsoDate(_field<String>(json, 'addedOn'));
    if (day == null || start == null || added == null) {
      throw LessonFormatException('некоректний день, час або дата', json);
    }
    final kind = _field<String>(json, 'kind');
    return _create(
          kind,
          subject: _field<String>(json, 'subject'),
          lecturer: _field<String>(json, 'lecturer'),
          weekday: day,
          startMinutes: start,
          room: _field<String>(json, 'room'),
          pairs: _field<int>(json, 'pairs'),
          addedOn: added,
        ) ??
        (throw LessonFormatException('невідомий тип "$kind"', json));
  }

  /// Розбирає рядок CSV або повертає `null`, якщо рядок пошкоджений.
  static Lesson? tryParse(String row) => _decode(row).$1;

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

  /// Подання заняття у форматі JSON.
  Map<String, Object?> toJson() => {
    'subject': subject,
    'lecturer': lecturer,
    'kind': kind,
    'weekday': weekday.number,
    'time': time,
    'room': room,
    'pairs': pairs,
    'addedOn': isoDay(addedOn),
  };

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

/// Читає з [json] поле [key] типу [T] або кидає [LessonFormatException].
T _field<T>(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is T) return value;
  throw LessonFormatException(
    'поле "$key": очікувався ${T.toString()}, отримано '
    '${value.runtimeType}',
    json,
  );
}

/// Створює підтип заняття за назвою [kind]; `null` для невідомого типу.
Lesson? _create(
  String kind, {
  required String subject,
  required String lecturer,
  required Weekday weekday,
  required int startMinutes,
  required String room,
  required int pairs,
  required DateTime addedOn,
}) {
  return switch (kind) {
    kindLecture => Lecture(
      subject: subject,
      lecturer: lecturer,
      weekday: weekday,
      startMinutes: startMinutes,
      room: room,
      pairs: pairs,
      addedOn: addedOn,
    ),
    kindPractice => Practice(
      subject: subject,
      lecturer: lecturer,
      weekday: weekday,
      startMinutes: startMinutes,
      room: room,
      pairs: pairs,
      addedOn: addedOn,
    ),
    kindLab => LabWork(
      subject: subject,
      lecturer: lecturer,
      weekday: weekday,
      startMinutes: startMinutes,
      room: room,
      pairs: pairs,
      addedOn: addedOn,
    ),
    _ => null,
  };
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
    (final dayNumber?, final start?, final count?, final addedOn?) =>
      switch (Weekday.fromNumber(dayNumber)) {
        null => (null, 'день тижня $dayNumber не існує'),
        final weekday => switch (_create(
          kind,
          subject: subject,
          lecturer: lecturer,
          weekday: weekday,
          startMinutes: start,
          room: room,
          pairs: count,
          addedOn: addedOn,
        )) {
          null => (null, 'невідомий тип заняття "$kind"'),
          final lesson => (lesson, null),
        },
      },
  };
}
