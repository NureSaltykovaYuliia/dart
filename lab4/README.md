# ЛР 4 — Застосунок і HTTP-сервіс (group_schedule_app)

Четверта лабораторна, варіант 4. Проєкт отримав стандартну структуру
Dart-пакета (`bin/` — точки входу, `lib/src/` — реалізація,
`lib/group_schedule_app.dart` — фасад), а також:

* роботу з файлами: JSON і CSV;
* запит до зовнішнього REST API;
* власний HTTP-сервіс на `shelf`.

## Що це таке

* **Консольний застосунок** з командами `import`, `list`, `stats`,
  `holidays`.
* **HTTP-сервіс** `bin/server.dart`: `GET /items` (фільтри `kind`, `day`,
  `q`), `GET /items/<id>` (404, якщо немає), `POST /items` (400 на
  некоректне тіло, 409 на дублікат).
* **Зовнішнє API** — відкритий сервіс державних свят
  <https://date.nager.at>, ключ не потрібен. `holidays` показує, скільки
  занять випадає на кожне свято.

## Запуск

```bash
dart pub get
dart run bin/group_schedule_app.dart --help
dart run bin/group_schedule_app.dart import data/timetable.csv
dart run bin/group_schedule_app.dart list --kind лабораторна --masked
dart run bin/group_schedule_app.dart stats
dart run bin/group_schedule_app.dart holidays --year 2026

dart run bin/server.dart 8080          # сервіс на http://127.0.0.1:8080
curl "http://127.0.0.1:8080/items?day=1"

dart analyze
dart test                              # 30 тестів
```

Коди завершення: `0` — усе добре, `64` — неправильні аргументи, `65` —
пошкоджені дані, `66` — файл не знайдено, `69` — сервіс свят недоступний.
Повідомлення про помилки йдуть у `stderr`.

Збірка у виконуваний файл:

```bash
dart compile exe bin/group_schedule_app.dart -o build/group_schedule_app.exe
```

## Як влаштований код

| Місце | Що в ньому |
|---|---|
| `bin/group_schedule_app.dart` | `exitCode = await runCli(arguments, CliContext(...))` |
| `bin/server.dart` | завантаження даних і запуск `shelf_io.serve` |
| `lib/group_schedule_app.dart` | фасад із `export` |
| `lib/src/lesson.dart`, `weekday.dart`, `time_slot.dart`, `rules.dart`, … | модель з ЛР 2 + `toJson` / `fromJson` |
| `lib/src/storage.dart` | JSON-файл (`p.join`), потокове читання CSV |
| `lib/src/holidays.dart` | клієнт REST API, три рівні відмов |
| `lib/src/cli.dart` | команди й опції (`args`), довідка, коди завершення |
| `lib/src/server.dart` | маршрути, `Middleware` журналювання, JSON-відповіді |
| `data/` | вхідні `timetable.csv` і `lessons.json` |
| `test/` | 30 тестів: CLI, свята, серіалізація, сервер, сховище |

Логіку не можна тримати в `bin/`: код звідти не можна підключити, а отже
й протестувати. Тому `runCli` і `buildHandler` лежать у `lib/`, а `bin/` —
лише виклик.

## Чому така структура й такі типи

**Консольний інтерфейс — функція `runCli(arguments, CliContext)`.** Потоки
виводу й HTTP-клієнт передаються ззовні, тому в тестах підставляються
буфер і підроблений клієнт, і програму можна перевірити без запуску
процесу чи реальної мережі. *Альтернатива:* звертатися до `stdout` і
створювати `http.Client` прямо в коді — тоді тест вийшов би на реальну
мережу.

**Три рівні відмов мережі — запечатана ієрархія `HolidayFailure`.**
Успішний `await` не означає успішний запит, тому статус і тіло
перевіряються окремо:

| Що сталося | Виняток | Результат |
|---|---|---|
| немає з'єднання | `SocketException`, `ClientException`, `TimeoutException` → `NoConnection` | повідомлення в `stderr`, код 69 |
| код не 2xx | `BadStatus(statusCode)` | те саме, у тексті код відповіді |
| хибне тіло | `FormatException` → `BadBody` | те саме |

Клієнт, створений командою, закривається у `finally`.

**JSON — вручну, без кодогенерації.** Результат `jsonDecode` має тип
`dynamic`, тому його одразу перетворюють на модель; кожне поле читає
допоміжна `_field<T>`, яка перевіряє тип (`value is T`) і кидає
`LessonFormatException` з назвою поля. *Альтернатива:* кодогенерація
(`json_serializable`) — тут зайва для однієї моделі з кількома полями.

**CSV читається потоком** (`openRead()` → `utf8.decoder` →
`LineSplitter`), а не цілим файлом у пам'ять. Рядки, що не розбираються
або порушують правила, потрапляють у список відхилених із номером рядка.
Тест створює файл на 20 002 рядки.

**Ідентифікатор заняття** `Дисципліна/День/Час` містить `/`, тому в URL
його треба кодувати (`Uri.encodeComponent`). `shelf_router` не декодує
параметр, тому обробник сам викликає `Uri.decodeComponent`.

## Залежності

`dart pub deps`: усього 53 пакети, 7 прямих (їх видно в `pubspec.yaml`),
решта — транзитивні (переважно від `test` і `shelf`). `dart pub outdated`:
«Found no outdated packages». `pubspec.lock` закомічено, бо це застосунок,
а не бібліотека.

| Пакет | Навіщо | Альтернатива |
|---|---|---|
| `args` | команди, опції, автоматична довідка, `allowed` для перевірки значень `--kind` і `--day` | ручний розбір `List<String>` — більше коду й помилок |
| `path` | `p.join` — шляхи, що працюють на будь-якій ОС | склеювання з `/` ламається на Windows |
| `http` | `http.Client` для GET-запиту; `MockClient` для тестів без мережі | `dart:io HttpClient` — нижчий рівень; `dio` — важча залежність |
| `shelf`, `shelf_router` | обробники запитів, `Middleware`, маршрути `/items/<id>` | `dart_frog`, `serverpod` — фреймворки, що приховують механіку; саме її й треба було вивчити |
| `test` (dev) | тести; лише для розробки, тому в `dev_dependencies` | — |
| `lints` (dev) | правила `dart analyze` | `flutter_lints` — для Flutter |

## `!`, `late`, `dynamic`, `as`

У `lib/` немає `!`, `dynamic` і `as`: замість приведення типів — явні
перевірки `is`. У тестах `late` (`late Directory dir;`, `late
StringBuffer out;`) ініціалізується в `setUp`, а `as` потрібен для розбору
відповіді (`jsonDecode(...) as Map<String, Object?>`).

## Відомі обмеження

* Сервіс зберігає дані в JSON-файл після кожного успішного `POST` і не
  захищає від паралельних записів. Для навчальної роботи цього достатньо.
