/// Державні свята із зовнішнього REST API та їх вплив на розклад.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'clock.dart';
import 'lesson.dart';
import 'weekday.dart';

/// Адреса сервісу державних свят (відкритий API без ключа).
const String holidaysBaseUrl = 'https://date.nager.at/api/v3/PublicHolidays';

/// Код країни за замовчуванням.
const String defaultCountry = 'UA';

/// Скільки чекати на відповідь сервера.
const Duration requestTimeout = Duration(seconds: 10);

/// Державне свято.
typedef Holiday = ({DateTime date, String name});

/// Невдача отримання свят; підтипи відповідають трьом рівням відмов.
sealed class HolidayFailure implements Exception {
  /// Створює невдачу з описом [message].
  const HolidayFailure(this.message);

  /// Опис невдачі.
  final String message;

  @override
  String toString() => message;
}

/// Рівень 1: немає з'єднання (`SocketException`, `ClientException`).
final class NoConnection extends HolidayFailure {
  /// Створює помилку з'єднання.
  const NoConnection(super.message);
}

/// Рівень 2: сервер відповів кодом, відмінним від 2xx.
final class BadStatus extends HolidayFailure {
  /// Створює помилку статусу [statusCode].
  const BadStatus(this.statusCode) : super('сервер відповів кодом $statusCode');

  /// HTTP-код відповіді.
  final int statusCode;
}

/// Рівень 3: тіло відповіді не є очікуваним JSON (`FormatException`).
final class BadBody extends HolidayFailure {
  /// Створює помилку тіла відповіді.
  const BadBody(super.message);
}

/// Клієнт сервісу свят; HTTP-клієнт передається ззовні, тож у тестах
/// його підміняє `MockClient`.
class HolidayClient {
  /// Створює клієнт поверх [client]; [baseUrl] можна перевизначити в тестах.
  HolidayClient(this._client, {this.baseUrl = holidaysBaseUrl});

  final http.Client _client;

  /// Адреса сервісу.
  final String baseUrl;

  /// Свята країни [country] у році [year].
  ///
  /// Кидає підтип [HolidayFailure] на кожному з трьох рівнів відмов.
  Future<List<Holiday>> fetch(
    int year, {
    String country = defaultCountry,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$baseUrl/$year/$country'))
          .timeout(requestTimeout);
    } on SocketException catch (e) {
      throw NoConnection('немає з\'єднання: ${e.message}');
    } on http.ClientException catch (e) {
      throw NoConnection('помилка клієнта: ${e.message}');
    } on TimeoutException {
      throw const NoConnection('час очікування відповіді вичерпано');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BadStatus(response.statusCode);
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List<Object?>) {
        throw const FormatException('очікувався масив');
      }
      return [
        for (final item in decoded)
          if (item case {
            'date': final String date,
            'localName': final String name,
          })
            (date: _parseDate(date), name: name)
          else
            throw FormatException('невідомий елемент', item),
      ];
    } on FormatException catch (e) {
      throw BadBody('некоректне тіло відповіді: ${e.message}');
    }
  }

  DateTime _parseDate(String raw) =>
      readIsoDate(raw) ?? (throw FormatException('некоректна дата "$raw"'));
}

/// Для кожного свята, що припадає на навчальний день, повертає заняття,
/// які цього дня не відбудуться.
Map<Holiday, List<Lesson>> lessonsLostToHolidays(
  Iterable<Lesson> lessons,
  Iterable<Holiday> holidays,
) {
  final result = <Holiday, List<Lesson>>{};
  for (final holiday in holidays) {
    final day = Weekday.fromNumber(holiday.date.weekday);
    if (day == null || !day.isStudyDay) continue;
    final lost = lessons.where((l) => l.weekday == day).toList();
    if (lost.isNotEmpty) result[holiday] = lost;
  }
  return result;
}
