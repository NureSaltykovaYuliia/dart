/// Модель предметної області «Розклад занять групи».
///
/// Класи в ЛР1 не застосовуються, тому заняття описано іменованим
/// записом (record), а функціональні типи мають власні псевдоніми.
library;

/// Одне заняття з розкладу групи.
///
/// * `subject` — назва дисципліни;
/// * `lecturer` — викладач у форматі `Прізвище І.Б.`;
/// * `kind` — тип заняття (лекція, практика, лабораторна);
/// * `weekday` — день тижня за `DateTime.weekday` (1 — понеділок);
/// * `startMinutes` — початок пари в хвилинах від півночі;
/// * `room` — номер аудиторії з необов'язковою літерою корпусу;
/// * `pairs` — кількість пар за семестр;
/// * `addedOn` — дата внесення запису до розкладу (UTC).
typedef Lesson = ({
  String subject,
  String lecturer,
  String kind,
  int weekday,
  int startMinutes,
  String room,
  int pairs,
  DateTime addedOn,
});

/// Підсумок розбору рядка: `(заняття, null)` у разі успіху
/// або `(null, причина)` у разі відмови.
typedef Decoded = (Lesson?, String?);

/// Умова, якій заняття відповідає або ні.
typedef LessonTest = bool Function(Lesson lesson);

/// Порядок двох занять: від'ємне число — `a` раніше, додатне — пізніше.
typedef LessonOrder = int Function(Lesson a, Lesson b);

/// Правило перевірки: умова коректності та опис порушення.
typedef LessonRule = ({
  LessonTest holds,
  String Function(Lesson lesson) explain,
});

/// Зведення за кількістю пар за семестр.
typedef PairsSummary = ({
  int lessons,
  int sum,
  int fewest,
  int most,
  double mean,
});
