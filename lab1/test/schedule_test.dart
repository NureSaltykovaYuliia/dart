import 'package:group_schedule/group_schedule.dart';
import 'package:test/test.dart';

/// Коректні заняття з вхідного набору.
final List<Lesson> _valid = [
  for (final row in timetableRows)
    if (readLesson(row) case (final lesson?, _) when passesRules(lesson))
      lesson,
];

void main() {
  group('readLesson', () {
    test('збирає заняття з коректного рядка', () {
      final (lesson, error) = readLesson(timetableRows.first);
      expect(error, isNull);
      expect(lesson?.lecturer, 'Петренко О.В.');
      expect(lesson?.startMinutes, 9 * 60 + 30);
    });

    test('повідомляє про нестачу полів', () {
      final (lesson, error) = readLesson(
        'А;Б В.Г.;лекція;1;09:30;287;2026-09-01',
      );
      expect(lesson, isNull);
      expect(error, contains('полів'));
    });

    test('не приймає 30 лютого', () {
      expect(
        readLesson('А;Б В.Г.;лекція;1;09:30;287;8;2026-02-30').$2,
        contains('дата'),
      );
    });

    test('у вхідних даних 4 нерозбірні рядки', () {
      final failed = timetableRows.map(readLesson).where((d) => d.$1 == null);
      expect(failed.length, 4);
    });
  });

  group('rules', () {
    test('рядок «Економіка» порушує п’ять правил', () {
      final economics = timetableRows.firstWhere(
        (r) => r.startsWith('Економіка'),
      );
      final lesson = readLesson(economics).$1;
      expect(lesson, isNotNull);
      if (lesson != null) expect(problemsOf(lesson).length, 5);
    });

    test('коректних занять дванадцять', () {
      expect(_valid.length, 12);
    });
  });

  group('запити, порядок і дати', () {
    test('сім дисциплін', () {
      expect(bySubject(_valid).length, 7);
    });

    test('єдиний конфлікт аудиторії — понеділок 09:30, ауд.287', () {
      expect(clashes(_valid).keys.toList(), ['Пн 09:30 ауд.287']);
    });

    test('другий критерій сортування розв’язує нічию', () {
      final monday930 = arranged(_valid).take(2).map((l) => l.lecturer);
      expect(monday930, ['Петренко О.В.', 'Ткаченко В.Г.']);
    });

    test('заняття сьогодні пізніше — наступне через 0 днів', () {
      final mondayMorning = DateTime.utc(2026, 10, 19, 8);
      expect(daysToNextSession(_valid.first, mondayMorning), 0);
    });

    test('заняття сьогодні вже минуло — наступне через тиждень', () {
      final mondayNoon = DateTime.utc(2026, 10, 19, 12);
      expect(daysToNextSession(_valid.first, mondayNoon), 7);
    });

    test('пара триває 95 хвилин', () {
      expect(hhmm(finishMinutes(_valid.first)), '11:05');
    });

    test('прізвище маскується, ініціали лишаються', () {
      expect(hideSurname('Петренко О.В.'), 'П******* О.В.');
    });
  });
}
