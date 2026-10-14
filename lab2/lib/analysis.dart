/// Обчислення над заняттями: записи, зіставлення зі зразком, switch.
library;

import 'extensions.dart';
import 'lesson.dart';
import 'time_slot.dart';

/// Підсумок за набором занять.
typedef LoadSummary = ({int lessons, int hours, double meanPairs});

/// Підсумок за [lessons]; `null` для порожнього набору.
LoadSummary? summarize(Iterable<Lesson> lessons) {
  if (lessons.isEmpty) return null;
  final count = lessons.length;
  final totalPairs = lessons.fold(0, (sum, l) => sum + l.pairs);
  return (
    lessons: count,
    hours: lessons.academicHours,
    meanPairs: totalPairs / count,
  );
}

/// Найраніше та найпізніше заняття тижня; для порожнього набору — `null`.
({Lesson first, Lesson last})? extremes(Iterable<Lesson> lessons) {
  if (lessons.isEmpty) return null;
  final sorted = lessons.toList()
    ..sort((a, b) => a.weekMinute.compareTo(b.weekMinute));
  return (first: sorted.first, last: sorted.last);
}

/// Коефіцієнт навантаження викладача залежно від підтипу заняття.
///
/// `switch` без гілки `default`: додавання нового підтипу [Lesson]
/// спричинить помилку компіляції саме тут.
double loadFactor(Lesson lesson) => switch (lesson) {
  Lecture() => 1.0,
  Practice() => 0.75,
  LabWork() => 0.5,
};

/// Навантаження викладача за семестр у годинах з урахуванням коефіцієнта.
double lecturerLoad(Lesson lesson) => lesson.academicHours * loadFactor(lesson);

/// Кількість пар, починаючи з якої курс вважається повним.
const int fullCoursePairs = 16;

/// Короткий опис заняття; охоронці `when` уточнюють зіставлення.
String describe(Lesson lesson) => switch (lesson) {
  Lecture(:final pairs) when pairs >= fullCoursePairs =>
    'повний курс лекцій ($pairs пар)',
  Lecture(:final pairs) => 'скорочений курс лекцій ($pairs пар)',
  Practice(:final lecturer) when lecturer.isLecturerName =>
    'практика, веде ${lecturer.masked}',
  Practice() => 'практика',
  LabWork(:final room) when room.endsWith('и') =>
    'лабораторія корпусу «и», ауд.$room',
  LabWork(:final room) => 'лабораторна, ауд.$room',
};

/// Чи перетинаються два заняття або консультація й заняття за часом.
bool collide(Schedulable a, TimeSlot b) => a.overlaps(b);
