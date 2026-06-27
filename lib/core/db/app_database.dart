import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../data/categories.dart';

/// Opens and migrates the local SQLite database. On desktop (macOS/Win/Linux)
/// it routes through the FFI factory so the same code runs everywhere we
/// iterate; on Android/iOS it uses the native plugin.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final bool isDesktop = !kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
    if (isDesktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await databaseFactory.getDatabasesPath();
    final path = p.join(dir, 'ai_expense_tracker.db');
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  /// v1 → v2: remove the old bundled demo data so only real (SMS-imported and
  /// manually added) transactions remain.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.delete('transactions');
      await db.delete('budgets');
      await db.delete('savings_goals');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        merchant TEXT NOT NULL,
        note TEXT,
        date INTEGER NOT NULL,
        payment_method TEXT,
        bank TEXT,
        reference_no TEXT,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        tags TEXT,
        source TEXT NOT NULL DEFAULT 'manual',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_txn_date ON transactions(date DESC)');
    await db.execute(
        'CREATE INDEX idx_txn_category ON transactions(category)');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon_key TEXT NOT NULL,
        color INTEGER NOT NULL,
        parent TEXT,
        is_custom INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        period TEXT NOT NULL DEFAULT 'monthly',
        amount REAL NOT NULL,
        rollover INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target REAL NOT NULL,
        saved REAL NOT NULL DEFAULT 0,
        deadline INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_messages (
        id TEXT PRIMARY KEY,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await _seedCategories(db);
  }

  Future<void> _seedCategories(Database db) async {
    final batch = db.batch();
    for (final c in Categories.all) {
      batch.insert('categories', {
        'name': c.name,
        'icon_key': c.icon.codePoint.toString(),
        'color': c.color.toARGB32(),
        'is_custom': 0,
      });
    }
    await batch.commit(noResult: true);
  }
}
