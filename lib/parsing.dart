/// Розбір вхідних рядків у записи занять.
library;

import 'constants.dart';
import 'dates.dart';
import 'model.dart';

/// Розбирає рядок [line] у заняття.
///
/// Повертає запис, у якому заповнене або поле `lesson`, або поле `error`
/// з описом причини відмови. Винятки не використовуються: пошкоджені дані
/// — очікувана ситуація, тому перевірка виконується через `tryParse`.
ParseResult parseLine(String line) {
  final fields = line.split(fieldSeparator).map((f) => f.trim()).toList();
  if (fields.length != fieldCount) {
    return _fail('очікувалось $fieldCount полів, отримано ${fields.length}');
  }
  if (fields.any((f) => f.isEmpty)) {
    return _fail('порожнє поле');
  }

  final [
    discipline,
    teacher,
    type,
    rawDay,
    rawStart,
    room,
    rawPairs,
    rawCreated,
  ] = fields;

  final dayOfWeek = int.tryParse(rawDay);
  if (dayOfWeek == null) return _fail('день тижня "$rawDay" не є числом');

  final start = parseTime(rawStart);
  if (start == null) return _fail('некоректний час початку "$rawStart"');

  final pairsCount = int.tryParse(rawPairs);
  if (pairsCount == null) {
    return _fail('кількість пар "$rawPairs" не є числом');
  }

  final createdAt = parseStrictDate(rawCreated);
  if (createdAt == null) {
    return _fail('некоректна дата внесення "$rawCreated"');
  }

  return (
    lesson: (
      discipline: discipline,
      teacher: teacher,
      type: type,
      dayOfWeek: dayOfWeek,
      start: start,
      room: room,
      pairsCount: pairsCount,
      createdAt: createdAt,
    ),
    error: null,
  );
}

/// Формує результат розбору з помилкою [message].
ParseResult _fail(String message) => (lesson: null, error: message);
