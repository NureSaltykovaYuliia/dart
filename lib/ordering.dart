/// Порядки занять і їх комбінування.
///
/// Замість однієї функції сортування з набором прапорців тут є малі
/// порядки, які поєднуються: [chain] задає другий критерій на випадок
/// рівності першого, [descending] обертає напрям.
library;

import 'clock.dart';
import 'lesson.dart';

/// Порядок за зростанням значення, яке повертає [key].
LessonOrder ascendingBy(Comparable<Object> Function(Lesson lesson) key) =>
    (a, b) => key(a).compareTo(key(b));

/// Обернений порядок до [order].
LessonOrder descending(LessonOrder order) =>
    (a, b) => order(b, a);

/// Лексикографічне поєднання: кожен наступний порядок у [orders]
/// застосовується, лише коли всі попередні вважають заняття рівними.
LessonOrder chain(List<LessonOrder> orders) =>
    (a, b) => orders
        .map((order) => order(a, b))
        .firstWhere((result) => result != 0, orElse: () => 0);

/// За днем тижня та часом початку.
final LessonOrder byWeekTime = ascendingBy(weekMinute);

/// За прізвищем викладача.
final LessonOrder byLecturer = ascendingBy((l) => l.lecturer);

/// За кількістю пар за семестр.
final LessonOrder byPairs = ascendingBy((l) => l.pairs);

/// Типовий порядок розкладу: день і час, за рівності — викладач.
final LessonOrder timetableOrder = chain([byWeekTime, byLecturer]);

/// Нова впорядкована копія [lessons]; без [order] — [timetableOrder].
List<Lesson> arranged(Iterable<Lesson> lessons, [LessonOrder? order]) =>
    lessons.toList()..sort(order ?? timetableOrder);
