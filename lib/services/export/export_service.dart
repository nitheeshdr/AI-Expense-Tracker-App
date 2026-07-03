import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/repositories.dart';

/// Exports all transactions as a CSV file and opens the system share sheet
/// (save to Drive/Files, mail it, etc.).
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  String _csvEscape(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  Future<int> shareCsv(TransactionRepository repo) async {
    final txns = await repo.all();
    final df = DateFormat('yyyy-MM-dd HH:mm');

    final buf = StringBuffer(
        'date,type,amount,category,merchant,payment_method,bank,reference,note,source\n');
    for (final t in txns) {
      buf.writeln([
        df.format(t.date),
        t.type.name,
        t.amount.toStringAsFixed(2),
        _csvEscape(t.category),
        _csvEscape(t.merchant),
        _csvEscape(t.paymentMethod ?? ''),
        _csvEscape(t.bank ?? ''),
        _csvEscape(t.referenceNo ?? ''),
        _csvEscape(t.note ?? ''),
        t.source.name,
      ].join(','));
    }

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/expenses_$stamp.csv');
    await file.writeAsString(buf.toString());

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: 'AI Expense Tracker export',
    ));
    return txns.length;
  }
}
