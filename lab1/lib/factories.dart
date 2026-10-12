/// Функції, що створюють інші функції із захопленим станом (замикання).
library;

import 'lesson.dart';

/// Обгортає [fn] так, що кожен виклик підраховується.
///
/// `run` викликає [fn] і збільшує захоплену змінну `calls`, `calls`
/// повертає її поточне значення. Обидві функції бачать ту саму змінну,
/// яка живе далі, хоча `countingCalls` уже завершилась.
({R Function(A arg) run, int Function() calls}) countingCalls<A, R>(
  R Function(A arg) fn,
) {
  var calls = 0;
  return (
    run: (arg) {
      calls++;
      return fn(arg);
    },
    calls: () => calls,
  );
}

/// Умова «заняття має тип [kind]».
LessonTest kindIs(String kind) =>
    (l) => l.kind == kind;

/// Умова «заняття починається о [hour]:00 або пізніше».
LessonTest startsNotBefore(int hour) =>
    (l) => l.startMinutes >= hour * Duration.minutesPerHour;

/// Умова «заняття проводиться в день [weekday]».
LessonTest heldOn(int weekday) =>
    (l) => l.weekday == weekday;

/// Умова, що виконується лише тоді, коли виконуються всі [tests].
///
/// Будується згортанням: кожен крок загортає попередню умову в нову.
LessonTest allPass(Iterable<LessonTest> tests) => tests.fold<LessonTest>(
  (_) => true,
  (combined, next) =>
      (l) => combined(l) && next(l),
);
