import 'package:group_schedule/group_schedule.dart';
import 'package:test/test.dart';

void main() {
  group('parseLine', () {
    test('розбирає коректний рядок', () {
      final result = parseLine(rawLessons.first);
      expect(result.error, isNull);
      expect(result.lesson?.teacher, 'Петренко О.В.');
      expect(result.lesson?.start, (hour: 9, minute: 30));
    });

    test('відхиляє рядок із відсутнім полем', () {
      expect(
        parseLine('А;Б В.Г.;лекція;1;09:30;287;2026-09-01').error,
        isNotNull,
      );
    });

    test('відхиляє неіснуючу дату', () {
      expect(
        parseLine('А;Б В.Г.;лекція;1;09:30;287;8;2026-02-30').error,
        contains('дата'),
      );
    });

    test('рівно 4 пошкоджені рядки у вхідних даних', () {
      expect(
        rawLessons.map(parseLine).where((r) => r.lesson == null),
        hasLength(4),
      );
    });
  });

  group('validateLesson', () {
    test('знаходить усі порушення', () {
      final lesson = parseLine(rawLessons[rawLessons.length - 2]).lesson;
      expect(lesson, isNotNull);
      if (lesson != null) expect(validateLesson(lesson), hasLength(5));
    });
  });

  group('конвеєри та дати', () {
    final lessons = rawLessons
        .map(parseLine)
        .map((r) => r.lesson)
        .nonNulls
        .where(isValidLesson)
        .toList();

    test('групування за дисципліною', () {
      expect(groupByDiscipline(lessons), hasLength(7));
    });

    test('виявлення конфлікту аудиторій', () {
      expect(roomConflicts(lessons).keys, ['Пн 09:30 ауд.287']);
    });

    test('найближче заняття в той самий день тижня', () {
      final lesson = lessons.first; // понеділок, 09:30
      final monday = DateTime.utc(2026, 10, 19, 8);
      expect(daysUntilNext(lesson, monday), 0);
    });

    test('маскування викладача', () {
      expect(maskTeacher('Петренко О.В.'), 'П******* О.В.');
    });
  });
}
