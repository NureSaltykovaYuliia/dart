import 'dart:io';

import 'package:group_schedule_app/group_schedule_app.dart';

/// Точка входу консольного застосунку.
Future<void> main(List<String> arguments) async {
  exitCode = await runCli(arguments, CliContext(out: stdout, err: stderr));
}
