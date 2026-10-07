/// Конвеєри обробки колекцій занять: фільтрація, перетворення,
/// згортання, групування та сортування.
library;

import 'constants.dart';
import 'model.dart';
import 'text_utils.dart';

// ---------------------------------------------------------------------------
// Фільтрація
// ---------------------------------------------------------------------------

/// Відбирає лекції.
Iterable<Lesson> lecturesOnly(Iterable<Lesson> lessons) =>
    lessons.where((l) => l.type == typeLecture);

/// Відбирає заняття, що проводяться в день [dayOfWeek].
Iterable<Lesson> lessonsOnDay(Iterable<Lesson> lessons, int dayOfWeek) =>
    lessons.where((l) => l.dayOfWeek == dayOfWeek);

/// Шукає перше заняття з дисципліни [discipline]; повертає `null`,
/// якщо такого немає.
Lesson? findByDiscipline(Iterable<Lesson> lessons, String discipline) =>
    lessons.where((l) => l.discipline == discipline).firstOrNull;

// ---------------------------------------------------------------------------
// Перетворення
// ---------------------------------------------------------------------------

/// Перетворює заняття на короткі рядки виду `Пн 09:30 ауд.287 Дисципліна`.
List<String> toScheduleLines(Iterable<Lesson> lessons) => lessons
    .map(
      (l) =>
          '${dayName(l.dayOfWeek)} ${formatTime(l.start)} '
          'ауд.${l.room} ${l.discipline} (${l.type})',
    )
    .toList();

// ---------------------------------------------------------------------------
// Згортання
// ---------------------------------------------------------------------------

/// Обчислює кількість академічних годин аудиторних занять
/// конвеєром `where → map → fold`.
int contactHours(Iterable<Lesson> lessons, {String? type}) => lessons
    .where((l) => type == null || l.type == type)
    .map((l) => l.pairsCount * academicHoursPerPair)
    .fold(0, (sum, hours) => sum + hours);

/// Обчислює кількість, суму, середнє, мінімум і максимум пар за семестр.
///
/// Повертає `null` для порожнього набору: середнє й екстремуми в цьому
/// випадку не визначені.
PairsStats? pairsStats(Iterable<Lesson> lessons) {
  if (lessons.isEmpty) return null;
  final pairs = lessons.map((l) => l.pairsCount);
  final total = pairs.fold(0, (sum, p) => sum + p);
  final min = pairs.fold(maxPairs, (m, p) => p < m ? p : m);
  final max = pairs.fold(0, (m, p) => p > m ? p : m);
  final count = pairs.length;
  return (
    count: count,
    total: total,
    average: total / count,
    min: min,
    max: max,
  );
}

/// Підраховує кількість занять кожного типу.
Map<String, int> countByType(Iterable<Lesson> lessons) => lessons.fold(
  <String, int>{},
  (counts, l) => counts..update(l.type, (n) => n + 1, ifAbsent: () => 1),
);

// ---------------------------------------------------------------------------
// Групування
// ---------------------------------------------------------------------------

/// Групує заняття за дисципліною.
Map<String, List<Lesson>> groupByDiscipline(Iterable<Lesson> lessons) =>
    lessons.fold(
      <String, List<Lesson>>{},
      (groups, l) => groups..putIfAbsent(l.discipline, () => []).add(l),
    );

/// Обчислює кількість академічних годин для кожної групи [groups].
Map<String, int> hoursPerGroup(Map<String, List<Lesson>> groups) =>
    groups.map((key, lessons) => MapEntry(key, contactHours(lessons)));

/// Знаходить конфлікти аудиторій: кілька занять в одній аудиторії
/// в той самий день і час.
Map<String, List<Lesson>> roomConflicts(Iterable<Lesson> lessons) {
  final bySlot = lessons.fold(
    <String, List<Lesson>>{},
    (groups, l) => groups
      ..putIfAbsent(
        '${dayName(l.dayOfWeek)} ${formatTime(l.start)} ауд.${l.room}',
        () => [],
      ).add(l),
  );
  return {
    for (final MapEntry(:key, :value) in bySlot.entries)
      if (value.length > 1) key: value,
  };
}

// ---------------------------------------------------------------------------
// Сортування
// ---------------------------------------------------------------------------

/// Порівнює заняття за днем тижня, а в межах дня — за часом початку.
int compareByDayAndTime(Lesson a, Lesson b) {
  final byDay = a.dayOfWeek.compareTo(b.dayOfWeek);
  if (byDay != 0) return byDay;
  final byHour = a.start.hour.compareTo(b.start.hour);
  return byHour != 0 ? byHour : a.start.minute.compareTo(b.start.minute);
}

/// Порівнює заняття за прізвищем викладача.
int compareByTeacher(Lesson a, Lesson b) => a.teacher.compareTo(b.teacher);

/// Порівнює заняття за кількістю пар за семестр.
int compareByPairs(Lesson a, Lesson b) => a.pairsCount.compareTo(b.pairsCount);

/// Повертає нову відсортовану копію [lessons].
///
/// Основний критерій — [by], додатковий (за рівності основного) —
/// [thenBy]. Напрям основного критерію задає [ascending]; додатковий
/// критерій завжди за зростанням.
List<Lesson> sortLessons(
  Iterable<Lesson> lessons, {
  LessonComparator by = compareByDayAndTime,
  LessonComparator thenBy = compareByTeacher,
  bool ascending = true,
}) {
  final direction = ascending ? 1 : -1;
  return List.of(lessons)..sort((a, b) {
    final primary = by(a, b) * direction;
    return primary != 0 ? primary : thenBy(a, b);
  });
}

/// Форматує рядок групи для виводу: назва, кількість занять і годин.
String describeGroup(String discipline, List<Lesson> lessons, int hours) =>
    '$discipline: ${lessons.length} зан., $hours год';
