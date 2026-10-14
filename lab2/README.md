# Розклад занять групи — ЛР 2: об'єктно-орієнтована модель (group_schedule_oop)

Лабораторна робота №2 з дисципліни «Програмування мовою Dart», варіант 4
(«Розклад занять групи»). Ті самі дані, що й у ЛР 1 (`../lab1`), переписано
з записів і функцій на класи: ієрархія типів, домішка, узагальнене сховище,
перелічення, методи розширення, записи та зіставлення зі зразком.

## Запуск

```bash
dart pub get
dart run                                   # демонстрація моделі
dart run example/hash_code_experiment.dart # == без hashCode
dart run example/consultation_classic.dart # первинний і класичний конструктор
dart analyze
dart test
```

## Результати перевірок

```text
$ dart analyze
Analyzing lab2...
No issues found!

$ dart test
00:00 +16: All tests passed!
```

## Структура: що де лежить і чому

| Файл | Призначення |
|---|---|
| `bin/group_schedule_oop.dart` | лише точка входу: послідовність демонстрацій |
| `lib/group_schedule_oop.dart` | фасад бібліотеки з `export` |
| `lib/lesson.dart` | `sealed class Lesson` і підтипи `Lecture`, `Practice`, `LabWork`; `fromCsv`, `tryParse`, `cached`; `==`/`hashCode` |
| `lib/time_slot.dart` | `Identifiable`, `TimeSlot`, домішка `Schedulable on TimeSlot` |
| `lib/consultation.dart` | `Consultation` — другий клас із домішкою (первинний конструктор) |
| `lib/weekday.dart` | `enum Weekday` з полями, конструктором і методами |
| `lib/repository.dart` | `Repository<T extends Identifiable>` |
| `lib/extensions.dart` | методи розширення для `Iterable<Lesson>` і `String` |
| `lib/analysis.dart` | записи, `switch` без `default`, охоронці `when` |
| `lib/rules.dart`, `settings.dart`, `clock.dart`, `patterns.dart` | правила, константи, час, регулярні вирази (з ЛР 1) |
| `example/` | експерименти, на які посилається звіт |
| `test/model_test.dart` | 16 модульних тестів |

Логіку винесено в `lib/`, у `bin/` лише послідовність викликів: код із `bin/`
не можна імпортувати, а отже й тестувати.

## Обґрунтування рішень

* **`sealed class Lesson` із трьома `final`-підтипами** замість поля-рядка
  `kind`: тип заняття тепер частина системи типів. `switch` по `Lesson`
  без гілки `default` перевіряється компілятором на вичерпність; якщо додати
  четвертий підтип, компілятор вкаже на кожне місце, де його не враховано.
  Альтернатива — `enum LessonKind` + поле: поведінка залишилась би в
  `switch` по перелічення, а підтипи не могли б мати власних полів і методів.
* **Незмінність**: усі поля `final`, конструктор `const`. Рівність за
  значенням (`==` + `hashCode` разом) дозволяє класти заняття в `Set` і
  порівнювати в тестах.
* **Три способи створення**: `Lesson.fromCsv` кидає
  `LessonFormatException`, `Lesson.tryParse` повертає `null`,
  `Lesson.cached` повертає той самий екземпляр для того самого рядка.
  Замість винятків у ЛР 1 тут конструктор не може повернути `null`,
  тому обидва підходи доступні.
* **Домішка `Schedulable on TimeSlot`** підмішана до `Lesson` і до
  `Consultation` — класів з різних гілок. Обмеження `on` дозволяє домішці
  читати `weekday` і `startMinutes`, а компілятору — не пустити її до
  класів, які не є слотами. Успадкування не підходить: Dart має одиничне
  успадкування, а поведінка потрібна лише тим слотам, що повторюються щотижня.
* **`Repository<T extends Identifiable>`**: обмеження дає право викликати
  `item.id`. Без нього `T` — це `Object?`, і код не компілюється
  (див. звіт, п. 1.8).
* **`enum Weekday`** з номером, назвою, методами `next`/`isStudyDay` замінює
  мапу `weekdayLabels` і «магічні» числа.
* **Записи** (`LoadSummary`, `({Lesson first, Lesson last})`,
  `({int hours, int minutes})`) повертають кілька значень без окремих класів;
  розбираються деструктуризацією.
* **Типи даних**: час — `int` хвилин від півночі, дата — `DateTime` в UTC,
  день тижня — `Weekday`.

## Первинний конструктор (Dart 3.13)

`Consultation` оголошено первинним конструктором (`lib/consultation.dart`),
її класичний еквівалент — у `example/consultation_classic.dart`. Поведінка
однакова (вивід збігається), обсяг оголошення: 13 рядків коду проти 18.
Побічний ефект: лінт `public_member_api_docs` ще не вміє документувати
первинний конструктор, тому в одному місці стоїть
`// ignore: public_member_api_docs`.

## Залежності

Залежностей часу виконання немає. У `dev_dependencies`:

* `lints` — набір `recommended` + суворіші правила в `analysis_options.yaml`
  (альтернатива `flutter_lints` непотрібна: проєкт не Flutter);
* `test` — модульні тести (офіційний пакет команди Dart; альтернатива
  `flutter_test` непридатна поза Flutter).

## `!`, `late`, `dynamic`

У коді — не вживаються. Відсутні й приведення `as` у `lib/`.

## Що змінилось порівняно з ЛР 1

Тип заняття став підтипом, а не рядком; записи `Lesson`/`Decoded` —
класом і результатом `Lesson.tryParse`; правила переведено на `Weekday`.
Функції `nextSession`, `weekMinute`, `finishMinutes` стали методами домішки.
