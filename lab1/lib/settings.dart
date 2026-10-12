/// Налаштування предметної області: формат рядка, межі значень,
/// сітка пар, типи занять і параметри звіту.
///
/// Значення згруповано за змістом, щоб правило перевірки змінювалося
/// в одному місці, а не шукалося по всьому коду.
library;

// ── Формат вхідного рядка ──────────────────────────────────────────────────

/// Символ, що відділяє поля одного запису.
const String cellDelimiter = ';';

/// Назви колонок вхідного рядка в порядку їх слідування.
///
/// Довжина списку задає очікувану кількість полів, а назви
/// використовуються в повідомленнях про порожні поля.
const List<String> columns = [
  'дисципліна',
  'викладач',
  'тип',
  'день',
  'час',
  'аудиторія',
  'пар',
  'внесено',
];

// ── Межі значень ───────────────────────────────────────────────────────────

/// Допустимі межі числових полів заняття: навчальні дні тижня
/// (за нумерацією `DateTime.weekday`) і кількість пар за семестр.
const ({int firstDay, int lastDay, int minPairs, int maxPairs}) bounds = (
  firstDay: DateTime.monday,
  lastDay: DateTime.saturday,
  minPairs: 1,
  maxPairs: 32,
);

// ── Календар і сітка пар ───────────────────────────────────────────────────

/// Короткі назви днів тижня за номером `DateTime.weekday`.
const Map<int, String> weekdayLabels = {
  DateTime.monday: 'Пн',
  DateTime.tuesday: 'Вт',
  DateTime.wednesday: 'Ср',
  DateTime.thursday: 'Чт',
  DateTime.friday: 'Пт',
  DateTime.saturday: 'Сб',
  DateTime.sunday: 'Нд',
};

/// Сітка розкладу університету: час початку кожної пари.
const List<String> pairGrid = [
  '07:45',
  '09:30',
  '11:15',
  '13:10',
  '14:55',
  '16:40',
  '18:25',
];

/// Тривалість однієї пари.
const Duration pairLength = Duration(minutes: 95);

/// Скільки академічних годин містить одна пара.
const int hoursPerPair = 2;

/// Кількість хвилин у тижні — період повторення розкладу.
const int minutesPerWeek = Duration.minutesPerDay * DateTime.daysPerWeek;

/// Горизонт, у межах якого заняття вважається найближчим.
const Duration soonHorizon = Duration(days: 2);

// ── Типи занять ────────────────────────────────────────────────────────────

/// Лекція.
const String kindLecture = 'лекція';

/// Практичне заняття.
const String kindPractice = 'практика';

/// Лабораторна робота.
const String kindLab = 'лабораторна';

/// Усі типи занять, які приймає програма.
const Set<String> knownKinds = {kindLecture, kindPractice, kindLab};

// ── Звіт ───────────────────────────────────────────────────────────────────

/// Скільки рядків таблиці виводить звіт, якщо не вказано інше.
const int defaultReportRows = 5;

/// Роздільник комірок таблиці звіту за замовчуванням.
const String defaultCellGap = ' | ';

/// Ширина колонок таблиці звіту.
const ({int subject, int room}) columnWidths = (subject: 24, room: 8);

/// Символ, яким приховуються літери прізвища викладача.
const String maskSymbol = '*';

/// Кількість знаків після коми для середніх значень.
const int averageDigits = 1;
