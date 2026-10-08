/// Форматування текстового звіту.
library;

import 'constants.dart';
import 'dates.dart';
import 'model.dart';
import 'pipelines.dart';
import 'text_utils.dart';

/// Формує текстовий звіт за списком [items].
///
/// Звіт містить [topCount] найближчих занять відносно моменту [now],
/// відсортованих за датою проведення (напрям задає [ascending];
/// за замовчуванням — від найближчого). Колонки розділяються [separator].
/// Момент [now] не може бути значенням за замовчуванням, бо
/// `DateTime.now()` не є константою, тому параметр nullable.
String buildReport(
  List<Lesson> items, {
  int topCount = defaultTopCount,
  bool ascending = true,
  String separator = defaultColumnSeparator,
  DateTime? now,
}) {
  final moment = now ?? DateTime.now();
  final direction = ascending ? 1 : -1;
  final upcoming = List.of(items)
    ..sort(
      (a, b) =>
          nextOccurrence(a, moment).compareTo(nextOccurrence(b, moment)) *
          direction,
    );

  final buffer = StringBuffer()
    ..writeln('РОЗКЛАД ГРУПИ на ${formatDate(moment)}')
    ..writeln(
      'Усього занять: ${items.length}, '
      'аудиторних годин за семестр: ${contactHours(items)}',
    )
    ..writeln()
    ..writeln('Найближчі $topCount занять:');

  for (final l in upcoming.take(topCount)) {
    buffer.writeln(
      [
        formatDate(nextOccurrence(l, moment)),
        '${dayName(l.dayOfWeek)} ${formatTime(l.start)}–'
            '${formatTime(endTime(l))}',
        fitColumn(l.discipline, disciplineColumnWidth),
        l.type.padRight(typeLab.length),
        'ауд.${l.room}'.padRight(8),
        maskTeacher(l.teacher),
      ].join(separator),
    );
  }
  return buffer.toString();
}
