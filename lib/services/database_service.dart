import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/daily_record.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finguard.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_records (
        date TEXT PRIMARY KEY,
        totalSpent REAL NOT NULL DEFAULT 0,
        carryForward REAL NOT NULL DEFAULT 0,
        dailyLimit REAL NOT NULL DEFAULT 160
      )
    ''');
  }

  // ── Expense Operations ──

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    final id = await db.insert('expenses', expense.toMap());
    await _updateTotalSpent(expense.date);
    return id;
  }

  Future<void> deleteExpense(int id, String date) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    await _updateTotalSpent(date);
  }

  Future<List<Expense>> getExpensesForDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<double> getTotalSpentForDate(String date) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date = ?',
      [date],
    );
    return (result.first['total'] as num).toDouble();
  }

  // ── Daily Record Operations ──

  Future<void> _updateTotalSpent(String date) async {
    final total = await getTotalSpentForDate(date);
    final db = await database;
    await db.rawUpdate(
      'UPDATE daily_records SET totalSpent = ? WHERE date = ?',
      [total, date],
    );
  }

  Future<void> upsertDailyRecord(DailyRecord record) async {
    final db = await database;
    await db.insert(
      'daily_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DailyRecord?> getDailyRecord(String date) async {
    final db = await database;
    final maps = await db.query(
      'daily_records',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isEmpty) return null;
    return DailyRecord.fromMap(maps.first);
  }

  Future<DailyRecord?> getPreviousDayRecord(String todayDate) async {
    final today = DateFormat('yyyy-MM-dd').parse(todayDate);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
    return getDailyRecord(yesterdayStr);
  }

  Future<List<DailyRecord>> getWeeklyRecords() async {
    final db = await database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final weekAgo = DateFormat('yyyy-MM-dd').format(
      DateTime.now().subtract(const Duration(days: 6)),
    );
    final maps = await db.query(
      'daily_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [weekAgo, today],
      orderBy: 'date ASC',
    );
    return maps.map((m) => DailyRecord.fromMap(m)).toList();
  }
}
