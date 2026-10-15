/// Правила коректності заняття.
///
/// Кожне правило — запис «умова + опис порушення». Новий критерій
/// додається одним елементом списку без зміни функцій перевірки.
library;

import 'clock.dart';
import 'lesson.dart';
import 'patterns.dart';
import 'settings.dart';

/// Правило перевірки: умова коректності та опис порушення.
typedef LessonRule = ({
  bool Function(Lesson lesson) holds,
  String Function(Lesson lesson) explain,
});

/// Набір правил, яким має відповідати кожне заняття.
final List<LessonRule> lessonRules = [
  (
    holds: (l) => isLecturerName(l.lecturer),
    explain: (l) =>
        'викладач "${l.lecturer}" не відповідає формату "Прізвище І.Б."',
  ),
  (
    holds: (l) => l.weekday.isStudyDay,
    explain: (l) => '${l.weekday.label} — вихідний день',
  ),
  (
    holds: (l) => pairGrid.contains(hhmm(l.startMinutes)),
    explain: (l) => 'час ${l.time} не збігається з сіткою пар',
  ),
  (
    holds: (l) => isRoomCode(l.room),
    explain: (l) => 'некоректний номер аудиторії "${l.room}"',
  ),
  (
    holds: (l) => l.pairs >= pairBounds.min && l.pairs <= pairBounds.max,
    explain: (l) =>
        'кількість пар ${l.pairs} поза межами '
        '${pairBounds.min}..${pairBounds.max}',
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
