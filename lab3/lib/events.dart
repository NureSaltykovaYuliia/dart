/// Події розкладу та джерело подій на `StreamController`.
library;

import 'dart:async';

import 'lesson.dart';

/// Подія зміни розкладу.
sealed class ScheduleEvent {
  /// Створює подію про заняття [lesson].
  const ScheduleEvent(this.lesson);

  /// Заняття, якого стосується подія.
  final Lesson lesson;
}

/// Заняття додано до розкладу.
final class LessonAdded extends ScheduleEvent {
  /// Створює подію додавання.
  const LessonAdded(super.lesson);
}

/// Заняття скасовано.
final class LessonCancelled extends ScheduleEvent {
  /// Створює подію скасування з причиною [reason].
  const LessonCancelled(super.lesson, this.reason);

  /// Причина скасування.
  final String reason;
}

/// Заняття перенесено в іншу аудиторію.
final class RoomChanged extends ScheduleEvent {
  /// Створює подію зміни аудиторії з [oldRoom] на аудиторію заняття.
  const RoomChanged(super.lesson, this.oldRoom);

  /// Попередня аудиторія.
  final String oldRoom;
}

/// Короткий текст події для виводу.
String describeEvent(ScheduleEvent event) => switch (event) {
  LessonAdded(:final lesson) => '+ ${lesson.subject}',
  LessonCancelled(:final lesson, :final reason) =>
    '− ${lesson.subject} ($reason)',
  RoomChanged(:final lesson, :final oldRoom) =>
    '→ ${lesson.subject}: ауд.$oldRoom → ауд.${lesson.room}',
};

/// Джерело подій розкладу.
///
/// Потік одноразової підписки буферизує події, додані до появи слухача;
/// широкомовний потік такі події втрачає.
class ScheduleEvents {
  /// Створює джерело; [broadcast] обирає широкомовний потік.
  ScheduleEvents({bool broadcast = false})
    : _controller = broadcast
          ? StreamController<ScheduleEvent>.broadcast()
          : StreamController<ScheduleEvent>();

  final StreamController<ScheduleEvent> _controller;

  /// Потік подій.
  Stream<ScheduleEvent> get stream => _controller.stream;

  /// Публікує подію [event].
  void emit(ScheduleEvent event) => _controller.add(event);

  /// Публікує помилку [error] у потоці.
  void emitError(Object error) => _controller.addError(error);

  /// Закриває потік; підписники отримують подію завершення.
  Future<void> close() => _controller.close();
}
