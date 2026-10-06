/// Перевірка діапазонів і формату полів заняття.
library;

import 'constants.dart';
import 'model.dart';
import 'text_utils.dart';

/// Перевіряє заняття [lesson] і повертає перелік виявлених порушень.
///
/// Порожній список означає, що заняття коректне.
List<String> validateLesson(Lesson lesson) => [
  if (!isValidTeacher(lesson.teacher))
    'викладач "${lesson.teacher}" не відповідає формату "Прізвище І.Б."',
  if (!allowedTypes.contains(lesson.type))
    'невідомий тип заняття "${lesson.type}"',
  if (lesson.dayOfWeek < firstStudyDay || lesson.dayOfWeek > lastStudyDay)
    'день тижня ${lesson.dayOfWeek} поза межами '
        '$firstStudyDay..$lastStudyDay',
  if (!pairStartTimes.contains(formatTime(lesson.start)))
    'час ${formatTime(lesson.start)} не збігається з сіткою пар',
  if (!isValidRoom(lesson.room)) 'некоректний номер аудиторії "${lesson.room}"',
  if (lesson.pairsCount < minPairs || lesson.pairsCount > maxPairs)
    'кількість пар ${lesson.pairsCount} поза межами $minPairs..$maxPairs',
];

/// Перевіряє, чи заняття [lesson] не має жодного порушення.
bool isValidLesson(Lesson lesson) => validateLesson(lesson).isEmpty;
