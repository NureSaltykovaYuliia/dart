# Програмування мовою Dart — лабораторні роботи

Наскрізний проєкт за варіантом 4 — **«Розклад занять групи»**. Кожна
лабораторна робота — окремий пакет Dart у власній папці з `pubspec.yaml`,
`analysis_options.yaml`, `README.md` та тестами; попередні етапи не
видаляються, щоб їх можна було порівняти.

| Папка | Тема | Пакет |
|---|---|---|
| [`lab1`](lab1) | функції, замикання, колекції, рядки, дати (без класів) | `group_schedule` |
| [`lab2`](lab2) | класи, ієрархії, домішки, узагальнення, записи | `group_schedule_oop` |
| [`lab3`](lab3) | `Future`, `Stream`, ізоляти, модульні тести | `group_schedule_async` |
| [`lab4`](lab4) | пакет `lib/src`, файли, JSON, HTTP, `shelf`, `args` | `group_schedule_app` |

## Як перевірити будь-яку роботу

```bash
cd lab2        # або lab1, lab3, lab4
dart pub get
dart analyze   # має бути: No issues found!
dart test
dart run
```

Вимоги: Dart SDK 3.13 (канал stable). Докладніше — у `README.md`
кожної папки: обґрунтування структури й типів даних, залежності та
альтернативи, місця вживання `!`, `late`, `dynamic`.

## Структура репозиторію

```text
.gitignore
README.md
lab1/ … lab4/
  bin/        точка входу
  lib/        логіка (з lab4 — lib/src/)
  test/       модульні тести
  analysis_options.yaml
  pubspec.yaml
  README.md
```

Секрети й локальні файли (`.env`, `.vscode/`, `.dart_tool/`, `build/`) у
репозиторій не потрапляють.
