import '../categorization/rule_categorizer.dart';

/// Structured result of parsing a bank/UPI SMS. Pure data — no Flutter deps —
/// so it can be unit-tested without a device.
class ParsedSms {
  final double amount;
  final bool isCredit; // true = money in
  final String? merchant;
  final String? bank;
  final String? paymentMethod;
  final String? referenceNo;
  final String category;

  const ParsedSms({
    required this.amount,
    required this.isCredit,
    this.merchant,
    this.bank,
    this.paymentMethod,
    this.referenceNo,
    required this.category,
  });
}

/// Heuristic parser for Indian bank + UPI transaction SMS. Covers the common
/// formats from SBI, HDFC, ICICI, Axis, Kotak and the major UPI apps. Returns
/// null when the text isn't a recognizable transaction alert.
class SmsParser {
  SmsParser._();

  static const _banks = {
    'sbi': 'SBI',
    'state bank': 'SBI',
    'hdfc': 'HDFC',
    'icici': 'ICICI',
    'axis': 'Axis',
    'kotak': 'Kotak',
    'baroda': 'Bank of Baroda',
    'canara': 'Canara',
    'union bank': 'Union Bank',
    'pnb': 'Punjab National Bank',
    'punjab national': 'Punjab National Bank',
    'idfc': 'IDFC FIRST',
    'federal': 'Federal Bank',
    'indusind': 'IndusInd',
    'yes bank': 'Yes Bank',
    'au small': 'AU Small Finance',
    'indian bank': 'Indian Bank',
  };

  static final _amountRe = RegExp(
    r'(?:rs\.?|inr|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  // Strong action verbs only — avoids matching nouns like "credit card offer".
  static final _creditRe = RegExp(
    r'\b(credited|received|deposited)\b',
    caseSensitive: false,
  );
  static final _debitRe = RegExp(
    r'\b(debited|spent|withdrawn|paid|purchase|sent|transferred|trf)\b',
    caseSensitive: false,
  );
  // Real bank/UPI alerts include account/transaction context.
  static final _contextRe = RegExp(
    r'(a/c|a/c\.|acct|account|\bcard\b|\bupi\b|vpa|imps|neft|rtgs|txn|avl bal|available bal|\bbal\b|\bref\b)',
    caseSensitive: false,
  );
  // Promotional / rewards / advertising markers — reject these outright so
  // only genuine bank debit/credit alerts are captured (no cashback/rewards).
  static final _promoRe = RegExp(
    r'(\boffer\b|\bdiscount\b|% off|\bsale\b|\bdeal\b|voucher|coupon|\bcashback\b|\breward(s|ed)?\b|scratch|\bearn(ed)?\b|redeem|\bpoints\b|loyalty|gift\s?card|wallet|apply now|click here|\bwin\b|congratulat|pre-?approved|lowest|hurry|limited time|buy now|download|register now|t&c|terms apply)',
    caseSensitive: false,
  );
  // "to MERCHANT", "at MERCHANT", "VPA merchant@bank"
  static final _merchantAtRe = RegExp(
    r'\b(?:at|to|towards)\s+([A-Za-z0-9&._\- ]{2,40}?)(?:\s+(?:on|via|ref|upi|a/c|for|dated)\b|[.,]|$)',
    caseSensitive: false,
  );
  static final _vpaRe = RegExp(r'\b([a-zA-Z0-9._\-]{2,})@[a-zA-Z]{2,}\b');
  static final _refRe = RegExp(
    r'(?:upi\s*ref(?:erence)?(?:\s*no)?|ref(?:erence)?(?:\s*no)?|txn(?:\s*id)?)\.?[:\s#-]*([A-Za-z0-9]{6,})',
    caseSensitive: false,
  );

  static ParsedSms? parse(String sms) {
    final text = sms.trim();
    if (text.isEmpty) return null;
    final lower = text.toLowerCase();

    // Reject promotional / advertising messages outright.
    if (_promoRe.hasMatch(lower)) return null;

    final amountMatch = _amountRe.firstMatch(text);
    if (amountMatch == null) return null;
    final amount =
        double.tryParse(amountMatch.group(1)!.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return null;

    // Must be a real debit/credit alert with account/transaction context —
    // this is what separates payment SMS from everything else.
    final hasCredit = _creditRe.hasMatch(lower);
    final hasDebit = _debitRe.hasMatch(lower);
    if (!hasCredit && !hasDebit) return null;
    if (!_contextRe.hasMatch(lower)) return null;

    // If both appear (rare), prefer debit unless "credited" is the action.
    final isCredit = hasCredit && !hasDebit;

    String? bank;
    for (final e in _banks.entries) {
      if (lower.contains(e.key)) {
        bank = e.value;
        break;
      }
    }

    String? merchant;
    final vpa = _vpaRe.firstMatch(text);
    final at = _merchantAtRe.firstMatch(text);
    if (at != null) {
      merchant = at.group(1)!.trim();
    } else if (vpa != null) {
      merchant = vpa.group(1);
    }
    if (merchant != null && merchant.length > 36) {
      merchant = merchant.substring(0, 36).trim();
    }

    String? method;
    if (lower.contains('upi') || vpa != null) {
      method = 'UPI';
    } else if (lower.contains('credit card') || lower.contains('cc ')) {
      method = 'Credit Card';
    } else if (lower.contains('debit card') || lower.contains('atm')) {
      method = 'Debit Card';
    } else if (lower.contains('neft') ||
        lower.contains('imps') ||
        lower.contains('transfer')) {
      method = 'Bank Transfer';
    }

    final ref = _refRe.firstMatch(text)?.group(1);

    final category = RuleCategorizer.categorize(
      merchant ?? text,
      isIncome: isCredit,
    );

    return ParsedSms(
      amount: amount,
      isCredit: isCredit,
      merchant: merchant,
      bank: bank,
      paymentMethod: method,
      referenceNo: ref,
      category: category,
    );
  }
}
