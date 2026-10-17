/// Узагальнене сховище сутностей з ідентифікатором.
library;

import 'time_slot.dart';

/// Сховище сутностей, які вміють повідомляти власний ідентифікатор.
///
/// Обмеження `T extends Identifiable` дає компілятору право викликати
/// `item.id`; без нього код не скомпілюється.
class Repository<T extends Identifiable> {
  final Map<String, T> _items = {};

  /// Кількість збережених сутностей.
  int get length => _items.length;

  /// Усі збережені сутності в порядку додавання.
  Iterable<T> get all => _items.values;

  /// Додає [item]; сутність із тим самим `id` замінюється.
  void add(T item) => _items[item.id] = item;

  /// Сутність за ідентифікатором [id] або `null`.
  T? findById(String id) => _items[id];

  /// Видаляє сутність [id] і повертає її (або `null`, якщо її не було).
  T? remove(String id) => _items.remove(id);

  /// Сутності, що задовольняють [test].
  Iterable<T> where(bool Function(T item) test) => _items.values.where(test);
}
