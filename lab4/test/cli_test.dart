import 'dart:io';

import 'package:group_schedule_app/group_schedule_app.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late StringBuffer out;
  late StringBuffer err;
  late String data;

  CliContext context({http.Client Function()? client}) => CliContext(
    out: out,
    err: err,
    clientFactory: client,
    now: DateTime.utc(2026, 10, 19),
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('schedule_cli_');
    out = StringBuffer();
    err = StringBuffer();
    data = p.join(dir.path, 'lessons.json');
    await File(p.join(dir.path, 'in.csv')).writeAsString(
      '${columns.join(cellDelimiter)}\n${timetableRows.join('\n')}\n',
    );
  });

  tearDown(() => dir.delete(recursive: true));

  Future<int> run(List<String> args, [CliContext? ctx]) =>
      runCli(args, ctx ?? context());

  group('аргументи командного рядка', () {
    test('--help друкує довідку й повертає 0', () async {
      expect(await run(['--help']), exitOk);
      expect(out.toString(), contains('Команда list'));
    });

    test('без команди — довідка в stderr і код 64', () async {
      expect(await run([]), exitUsage);
      expect(err.toString(), contains('Використання'));
    });

    test('невідома опція — код 64', () async {
      expect(await run(['list', '--nope']), exitUsage);
      expect(err.toString(), contains('Помилка аргументів'));
    });

    test('недопустиме значення --kind — код 64', () async {
      expect(await run(['list', '--kind', 'семінар']), exitUsage);
    });
  });

  group('команди', () {
    test('import → list → stats працюють разом', () async {
      final csv = p.join(dir.path, 'in.csv');
      expect(await run(['import', csv, '-d', data]), exitOk);
      expect(out.toString(), contains('збережено: 12'));
      expect(err.toString(), contains('олійник'));

      out.clear();
      expect(await run(['list', '-d', data, '--kind', 'лабораторна']), exitOk);
      expect(out.toString().trim().split('\n'), hasLength(3));

      out.clear();
      expect(await run(['stats', '-d', data]), exitOk);
      expect(out.toString(), contains('336'));
    });

    test('list без файлу — код 66 і повідомлення в stderr', () async {
      expect(await run(['list', '-d', data]), exitNoInput);
      expect(err.toString(), contains('Файл не знайдено'));
    });

    test('holidays: сервіс недоступний — код 69, клієнт закрито', () async {
      await run(['import', p.join(dir.path, 'in.csv'), '-d', data]);
      var closed = false;
      final client = _TrackingClient(
        MockClient((_) async => throw const SocketException('offline')),
        onClose: () => closed = true,
      );
      final code = await run([
        'holidays',
        '-d',
        data,
      ], context(client: () => client));
      expect(code, exitUnavailable);
      expect(err.toString(), contains('немає з\'єднання'));
      expect(closed, isTrue);
    });
  });
}

/// Клієнт-обгортка, що фіксує виклик `close`.
class _TrackingClient extends http.BaseClient {
  _TrackingClient(this._inner, {required this.onClose});

  final http.Client _inner;
  final void Function() onClose;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request);

  @override
  void close() {
    onClose();
    _inner.close();
  }
}
