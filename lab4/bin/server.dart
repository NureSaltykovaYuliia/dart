import 'dart:io';

import 'package:group_schedule_app/group_schedule_app.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Точка входу HTTP-сервісу: `dart run bin/server.dart [порт] [файл.json]`.
Future<void> main(List<String> arguments) async {
  final port = int.tryParse(arguments.firstOrNull ?? '') ?? defaultPort;
  final dataPath = arguments.elementAtOrNull(1) ?? defaultDataPath;

  final repo = Repository<Lesson>();
  if (File(dataPath).existsSync()) {
    (await loadLessons(dataPath)).forEach(repo.add);
  }

  final handler = buildHandler(
    repo,
    log: stdout,
    onChange: (lessons) => saveLessons(dataPath, lessons),
  );
  final server = await io.serve(handler, InternetAddress.loopbackIPv4, port);
  stdout.writeln('Сервіс слухає http://${server.address.host}:${server.port}');
}
