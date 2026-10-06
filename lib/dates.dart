/// Розбір дат і часу та арифметика дат.
library;

import 'constants.dart';
import 'model.dart';
import 'text_utils.dart';

/// Строго розбирає дату у форматі `РРРР-ММ-ДД`.
///
/// `DateTime.tryParse` нормалізує неіснуючі дати (`2026-02-30` перетворюється
/// на 2 березня), тому після розбору компоненти звіряються з іменованими
/// групами регулярного виразу. Дата повертається в UTC, щоб перехід на
/// літній/зимовий час не спотворював різницю в днях. Повертає `null`,
/// якщо дата некоректна.
DateTime? parseStrictDate(String raw) {
  final match = isoDatePattern.firstMatch(raw);
  final parsed = DateTime.tryParse(raw);
  if (match == null || parsed == null) return null;

  final month = int.tryParse(match.namedGroup('month') ?? '');
  final day = int.tryParse(match.namedGroup('day') ?? '');
  final isSameDate = parsed.month == month && parsed.day == day;
  return isSameDate ? dateOnly(parsed) : null;
}

/// Розбирає час у форматі `ГГ:ХХ`; повертає `null`, якщо формат
/// або значення некоректні.
TimeOfDay? parseTime(String raw) {
  final match = timePattern.firstMatch(raw);
  if (match == null) return null;

  final hour = int.tryParse(match.namedGroup('hour') ?? '');
  final minute = int.tryParse(match.namedGroup('minute') ?? '');
  if (hour == null || minute == null) return null;
  if (hour > maxHour || minute > maxMinute) return null;
  return (hour: hour, minute: minute);
}

/// Відкидає час доби, залишаючи лише календарну дату [moment] в UTC.
DateTime dateOnly(DateTime moment) =>
    DateTime.utc(moment.year, moment.month, moment.day);

/// Обчислює вік запису в днях від дати внесення до [now].
int ageInDays(Lesson lesson, DateTime now) =>
    dateOnly(now).difference(lesson.createdAt).inDays;

/// Повертає дату й час найближчого проведення заняття, починаючи з [now].
///
/// Якщо заняття сьогодні й ще не почалося — повертається сьогоднішня дата.
DateTime nextOccurrence(Lesson lesson, DateTime now) {
  final today = dateOnly(now);
  final daysAhead = (lesson.dayOfWeek - today.weekday) % DateTime.daysPerWeek;
  final candidate = today.add(
    Duration(
      days: daysAhead,
      hours: lesson.start.hour,
      minutes: lesson.start.minute,
    ),
  );
  final nowUtc = DateTime.utc(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
  );
  return candidate.isBefore(nowUtc)
      ? candidate.add(const Duration(days: DateTime.daysPerWeek))
      : candidate;
}

/// Обчислює кількість днів до найближчого проведення заняття.
int daysUntilNext(Lesson lesson, DateTime now) =>
    dateOnly(nextOccurrence(lesson, now)).difference(dateOnly(now)).inDays;

/// Обчислює час закінчення пари, додаючи [pairDuration] до часу початку.
TimeOfDay endTime(Lesson lesson) {
  final start = DateTime.utc(
    2000,
    1,
    1,
    lesson.start.hour,
    lesson.start.minute,
  );
  final end = start.add(pairDuration);
  return (hour: end.hour, minute: end.minute);
}

/// Перевіряє, чи відбудеться заняття протягом [upcomingWindow] від [now].
bool isUpcoming(Lesson lesson, DateTime now) {
  final left = nextOccurrence(lesson, now).difference(dateOnly(now));
  return left <= upcomingWindow;
}

/// Форматує дату [date] як `РРРР-ММ-ДД`.
String formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
