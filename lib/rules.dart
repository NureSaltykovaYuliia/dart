/// Правила коректності заняття.
///
/// Кожне правило — запис «умова + опис порушення». Новий критерій
/// додається одним елементом списку без зміни функцій перевірки.
library;

import 'clock.dart';
import 'lesson.dart';
import 'patterns.dart';
import 'settings.dart';

/// Набір правил, яким має відповідати кожне заняття.
final List<LessonRule> lessonRules = [
  (
    holds: (l) => isLecturerName(l.lecturer),
    explain: (l) =>
        'викладач "${l.lecturer}" не відповідає формату "Прізвище І.Б."',
  ),
  (
    holds: (l) => knownKinds.contains(l.kind),
    explain: (l) => 'невідомий тип заняття "${l.kind}"',
  ),
  (
    holds: (l) => l.weekday >= bounds.firstDay && l.weekday <= bounds.lastDay,
    explain: (l) =>
        'день тижня ${l.weekday} поза межами '
        '${bounds.firstDay}..${bounds.lastDay}',
  ),
  (
    holds: (l) => pairGrid.contains(hhmm(l.startMinutes)),
    explain: (l) => 'час ${hhmm(l.startMinutes)} не збігається з сіткою пар',
  ),
  (
    holds: (l) => isRoomCode(l.room),
    explain: (l) => 'некоректний номер аудиторії "${l.room}"',
  ),
  (
    holds: (l) => l.pairs >= bounds.minPairs && l.pairs <= bounds.maxPairs,
    explain: (l) =>
        'кількість пар ${l.pairs} поза межами '
        '${bounds.minPairs}..${bounds.maxPairs}',
  ),
];

/// Описи всіх правил, які порушує [lesson]; порожній список — порушень немає.
List<String> problemsOf(Lesson lesson) => [
  for (final rule in lessonRules)
    if (!rule.holds(lesson)) rule.explain(lesson),
];

/// Чи виконує [lesson] усі правила.
bool passesRules(Lesson lesson) =>
    lessonRules.every((rule) => rule.holds(lesson));
