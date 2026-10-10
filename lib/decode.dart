/// Перетворення сирого рядка розкладу на заняття.
library;

import 'clock.dart';
import 'lesson.dart';
import 'settings.dart';

/// Розбирає рядок [row] розкладу.
///
/// Пошкоджений рядок — звичайна ситуація для вхідних даних, тому замість
/// винятків функція повертає пару `(заняття, причина)`. Усі числові поля
/// декодуються одразу, а `switch` по кортежу результатів обирає першу
/// причину відмови або збирає заняття, якщо жодне поле не дорівнює `null`.
Decoded readLesson(String row) {
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
    (final weekday?, final start?, final count?, final addedOn?) => (
      (
        subject: subject,
        lecturer: lecturer,
        kind: kind,
        weekday: weekday,
        startMinutes: start,
        room: room,
        pairs: count,
        addedOn: addedOn,
      ),
      null,
    ),
  };
}
