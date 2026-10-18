/// HTTP-сервіс розкладу на базі `shelf`.
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'lesson.dart';
import 'repository.dart';
import 'rules.dart';

/// Заголовок типу вмісту для JSON з явним кодуванням.
const Map<String, String> jsonHeaders = {
  'content-type': 'application/json; charset=utf-8',
};

/// Порт сервера за замовчуванням.
const int defaultPort = 8080;

/// Відповідь [status] з JSON-тілом [body] у кодуванні UTF-8.
Response jsonResponse(
  int status,
  Object? body, {
  Map<String, String> headers = const {},
}) => Response(
  status,
  body: jsonEncode(body),
  headers: {...jsonHeaders, ...headers},
);

/// Проміжний обробник: пише рядок «МЕТОД шлях → код» у [sink].
Middleware logRequestsTo(StringSink sink) =>
    (inner) => (request) async {
      final response = await inner(request);
      sink.writeln(
        '${request.method} /${request.url} → ${response.statusCode}',
      );
      return response;
    };

/// Будує маршрутизатор сервісу над сховищем [repo].
///
/// [onChange] викликається після успішного додавання (наприклад, щоб
/// зберегти розклад у файл).
Router buildRouter(
  Repository<Lesson> repo, {
  Future<void> Function(Iterable<Lesson> lessons)? onChange,
}) {
  final router = Router();

  router.get('/items', (Request request) {
    final query = request.url.queryParameters;
    final kind = query['kind'];
    final day = int.tryParse(query['day'] ?? '');
    final text = query['q']?.toLowerCase();
    final items = repo.where(
      (l) =>
          (kind == null || l.kind == kind) &&
          (day == null || l.weekday.number == day) &&
          (text == null || l.subject.toLowerCase().contains(text)),
    );
    return jsonResponse(200, [for (final l in items) l.toJson()]);
  });

  router.get('/items/<id>', (Request request, String id) {
    final lesson = repo.findById(Uri.decodeComponent(id));
    if (lesson == null) {
      return jsonResponse(404, {'error': 'заняття "$id" не знайдено'});
    }
    return jsonResponse(200, lesson.toJson());
  });

  router.post('/items', (Request request) async {
    final Lesson lesson;
    try {
      final decoded = jsonDecode(await request.readAsString());
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('очікувався JSON-об\'єкт');
      }
      lesson = Lesson.fromJson(decoded);
    } on FormatException catch (e) {
      return jsonResponse(400, {'error': e.message});
    }

    final problems = problemsOf(lesson);
    if (problems.isNotEmpty) {
      return jsonResponse(400, {
        'error': 'порушено правила',
        'problems': problems,
      });
    }
    if (repo.findById(lesson.id) != null) {
      return jsonResponse(409, {'error': 'заняття "${lesson.id}" уже існує'});
    }
    repo.add(lesson);
    await onChange?.call(repo.all);
    return jsonResponse(
      201,
      lesson.toJson(),
      headers: {'location': '/items/${Uri.encodeComponent(lesson.id)}'},
    );
  });

  return router;
}

/// Повний обробник із журналюванням запитів у [log].
Handler buildHandler(
  Repository<Lesson> repo, {
  required StringSink log,
  Future<void> Function(Iterable<Lesson> lessons)? onChange,
}) => const Pipeline()
    .addMiddleware(logRequestsTo(log))
    .addHandler(buildRouter(repo, onChange: onChange).call);
