import 'package:group_schedule_oop/group_schedule_oop.dart';

/// Скільки рядків показувати в добірках виводу.
const int _preview = 4;

/// Точка входу: демонструє об'єктно-орієнтовану модель розкладу.
void main() {
  // 1. Розбір: tryParse, fromCsv (виняток), cached (кешування).
  _section('1. Розбір рядків у класи');
  final lessons = <Lesson>[];
  for (final row in timetableRows) {
    final lesson = Lesson.tryParse(row);
    if (lesson == null) {
      try {
        Lesson.fromCsv(row);
      } on LessonFormatException catch (e) {
        print('  ✗ ${e.message}');
      }
    } else {
      lessons.add(lesson);
    }
  }
  print('Розібрано: ${lessons.length} з ${timetableRows.length}');

  final first = Lesson.cached(timetableRows.first);
  final again = Lesson.cached(timetableRows.first);
  print('cached: однаковий об\'єкт? ${identical(first, again)}');

  // 2. Перевірка правил.
  _section('2. Правила перевірки');
  final valid = <Lesson>[];
  for (final lesson in lessons) {
    final problems = problemsOf(lesson);
    if (problems.isEmpty) {
      valid.add(lesson);
    } else {
      print('  ${lesson.subject}: ${problems.join('; ')}');
    }
  }
  print('Коректних занять: ${valid.length}');

  // 3. Сховище з обмеженням параметра типу.
  _section('3. Repository<T extends Identifiable>');
  final repo = Repository<Lesson>();
  valid.forEach(repo.add);
  print('У сховищі: ${repo.length}');
  print('findById: ${repo.findById('Бази даних/Вт/07:45')}');
  print('Лабораторні: ${repo.where((l) => l is LabWork).length}');

  // 4. Поліморфізм і switch без default.
  _section('4. Підтипи: поліморфізм та switch');
  for (final lesson in valid.take(_preview)) {
    print(
      '  ${lesson.runtimeType.toString().padRight(9)} '
      'місць: ${lesson.seatsNeeded(defaultGroupSize)}, '
      'коефіцієнт: ${loadFactor(lesson)}, '
      'навантаження: ${lecturerLoad(lesson)} год',
    );
  }

  // 5. Зіставлення зі зразком з охоронцем.
  _section('5. Опис через when');
  for (final lesson in valid.take(_preview + 2)) {
    print('  ${describe(lesson)}');
  }

  // 6. Домішка Schedulable на двох різних класах.
  _section('6. Домішка Schedulable (on TimeSlot)');
  const consultation = Consultation(
    lecturer: 'Петренко О.В.',
    weekday: Weekday.monday,
    startMinutes: 9 * 60 + 45,
    room: '287',
  );
  final lecture = valid.first;
  print('$lecture');
  print('$consultation');
  print('Перетин у часі: ${lecture.overlaps(consultation)}');
  print('Закінчення пари: ${hhmm(lecture.finishMinutes)}');
  final now = DateTime.utc(2026, 10, 19, 9);
  print('Найближче проведення: ${isoDay(lecture.nextOccurrence(now))}');

  // 7. Перелічення та метод розширення.
  _section('7. Weekday і розширення');
  print('Після неділі: ${Weekday.sunday.next.label}');
  print('Номер 3 → ${Weekday.fromNumber(3)?.label}');
  for (final MapEntry(:key, :value) in valid.byWeekday.entries.take(3)) {
    print('  ${key.label}: ${value.length} зан.');
  }
  print('Лекцій: ${valid.ofType<Lecture>().length}');
  print('Викладач: ${valid.first.lecturer.masked}');

  // 8. Записи й деструктуризація.
  _section('8. Записи');
  if (summarize(valid) case (:final lessons, :final hours, :final meanPairs)) {
    print('Занять: $lessons, годин: $hours, пар у середньому: $meanPairs');
  }
  if (extremes(valid) case (:final first, :final last)) {
    print('Перше: $first\nОстаннє: $last');
  }

  // 9. Рівність за значенням.
  _section('9. == та hashCode');
  final copy = Lesson.fromCsv(timetableRows.first);
  print(
    'Той самий вміст, інший об\'єкт: ${copy == first}, '
    'identical: ${identical(copy, first)}',
  );
  print('Розмір Set з двох однакових занять: ${{first, copy}.length}');
}

void _section(String title) => print('\n=== $title ===');
