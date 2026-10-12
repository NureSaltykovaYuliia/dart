/// Регулярні вирази та операції над рядками.
library;

import 'settings.dart';

/// Час `ГГ:ХХ`; допустимий діапазон годин і хвилин закладено
/// безпосередньо у вираз, тому `25:00` чи `09:61` не збігаються.
final RegExp clockPattern = RegExp(r'^(?<h>[01]\d|2[0-3]):(?<m>[0-5]\d)$');

/// Календарна дата `РРРР-ММ-ДД`.
final RegExp isoDatePattern = RegExp(r'^(?<y>\d{4})-(?<mo>\d{2})-(?<d>\d{2})$');

/// Викладач `Прізвище І.Б.`: прізвище з великої літери та два ініціали.
///
/// Прапорець `unicode` вмикає класи `\p{Lu}`/`\p{Ll}`, що покривають
/// кирилицю без переліку літер вручну.
final RegExp lecturerPattern = RegExp(
  r"^(?<surname>\p{Lu}[\p{Ll}’'-]+) (?<initials>(?:\p{Lu}\.){2})$",
  unicode: true,
);

/// Аудиторія: 2–3 цифри та, можливо, літера корпусу (`287`, `161и`).
final RegExp roomPattern = RegExp(r'^(?<num>\d{2,3})(?<wing>[а-яіїєґ]?)$');

/// Будь-який непробільний символ першого слова, крім першого.
///
/// Ретроспективна перевірка `(?<=^\S+)` вимагає, щоб перед символом
/// від початку рядка йшли лише непробільні символи.
final RegExp _surnameTail = RegExp(r'(?<=^\S+)\S');

/// Чи записано [name] у форматі `Прізвище І.Б.`.
bool isLecturerName(String name) => lecturerPattern.hasMatch(name);

/// Чи є [room] коректним номером аудиторії.
bool isRoomCode(String room) => roomPattern.hasMatch(room);

/// Літера корпусу з номера [room]; порожній рядок, якщо її немає
/// або номер некоректний.
String wingOf(String room) =>
    roomPattern.firstMatch(room)?.namedGroup('wing') ?? '';

/// Приховує прізвище, залишаючи першу літеру:
/// `Петренко О.В.` → `П******* О.В.`.
String hideSurname(String lecturer) =>
    lecturer.replaceAllMapped(_surnameTail, (_) => maskSymbol);

/// Вирівнює [text] до ширини [width]: довгий текст обрізається
/// з трикрапкою, короткий доповнюється пробілами.
String fitWidth(String text, int width) => text.length > width
    ? text.replaceRange(width - 1, null, '…')
    : text.padRight(width);
