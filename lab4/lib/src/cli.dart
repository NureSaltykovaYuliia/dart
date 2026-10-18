/// Командний рядок: розбір аргументів і виконання команд.
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

import 'analysis.dart';
import 'extensions.dart';
import 'holidays.dart';
import 'settings.dart';
import 'storage.dart';
import 'weekday.dart';

/// Код завершення: успіх.
const int exitOk = 0;

/// Код завершення: неправильні аргументи (`EX_USAGE`).
const int exitUsage = 64;

/// Код завершення: пошкоджені дані (`EX_DATAERR`).
const int exitData = 65;

/// Код завершення: вхідний файл не знайдено (`EX_NOINPUT`).
const int exitNoInput = 66;

/// Код завершення: сервіс недоступний (`EX_UNAVAILABLE`).
const int exitUnavailable = 69;

/// Середовище виконання команди: виводи та джерело HTTP-клієнта.
///
/// Усе, що торкається зовнішнього світу, передається ззовні, щоб у тестах
/// його можна було підмінити.
class CliContext {
  /// Створює середовище; [clientFactory] і [now] мають розумні типові
  /// значення.
  CliContext({
    required this.out,
    required this.err,
    http.Client Function()? clientFactory,
    DateTime? now,
  }) : clientFactory = clientFactory ?? http.Client.new,
       now = now ?? DateTime.now();

  /// Куди писати результат.
  final StringSink out;

  /// Куди писати повідомлення про помилки (stderr).
  final StringSink err;

  /// Створює HTTP-клієнт.
  final http.Client Function() clientFactory;

  /// Поточний момент.
  final DateTime now;
}

/// Будує парсер аргументів з командами `list`, `import`, `stats`, `holidays`.
ArgParser buildParser() {
  ArgParser withData(ArgParser parser) => parser
    ..addOption(
      'data',
      abbr: 'd',
      help: 'Шлях до JSON-файлу з розкладом.',
      defaultsTo: defaultDataPath,
    );

  return ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Показати довідку.')
    ..addCommand(
      'list',
      withData(ArgParser())
        ..addOption(
          'kind',
          abbr: 'k',
          help: 'Лише заняття цього типу.',
          allowed: [kindLecture, kindPractice, kindLab],
        )
        ..addOption(
          'day',
          help: 'Лише заняття цього дня (1 — понеділок).',
          allowed: [for (final d in Weekday.values) '${d.number}'],
        )
        ..addFlag('masked', negatable: false, help: 'Сховати прізвища.'),
    )
    ..addCommand('import', withData(ArgParser()))
    ..addCommand('stats', withData(ArgParser()))
    ..addCommand(
      'holidays',
      withData(ArgParser())
        ..addOption(
          'year',
          abbr: 'y',
          help: 'Рік свят (за замовчуванням — поточний).',
        )
        ..addOption('country', abbr: 'c', defaultsTo: defaultCountry),
    );
}

/// Текст довідки з переліком команд та їхніх опцій.
String usage() {
  final parser = buildParser();
  final text = StringBuffer()
    ..writeln('Розклад занять групи.')
    ..writeln()
    ..writeln('Використання: group_schedule_app <команда> [опції]')
    ..writeln()
    ..writeln('Загальні опції:')
    ..writeln(parser.usage);
  for (final MapEntry(:key, :value) in parser.commands.entries) {
    text
      ..writeln()
      ..writeln('Команда $key:')
      ..writeln(value.usage);
  }
  text
    ..writeln()
    ..writeln('Приклад: group_schedule_app import data/timetable.csv');
  return text.toString();
}

/// Виконує команду з [arguments] і повертає код завершення.
Future<int> runCli(List<String> arguments, CliContext context) async {
  final ArgResults results;
  try {
    results = buildParser().parse(arguments);
  } on ArgParserException catch (e) {
    context.err.writeln('Помилка аргументів: ${e.message}');
    context.err.write(usage());
    return exitUsage;
  }

  final command = results.command;
  if (results.flag('help') || command == null) {
    (command == null && !results.flag('help') ? context.err : context.out)
        .write(usage());
    return results.flag('help') ? exitOk : exitUsage;
  }

  final dataPath = command.option('data') ?? defaultDataPath;
  try {
    return switch (command.name) {
      'list' => await _list(command, dataPath, context),
      'import' => await _import(command, dataPath, context),
      'stats' => await _stats(dataPath, context),
      'holidays' => await _holidays(command, dataPath, context),
      _ => exitUsage,
    };
  } on PathNotFoundException catch (e) {
    context.err.writeln('Файл не знайдено: ${e.path}. Виконайте import.');
    return exitNoInput;
  } on FormatException catch (e) {
    context.err.writeln('Пошкоджені дані: ${e.message}');
    return exitData;
  }
}

Future<int> _list(
  ArgResults command,
  String dataPath,
  CliContext context,
) async {
  final kind = command.option('kind');
  final day = int.tryParse(command.option('day') ?? '');
  final masked = command.flag('masked');
  final lessons = (await loadLessons(dataPath)).where(
    (l) =>
        (kind == null || l.kind == kind) &&
        (day == null || l.weekday.number == day),
  );
  for (final l in lessons) {
    final lecturer = masked ? l.lecturer.masked : l.lecturer;
    context.out.writeln(
      '${l.weekday.label} ${l.time} ауд.${l.room} ${l.subject} '
      '(${l.kind}) — $lecturer',
    );
  }
  return exitOk;
}

Future<int> _import(
  ArgResults command,
  String dataPath,
  CliContext context,
) async {
  final input = command.rest.firstOrNull;
  if (input == null) {
    context.err.writeln('Вкажіть CSV-файл: import <файл.csv>');
    return exitUsage;
  }
  final report = await importCsv(input);
  for (final reason in report.rejected) {
    context.err.writeln('Відхилено, $reason');
  }
  await saveLessons(dataPath, report.lessons);
  context.out.writeln(
    'Прочитано рядків: ${report.lines}, збережено: ${report.lessons.length}, '
    'відхилено: ${report.rejected.length} → $dataPath',
  );
  return exitOk;
}

Future<int> _stats(String dataPath, CliContext context) async {
  final lessons = await loadLessons(dataPath);
  final summary = summarize(lessons);
  if (summary == null) {
    context.out.writeln('Розклад порожній.');
    return exitOk;
  }
  final (lessons: count, :hours, :meanPairs) = summary;
  context.out
    ..writeln('Занять: $count')
    ..writeln('Академічних годин за семестр: $hours')
    ..writeln('Пар на заняття в середньому: ${meanPairs.toStringAsFixed(1)}');
  return exitOk;
}

Future<int> _holidays(
  ArgResults command,
  String dataPath,
  CliContext context,
) async {
  final year = int.tryParse(command.option('year') ?? '') ?? context.now.year;
  final country = command.option('country') ?? defaultCountry;
  final lessons = await loadLessons(dataPath);

  final client = context.clientFactory();
  try {
    final holidays = await HolidayClient(client).fetch(year, country: country);
    final lost = lessonsLostToHolidays(lessons, holidays);
    context.out.writeln('Свята $country $year: ${holidays.length}');
    for (final MapEntry(key: holiday, value: affected) in lost.entries) {
      context.out.writeln(
        '${isoDate(holiday.date)} ${holiday.name}: '
        'не відбудеться занять — ${affected.length}',
      );
    }
    return exitOk;
  } on HolidayFailure catch (e) {
    context.err.writeln('Не вдалося отримати свята: $e');
    return exitUnavailable;
  } finally {
    client.close();
  }
}

/// Календарна дата у вигляді `РРРР-ММ-ДД`.
String isoDate(DateTime date) => date.toIso8601String().substring(0, 10);
