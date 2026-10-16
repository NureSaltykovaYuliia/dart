import 'dart:async';

import 'package:group_schedule_async/group_schedule_async.dart';

/// Кількість «простих» чисел, що рахуємо у важкому обчисленні.
const int _primeLimit = 40000000;

/// Скільки однакових обчислень запускаємо для порівняння.
const int _isolateParts = 4;

/// Період тиків таймера, що показує «життя» головного ізолята.
const Duration _tick = Duration(milliseconds: 100);

/// Затримка однієї «довгої» операції у вимірюваннях.
const Duration _slow = Duration(milliseconds: 500);

/// Заняття з вхідних даних, що проходять перевірку.
final List<Lesson> _lessons = [
  for (final row in timetableRows)
    if (Lesson.tryParse(row) case final lesson? when passesRules(lesson))
      lesson,
];

/// Точка входу: послідовно демонструє `Future`, `Stream` та ізоляти.
Future<void> main() async {
  await _forgottenAwait();
  await _sequentialVsParallel();
  await _futureWaitErrors();
  await _uncaughtAsyncError();
  await _generatorAndLaziness();
  await _controllerBuffering();
  await _errorInStream();
  await _singleVsBroadcast();
  await _pipeline();
  await _isolates();
}

void _section(String title) => print('\n=== $title ===');

// ── 3. Забутий await ───────────────────────────────────────────────────────

Future<void> _forgottenAwait() async {
  _section('3. Забутий await');
  final repo = AsyncRepository<Lesson>(
    latency: const Duration(milliseconds: 50),
  );

  // ignore: unawaited_futures
  repo.save(_lessons[0]);
  print('Без await одразу після save: у сховищі ${repo.length}');

  await Future<void>.delayed(const Duration(milliseconds: 100));
  print('Після очікування: у сховищі ${repo.length}');

  await repo.save(_lessons[1]);
  print('З await: у сховищі ${repo.length}');
}

// ── 4. Послідовно та одночасно ─────────────────────────────────────────────

Future<void> _sequentialVsParallel() async {
  _section('4. Stopwatch: послідовно та одночасно (3 × 500 мс)');
  final repo = AsyncRepository<Lesson>(latency: _slow);

  final sequential = Stopwatch()..start();
  for (final lesson in _lessons.take(3)) {
    await repo.save(lesson);
  }
  sequential.stop();

  final parallel = Stopwatch()..start();
  await Future.wait([
    for (final lesson in _lessons.skip(3).take(3)) repo.save(lesson),
  ]);
  parallel.stop();

  print('Послідовні await: ${sequential.elapsedMilliseconds} мс');
  print('Future.wait:      ${parallel.elapsedMilliseconds} мс');
}

// ── 5. Помилка в групі операцій ────────────────────────────────────────────

Future<void> _futureWaitErrors() async {
  _section('5. Помилка в одній із трьох операцій');
  final lesson = _lessons.first;
  final repo = AsyncRepository<Lesson>(
    latency: const Duration(milliseconds: 100),
    brokenIds: {'зламаний-1', 'зламаний-2'},
  );
  await repo.save(lesson);

  List<Future<Lesson?>> operations() => [
    repo.load(lesson.id),
    repo.load('зламаний-1'),
    repo.load('зламаний-2'),
  ];

  try {
    final results = await Future.wait(operations());
    print('Future.wait: $results');
  } on StorageException catch (e) {
    print('Future.wait: лише перша помилка → $e; результатів немає');
  }

  try {
    final results = await operations().wait;
    print('.wait: $results');
  } on ParallelWaitError<List<Lesson?>, List<AsyncError?>> catch (e) {
    print('.wait: ParallelWaitError');
    print('  values (часткові): ${e.values}');
    print('  errors: ${e.errors.map((x) => x?.error).toList()}');
  }
}

// ── 6. Неспіймана асинхронна помилка ──────────────────────────────────────

Future<void> _uncaughtAsyncError() async {
  _section('6. try/catch без await не ловить помилку');
  final repo = AsyncRepository<Lesson>(
    latency: const Duration(milliseconds: 50),
    brokenIds: {'зламаний'},
  );
  await runZonedGuarded(() async {
    try {
      // ignore: unawaited_futures
      repo.load('зламаний');
      print('try завершився без винятку — помилки ще немає');
    } on StorageException catch (e) {
      print('catch всередині: $e (цього рядка не буде)');
    }
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }, (error, _) => print('Неспіймана в зоні: $error'));
}

// ── 7–8. Генератор async* і його лінивість ────────────────────────────────

Stream<int> _numbers() async* {
  print('  тіло генератора розпочалось');
  for (var i = 1; i <= 3; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    yield i;
  }
}

Future<void> _generatorAndLaziness() async {
  _section('7–8. async*: await for та лінивість');
  final repo = AsyncRepository<Lesson>(
    latency: const Duration(milliseconds: 80),
  );
  for (final lesson in _lessons.take(3)) {
    await repo.save(lesson);
  }
  await for (final lesson in repo.watchAll()) {
    print('  отримано: ${lesson.subject} (${lesson.kind})');
  }

  final stream = _numbers();
  print('Потік створено, ніхто не підписався');
  await Future<void>.delayed(const Duration(milliseconds: 100));
  print('Минуло 100 мс — тіло так і не виконалось. Підписуємось:');
  await stream.forEach((n) => print('  отримано $n'));
}

// ── 9–10. StreamController і підписка ─────────────────────────────────────

Future<void> _controllerBuffering() async {
  _section('9–10. StreamController: події до підписки');
  final events = ScheduleEvents()
    ..emit(LessonAdded(_lessons[0]))
    ..emit(RoomChanged(_lessons[1], '214'))
    ..emit(LessonCancelled(_lessons[2], 'хвороба викладача'));
  print('Три події додано до підписки');

  final received = <String>[];
  final subscription = events.stream.listen(
    (e) => received.add(describeEvent(e)),
    onDone: () => print('  потік завершено'),
  );
  await Future<void>.delayed(const Duration(milliseconds: 20));
  for (final line in received) {
    print('  $line');
  }

  await subscription.cancel();
  print('Підписку скасовано явно');
  await events.close();
}

// ── 11. Помилка всередині потоку ──────────────────────────────────────────

Stream<int> _withError() async* {
  yield 1;
  yield 2;
  throw StorageException('збій на третьому елементі');
}

Stream<int> _controllerWithError() {
  final controller = StreamController<int>();
  controller
    ..add(1)
    ..addError(StorageException('помилка посередині'))
    ..add(3);
  unawaited(controller.close());
  return controller.stream;
}

Future<void> _errorInStream() async {
  _section('11. Помилка посеред потоку');
  try {
    await for (final n in _controllerWithError()) {
      print('  await for: $n');
    }
  } on StorageException catch (e) {
    print('  await for перервано: $e (елемент 3 не отримано)');
  }

  final done = Completer<void>();
  final subscription = _controllerWithError().listen(
    (n) => print('  listen: $n'),
    onError: (Object e) => print('  listen: помилка "$e", продовжуємо'),
    onDone: done.complete,
    cancelOnError: false,
  );
  await done.future;
  await subscription.cancel();

  print('  async* після throw завершується назавжди:');
  try {
    await for (final n in _withError()) {
      print('  async*: $n');
    }
  } on StorageException catch (e) {
    print('  async*: $e');
  }
}

// ── 12. Одноразова підписка та широкомовний потік ─────────────────────────

Future<void> _singleVsBroadcast() async {
  _section('12. Одноразова підписка і broadcast');
  final single = ScheduleEvents();
  final first = single.stream.listen((_) {});
  try {
    single.stream.listen((_) {});
  } on StateError catch (e) {
    print('Друга підписка на звичайний потік: $e');
  }
  await first.cancel();
  await single.close();

  final broadcast = ScheduleEvents(broadcast: true);
  final subs = [
    broadcast.stream.listen((e) => print('  слухач 1: ${describeEvent(e)}')),
    broadcast.stream.listen((e) => print('  слухач 2: ${describeEvent(e)}')),
  ];
  broadcast.emit(LessonAdded(_lessons.first));
  await Future<void>.delayed(const Duration(milliseconds: 20));
  for (final subscription in subs) {
    await subscription.cancel();
  }
  await broadcast.close();
}

// ── 13. Конвеєр над потоком ──────────────────────────────────────────────

Future<void> _pipeline() async {
  _section('13. where → map → take над потоком подій');
  final events = ScheduleEvents(broadcast: true);
  final lines = events.stream
      .where((e) => e is! LessonAdded)
      .map(describeEvent)
      .take(2)
      .toList();

  events
    ..emit(LessonAdded(_lessons[0]))
    ..emit(RoomChanged(_lessons[1], '214'))
    ..emit(LessonAdded(_lessons[2]))
    ..emit(LessonCancelled(_lessons[3], 'свято'))
    ..emit(LessonCancelled(_lessons[4], 'зайве'));
  for (final line in await lines) {
    print('  $line');
  }
  await events.close();
}

// ── 14–15. Ізоляти ───────────────────────────────────────────────────────

Future<void> _isolates() async {
  _section('14. Важке обчислення: прості числа до $_primeLimit');

  var maxGap = Duration.zero;
  var previous = Stopwatch()..start();
  final ticker = Timer.periodic(_tick, (_) {
    final gap = previous.elapsed;
    if (gap > maxGap) maxGap = gap;
    previous = Stopwatch()..start();
  });

  final sync = Stopwatch()..start();
  final syncResult = countPrimes(_primeLimit);
  sync.stop();
  await Future<void>.delayed(_tick * 2);
  print(
    'Синхронно: $syncResult за ${sync.elapsedMilliseconds} мс; '
    'найбільша пауза між тиками таймера ${maxGap.inMilliseconds} мс',
  );

  maxGap = Duration.zero;
  previous = Stopwatch()..start();
  final single = Stopwatch()..start();
  final isolateResult = await countPrimesInIsolate(_primeLimit);
  single.stop();
  print(
    'Isolate.run: $isolateResult за ${single.elapsedMilliseconds} мс; '
    'найбільша пауза між тиками ${maxGap.inMilliseconds} мс',
  );
  ticker.cancel();

  final sequential = Stopwatch()..start();
  for (var i = 0; i < _isolateParts; i++) {
    countPrimes(_primeLimit);
  }
  sequential.stop();
  final parallel = Stopwatch()..start();
  await Future.wait([
    for (var i = 0; i < _isolateParts; i++) countPrimesInIsolate(_primeLimit),
  ]);
  parallel.stop();
  print(
    '$_isolateParts однакових обчислення: послідовно '
    '${sequential.elapsedMilliseconds} мс, в ізолятах '
    '${parallel.elapsedMilliseconds} мс',
  );

  _section('15. Глобальна змінна в ізоляті');
  final inside = await bumpCounterInIsolate();
  print('В ізоляті globalCounter = $inside, у головному = $globalCounter');
}
