/// Робота з файлами: JSON-сховище та потокове читання CSV.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'lesson.dart';
import 'rules.dart';

/// Каталог із даними за замовчуванням.
const String defaultDataDir = 'data';

/// Ім'я JSON-файлу із розкладом за замовчуванням.
const String defaultDataFile = 'lessons.json';

/// Префікс заголовка CSV-файлу, який пропускається під час імпорту.
const String csvHeaderPrefix = 'дисципліна';

/// Шлях до JSON-файлу за замовчуванням, побудований через `p.join`.
String get defaultDataPath => p.join(defaultDataDir, defaultDataFile);

/// Зберігає заняття у JSON-файлі [path], створюючи каталоги за потреби.
Future<void> saveLessons(String path, Iterable<Lesson> lessons) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString(
    encoder.convert([for (final l in lessons) l.toJson()]),
  );
}

/// Завантажує заняття з JSON-файлу [path].
///
/// Кидає [PathNotFoundException], якщо файлу немає, і
/// [LessonFormatException] чи [FormatException] для пошкодженого вмісту.
Future<List<Lesson>> loadLessons(String path) async {
  final decoded = jsonDecode(await File(path).readAsString());
  if (decoded is! List<Object?>) {
    throw FormatException('очікувався масив занять', decoded);
  }
  return [
    for (final item in decoded)
      if (item is Map<String, Object?>)
        Lesson.fromJson(item)
      else
        throw FormatException('елемент не є об\'єктом', item),
  ];
}

/// Підсумок імпорту CSV.
typedef ImportReport = ({
  List<Lesson> lessons,
  List<String> rejected,
  int lines,
});

/// Читає CSV-файл [path] рядок за рядком, не завантажуючи його в пам'ять.
///
/// Рядки, що не розбираються або порушують правила, потрапляють у
/// `rejected` з номером рядка та причиною.
Future<ImportReport> importCsv(String path) async {
  final lines = File(path)
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());

  final lessons = <Lesson>[];
  final rejected = <String>[];
  var number = 0;
  await for (final line in lines) {
    number++;
    if (line.trim().isEmpty || line.startsWith(csvHeaderPrefix)) continue;
    final lesson = Lesson.tryParse(line);
    if (lesson == null) {
      rejected.add('рядок $number: не розібрано');
      continue;
    }
    final problems = problemsOf(lesson);
    if (problems.isEmpty) {
      lessons.add(lesson);
    } else {
      rejected.add('рядок $number: ${problems.join('; ')}');
    }
  }
  return (lessons: lessons, rejected: rejected, lines: number);
}
