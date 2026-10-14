import 'package:group_schedule_oop/group_schedule_oop.dart';
import 'package:test/test.dart';

/// Заняття, які розбираються з вхідних рядків.
final List<Lesson> _parsed = [
  for (final row in timetableRows) ?Lesson.tryParse(row),
];

void main() {
  group('Lesson.fromCsv / tryParse', () {
    test('створює підтип за назвою типу', () {
      expect(Lesson.fromCsv(timetableRows[0]), isA<Lecture>());
      expect(Lesson.fromCsv(timetableRows[1]), isA<LabWork>());
      expect(Lesson.fromCsv(timetableRows[5]), isA<Practice>());
    });

    test('кидає LessonFormatException для пошкодженого рядка', () {
      expect(
        () => Lesson.fromCsv(timetableRows[12]),
        throwsA(isA<LessonFormatException>()),
      );
    });

    test('tryParse повертає null замість винятку', () {
      expect(Lesson.tryParse('сміття'), isNull);
    });

    test('розбирається 13 рядків з 18', () {
      expect(_parsed, hasLength(13));
    });

    test('cached повертає той самий об\'єкт', () {
      final a = Lesson.cached(timetableRows.first);
      final b = Lesson.cached(timetableRows.first);
      expect(identical(a, b), isTrue);
    });
  });

  group('рівність', () {
    test('однакові за вмістом заняття рівні й дають один елемент Set', () {
      final a = Lesson.fromCsv(timetableRows.first);
      final b = Lesson.fromCsv(timetableRows.first);
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect({a, b}, hasLength(1));
    });

    test('різні підтипи з однаковими полями не рівні', () {
      final lecture = Lesson.fromCsv(
        'А;Іваненко І.І.;лекція;1;09:30;287;16;2026-09-01',
      );
      final practice = Lesson.fromCsv(
        'А;Іваненко І.І.;практика;1;09:30;287;16;2026-09-01',
      );
      expect(lecture, isNot(practice));
    });
  });

  group('підтипи', () {
    test('лабораторна ділить групу навпіл, лекція — ні', () {
      final lecture = _parsed.whereType<Lecture>().first;
      final lab = _parsed.whereType<LabWork>().first;
      expect(lecture.seatsNeeded(25), 25);
      expect(lab.seatsNeeded(25), 13);
    });

    test('коефіцієнт навантаження залежить від підтипу', () {
      expect(loadFactor(_parsed.whereType<Lecture>().first), 1.0);
      expect(loadFactor(_parsed.whereType<Practice>().first), 0.75);
      expect(loadFactor(_parsed.whereType<LabWork>().first), 0.5);
    });

    test('describe використовує охоронець when', () {
      final full = Lesson.fromCsv(
        'А;Іваненко І.І.;лекція;1;09:30;287;16;2026-09-01',
      );
      final short = Lesson.fromCsv(
        'А;Іваненко І.І.;лекція;1;09:30;287;8;2026-09-01',
      );
      expect(describe(full), contains('повний'));
      expect(describe(short), contains('скорочений'));
    });
  });

  group('правила', () {
    test('12 розібраних занять коректні, одне ні', () {
      expect(_parsed.where(passesRules), hasLength(12));
      final bad = _parsed.where((l) => !passesRules(l)).single;
      expect(problemsOf(bad).single, contains('викладач'));
    });
  });

  group('домішка Schedulable', () {
    const consultation = Consultation(
      lecturer: 'Петренко О.В.',
      weekday: Weekday.monday,
      startMinutes: 9 * 60 + 45,
      room: '287',
    );

    test('працює і для заняття, і для консультації', () {
      final lecture = Lesson.fromCsv(timetableRows.first);
      expect(lecture.overlaps(consultation), isTrue);
      expect(consultation.overlaps(lecture), isTrue);
      expect(consultation.finishMinutes, 11 * 60 + 20);
    });

    test('nextOccurrence повертає найближчий понеділок', () {
      final next = consultation.nextOccurrence(DateTime.utc(2026, 10, 20, 8));
      expect(next.weekday, DateTime.monday);
      expect(next, DateTime.utc(2026, 10, 26, 9, 45));
    });
  });

  group('Repository та розширення', () {
    test('зберігає, знаходить і видаляє за id', () {
      final repo = Repository<Lesson>();
      final lesson = Lesson.fromCsv(timetableRows.first);
      repo.add(lesson);
      expect(repo.findById(lesson.id), lesson);
      expect(repo.remove(lesson.id), lesson);
      expect(repo.length, 0);
    });

    test('academicHours і byWeekday', () {
      final valid = _parsed.where(passesRules);
      expect(valid.academicHours, 336);
      expect(valid.byWeekday[Weekday.monday], hasLength(3));
    });

    test('Weekday.next та fromNumber', () {
      expect(Weekday.sunday.next, Weekday.monday);
      expect(Weekday.fromNumber(8), isNull);
      expect(Weekday.fromNumber(3), Weekday.wednesday);
    });
  });
}
