import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/models.dart';
import '../../services/sms/sms_inbox_reader.dart';

enum SmsImportPhase { idle, requesting, importing, done, denied, unsupported }

class SmsImportState {
  final SmsImportPhase phase;
  final int imported;
  final String? message;
  const SmsImportState({
    this.phase = SmsImportPhase.idle,
    this.imported = 0,
    this.message,
  });

  SmsImportState copyWith({SmsImportPhase? phase, int? imported, String? message}) =>
      SmsImportState(
        phase: phase ?? this.phase,
        imported: imported ?? this.imported,
        message: message,
      );
}

final smsInboxReaderProvider =
    Provider<SmsInboxReader>((ref) => SmsInboxReader());

/// Requests SMS permission, reads + parses the inbox, and stores recognized
/// bank/UPI transactions. Idempotent: stable ids prevent duplicate rows.
class SmsImportController extends Notifier<SmsImportState> {
  @override
  SmsImportState build() => const SmsImportState();

  bool _listening = false;

  /// Begins foreground real-time listening: new bank/UPI SMS are parsed, stored
  /// and surfaced via [onAdded] (used to show a snackbar). No-ops off Android.
  void startRealtime(void Function(TransactionEntity) onAdded) {
    if (_listening || !Platform.isAndroid) return;
    _listening = true;
    final reader = ref.read(smsInboxReaderProvider);
    reader.startListening((txn) async {
      await ref.read(transactionRepoProvider).upsert(txn);
      ref.read(dataRevisionProvider.notifier).bump();
      onAdded(txn);
    });
  }

  Future<void> importInbox() async {
    if (!Platform.isAndroid) {
      state = const SmsImportState(
        phase: SmsImportPhase.unsupported,
        message: 'SMS reading is available on Android only.',
      );
      return;
    }

    final reader = ref.read(smsInboxReaderProvider);

    state = state.copyWith(phase: SmsImportPhase.requesting);
    final granted = await reader.requestPermission();
    if (!granted) {
      state = const SmsImportState(
        phase: SmsImportPhase.denied,
        message: 'SMS permission denied. Grant it to auto-import transactions.',
      );
      return;
    }

    state = state.copyWith(phase: SmsImportPhase.importing);
    try {
      final txns = await reader.importTransactions();
      final repo = ref.read(transactionRepoProvider);
      for (final t in txns) {
        await repo.upsert(t);
      }
      ref.read(dataRevisionProvider.notifier).bump();
      state = SmsImportState(
        phase: SmsImportPhase.done,
        imported: txns.length,
        message: txns.isEmpty
            ? 'No bank transactions found in your recent SMS.'
            : 'Imported ${txns.length} transactions from SMS.',
      );
    } catch (e) {
      state = SmsImportState(
        phase: SmsImportPhase.denied,
        message: 'Could not read SMS: $e',
      );
    }
  }
}

final smsImportProvider =
    NotifierProvider<SmsImportController, SmsImportState>(
        SmsImportController.new);
