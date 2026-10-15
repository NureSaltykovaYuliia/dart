/// Перелічення днів тижня.
library;

/// День тижня з номером за `DateTime.weekday` і короткою назвою.
enum Weekday {
  /// Понеділок.
  monday(DateTime.monday, 'Пн'),

  /// Вівторок.
  tuesday(DateTime.tuesday, 'Вт'),

  /// Середа.
  wednesday(DateTime.wednesday, 'Ср'),

  /// Четвер.
  thursday(DateTime.thursday, 'Чт'),

  /// П'ятниця.
  friday(DateTime.friday, 'Пт'),

  /// Субота.
  saturday(DateTime.saturday, 'Сб'),

  /// Неділя.
  sunday(DateTime.sunday, 'Нд');

  /// Створює день тижня з номером [number] і назвою [label].
  const Weekday(this.number, this.label);

  /// Номер дня за `DateTime.weekday` (1 — понеділок).
  final int number;

  /// Коротка назва дня.
  final String label;

  /// Чи проводяться в цей день заняття (неділя — вихідний).
  bool get isStudyDay => this != sunday;

  /// Наступний день тижня; після неділі — понеділок.
  Weekday get next => values[(index + 1) % values.length];

  /// День тижня за номером [number] або `null`, якщо номер не з 1..7.
  static Weekday? fromNumber(int number) =>
      values.where((day) => day.number == number).firstOrNull;
}
