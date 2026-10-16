# Розклад занять групи — ЛР 3: асинхронність (group_schedule_async)

Лабораторна робота №3, варіант 4. Модель з ЛР 2 доповнено асинхронним
сховищем (`Future`), потоком подій розкладу (`Stream`) і винесенням важкого
обчислення в ізолят.

## Запуск

```bash
dart pub get
dart run          # усі демонстрації кроків 3–15 з виводом
dart analyze
dart test
```

## Результати перевірок

```text
$ dart analyze
Analyzing lab3...
No issues found!

$ dart test
00:00 +28: All tests passed!
```

У тестах 28 випробувань: 16 успадковано з ЛР 2 (`model_test.dart`) та 12 нових
(`async_test.dart`: сховище, потоки, ізоляти; групи `group`, `setUp`,
`expectLater`, тест на помилку й на порядок подій).

## Структура

| Файл | Призначення |
|---|---|
| `bin/group_schedule_async.dart` | точка входу: послідовність демонстрацій за кроками методички |
| `lib/async_repository.dart` | `AsyncRepository<T>`: `load`, `save`, `delete`, `loadAll`, `watchAll` (async*) |
| `lib/events.dart` | `sealed class ScheduleEvent` і `ScheduleEvents` на `StreamController` |
| `lib/heavy.dart` | `countPrimes` і `Isolate.run` |
| інші файли `lib/` | модель з ЛР 2 без змін |

## Обґрунтування рішень

* **Сховище імітує диск затримкою `Future.delayed`**: реальні файли будуть
  у ЛР 4; параметр `latency` дозволяє тестам працювати з 5 мс, а демонстрації
  — з 500 мс.
* **Лінти `unawaited_futures` і `discarded_futures`** увімкнено в
  `analysis_options.yaml`: забутий `await` стає зауваженням. Навмисні місця
  в демонстраціях позначено `// ignore: unawaited_futures`.
* **`sealed class ScheduleEvent`** з підтипами `LessonAdded`,
  `LessonCancelled`, `RoomChanged`: `switch` у `describeEvent` вичерпний.
* **Потік одноразової підписки за замовчуванням**: він буферизує події до
  появи слухача (корисно для журналу), а `ScheduleEvents(broadcast: true)` —
  для кількох слухачів одночасно.
* **Кожна підписка має явне скасування**: `listen` повертає
  `StreamSubscription`, який зберігається й скасовується через `cancel()`.
* **Ізолят — лише для справді важкого обчислення** (решето Ератосфена до
  40 млн). `Isolate.run` не прискорює одне обчислення, але звільняє головний
  ізолят; прискорення видно, коли обчислень кілька (4 в ізолятах — 6,6 с
  проти 11,9 с послідовно на цій машині).

## Залежності

Залежностей часу виконання немає (лише `dart:async`, `dart:isolate`).
`lints` і `test` — як у ЛР 2.

## `!`, `late`, `dynamic`

* `!` і `dynamic` — не вживаються.
* `late` — лише в `test/async_test.dart` (`late AsyncRepository<Lesson> repo;`):
  змінна ініціалізується в `setUp` перед кожним тестом, це стандартний
  патерн пакета `test`; альтернатива — `AsyncRepository<Lesson>? repo` з
  перевірками на `null` у кожному тесті.

## Нове в Dart, використане тут

Приватний іменований параметр `this._brokenIds` у конструкторі
`AsyncRepository` (Dart 3.12+) — без проміжної змінної.
