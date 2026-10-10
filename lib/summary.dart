/// Текстовий звіт про найближчі заняття.
library;

import 'clock.dart';
import 'lesson.dart';
import 'ordering.dart';
import 'patterns.dart';
import 'queries.dart';
import 'settings.dart';

/// Будує звіт про розклад [lessons] станом на момент [at].
///
/// У таблицю потрапляють [rows] занять, упорядкованих за датою
/// найближчого проведення: від найближчого, якщо [nearestFirst],
/// інакше — від найвіддаленішого. Комірки розділяє [gap].
/// `DateTime.now()` не є константою й не може бути значенням
/// за замовчуванням, тому [at] — nullable.
String renderTimetable(
  List<Lesson> lessons, {
  DateTime? at,
  int rows = defaultReportRows,
  bool nearestFirst = true,
  String gap = defaultCellGap,
}) {
  final moment = at ?? DateTime.now();
  int bySession(Lesson a, Lesson b) =>
      nextSession(a, moment).compareTo(nextSession(b, moment));
  final ordered = arranged(
    lessons,
    nearestFirst ? bySession : descending(bySession),
  );

  final out = StringBuffer()
    ..write('РОЗКЛАД ГРУПИ на ${isoDay(moment)}\n')
    ..write('Усього занять: ${lessons.length}, ')
    ..write('аудиторних годин за семестр: ${academicHours(lessons)}\n\n')
    ..write('Найближчі $rows занять:\n');
  for (final lesson in ordered.take(rows)) {
    out
      ..writeAll(_cells(lesson, moment), gap)
      ..writeln();
  }
  return out.toString();
}

/// Комірки одного рядка таблиці звіту.
List<String> _cells(Lesson l, DateTime moment) => [
  isoDay(nextSession(l, moment)),
  '${weekdayLabel(l.weekday)} '
      '${hhmm(l.startMinutes)}–${hhmm(finishMinutes(l))}',
  fitWidth(l.subject, columnWidths.subject),
  l.kind.padRight(kindLab.length),
  'ауд.${l.room}'.padRight(columnWidths.room),
  hideSurname(l.lecturer),
];
