/// Час доби та календарні дати: розбір, форматування, межі доби.
library;

import 'patterns.dart';

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
/// `DateTime.utc` «переносить» зайві дні (30 лютого → 2 березня), тому
/// дата вважається справжньою, лише коли місяць і день не змінилися.
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

/// Розкладає хвилини від півночі на години й хвилини.
({int hours, int minutes}) splitMinutes(int total) => (
  hours: total ~/ Duration.minutesPerHour,
  minutes: total % Duration.minutesPerHour,
);

/// Записує хвилини від півночі [minutes] як `ГГ:ХХ`.
String hhmm(int minutes) {
  final (:hours, minutes: rest) = splitMinutes(minutes);
  String two(int n) => '$n'.padLeft(2, '0');
  return '${two(hours)}:${two(rest)}';
}

/// Календарна частина [moment] у вигляді `РРРР-ММ-ДД`.
String isoDay(DateTime moment) => moment.toIso8601String().substring(0, 10);

/// Календарна дата [moment] без часу доби, в UTC.
DateTime midnightUtc(DateTime moment) =>
    DateTime.utc(moment.year, moment.month, moment.day);
