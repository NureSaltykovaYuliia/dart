import 'dart:convert';

import 'package:group_schedule_app/group_schedule_app.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late Repository<Lesson> repo;
  late StringBuffer log;
  late Handler handler;

  Future<Response> send(String method, String path, {String? body}) async =>
      handler(Request(method, Uri.parse('http://localhost$path'), body: body));

  Future<Object?> jsonOf(Response response) async =>
      jsonDecode(await response.readAsString());

  setUp(() {
    repo = Repository<Lesson>();
    for (final row in timetableRows.take(6)) {
      repo.add(Lesson.fromCsv(row));
    }
    log = StringBuffer();
    handler = buildHandler(repo, log: log);
  });

  group('GET /items', () {
    test('повертає всі заняття в JSON з UTF-8', () async {
      final response = await send('GET', '/items');
      expect(response.statusCode, 200);
      expect(
        response.headers['content-type'],
        'application/json; charset=utf-8',
      );
      expect(await jsonOf(response), hasLength(6));
    });

    test('фільтрує за типом і днем', () async {
      final kind = Uri.encodeQueryComponent('лабораторна');
      final response = await send('GET', '/items?kind=$kind&day=3');
      final items = await jsonOf(response) as List<Object?>;
      expect(items, hasLength(1));
      final first = items.single as Map<String, Object?>;
      expect(first['subject'], contains('Dart'));
    });
  });

  group('GET /items/<id>', () {
    test('знаходить заняття за закодованим id', () async {
      final id = Uri.encodeComponent(Lesson.fromCsv(timetableRows[2]).id);
      final response = await send('GET', '/items/$id');
      expect(response.statusCode, 200);
      final body = await jsonOf(response) as Map<String, Object?>;
      expect(body['subject'], 'Бази даних');
    });

    test('для відсутнього id — 404', () async {
      final response = await send('GET', '/items/nothing');
      expect(response.statusCode, 404);
      expect(
        await jsonOf(response),
        containsPair('error', contains('не знайдено')),
      );
    });
  });

  group('POST /items', () {
    const valid =
        '{"subject":"Теорія алгоритмів","lecturer":"Остапенко В.П.",'
        '"kind":"лекція","weekday":2,"time":"09:30","room":"310",'
        '"pairs":16,"addedOn":"2026-10-19"}';

    test('створює заняття: 201, Location і запис у сховищі', () async {
      final response = await send('POST', '/items', body: valid);
      expect(response.statusCode, 201);
      expect(response.headers['location'], startsWith('/items/'));
      expect(repo.length, 7);
    });

    test('некоректний JSON — 400', () async {
      final response = await send('POST', '/items', body: '{не json');
      expect(response.statusCode, 400);
      expect(repo.length, 6);
    });

    test('порушення правил — 400 з переліком', () async {
      final response = await send(
        'POST',
        '/items',
        body: valid.replaceAll('Остапенко В.П.', 'остапенко'),
      );
      expect(response.statusCode, 400);
      expect(await jsonOf(response), containsPair('problems', isNotEmpty));
    });

    test('дублікат — 409', () async {
      await send('POST', '/items', body: valid);
      expect((await send('POST', '/items', body: valid)).statusCode, 409);
    });
  });

  test('middleware журналює метод, шлях і код відповіді', () async {
    await send('GET', '/items/nothing');
    expect(log.toString(), contains('GET /items/nothing → 404'));
  });
}
