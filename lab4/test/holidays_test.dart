import 'dart:convert';
import 'dart:io';

import 'package:group_schedule_app/group_schedule_app.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

HolidayClient _clientReplying(http.Response Function(http.Request) reply) =>
    HolidayClient(MockClient((request) async => reply(request)));

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  group('HolidayClient', () {
    test('розбирає успішну відповідь з кирилицею', () async {
      final client = _clientReplying(
        (_) => _json([
          {'date': '2026-08-24', 'localName': 'День Незалежності'},
        ]),
      );
      final holidays = await client.fetch(2026);
      expect(holidays.single.name, 'День Незалежності');
      expect(holidays.single.date, DateTime.utc(2026, 8, 24));
    });

    test('формує адресу з роком і країною', () async {
      Uri? requested;
      final client = _clientReplying((request) {
        requested = request.url;
        return _json(<Object>[]);
      });
      await client.fetch(2027, country: 'PL');
      expect(requested?.path, endsWith('/PublicHolidays/2027/PL'));
    });

    test('рівень 1: немає з\'єднання — NoConnection', () async {
      final client = HolidayClient(
        MockClient((_) async => throw const SocketException('offline')),
      );
      await expectLater(client.fetch(2026), throwsA(isA<NoConnection>()));
    });

    test('рівень 2: код 500 — BadStatus', () async {
      final client = _clientReplying((_) => http.Response('error', 500));
      await expectLater(
        client.fetch(2026),
        throwsA(isA<BadStatus>().having((e) => e.statusCode, 'code', 500)),
      );
    });

    test('рівень 3: некоректне тіло — BadBody', () async {
      final client = _clientReplying((_) => http.Response('<html>', 200));
      await expectLater(client.fetch(2026), throwsA(isA<BadBody>()));
    });
  });

  test('свято в навчальний день скасовує заняття цього дня', () {
    final lessons = [for (final r in timetableRows.take(4)) Lesson.fromCsv(r)];
    final lost = lessonsLostToHolidays(lessons, [
      (date: DateTime.utc(2026, 8, 24), name: 'День Незалежності'),
      (date: DateTime.utc(2026, 8, 23), name: 'Неділя'),
    ]);
    expect(lost.keys.single.name, 'День Незалежності');
    expect(
      lost.values.single.every((l) => l.weekday == Weekday.monday),
      isTrue,
    );
  });
}
