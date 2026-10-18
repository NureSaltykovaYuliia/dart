import 'dart:io';

import 'package:group_schedule_app/group_schedule_app.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('schedule_test_');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  group('JSON-сховище', () {
    test('save і load зберігають заняття без втрат', () async {
      final lessons = [
        for (final row in timetableRows.take(3)) Lesson.fromCsv(row),
      ];
      final path = p.join(dir.path, 'nested', 'lessons.json');
      await saveLessons(path, lessons);
      expect(await loadLessons(path), lessons);
    });

    test('відсутній файл — PathNotFoundException', () async {
      await expectLater(
        loadLessons(p.join(dir.path, 'немає.json')),
        throwsA(isA<PathNotFoundException>()),
      );
    });

    test('пошкоджений JSON — FormatException', () async {
      final path = p.join(dir.path, 'bad.json');
      await File(path).writeAsString('{не json');
      await expectLater(loadLessons(path), throwsFormatException);
    });
  });

  group('потокове читання CSV', () {
    test('великий файл читається рядок за рядком', () async {
      final path = p.join(dir.path, 'big.csv');
      final sink = File(path).openWrite()..writeln(columns.join(cellDelimiter));
      for (var i = 0; i < 20000; i++) {
        sink.writeln(timetableRows.first);
      }
      sink.writeln('сміття');
      await sink.close();

      final report = await importCsv(path);
      expect(report.lines, 20002);
      expect(report.lessons, hasLength(20000));
      expect(report.rejected, ['рядок 20002: не розібрано']);
    });
  });
}
