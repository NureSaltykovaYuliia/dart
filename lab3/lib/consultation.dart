/// Консультація викладача — слот, що не є заняттям розкладу.
library;

import 'clock.dart';
import 'time_slot.dart';

/// Щотижнева консультація викладача.
///
/// Оголошена первинним конструктором: поля, їхні типи й конструктор
/// записані в одному місці, а тіло містить лише поведінку.
// ignore: public_member_api_docs (лінт ще не знає про первинні конструктори)
class const Consultation({
  /// Викладач, який проводить консультацію.
  required final String lecturer,
  required super.weekday,
  required super.startMinutes,

  /// Аудиторія консультації.
  required final String room,
}) extends TimeSlot with Schedulable implements Identifiable {
  @override
  String get id => 'consultation/$lecturer/${weekday.label}';

  @override
  String toString() =>
      'Consultation($lecturer, ${weekday.label} ${hhmm(startMinutes)}, '
      'ауд.$room)';
}
