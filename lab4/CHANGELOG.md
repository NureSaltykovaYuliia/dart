## 4.0.0

- ЛР4: структура пакета (`bin/`, `lib/src/`, фасад `lib/group_schedule_app.dart`).
- Команди `import`, `list`, `stats`, `holidays` (пакет `args`) і коди завершення.
- JSON-сховище, потокове читання CSV (`openRead`), `toJson`/`fromJson`.
- Клієнт REST API свят із трьома рівнями відмов.
- HTTP-сервіс на `shelf`: `GET /items`, `GET /items/<id>`, `POST /items`, middleware журналювання.
- 30 модульних тестів, мережа в тестах підмінена `MockClient`.
