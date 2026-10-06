/// Робота з рядками та регулярними виразами.
library;

import 'constants.dart';
import 'model.dart';

/// Шаблон часу у форматі `ГГ:ХХ`.
final RegExp timePattern = RegExp(r'^(?<hour>\d{2}):(?<minute>\d{2})$');

/// Шаблон дати у форматі `РРРР-ММ-ДД`.
final RegExp isoDatePattern = RegExp(
  r'^(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})$',
);

/// Шаблон викладача: прізвище з великої літери та ініціали,
/// наприклад `Петренко О.В.`.
final RegExp teacherPattern = RegExp(
  r"^(?<surname>[А-ЯІЇЄҐ][а-яіїєґ’'-]+) (?<initials>[А-ЯІЇЄҐ]\.[А-ЯІЇЄҐ]\.)$",
);

/// Шаблон аудиторії: номер з 2–3 цифр і необов'язкова літера корпусу,
/// наприклад `287` або `161и`.
final RegExp roomPattern = RegExp(r'^(?<number>\d{2,3})(?<wing>[а-яії]?)$');

/// Шаблон першого слова рядка: перша літера та решта слова.
final RegExp _firstWord = RegExp(r'^(?<first>\S)(?<rest>\S*)');

/// Перевіряє, чи відповідає [teacher] формату `Прізвище І.Б.`.
bool isValidTeacher(String teacher) => teacherPattern.hasMatch(teacher);

/// Перевіряє, чи відповідає [room] формату номера аудиторії.
bool isValidRoom(String room) => roomPattern.hasMatch(room);

/// Повертає літеру корпусу з номера аудиторії [room] або порожній рядок.
String roomWing(String room) =>
    roomPattern.firstMatch(room)?.namedGroup('wing') ?? '';

/// Маскує прізвище викладача, крім першої літери:
/// `Петренко О.В.` → `П******* О.В.`.
String maskTeacher(String teacher) => teacher.replaceAllMapped(_firstWord, (m) {
  // `RegExp` завжди передає `RegExpMatch`; перевірка просуває тип
  // і відкриває доступ до іменованих груп без приведення `as`.
  if (m is! RegExpMatch) return m[0] ?? '';
  final first = m.namedGroup('first') ?? '';
  final rest = m.namedGroup('rest') ?? '';
  return '$first${maskChar * rest.length}';
});

/// Форматує час [time] як `ГГ:ХХ`.
String formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// Повертає скорочену назву дня тижня за номером [dayOfWeek] (1–7).
String dayName(int dayOfWeek) => dayOfWeek >= 1 && dayOfWeek <= dayNames.length
    ? dayNames[dayOfWeek - 1]
    : '?';

/// Обрізає [text] до [width] символів із трикрапкою та доповнює пробілами.
String fitColumn(String text, int width) {
  final fitted = text.length <= width
      ? text
      : '${text.substring(0, width - 1)}…';
  return fitted.padRight(width);
}
