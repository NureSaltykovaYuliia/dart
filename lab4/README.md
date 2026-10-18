# Розклад занять групи — ЛР 4: застосунок і HTTP-сервіс (group_schedule_app)

Лабораторна робота №4, варіант 4. Проєкт набув канонічної структури пакета
(`bin/` — лише точки входу, `lib/src/` — реалізація, `lib/group_schedule_app.dart`
— фасад), отримав роботу з файлами та JSON, запит до зовнішнього REST API і
власний HTTP-сервіс на `shelf`.

## Що це

* **Консольний застосунок** `group_schedule_app` з командами `import`, `list`,
  `stats`, `holidays`.
* **HTTP-сервіс** (`bin/server.dart`) з маршрутами `GET /items`,
  `GET /items/<id>`, `POST /items`.
* **Зовнішнє API** — відкритий сервіс державних свят
  <https://date.nager.at> (ключ не потрібен): команда `holidays` показує, які
  заняття не відбудуться через свято.

## Як запустити

```bash
dart pub get
dart run bin/group_schedule_app.dart --help
dart run bin/group_schedule_app.dart import data/timetable.csv
dart run bin/group_schedule_app.dart list --kind лабораторна --masked
dart run bin/group_schedule_app.dart stats
dart run bin/group_schedule_app.dart holidays --year 2026

dart run bin/server.dart 8080          # сервіс на http://127.0.0.1:8080
curl "http://127.0.0.1:8080/items?day=1"
```

Коди завершення: `0` — успіх, `64` — помилка аргументів, `65` — пошкоджені
дані, `66` — файл не знайдено, `69` — сервіс свят недоступний. Помилки
виводяться в `stderr`.

Компіляція в машинний код:

```bash
dart compile exe bin/group_schedule_app.dart -o build/group_schedule_app.exe
```

## Результати перевірок

```text
$ dart analyze
Analyzing lab4...
No issues found!

$ dart test
00:01 +30: All tests passed!
```

## Розподіл між `bin/` і `lib/`

| Місце | Що містить |
|---|---|
| `bin/group_schedule_app.dart` | `exitCode = await runCli(args, CliContext(...))` |
| `bin/server.dart` | читання даних і запуск `shelf_io.serve` |
| `lib/group_schedule_app.dart` | фасад з `export` |
| `lib/src/lesson.dart`, `weekday.dart`, `time_slot.dart`, `rules.dart`, … | модель з ЛР 2, доповнена `toJson`/`fromJson` |
| `lib/src/storage.dart` | JSON-файл (`p.join`) і потокове читання CSV (`openRead`) |
| `lib/src/holidays.dart` | клієнт REST API, три рівні відмов |
| `lib/src/cli.dart` | `args`: команди, опції, довідка, коди завершення |
| `lib/src/server.dart` | маршрути, `Middleware`, відповіді JSON |
| `test/` | 30 тестів |

Логіку не можна тримати в `bin/`: код звідти неможливо імпортувати, отже й
протестувати. Тому `runCli` і `buildHandler` — у `lib/`, а в `bin/` лише виклик.

## Залежності та альтернативи

| Пакет | Навіщо | Альтернатива і чому не вона |
|---|---|---|
| `args` | команди, опції, довідка | ручний розбір `List<String>`: більше коду й помилок; `cli_script` — зайва складність |
| `path` | `p.join` для шляхів між ОС | конкатенація з `/` ламається на Windows |
| `http` | `http.Client` для GET, `MockClient` для тестів | `dart:io HttpClient` — нижчий рівень, ручне кодування тіла; `dio` — важча залежність |
| `shelf`, `shelf_router` | обробники, `Middleware`, маршрути | `dart_frog`/`serverpod` — фреймворки, що приховують те, що вимагає вивчити робота |
| `test` (dev) | тести; у `dev_dependencies`, бо потрібен лише розробнику | — |
| `lints` (dev) | правила `dart analyze` | `flutter_lints` — для Flutter |

`dart pub deps`: усього 53 пакети (7 прямих, решта транзитивні, більшість — з
`test` і `shelf`). `dart pub outdated`: «Found no outdated packages» —
оновлювати нічого. `pubspec.lock` закомічено, бо це застосунок, а не бібліотека.

## Мережа: три рівні відмов

| Рівень | Виняток | Поведінка |
|---|---|---|
| немає з'єднання | `SocketException`, `ClientException`, `TimeoutException` → `NoConnection` | повідомлення в `stderr`, код 69 |
| статус не 2xx | `BadStatus(statusCode)` | те саме |
| хибне тіло | `FormatException` → `BadBody` | те саме |

`http.Client` створюється фабрикою контексту, передається в `HolidayClient` і
закривається у `finally`. У тестах його підміняє `MockClient`; справжня мережа
в тестах не використовується.

## Рішення щодо JSON

`toJson`/`fromJson` написано вручну; поля читає `_field<T>`, що явно
перевіряє тип (`value is T`) і кидає `LessonFormatException`. Код не
генерується. `jsonDecode` повертає `dynamic`, тому результат одразу
перетворюється на модель.

## `!`, `late`, `dynamic`

* `!` і `dynamic` у коді не вживаються.
* `late` — лише в тестах (`late Directory dir; late StringBuffer out; …`):
  змінні ініціалізуються в `setUp` перед кожним тестом.
* `as` — лише в тестах: `jsonDecode(...) as Map<String, Object?>` та
  `as List<Object?>` для розбору відповіді; у `lib/` явні перевірки `is`.

## Відомі обмеження

* Ідентифікатор заняття `Дисципліна/День/Час` містить `/`, тому в URL його
  треба кодувати (`Uri.encodeComponent`). `shelf_router` не декодує
  параметр, тому обробник викликає `Uri.decodeComponent` сам.
* Сервіс зберігає дані в JSON-файл після кожного `POST`; паралельних записів
  не захищає (навчальний рівень).
