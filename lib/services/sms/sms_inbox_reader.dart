import 'dart:ui';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/widgets.dart';

import '../../core/data/models.dart';
import '../../core/data/repositories.dart';
import '../../core/utils/formatters.dart';
import '../notifications/notification_service.dart';
import 'sms_parser.dart';

/// Top-level so the background isolate can keep it (vm:entry-point). Parses an
/// incoming SMS, stores it, and notifies — runs even when the app is closed.
@pragma('vm:entry-point')
Future<void> smsBackgroundHandler(SmsMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final body = message.body;
  if (body == null || body.isEmpty) return;
  final parsed = SmsParser.parse(body);
  if (parsed == null) return;
  final txn = entityFromParsed(
      parsed, DateTime.now().millisecondsSinceEpoch, message.address);
  try {
    await TransactionRepository().upsert(txn);
    final isIncome = txn.type == TxnType.income;
    await AppNotifications.instance.show(
      isIncome ? 'Money received' : 'Expense captured',
      '${Money.signed(isIncome ? txn.amount : -txn.amount)} · ${txn.merchant}',
    );
  } catch (_) {
    // Background best-effort; ignore failures.
  }
}

/// Builds a transaction entity from a parsed SMS (shared by inbox + realtime +
/// background paths). Stable id prevents duplicate rows on re-import.
TransactionEntity entityFromParsed(ParsedSms p, int dateMs, String? sender) {
  return TransactionEntity(
    id: 'sms_${dateMs}_${p.amount.toStringAsFixed(0)}_${p.referenceNo ?? p.merchant ?? sender ?? ''}'
        .replaceAll(RegExp(r'\s+'), '_'),
    amount: p.amount,
    type: p.isCredit ? TxnType.income : TxnType.expense,
    category: p.category,
    merchant: p.merchant ?? p.bank ?? sender ?? 'Bank',
    date: DateTime.fromMillisecondsSinceEpoch(dateMs),
    paymentMethod: p.paymentMethod,
    bank: p.bank,
    referenceNo: p.referenceNo,
    source: TxnSource.sms,
  );
}

/// Reads the device SMS inbox (Android), parses bank/UPI messages via
/// [SmsParser], and returns ready-to-store [TransactionEntity] objects.
class SmsInboxReader {
  final Telephony _telephony = Telephony.instance;

  /// Requests SMS read permission. Returns true if granted.
  Future<bool> requestPermission() async {
    final granted = await _telephony.requestSmsPermissions;
    return granted ?? false;
  }

  /// Starts the incoming-SMS listener. Foreground messages call [onTransaction];
  /// messages received while the app is closed are handled in the background
  /// isolate by [smsBackgroundHandler] (stored + notified automatically).
  void startListening(void Function(TransactionEntity) onTransaction) {
    _telephony.listenIncomingSms(
      onNewMessage: (message) {
        final body = message.body;
        if (body == null || body.isEmpty) return;
        final parsed = SmsParser.parse(body);
        if (parsed == null) return;
        onTransaction(entityFromParsed(
            parsed, DateTime.now().millisecondsSinceEpoch, message.address));
      },
      onBackgroundMessage: smsBackgroundHandler,
      listenInBackground: true,
    );
  }

  /// Reads the inbox and converts recognizable transaction SMS into entities.
  /// [sinceDays] limits how far back we scan (default ~6 months).
  Future<List<TransactionEntity>> importTransactions({int sinceDays = 180}) async {
    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
    );

    final cutoff = DateTime.now()
        .subtract(Duration(days: sinceDays))
        .millisecondsSinceEpoch;

    final out = <TransactionEntity>[];
    for (final m in messages) {
      final body = m.body;
      if (body == null || body.isEmpty) continue;
      final dateMs = m.date ?? DateTime.now().millisecondsSinceEpoch;
      if (dateMs < cutoff) continue;

      final parsed = SmsParser.parse(body);
      if (parsed == null) continue;

      out.add(entityFromParsed(parsed, dateMs, m.address));
    }
    return out;
  }
}
