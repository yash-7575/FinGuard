import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/daily_record.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'add_expense_sheet.dart';
import 'settings_screen.dart';
import 'weekly_chart_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();

  double _dailyLimit = 160.0;
  double _totalSpent = 0.0;
  double _carryForward = 0.0;
  List<Expense> _expenses = [];
  bool _limitExceededNotified = false;

  String get _todayStr => DateFormat('yyyy-MM-dd').format(DateTime.now());
  double get _effectiveLimit => _dailyLimit + _carryForward;
  bool get _isExceeded => _totalSpent > _effectiveLimit;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _notifications.initialize();
    await _loadDailyLimit();
    await _ensureTodayRecord();
    await _loadData();
  }

  Future<void> _loadDailyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyLimit = prefs.getDouble('daily_limit') ?? 160.0;
  }

  Future<void> _ensureTodayRecord() async {
    final existing = await _db.getDailyRecord(_todayStr);
    if (existing == null) {
      // Compute carry forward from previous day
      final prev = await _db.getPreviousDayRecord(_todayStr);
      double cf = 0.0;
      if (prev != null) {
        cf = prev.effectiveLimit - prev.totalSpent;
      }

      final record = DailyRecord(
        date: _todayStr,
        totalSpent: 0,
        carryForward: cf,
        dailyLimit: _dailyLimit,
      );
      await _db.upsertDailyRecord(record);
    }
  }

  Future<void> _loadData() async {
    final record = await _db.getDailyRecord(_todayStr);
    final expenses = await _db.getExpensesForDate(_todayStr);

    setState(() {
      _totalSpent = record?.totalSpent ?? 0;
      _carryForward = record?.carryForward ?? 0;
      _dailyLimit = record?.dailyLimit ?? _dailyLimit;
      _expenses = expenses;
    });

    // Trigger notification once when limit is exceeded
    if (_isExceeded && !_limitExceededNotified) {
      _limitExceededNotified = true;
      _notifications.showLimitExceeded();
    }
    if (!_isExceeded) {
      _limitExceededNotified = false;
    }
  }

  Future<void> _addExpense(Expense expense) async {
    await _db.insertExpense(expense);
    await _loadData();
  }

  Future<void> _deleteExpense(Expense expense) async {
    if (expense.id != null) {
      await _db.deleteExpense(expense.id!, expense.date);
      await _loadData();
    }
  }

  void _openAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddExpenseSheet(
        onSave: (category, amount, description) {
          final expense = Expense(
            category: category,
            amount: amount,
            description: description,
            date: _todayStr,
            createdAt: DateTime.now().toIso8601String(),
          );
          _addExpense(expense);
        },
      ),
    );
  }

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    // Reload in case limit changed
    await _loadDailyLimit();

    // Update today's record with new limit
    final record = await _db.getDailyRecord(_todayStr);
    if (record != null) {
      await _db.upsertDailyRecord(record.copyWith(dailyLimit: _dailyLimit));
    }
    await _loadData();
  }

  void _openWeeklyChart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WeeklyChartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _effectiveLimit > 0 ? (_totalSpent / _effectiveLimit).clamp(0.0, 1.5) : 0.0;
    final themeColor = _isExceeded ? Colors.red : const Color(0xFF2E7D32);
    final balance = _effectiveLimit - _totalSpent;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'FinGuard',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        backgroundColor: _isExceeded ? Colors.red.shade50 : Colors.white,
        foregroundColor: themeColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Weekly Chart',
            onPressed: _openWeeklyChart,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Summary Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: _isExceeded ? Colors.red.shade50 : Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(
                  color: _isExceeded ? Colors.red.shade100 : Colors.grey.shade200,
                ),
              ),
            ),
            child: Column(
              children: [
                // Top row: Carry Forward | Total Spent | Daily Limit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carry Forward (left)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Carry Forward',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${_carryForward.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _carryForward >= 0
                                  ? const Color(0xFF2E7D32)
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Total Spent (center)
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Text(
                            'Today\'s Spending',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${_totalSpent.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: _isExceeded ? Colors.red : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Daily Limit (right)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Daily Limit',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${_dailyLimit.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.toDouble().clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                ),

                const SizedBox(height: 8),

                // Balance text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Effective limit: ₹${_effectiveLimit.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      balance >= 0
                          ? '₹${balance.toStringAsFixed(0)} remaining'
                          : '₹${balance.abs().toStringAsFixed(0)} over',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: balance >= 0
                            ? const Color(0xFF2E7D32)
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Warning Banner ──
          if (_isExceeded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              color: Colors.red.shade600,
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Limit exceeded. Discipline mode activated.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // ── Expense List Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Expenses',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${_expenses.length} entries',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // ── Expense List ──
          Expanded(
            child: _expenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No expenses today',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to add an expense',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _expenses.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final e = _expenses[index];
                      return Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red.shade50,
                          child: Icon(Icons.delete_outline, color: Colors.red.shade400),
                        ),
                        onDismissed: (_) => _deleteExpense(e),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: _isExceeded
                                ? Colors.red.shade50
                                : const Color(0xFFE8F5E9),
                            child: Icon(
                              _categoryIcon(e.category),
                              color: _isExceeded
                                  ? Colors.red.shade400
                                  : const Color(0xFF2E7D32),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            e.category,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: e.description != null &&
                                  e.description!.isNotEmpty
                              ? Text(
                                  e.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: Text(
                            '₹${e.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color:
                                  _isExceeded ? Colors.red : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpenseSheet,
        backgroundColor: themeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_outlined;
      case 'transport':
        return Icons.directions_bus_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'bills':
        return Icons.receipt_outlined;
      case 'health':
        return Icons.medical_services_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
