/// Замикання: лічильник і фабрики предикатів.
library;

import 'model.dart';

/// Створює лічильник оброблених записів.
///
/// Повертає запис із двох функцій, які захоплюють одну й ту саму локальну
/// змінну `count`. Змінна живе, доки існує хоча б одна з цих функцій,
/// хоча сам виклик `makeCounter` уже завершився.
({void Function() increment, int Function() value}) makeCounter() {
  var count = 0;
  return (increment: () => count++, value: () => count);
}

/// Фабрика предикатів: створює фільтр занять типу [type].
///
/// Повернена функція захоплює параметр [type].
LessonPredicate makeTypeFilter(String type) =>
    (lesson) => lesson.type == type;

/// Фабрика предикатів: створює фільтр занять, що починаються
/// не раніше години [hour].
LessonPredicate makeStartsFromFilter(int hour) =>
    (lesson) => lesson.start.hour >= hour;

/// Фабрика предикатів: створює фільтр занять у день [dayOfWeek].
LessonPredicate makeDayFilter(int dayOfWeek) =>
    (lesson) => lesson.dayOfWeek == dayOfWeek;

/// Поєднує кілька предикатів [predicates] логічним «І».
LessonPredicate allOf(List<LessonPredicate> predicates) =>
    (lesson) => predicates.every((p) => p(lesson));
