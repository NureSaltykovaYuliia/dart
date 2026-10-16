import 'dart:async';

import 'package:group_schedule_async/group_schedule_async.dart';
import 'package:test/test.dart';

/// Коректні заняття з вхідного набору.
final List<Lesson> _lessons = [
  for (final row in timetableRows)
    if (Lesson.tryParse(row) case final lesson? when passesRules(lesson))
      lesson,
];

void main() {
  group('AsyncRepository', () {
    late AsyncRepository<Lesson> repo;

    setUp(() {
      repo = AsyncRepository<Lesson>(
        latency: const Duration(milliseconds: 5),
        brokenIds: {'зламаний'},
      );
    });

    test('save, load і delete повертають очікувані значення', () async {
      final lesson = _lessons.first;
      await repo.save(lesson);
      expect(await repo.load(lesson.id), lesson);
      expect(await repo.delete(lesson.id), isTrue);
      expect(await repo.load(lesson.id), isNull);
      expect(await repo.delete(lesson.id), isFalse);
    });

    test('без await збереження ще не відбулось', () async {
      final pending = repo.save(_lessons.first);
      expect(repo.length, 0);
      await pending;
      expect(repo.length, 1);
    });

    test('пошкоджений id завершує Future помилкою', () async {
      await expectLater(
        repo.load('зламаний'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Future.wait віддає першу помилку, .wait — усі', () async {
      List<Future<Lesson?>> three() => [
        repo.load('a'),
        repo.load('зламаний'),
        repo.load('b'),
      ];

      await expectLater(Future.wait(three()), throwsA(isA<StorageException>()));
      await expectLater(
        three().wait,
        throwsA(isA<ParallelWaitError<List<Lesson?>, List<AsyncError?>>>()),
      );
    });

    test('watchAll видає сутності в порядку збереження', () async {
      for (final lesson in _lessons.take(3)) {
        await repo.save(lesson);
      }
      await expectLater(
        repo.watchAll(),
        emitsInOrder([..._lessons.take(3), emitsDone]),
      );
    });
  });

  group('ScheduleEvents', () {
    test('одноразовий потік зберігає події до підписки', () async {
      final events = ScheduleEvents()
        ..emit(LessonAdded(_lessons[0]))
        ..emit(LessonCancelled(_lessons[1], 'свято'))
        ..emit(RoomChanged(_lessons[2], '101'));
      unawaited(events.close());

      final texts = await events.stream.map(describeEvent).toList();
      expect(texts, hasLength(3));
      expect(texts[0], startsWith('+'));
      expect(texts[1], contains('свято'));
      expect(texts[2], contains('→'));
    });

    test('порядок подій у потоці збережено', () async {
      final events = ScheduleEvents(broadcast: true);
      final received = events.stream.map((e) => e.runtimeType).take(3).toList();
      events
        ..emit(LessonAdded(_lessons[0]))
        ..emit(RoomChanged(_lessons[0], '1'))
        ..emit(LessonCancelled(_lessons[0], 'x'));
      expect(await received, [LessonAdded, RoomChanged, LessonCancelled]);
      await events.close();
    });

    test('друга підписка на одноразовий потік — StateError', () async {
      final events = ScheduleEvents();
      final subscription = events.stream.listen((_) {});
      expect(() => events.stream.listen((_) {}), throwsStateError);
      await subscription.cancel();
      await events.close();
    });

    test('помилка в потоці передається підписнику', () async {
      final events = ScheduleEvents()
        ..emit(LessonAdded(_lessons[0]))
        ..emitError(const StorageException('збій'));
      unawaited(events.close());
      await expectLater(
        events.stream,
        emitsInOrder([isA<LessonAdded>(), emitsError(isA<StorageException>())]),
      );
    });
  });

  group('ізоляти', () {
    test('countPrimes рахує прості числа', () {
      expect(countPrimes(1), 0);
      expect(countPrimes(10), 4);
      expect(countPrimes(100), 25);
    });

    test('Isolate.run повертає той самий результат', () async {
      expect(await countPrimesInIsolate(1000), countPrimes(1000));
    });

    test('глобальна змінна в ізоляті не змінює головний ізолят', () async {
      final before = globalCounter;
      final inside = await bumpCounterInIsolate();
      expect(inside, before + 1);
      expect(globalCounter, before);
    });
  });
}
