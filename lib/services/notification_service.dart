import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/credit.dart';
import '../domain/card_calculator.dart';

const String _channelId = 'vencimientos';
const String _channelName = 'Vencimientos';
const String _channelDescription =
    'Avisos de vencimiento de cuotas y pagos de tarjeta';

/// Local (on-device only, no backend) due-date reminder notifications.
///
/// Notification ids are derived deterministically from the credit id, the
/// item within that credit (installment number, or a fixed slot for a
/// card's single due date), and how many days before the due date this
/// particular notification fires — so the same credit/item/day-offset
/// always maps to the same id, letting us cancel/replace a specific
/// credit's notifications without persisting an id→credit mapping.
///
/// id layout: `bucket * 1000 + itemSlot * 10 + dayOffset`
///   - `bucket`: hash of the credit id (0..99999)
///   - `itemSlot`: installment number (0..98) for loans, fixed 99 for a
///     card's due date
///   - `dayOffset`: 1..7, how many days before the due date this specific
///     reminder fires (only >1 when "repeat daily" is on; single-shot mode
///     always uses `daysBefore` as the offset)
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int _itemSlotCount = 100; // items per credit bucket
  static const int _dayOffsetCount = 10; // offsets per item (0..9 used, 1..7 valid)
  static const int _cardSlot = 99;

  int _bucketFor(String creditId) => creditId.hashCode.abs() % 100000;

  int _idFor(String creditId, int itemSlot, int dayOffset) =>
      _bucketFor(creditId) * _itemSlotCount * _dayOffsetCount +
      (itemSlot % _itemSlotCount) * _dayOffsetCount +
      (dayOffset % _dayOffsetCount);

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Bogota'));
    } catch (_) {
      // Fall back to whatever the device's default local timezone resolves
      // to if the fixed zone lookup ever fails.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );
    await _plugin.initialize(settings: initSettings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime day,
    required TimeOfDay time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(
      tz.local,
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) return; // don't schedule notifications in the past

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // If exact alarms aren't permitted on this device (permission revoked
      // by the user), fall back to inexact scheduling rather than failing
      // silently to schedule nothing at all.
      debugPrint('NotificationService: exact schedule failed ($e), retrying inexact');
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduled,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e2) {
        debugPrint('NotificationService: inexact schedule also failed ($e2)');
      }
    }
  }

  /// Schedules the reminder(s) for a single due date (an installment or a
  /// card's payment date), honoring `repeatDaily`:
  ///   - off: a single reminder, `daysBefore` days ahead.
  ///   - on: one reminder per day from `daysBefore` days ahead down to the
  ///     due date itself (offset 0 included), so the user gets a daily
  ///     nudge throughout the whole warning window.
  Future<void> _scheduleWindow({
    required String creditId,
    required int itemSlot,
    required DateTime dueDate,
    required int daysBefore,
    required TimeOfDay time,
    required bool repeatDaily,
    required String Function(int daysRemaining) titleBuilder,
    required String body,
  }) async {
    if (!repeatDaily) {
      await _scheduleAt(
        id: _idFor(creditId, itemSlot, daysBefore),
        title: titleBuilder(daysBefore),
        body: body,
        day: dueDate.subtract(Duration(days: daysBefore)),
        time: time,
      );
      return;
    }
    for (var offset = daysBefore; offset >= 0; offset--) {
      await _scheduleAt(
        id: _idFor(creditId, itemSlot, offset),
        title: titleBuilder(offset),
        body: body,
        day: dueDate.subtract(Duration(days: offset)),
        time: time,
      );
    }
  }

  /// Schedules due-date reminders for a single credit.
  Future<void> scheduleForCredit(
    Credit credit,
    int daysBefore, {
    TimeOfDay time = const TimeOfDay(hour: 9, minute: 0),
    bool repeatDaily = false,
  }) async {
    if (credit is LoanCredit) {
      for (final inst in credit.installments) {
        if (inst.paid) continue;
        final due = DateTime.tryParse(inst.dueDate);
        if (due == null) continue;
        await _scheduleWindow(
          creditId: credit.id,
          itemSlot: inst.number,
          dueDate: due,
          daysBefore: daysBefore,
          time: time,
          repeatDaily: repeatDaily,
          titleBuilder: (daysRemaining) => daysRemaining == 0
              ? 'Cuota #${inst.number} vence hoy'
              : 'Cuota #${inst.number} próxima a vencer',
          body: '${credit.name}: vence el ${inst.dueDate}',
        );
      }
    } else if (credit is CardCredit) {
      if (credit.currentBalance <= 0) return;
      final dueDate = getCardCycleDates(credit).dueDate;
      await _scheduleWindow(
        creditId: credit.id,
        itemSlot: _cardSlot,
        dueDate: dueDate,
        daysBefore: daysBefore,
        time: time,
        repeatDaily: repeatDaily,
        titleBuilder: (daysRemaining) => daysRemaining == 0
            ? 'Pago de tarjeta vence hoy'
            : 'Pago de tarjeta próximo a vencer',
        body: '${credit.name}: fecha límite de pago próxima',
      );
    }
  }

  /// Cancels every notification previously scheduled for [creditId].
  Future<void> cancelForCredit(String creditId) async {
    final bucket = _bucketFor(creditId);
    final base = bucket * _itemSlotCount * _dayOffsetCount;
    for (var slot = 0; slot < _itemSlotCount; slot++) {
      for (var offset = 0; offset < _dayOffsetCount; offset++) {
        await _plugin.cancel(id: base + slot * _dayOffsetCount + offset);
      }
    }
  }

  /// Cancels everything and reprograms all reminders from scratch. This is
  /// the simplest way to keep scheduled notifications in sync with the
  /// current credit list — call it whenever the credits list, or the
  /// notification settings, change.
  Future<void> rescheduleAll(
    List<Credit> credits,
    int daysBefore, {
    TimeOfDay time = const TimeOfDay(hour: 9, minute: 0),
    bool repeatDaily = false,
  }) async {
    await init();
    await _plugin.cancelAll();
    for (final credit in credits) {
      await scheduleForCredit(
        credit,
        daysBefore,
        time: time,
        repeatDaily: repeatDaily,
      );
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
