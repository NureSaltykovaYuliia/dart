/// Запити до колекції занять: відбір, перетворення, агрегування
/// та групування.
library;

import 'dart:math' as math;

import 'clock.dart';
import 'lesson.dart';
import 'settings.dart';

// ── Відбір ─────────────────────────────────────────────────────────────────

/// Заняття типу [kind].
Iterable<Lesson> ofKind(Iterable<Lesson> lessons, String kind) =>
    lessons.where((l) => l.kind == kind);

/// Заняття, що проводяться в день [weekday].
Iterable<Lesson> onWeekday(Iterable<Lesson> lessons, int weekday) =>
    lessons.where((l) => l.weekday == weekday);

/// Перше заняття з дисципліни [subject] або `null`, якщо її немає.
Lesson? findSubject(Iterable<Lesson> lessons, String subject) =>
    lessons.where((l) => l.subject == subject).firstOrNull;

// ── Перетворення ───────────────────────────────────────────────────────────

/// Рядок розкладу: `Пн 09:30 ауд.287 Дисципліна (тип)`.
String scheduleLine(Lesson l) =>
    '${weekdayLabel(l.weekday)} ${hhmm(l.startMinutes)} '
    'ауд.${l.room} ${l.subject} (${l.kind})';

/// Рядки розкладу для кожного заняття з [lessons].
List<String> scheduleLines(Iterable<Lesson> lessons) =>
    lessons.map(scheduleLine).toList();

// ── Агрегування ────────────────────────────────────────────────────────────

/// Академічні години за семестр (where → map → fold); якщо задано [kind],
/// враховуються лише заняття цього типу.
int academicHours(Iterable<Lesson> lessons, {String? kind}) => lessons
    .where((l) => kind == null || l.kind == kind)
    .map((l) => l.pairs * hoursPerPair)
    .fold(0, (acc, hours) => acc + hours);

/// Кількість, сума, мінімум, максимум і середнє пар за семестр,
/// обчислені за один прохід згортанням у запис-акумулятор.
///
/// Для порожньої колекції повертає `null`: екстремуми й середнє
/// для неї не визначені.
PairsSummary? summarizePairs(Iterable<Lesson> lessons) {
  if (lessons.isEmpty) return null;
  final seed = lessons.first.pairs;
  final (:n, :sum, :lo, :hi) = lessons.skip(1).fold(
    (n: 1, sum: seed, lo: seed, hi: seed),
    (acc, l) => (
      n: acc.n + 1,
      sum: acc.sum + l.pairs,
      lo: math.min(acc.lo, l.pairs),
      hi: math.max(acc.hi, l.pairs),
    ),
  );
  return (lessons: n, sum: sum, fewest: lo, most: hi, mean: sum / n);
}

// ── Групування ─────────────────────────────────────────────────────────────

/// Розкладає заняття по кошиках за ключем [keyOf] згортанням,
/// зберігаючи порядок першої появи ключа.
Map<K, List<Lesson>> bucket<K>(
  Iterable<Lesson> lessons,
  K Function(Lesson lesson) keyOf,
) => lessons.fold(
  <K, List<Lesson>>{},
  (buckets, lesson) =>
      buckets..putIfAbsent(keyOf(lesson), () => []).add(lesson),
);

/// Заняття, згруповані за дисципліною.
Map<String, List<Lesson>> bySubject(Iterable<Lesson> lessons) =>
    bucket(lessons, (l) => l.subject);

/// Кількість занять кожного типу.
Map<String, int> kindHistogram(Iterable<Lesson> lessons) => {
  for (final MapEntry(:key, :value) in bucket(lessons, (l) => l.kind).entries)
    key: value.length,
};

/// Академічні години для кожної групи з [groups].
Map<String, int> hoursOf(Map<String, List<Lesson>> groups) => {
  for (final MapEntry(:key, :value) in groups.entries)
    key: academicHours(value),
};

/// Слот розкладу «день, час, аудиторія», у якому проходить заняття.
String slotOf(Lesson l) =>
    '${weekdayLabel(l.weekday)} ${hhmm(l.startMinutes)} ауд.${l.room}';

/// Слоти, у яких одночасно стоїть більше одного заняття.
Map<String, List<Lesson>> clashes(Iterable<Lesson> lessons) => Map.fromEntries(
  bucket(lessons, slotOf).entries.where((e) => e.value.length > 1),
);

/// Підсумковий рядок групи: назва, кількість занять і годин.
String subjectLine(String subject, List<Lesson> items, int hours) =>
    '$subject: ${items.length} зан., $hours год';
