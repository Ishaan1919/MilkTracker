import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/milk_entry.dart';

class StorageService {
  static const _entriesKey = 'milk_entries';
  static const _priceKey = 'milk_price';
  static const _defaultLitersKey = 'default_liters';

Future<void> saveEntry(MilkEntry entry) async {
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString(_entriesKey);
  Map<String, dynamic> entries = data != null ? json.decode(data) : {};

  // Normalize date to remove time (00:00:00)
  final normalizedDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
  entries[normalizedDate.toIso8601String()] = entry.liters;

  prefs.setString(_entriesKey, json.encode(entries));
}


Future<Map<DateTime, double>> getAllEntries() async {
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString(_entriesKey);
  Map<String, dynamic> entries = data != null ? json.decode(data) : {};
  return entries.map((key, value) {
    final date = DateTime.parse(key);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return MapEntry(normalizedDate, value.toDouble());
  });
}


  Future<void> savePrice(double price) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(_priceKey, price);
  }

  Future<double> getPrice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_priceKey) ?? 0.0;
  }

  Future<void> saveDefaultLiters(double liters) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(_defaultLitersKey, liters);
  }

  Future<double> getDefaultLiters() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_defaultLitersKey) ?? 0.0;
}

Future<Map<String, double>> getAllMonthlyDefaults() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys().where((k) => k.startsWith("default_"));
  Map<String, double> defaults = {};
  for (String key in keys) {
    String monthKey = key.replaceFirst("default_", ""); // like "2024-05"
    defaults[monthKey] = prefs.getDouble(key) ?? 0.0;
  }
  return defaults;
}

Future<void> saveMonthlyDefaultLiters(Map<String, double> map) async {
  final prefs = await SharedPreferences.getInstance();
  for (var entry in map.entries) {
    await prefs.setDouble("default_${entry.key}", entry.value);
  }
}


}