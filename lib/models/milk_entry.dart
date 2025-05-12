class MilkEntry {
  final DateTime date;
  final double liters;

  MilkEntry({required this.date, required this.liters});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'liters': liters,
      };

  factory MilkEntry.fromJson(Map<String, dynamic> json) {
    return MilkEntry(
      date: DateTime.parse(json['date']),
      liters: json['liters'],
    );
  }
}