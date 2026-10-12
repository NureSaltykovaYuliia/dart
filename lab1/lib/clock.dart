/// Час доби, календарні дати та обчислення з ними.
///
/// Час пари зберігається як кількість хвилин від півночі: так його легко
/// порівнювати, додавати тривалість і переводити в позицію в тижні.
library;

import 'lesson.dart';
import 'patterns.dart';
import 'settings.dart';

// ── Розбір ─────────────────────────────────────────────────────────────────

/// Перетворює `ГГ:ХХ` на хвилини від півночі; `null` — якщо формат хибний.
int? readClock(String raw) {
  final match = clockPattern.firstMatch(raw);
  return switch ((
    int.tryParse(match?.namedGroup('h') ?? ''),
    int.tryParse(match?.namedGroup('m') ?? ''),
  )) {
    (final hours?, final minutes?) => hours * Duration.minutesPerHour + minutes,
    _ => null,
  };
}

/// Розбирає `РРРР-ММ-ДД` у дату опівночі UTC; `null` — якщо рядок
/// не відповідає формату або такого дня не існує.
///
/// Конструктор `DateTime.utc` «переносить» зайві дні в наступний місяць
/// (30 лютого стає 2 березня), тому дата вважається справжньою лише тоді,
/// коли місяць і день після побудови збігаються з введеними. UTC обрано,
/// щоб перехід на зимовий час не робив добу коротшою чи довшою.
DateTime? readIsoDate(String raw) {
  final match = isoDatePattern.firstMatch(raw);
  final parts = [
    for (final group in const ['y', 'mo', 'd'])
      int.tryParse(match?.namedGroup(group) ?? ''),
  ];
  if (parts case [final year?, final month?, final day?]) {
    final date = DateTime.utc(year, month, day);
    if (date.month == month && date.day == day) return date;
  }
  return null;
}

// ── Форматування ───────────────────────────────────────────────────────────

/// Записує хвилини від півночі [minutes] як `ГГ:ХХ`.
String hhmm(int minutes) {
  String two(int n) => '$n'.padLeft(2, '0');
  return '${two(minutes ~/ Duration.minutesPerHour)}:'
      '${two(minutes % Duration.minutesPerHour)}';
}

/// Календарна частина [moment] у вигляді `РРРР-ММ-ДД`.
String isoDay(DateTime moment) => moment.toIso8601String().substring(0, 10);

/// Коротка назва дня тижня [weekday]; `?` для неіснуючого номера.
String weekdayLabel(int weekday) => weekdayLabels[weekday] ?? '?';

// ── Арифметика ─────────────────────────────────────────────────────────────

/// Календарна дата [moment] без часу доби, в UTC.
DateTime midnightUtc(DateTime moment) =>
    DateTime.utc(moment.year, moment.month, moment.day);

/// Позиція початку заняття в тижні, у хвилинах від понеділка 00:00.
int weekMinute(Lesson lesson) =>
    (lesson.weekday - DateTime.monday) * Duration.minutesPerDay +
    lesson.startMinutes;

/// Хвилина закінчення пари (за модулем доби).
int finishMinutes(Lesson lesson) =>
    (lesson.startMinutes + pairLength.inMinutes) % Duration.minutesPerDay;

/// Скільки днів минуло від внесення запису до [now].
int daysSinceAdded(Lesson lesson, DateTime now) =>
    midnightUtc(now).difference(lesson.addedOn).inDays;

/// Момент найближчого проведення заняття, не раніше за [now].
///
/// Обидва моменти переводяться в хвилини від початку тижня; різниця
/// за модулем [minutesPerWeek] — скільки хвилин чекати. Якщо заняття
/// починається саме зараз, повертається поточний момент.
DateTime nextSession(Lesson lesson, DateTime now) {
  final nowMinute =
      (now.weekday - DateTime.monday) * Duration.minutesPerDay +
      now.hour * Duration.minutesPerHour +
      now.minute;
  final wait = (weekMinute(lesson) - nowMinute) % minutesPerWeek;
  final base = DateTime.utc(now.year, now.month, now.day, now.hour, now.minute);
  return base.add(Duration(minutes: wait));
}

/// Скільки календарних днів лишилося до найближчого заняття.
int daysToNextSession(Lesson lesson, DateTime now) =>
    midnightUtc(nextSession(lesson, now)).difference(midnightUtc(now)).inDays;

/// Чи відбудеться заняття в межах [soonHorizon] від початку дня [now].
bool isSoon(Lesson lesson, DateTime now) =>
    nextSession(lesson, now).difference(midnightUtc(now)) <= soonHorizon;
