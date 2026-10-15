/// Асинхронне сховище сутностей: кожна операція повертає `Future`.
library;

import 'time_slot.dart';

/// Затримка однієї операції сховища за замовчуванням (імітація диска).
const Duration defaultLatency = Duration(milliseconds: 300);

/// Помилка доступу до сховища.
class StorageException implements Exception {
  /// Створює помилку з описом [message].
  const StorageException(this.message);

  /// Опис помилки.
  final String message;

  @override
  String toString() => 'StorageException: $message';
}

/// Асинхронне сховище сутностей предметної області.
///
/// Затримки імітують звернення до зовнішнього джерела; реальні файли
/// й мережа з'являться в лабораторній роботі 4.
class AsyncRepository<T extends Identifiable> {
  /// Створює сховище із затримкою [latency] на кожну операцію.
  ///
  /// Для ідентифікаторів із [brokenIds] читання завершується помилкою.
  AsyncRepository({this.latency = defaultLatency, this._brokenIds = const {}});

  /// Тривалість однієї операції.
  final Duration latency;

  final Set<String> _brokenIds;
  final Map<String, T> _items = {};

  /// Кількість збережених сутностей (синхронний зріз без затримки).
  int get length => _items.length;

  Future<void> _pause() => Future<void>.delayed(latency);

  /// Повертає сутність за ідентифікатором [id] або `null`.
  ///
  /// Кидає [StorageException] для «пошкоджених» ідентифікаторів.
  Future<T?> load(String id) async {
    await _pause();
    if (_brokenIds.contains(id)) {
      throw StorageException('не вдалося прочитати "$id"');
    }
    return _items[id];
  }

  /// Зберігає [item]; сутність з тим самим `id` замінюється.
  Future<void> save(T item) async {
    await _pause();
    _items[item.id] = item;
  }

  /// Видаляє сутність [id]; повертає `true`, якщо вона існувала.
  Future<bool> delete(String id) async {
    await _pause();
    return _items.remove(id) != null;
  }

  /// Повертає всі збережені сутності.
  Future<List<T>> loadAll() async {
    await _pause();
    return _items.values.toList();
  }

  /// Видає сутності по одній у міру «надходження».
  Stream<T> watchAll() async* {
    for (final item in _items.values.toList()) {
      await _pause();
      yield item;
    }
  }
}
