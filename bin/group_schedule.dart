import 'package:group_schedule/group_schedule.dart';

/// Година, починаючи з якої лабораторна вважається пізньою.
const int _lateStartHour = 11;

/// Скільки рядків показувати у вибірках виводу.
const int _previewRows = 5;

/// Скільки занять показувати в розділі арифметики дат.
const int _datesPreviewRows = 4;

/// Точка входу: розбирає, перевіряє та агрегує вхідні заняття.
///
/// Необов'язковий аргумент — дата звіту у форматі `РРРР-ММ-ДД`
/// (за замовчуванням — поточний момент).
void main(List<String> arguments) {
  final argDate = arguments.firstOrNull;
  final now = (argDate == null ? null : readIsoDate(argDate)) ?? DateTime.now();

  // 1. Розбір: лічильник викликів — замикання над `readLesson`.
  final reader = countingCalls(readLesson);
  final decoded = [
    for (final row in timetableRows) (row: row, result: reader.run(row)),
  ];

  _section('1. Розбір вхідних рядків');
  print('Оброблено рядків: ${reader.calls()}');
  for (final (:row, :result) in decoded) {
    if (result case (null, final String error)) {
      print('  ✗ $error\n      ← $row');
    }
  }

  // 2. Перевірка правил.
  final candidates = [
    for (final d in decoded)
      if (d.result case (final Lesson lesson, _)) lesson,
  ];
  _section('2. Перевірка правил');
  for (final lesson in candidates) {
    final problems = problemsOf(lesson);
    if (problems.isNotEmpty) {
      print('  ${lesson.subject}:');
      for (final p in problems) {
        print('      - $p');
      }
    }
  }
  final lessons = candidates.where(passesRules).toList();
  print('Коректних занять: ${lessons.length} з ${timetableRows.length}');

  // 3. Запити: відбір, перетворення, агрегування.
  _section('3. Конвеєри обробки');
  print('Лекції:');
  scheduleLines(ofKind(lessons, kindLecture)).forEach(_bullet);
  print('Заняття в понеділок:');
  scheduleLines(onWeekday(lessons, DateTime.monday)).forEach(_bullet);
  print(
    'Аудиторних годин (where → map → fold): ${academicHours(lessons)}, '
    'з них лабораторних: ${academicHours(lessons, kind: kindLab)}',
  );
  final summary = summarizePairs(lessons);
  if (summary != null) {
    print(
      'Пар за семестр: усього ${summary.sum}, '
      'середнє ${summary.mean.toStringAsFixed(averageDigits)}, '
      'мін ${summary.fewest}, макс ${summary.most}',
    );
  }
  print('За типами: ${kindHistogram(lessons)}');

  // 4. Групування за дисципліною та конфлікти аудиторій.
  _section('4. Групування за дисципліною');
  final groups = bySubject(lessons);
  final hours = hoursOf(groups);
  for (final MapEntry(key: subject, value: items) in groups.entries) {
    _bullet(subjectLine(subject, items, hours[subject] ?? 0));
  }
  print('Конфлікти аудиторій:');
  for (final MapEntry(key: slot, value: items) in clashes(lessons).entries) {
    _bullet('$slot: ${items.map((l) => l.subject).join(' / ')}');
  }

  // 5. Сортування за двома критеріями.
  _section('5. Сортування');
  print('За днем і часом ↑, далі за викладачем:');
  scheduleLines(arranged(lessons)).forEach(_bullet);
  print('За кількістю пар ↓, далі за днем і часом:');
  scheduleLines(
    arranged(
      lessons,
      chain([descending(byPairs), byWeekTime]),
    ).take(_previewRows),
  ).forEach(_bullet);

  // 6. Фабрики умов (замикання).
  _section('6. Фабрика предикатів');
  print('Лабораторні, що починаються не раніше $_lateStartHour:00:');
  final lateLabs = allPass([kindIs(kindLab), startsNotBefore(_lateStartHour)]);
  scheduleLines(lessons.where(lateLabs)).forEach(_bullet);

  // 7. Регулярні вирази та маскування.
  _section('7. Регулярні вирази');
  for (final name in ['Петренко О.В.', 'олійник', 'Бондар С.П']) {
    _bullet(
      '$name → ${isLecturerName(name) ? 'коректний' : 'некоректний'}, '
      'маска: ${hideSurname(name)}',
    );
  }
  for (final room in ['287', '161и', '9999']) {
    final wing = wingOf(room);
    _bullet(
      'ауд.$room → ${isRoomCode(room) ? 'коректна' : 'некоректна'}'
      '${wing.isEmpty ? '' : ', корпус «$wing»'}',
    );
  }

  // 8. Арифметика дат.
  _section('8. Арифметика дат');
  for (final l in arranged(lessons).take(_datesPreviewRows)) {
    _bullet(
      '${l.subject} (${l.kind}): запис внесено ${daysSinceAdded(l, now)} дн. '
      'тому, наступне — ${isoDay(nextSession(l, now))} '
      '(через ${daysToNextSession(l, now)} дн.), '
      '${hhmm(l.startMinutes)}–${hhmm(finishMinutes(l))}'
      '${isSoon(l, now) ? ' — найближчим часом' : ''}',
    );
  }
  final missing = findSubject(lessons, 'Астрономія');
  print('Пошук «Астрономія»: ${missing?.lecturer ?? 'не знайдено'}');

  // 9. Звіт.
  _section('9. Звіт');
  print(renderTimetable(lessons, at: now));
}

/// Друкує заголовок розділу [title].
void _section(String title) => print('\n=== $title ===');

/// Друкує елемент списку [text].
void _bullet(String text) => print('  • $text');
