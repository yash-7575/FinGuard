class Expense {
  final int? id;
  final String category;
  final double amount;
  final String? description;
  final String date; // yyyy-MM-dd
  final String createdAt;

  Expense({
    this.id,
    required this.category,
    required this.amount,
    this.description,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date,
      'createdAt': createdAt,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      date: map['date'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}
