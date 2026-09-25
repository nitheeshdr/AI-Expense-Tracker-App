import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _kGranted = 'sms_granted';
  static const _kLastSync = 'sms_last_sync_ms';

  @override
  SmsImportState build() => const SmsImportState();

  bool _listening = false;
  bool _syncing = false;

  Future<void> _markSynced(SharedPreferences prefs) =>
      prefs.setInt(_kLastSync, DateTime.now().millisecondsSinceEpoch);

  /// Begins foreground real-time listening: new bank/UPI SMS are parsed, stored
  /// and surfaced via [onAdded] (used to show a snackbar). No-ops off Android.
  void startRealtime(void Function(TransactionEntity) onAdded) {
    if (_listening || !Platform.isAndroid) return;
    _listening = true;
    final reader = ref.read(smsInboxReaderProvider);
    reader.startListening((txn) async {
      await ref.read(transactionRepoProvider).upsert(txn);
      ref.read(dataRevisionProvider.notifier).bump();
      _markSynced(await SharedPreferences.getInstance());
      onAdded(txn);
    });
  }

  /// Silent catch-up sync — no permission prompts, no UI state changes. Called
  /// on every app start/resume so bank SMS that arrived while the app (or its
  /// background handler) was dead are still captured automatically. Only runs
  /// once the user has granted SMS access at least once.
  Future<int> silentSync() async {
    if (_syncing || !Platform.isAndroid) return 0;
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kGranted) ?? false)) return 0;
    _syncing = true;
    try {
      // Re-scan a little earlier than the last sync to be safe; stable ids
      // make re-imports idempotent (no duplicates).
      final lastSync = prefs.getInt(_kLastSync) ?? 0;
      final sinceMs = lastSync > 0
          ? lastSync - const Duration(hours: 6).inMilliseconds
          : DateTime.now()
              .subtract(const Duration(days: 180))
              .millisecondsSinceEpoch;
      final reader = ref.read(smsInboxReaderProvider);
      final txns = await reader.importTransactions(sinceMs: sinceMs);
      if (txns.isNotEmpty) {
        final repo = ref.read(transactionRepoProvider);
        for (final t in txns) {
          await repo.upsert(t);
        }
        ref.read(dataRevisionProvider.notifier).bump();
      }
      await _markSynced(prefs);
      return txns.length;
    } catch (_) {
      return 0;
    } finally {
      _syncing = false;
    }
  }

  /// [sinceDays] defaults to the reader's own default (180 days / 6 months).
  /// A larger value is used for the ad-unlocked "deep scan" that looks
  /// further back for older transactions.
  Future<void> importInbox({int? sinceDays}) async {
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
      // Remember that access was granted so silent auto-sync can run on every
      // app start/resume from now on.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kGranted, true);

      final txns = sinceDays == null
          ? await reader.importTransactions()
          : await reader.importTransactions(sinceDays: sinceDays);
      final repo = ref.read(transactionRepoProvider);
      for (final t in txns) {
        await repo.upsert(t);
      }
      await _markSynced(prefs);
      ref.read(dataRevisionProvider.notifier).bump();
      state = SmsImportState(
        phase: SmsImportPhase.done,
        imported: txns.length,
        message: txns.isEmpty
            ? 'No bank transactions found in your recent SMS.'
            : 'Imported ${txns.length} transactions from SMS.',
      );
      // A completed import is a meaningful action (frequency-capped).
      await ref.read(adsManagerProvider).registerActionAndMaybeShow();
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
