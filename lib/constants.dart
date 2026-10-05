/// Іменовані константи розкладу занять.
///
/// Усі «магічні» числа й рядки зібрано тут, щоб змінювати правила
/// перевірки в одному місці.
library;

/// Роздільник полів у вхідному CSV-подібному рядку.
const String fieldSeparator = ';';

/// Очікувана кількість полів у рядку заняття.
const int fieldCount = 8;

/// Номер першого навчального дня тижня (понеділок).
const int firstStudyDay = DateTime.monday;

/// Номер останнього навчального дня тижня (субота).
const int lastStudyDay = DateTime.saturday;

/// Скорочені назви днів тижня; індекс 0 відповідає понеділку.
const List<String> dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];

/// Мінімальна кількість пар за семестр.
const int minPairs = 1;

/// Максимальна кількість пар за семестр.
const int maxPairs = 32;

/// Кількість академічних годин в одній парі.
const int academicHoursPerPair = 2;

/// Тривалість однієї пари.
const Duration pairDuration = Duration(minutes: 95);

/// Час початку пар за сіткою розкладу університету.
const Set<String> pairStartTimes = {
  '07:45',
  '09:30',
  '11:15',
  '13:10',
  '14:55',
  '16:40',
  '18:25',
};

/// Найбільша допустима година.
const int maxHour = 23;

/// Найбільша допустима хвилина.
const int maxMinute = 59;

/// Тип заняття «лекція».
const String typeLecture = 'лекція';

/// Тип заняття «практика».
const String typePractice = 'практика';

/// Тип заняття «лабораторна».
const String typeLab = 'лабораторна';

/// Множина допустимих типів занять.
const Set<String> allowedTypes = {typeLecture, typePractice, typeLab};

/// Вікно, у межах якого заняття вважається найближчим.
const Duration upcomingWindow = Duration(days: 2);

/// Кількість занять у розділі «найближчі» звіту за замовчуванням.
const int defaultTopCount = 5;

/// Роздільник колонок у звіті за замовчуванням.
const String defaultColumnSeparator = ' | ';

/// Символ, яким маскуються літери прізвища.
const String maskChar = '*';

/// Ширина колонки з назвою дисципліни у звіті.
const int disciplineColumnWidth = 24;

/// Кількість знаків після коми для середніх значень.
const int averageFractionDigits = 1;
