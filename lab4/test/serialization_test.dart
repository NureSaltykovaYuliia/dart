import 'dart:convert';

import 'package:group_schedule_app/group_schedule_app.dart';
import 'package:test/test.dart';

/// Повний коректний JSON заняття.
Map<String, Object?> _json() => {
  'subject': 'Бази даних',
  'lecturer': 'Коваленко І.М.',
  'kind': 'лабораторна',
  'weekday': 4,
  'time': '13:10',
  'room': '160и',
  'pairs': 8,
  'addedOn': '2026-08-29',
};

void main() {
  group('Lesson JSON', () {
    test('toJson → fromJson дає рівне заняття', () {
      final lesson = Lesson.fromCsv(timetableRows[3]);
      final restored = Lesson.fromJson(
        jsonDecode(jsonEncode(lesson.toJson())) as Map<String, Object?>,
      );
      expect(restored, lesson);
      expect(restored, isA<LabWork>());
    });

    test('поле хибного типу — LessonFormatException', () {
      final json = _json()..['pairs'] = '8';
      expect(
        () => Lesson.fromJson(json),
        throwsA(
          isA<LessonFormatException>().having(
            (e) => e.message,
            'message',
            contains('pairs'),
          ),
        ),
      );
    });

    test('відсутнє поле — LessonFormatException', () {
      final json = _json()..remove('room');
      expect(
        () => Lesson.fromJson(json),
        throwsA(isA<LessonFormatException>()),
      );
    });

    test('невідомий тип заняття відхиляється', () {
      final json = _json()..['kind'] = 'семінар';
      expect(
        () => Lesson.fromJson(json),
        throwsA(isA<LessonFormatException>()),
      );
    });
  });
}
