import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../sms/sms_parser.dart';
import 'integrations.dart';

/// On-device receipt OCR via Google ML Kit's text recognizer — the image
/// never leaves the phone, matching the app's on-device-data promise
/// elsewhere (SMS parsing, transaction storage).
///
/// Parsing a receipt's total reliably is inherently heuristic: we look for
/// a line containing a "total"-style keyword first (most reliable), and
/// fall back to the largest cents-precision amount on the receipt if no
/// such line is found.
class MlKitOcrService implements OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  IntegrationStatus get status => IntegrationStatus.ready;

  @override
  Future<ParsedSms?> scan(String path) async {
    try {
      final result =
          await _recognizer.processImage(InputImage.fromFilePath(path));
      return _parse(result.text);
    } catch (_) {
      return null;
    }
  }

  void dispose() => _recognizer.close();

  static final _decimalAmount = RegExp(r'\d+\.\d{2}');
  static final _plainAmount = RegExp(r'\d+');
  static const _totalKeywords = [
    'grand total',
    'total amount',
    'net amount',
    'amount due',
    'balance due',
    'total due',
    'total',
  ];

  ParsedSms? _parse(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    final amount = _extractTotal(lines) ?? _extractLargestDecimalAmount(text);
    if (amount == null || amount <= 0) return null;

    return ParsedSms(
      amount: amount,
      isCredit: false,
      merchant: _extractMerchant(lines),
      category: 'Miscellaneous',
    );
  }

  double? _amountInLine(String line) {
    final cleaned = line.replaceAll(',', '');
    final decimal = _decimalAmount.firstMatch(cleaned);
    if (decimal != null) return double.tryParse(decimal.group(0)!);
    final plain = _plainAmount.firstMatch(cleaned);
    if (plain != null) return double.tryParse(plain.group(0)!);
    return null;
  }

  double? _extractTotal(List<String> lines) {
    for (final keyword in _totalKeywords) {
      for (final line in lines) {
        if (line.toLowerCase().contains(keyword)) {
          final value = _amountInLine(line);
          if (value != null && value > 0) return value;
        }
      }
    }
    return null;
  }

  double? _extractLargestDecimalAmount(String text) {
    double? largest;
    for (final match in _decimalAmount.allMatches(text.replaceAll(',', ''))) {
      final value = double.tryParse(match.group(0)!);
      if (value != null && (largest == null || value > largest)) {
        largest = value;
      }
    }
    return largest;
  }

  /// First short-ish line near the top that reads like a business name
  /// rather than an address/phone/date line.
  String? _extractMerchant(List<String> lines) {
    for (final line in lines.take(5)) {
      final letters = line.replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (letters.length >= 3 && line.length <= 40) return line;
    }
    return null;
  }
}
