import 'package:group_schedule/group_schedule.dart';

/// Точка входу: розбирає, перевіряє та агрегує вхідні заняття.
///
/// Необов'язковий аргумент — дата звіту у форматі `РРРР-ММ-ДД`
/// (за замовчуванням — поточний момент).
void main(List<String> arguments) {
  final argDate = arguments.firstOrNull;
  final now =
      (argDate == null ? null : parseStrictDate(argDate)) ?? DateTime.now();

  // 1. Розбір із лічильником-замиканням.
  final counter = makeCounter();
  final parsed = rawLessons.map((line) {
    counter.increment();
    return (line: line, result: parseLine(line));
  }).toList();

  _section('1. Розбір вхідних рядків');
  print('Оброблено рядків: ${counter.value()}');
  for (final (:line, :result) in parsed) {
    if (result case (lesson: null, :final String error)) {
      print('  ✗ $error\n      ← $line');
    }
  }

  // 2. Перевірка діапазонів і формату.
  final candidates = [
    for (final p in parsed)
      if (p.result.lesson case final Lesson lesson) lesson,
  ];
  _section('2. Перевірка діапазонів');
  for (final lesson in candidates) {
    final violations = validateLesson(lesson);
    if (violations.isNotEmpty) {
      print('  ${lesson.discipline}:');
      for (final v in violations) {
        print('      - $v');
      }
    }
  }
  final lessons = candidates.where(isValidLesson).toList();
  print('Коректних занять: ${lessons.length} з ${rawLessons.length}');

  // 3. Конвеєри: фільтрація, перетворення, згортання.
  _section('3. Конвеєри обробки');
  print('Лекції:');
  toScheduleLines(lecturesOnly(lessons)).forEach(_bullet);
  print('Заняття в понеділок:');
  toScheduleLines(lessonsOnDay(lessons, DateTime.monday)).forEach(_bullet);
  print(
    'Аудиторних годин (where → map → fold): ${contactHours(lessons)}, '
    'з них лабораторних: ${contactHours(lessons, type: typeLab)}',
  );
  final stats = pairsStats(lessons);
  if (stats != null) {
    print(
      'Пар за семестр: усього ${stats.total}, '
      'середнє ${stats.average.toStringAsFixed(averageFractionDigits)}, '
      'мін ${stats.min}, макс ${stats.max}',
    );
  }
  print('За типами: ${countByType(lessons)}');

  // 4. Групування за дисципліною та конфлікти аудиторій.
  _section('4. Групування за дисципліною');
  final groups = groupByDiscipline(lessons);
  final hours = hoursPerGroup(groups);
  for (final MapEntry(key: discipline, value: items) in groups.entries) {
    _bullet(describeGroup(discipline, items, hours[discipline] ?? 0));
  }
  print('Конфлікти аудиторій:');
  for (final MapEntry(key: slot, value: items) in roomConflicts(
    lessons,
  ).entries) {
    _bullet('$slot: ${items.map((l) => l.discipline).join(' / ')}');
  }

  // 5. Сортування за двома критеріями.
  _section('5. Сортування');
  print('За днем і часом ↑, далі за викладачем:');
  toScheduleLines(sortLessons(lessons)).forEach(_bullet);
  print('За кількістю пар ↓, далі за днем і часом:');
  toScheduleLines(
    sortLessons(
      lessons,
      by: compareByPairs,
      thenBy: compareByDayAndTime,
      ascending: false,
    ).take(5),
  ).forEach(_bullet);

  // 6. Фабрика предикатів (замикання).
  _section('6. Фабрика предикатів');
  print('Лабораторні, що починаються не раніше 11:00:');
  final lateLabs = allOf([makeTypeFilter(typeLab), makeStartsFromFilter(11)]);
  toScheduleLines(lessons.where(lateLabs)).forEach(_bullet);

  // 7. Регулярні вирази та маскування.
  _section('7. Регулярні вирази');
  for (final teacher in ['Петренко О.В.', 'олійник', 'Бондар С.П']) {
    _bullet(
      '$teacher → ${isValidTeacher(teacher) ? 'коректний' : 'некоректний'}, '
      'маска: ${maskTeacher(teacher)}',
    );
  }
  for (final room in ['287', '161и', '9999']) {
    _bullet(
      'ауд.$room → ${isValidRoom(room) ? 'коректна' : 'некоректна'}'
      '${roomWing(room).isEmpty ? '' : ', корпус «${roomWing(room)}»'}',
    );
  }

  // 8. Арифметика дат.
  _section('8. Арифметика дат');
  for (final l in sortLessons(lessons).take(4)) {
    _bullet(
      '${l.discipline} (${l.type}): запис внесено ${ageInDays(l, now)} дн. '
      'тому, наступне — ${formatDate(nextOccurrence(l, now))} '
      '(через ${daysUntilNext(l, now)} дн.), '
      '${formatTime(l.start)}–${formatTime(endTime(l))}'
      '${isUpcoming(l, now) ? ' — найближчим часом' : ''}',
    );
  }
  final missing = findByDiscipline(lessons, 'Астрономія');
  print('Пошук «Астрономія»: ${missing?.teacher ?? 'не знайдено'}');

  // 9. Звіт.
  _section('9. Звіт');
  print(buildReport(lessons, now: now));
}

/// Друкує заголовок розділу [title].
void _section(String title) => print('\n=== $title ===');

/// Друкує елемент списку [text].
void _bullet(String text) => print('  • $text');
