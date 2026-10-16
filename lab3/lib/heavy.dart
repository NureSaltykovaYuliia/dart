/// Важке синхронне обчислення та його винесення в ізолят.
library;

import 'dart:isolate';

/// Рахує прості числа до [limit] решетом Ератосфена.
int countPrimes(int limit) {
  if (limit < 2) return 0;
  final composite = List<bool>.filled(limit + 1, false);
  var count = 0;
  for (var n = 2; n <= limit; n++) {
    if (composite[n]) continue;
    count++;
    for (var multiple = n * n; multiple <= limit; multiple += n) {
      composite[multiple] = true;
    }
  }
  return count;
}

/// Те саме обчислення, виконане в окремому ізоляті.
Future<int> countPrimesInIsolate(int limit) =>
    Isolate.run(() => countPrimes(limit));

/// Лічильник, змінюваний у демонстрації «глобальна змінна й ізолят».
int globalCounter = 0;

/// Збільшує [globalCounter] в окремому ізоляті й повертає його значення
/// там; у головному ізоляті змінна не змінюється.
Future<int> bumpCounterInIsolate() => Isolate.run(() {
  globalCounter++;
  return globalCounter;
});
