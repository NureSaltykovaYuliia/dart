/// Методи розширення, корисні для предметної області.
library;

import 'lesson.dart';
import 'patterns.dart';
import 'weekday.dart';

/// Запити до колекції занять.
extension LessonCollection on Iterable<Lesson> {
  /// Сума академічних годин за семестр.
  int get academicHours => fold(0, (sum, l) => sum + l.academicHours);

  /// Заняття, згруповані за днем тижня.
  Map<Weekday, List<Lesson>> get byWeekday => fold(
    <Weekday, List<Lesson>>{},
    (groups, l) => groups..putIfAbsent(l.weekday, () => []).add(l),
  );

  /// Заняття вказаного підтипу [T].
  Iterable<T> ofType<T extends Lesson>() => whereType<T>();
}

/// Операції над рядком із прізвищем викладача.
extension LecturerName on String {
  /// Чи записано рядок у форматі `Прізвище І.Б.`.
  bool get isLecturerName => lecturerPattern.hasMatch(this);

  /// Рядок із прихованим прізвищем: `Петренко О.В.` → `П******* О.В.`.
  String get masked => hideSurname(this);
}
