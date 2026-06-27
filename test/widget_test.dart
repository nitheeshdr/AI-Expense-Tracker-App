import 'package:ai_expense_tracker/core/data/categories.dart';
import 'package:ai_expense_tracker/core/utils/date_grouping.dart';
import 'package:ai_expense_tracker/core/utils/formatters.dart';
import 'package:ai_expense_tracker/services/categorization/rule_categorizer.dart';
import 'package:ai_expense_tracker/services/sms/sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SmsParser', () {
    test('parses an HDFC UPI debit', () {
      final r = SmsParser.parse(
          'Rs.450.00 debited from HDFC Bank A/c xx1234 to swiggy via UPI ref 123456789. Not you? Call.');
      expect(r, isNotNull);
      expect(r!.amount, 450.0);
      expect(r.isCredit, isFalse);
      expect(r.bank, 'HDFC');
      expect(r.paymentMethod, 'UPI');
      expect(r.category, 'Food');
      expect(r.referenceNo, '123456789');
    });

    test('parses a Kotak "Sent" UPI debit with a report link', () {
      final r = SmsParser.parse(
          'Sent Rs.1.00 from XXXXXX9700 to THILAC D R on 27/06/2026. UPI ref no. 654402733518. Not you? Tap https://kotk.in/KOTAKD/FiXeUv to report -Kotak');
      expect(r, isNotNull);
      expect(r!.amount, 1.00);
      expect(r.isCredit, isFalse);
      expect(r.bank, 'Kotak');
      expect(r.referenceNo, '654402733518');
    });

    test('parses a salary credit', () {
      final r = SmsParser.parse(
          'INR 92,000.00 credited to your ICICI account towards SALARY on 25-06.');
      expect(r, isNotNull);
      expect(r!.amount, 92000.0);
      expect(r.isCredit, isTrue);
      expect(r.bank, 'ICICI');
    });

    test('returns null for non-transaction text', () {
      expect(SmsParser.parse('Your OTP is 4567'), isNull);
    });

    test('rejects promotional / ad messages', () {
      expect(
          SmsParser.parse(
              'Get Rs.5000 cashback! Apply now for a pre-approved loan. T&C apply'),
          isNull);
      expect(
          SmsParser.parse('FLAT 50% off on Rs.999. Hurry, limited time offer!'),
          isNull);
    });

    test('rejects messages without account/transaction context', () {
      expect(SmsParser.parse('You may have received Rs.100 somewhere'), isNull);
    });

    test('rejects cashback / reward credits', () {
      expect(
          SmsParser.parse(
              'Rs.1899 cashback credited to your account via UPI! Enjoy'),
          isNull);
      expect(
          SmsParser.parse('You earned Rs.50 reward points on your card'),
          isNull);
    });
  });

  group('RuleCategorizer', () {
    test('maps known merchants', () {
      expect(RuleCategorizer.categorize('Uber trip'), 'Taxi');
      expect(RuleCategorizer.categorize('Netflix'), 'OTT');
      expect(RuleCategorizer.categorize('BigBasket order'), 'Groceries');
    });

    test('falls back to Miscellaneous', () {
      expect(RuleCategorizer.categorize('zzz unknown'), 'Miscellaneous');
    });
  });

  group('DateGrouping', () {
    final now = DateTime(2026, 6, 27, 12);
    test('buckets relative dates', () {
      expect(DateGrouping.bucketFor(now, now: now), DateBucket.today);
      expect(
          DateGrouping.bucketFor(
              now.subtract(const Duration(days: 1)), now: now),
          DateBucket.yesterday);
      expect(
          DateGrouping.bucketFor(
              now.subtract(const Duration(days: 3)), now: now),
          DateBucket.thisWeek);
      expect(DateGrouping.bucketFor(DateTime(2025, 1, 1), now: now),
          DateBucket.older);
    });
  });

  group('Money', () {
    test('formats currency with symbol', () {
      expect(Money.format(1000, code: 'INR'), contains('₹'));
      expect(Money.format(1000, code: 'INR'), contains('1,000'));
    });
    test('signs amounts', () {
      expect(Money.signed(-450, code: 'INR').startsWith('-'), isTrue);
      expect(Money.signed(450, code: 'INR').startsWith('+'), isTrue);
    });
  });

  group('Categories', () {
    test('catalog is non-empty and resolves unknowns', () {
      expect(Categories.all, isNotEmpty);
      expect(Categories.of('NotARealCategory').name, 'Miscellaneous');
    });
  });
}
