import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TxnType { income, expense }

enum TxnSource { manual, sms, receipt, imported, voice }

/// A single money movement.
class TransactionEntity {
  final String id;
  final double amount;
  final TxnType type;
  final String category;
  final String merchant;
  final String? note;
  final DateTime date;
  final String? paymentMethod;
  final String? bank;
  final String? referenceNo;
  final bool isRecurring;
  final List<String> tags;
  final TxnSource source;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionEntity({
    String? id,
    required this.amount,
    required this.type,
    required this.category,
    required this.merchant,
    this.note,
    required this.date,
    this.paymentMethod,
    this.bank,
    this.referenceNo,
    this.isRecurring = false,
    this.tags = const [],
    this.source = TxnSource.manual,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get signedAmount => type == TxnType.income ? amount : -amount;

  TransactionEntity copyWith({
    double? amount,
    TxnType? type,
    String? category,
    String? merchant,
    String? note,
    DateTime? date,
    String? paymentMethod,
    bool? isRecurring,
    List<String>? tags,
  }) =>
      TransactionEntity(
        id: id,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        category: category ?? this.category,
        merchant: merchant ?? this.merchant,
        note: note ?? this.note,
        date: date ?? this.date,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        bank: bank,
        referenceNo: referenceNo,
        isRecurring: isRecurring ?? this.isRecurring,
        tags: tags ?? this.tags,
        source: source,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'category': category,
        'merchant': merchant,
        'note': note,
        'date': date.millisecondsSinceEpoch,
        'payment_method': paymentMethod,
        'bank': bank,
        'reference_no': referenceNo,
        'is_recurring': isRecurring ? 1 : 0,
        'tags': tags.join('||'),
        'source': source.name,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory TransactionEntity.fromMap(Map<String, Object?> m) => TransactionEntity(
        id: m['id'] as String,
        amount: (m['amount'] as num).toDouble(),
        type: TxnType.values.byName(m['type'] as String),
        category: m['category'] as String,
        merchant: m['merchant'] as String,
        note: m['note'] as String?,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        paymentMethod: m['payment_method'] as String?,
        bank: m['bank'] as String?,
        referenceNo: m['reference_no'] as String?,
        isRecurring: (m['is_recurring'] as int) == 1,
        tags: (m['tags'] as String?)?.isNotEmpty == true
            ? (m['tags'] as String).split('||')
            : const [],
        source: TxnSource.values.byName(m['source'] as String? ?? 'manual'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );
}

class BudgetEntity {
  final String id;
  final String category; // 'Overall' for the monthly cap
  final double amount;
  final bool rollover;
  final DateTime createdAt;

  BudgetEntity({
    String? id,
    required this.category,
    required this.amount,
    this.rollover = false,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toMap() => {
        'id': id,
        'category': category,
        'period': 'monthly',
        'amount': amount,
        'rollover': rollover ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory BudgetEntity.fromMap(Map<String, Object?> m) => BudgetEntity(
        id: m['id'] as String,
        category: m['category'] as String,
        amount: (m['amount'] as num).toDouble(),
        rollover: (m['rollover'] as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
}

class SavingsGoalEntity {
  final String id;
  final String name;
  final double target;
  final double saved;
  final DateTime? deadline;
  final DateTime createdAt;

  SavingsGoalEntity({
    String? id,
    required this.name,
    required this.target,
    this.saved = 0,
    this.deadline,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  double get progress => target <= 0 ? 0 : (saved / target).clamp(0, 1);

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'target': target,
        'saved': saved,
        'deadline': deadline?.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory SavingsGoalEntity.fromMap(Map<String, Object?> m) => SavingsGoalEntity(
        id: m['id'] as String,
        name: m['name'] as String,
        target: (m['target'] as num).toDouble(),
        saved: (m['saved'] as num).toDouble(),
        deadline: m['deadline'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['deadline'] as int)
            : null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
}

enum ChatRole { user, assistant }

class ChatMessageEntity {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  ChatMessageEntity({
    String? id,
    required this.role,
    required this.content,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toMap() => {
        'id': id,
        'role': role.name,
        'content': content,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory ChatMessageEntity.fromMap(Map<String, Object?> m) => ChatMessageEntity(
        id: m['id'] as String,
        role: ChatRole.values.byName(m['role'] as String),
        content: m['content'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
}

/// Aggregate rows used by dashboard/analytics (not persisted directly).
class CategoryTotal {
  final String category;
  final double total;
  const CategoryTotal(this.category, this.total);
}

class DayTotal {
  final DateTime day;
  final double total;
  const DayTotal(this.day, this.total);
}

/// A detected recurring bill / subscription / autopay mandate.
class SubscriptionItem {
  final String merchant;
  final String category;
  final double amount;
  final int count;
  final DateTime lastDate;
  const SubscriptionItem({
    required this.merchant,
    required this.category,
    required this.amount,
    required this.count,
    required this.lastDate,
  });
}
