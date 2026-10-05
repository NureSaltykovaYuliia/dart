/// Типи даних предметної області «Розклад занять групи».
///
/// У лабораторній роботі 1 класи свідомо не використовуються: заняття
/// подається іменованим записом (record), а для зручності читання коду
/// оголошено псевдоніми типів.
library;

/// Час доби: година та хвилина.
typedef TimeOfDay = ({int hour, int minute});

/// Заняття в розкладі групи.
///
/// Поля: дисципліна, викладач (`Прізвище І.Б.`), тип заняття, день тижня
/// (1 — понеділок … 7 — неділя), час початку, аудиторія, кількість пар
/// за семестр і дата внесення запису до розкладу.
typedef Lesson = ({
  String discipline,
  String teacher,
  String type,
  int dayOfWeek,
  TimeOfDay start,
  String room,
  int pairsCount,
  DateTime createdAt,
});

/// Результат розбору одного рядка: або заняття, або опис помилки.
///
/// Рівно одне з полів має значення, інше дорівнює `null`.
typedef ParseResult = ({Lesson? lesson, String? error});

/// Порівнювач двох занять для сортування.
typedef LessonComparator = int Function(Lesson a, Lesson b);

/// Предикат для фільтрації занять.
typedef LessonPredicate = bool Function(Lesson lesson);

/// Агреговані показники кількості пар для набору занять.
typedef PairsStats = ({int count, int total, double average, int min, int max});
