class DailyRecord {
  final String date; // yyyy-MM-dd, primary key
  final double totalSpent;
  final double carryForward;
  final double dailyLimit;

  DailyRecord({
    required this.date,
    required this.totalSpent,
    required this.carryForward,
    required this.dailyLimit,
  });

  double get effectiveLimit => dailyLimit + carryForward;
  double get balance => effectiveLimit - totalSpent;

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalSpent': totalSpent,
      'carryForward': carryForward,
      'dailyLimit': dailyLimit,
    };
  }

  factory DailyRecord.fromMap(Map<String, dynamic> map) {
    return DailyRecord(
      date: map['date'] as String,
      totalSpent: (map['totalSpent'] as num).toDouble(),
      carryForward: (map['carryForward'] as num).toDouble(),
      dailyLimit: (map['dailyLimit'] as num).toDouble(),
    );
  }

  DailyRecord copyWith({
    String? date,
    double? totalSpent,
    double? carryForward,
    double? dailyLimit,
  }) {
    return DailyRecord(
      date: date ?? this.date,
      totalSpent: totalSpent ?? this.totalSpent,
      carryForward: carryForward ?? this.carryForward,
      dailyLimit: dailyLimit ?? this.dailyLimit,
    );
  }
}
