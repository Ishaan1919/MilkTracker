import 'package:flutter/material.dart';
import 'package:milk_tracker/models/milk_entry.dart';
import 'package:milk_tracker/services/storage_service.dart';
import '../widgets/calendar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, double> _entries = {};
  double _pricePerLiter = 0.0;
  TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _entries = await _storage.getAllEntries();
    _pricePerLiter = await _storage.getPrice();
    _priceController.text = _pricePerLiter.toString();
    setState(() {});
  }

  void _updateEntry(double liters) async {
    _entries[_selectedDay] = liters;
    await _storage.saveEntry(MilkEntry(date: _selectedDay, liters: liters));
    setState(() {});
  }

  double _getLitersForDay(DateTime day) {
    return _entries[day] ?? _getDefaultFromPrevious(day);
  }

  double _getDefaultFromPrevious(DateTime day) {
    DateTime previousDay = day.subtract(const Duration(days: 1));
    return _entries[previousDay] ?? 0.0;
  }

  double _calculateTotalLitersForMonth(DateTime month) {
    return _entries.entries
        .where((e) =>
            e.key.year == month.year && e.key.month == month.month)
        .fold(0.0, (sum, e) => sum + e.value);
  }

  @override
  Widget build(BuildContext context) {
    double litersToday = _getLitersForDay(_selectedDay);
    double totalLiters = _calculateTotalLitersForMonth(_focusedDay);
    double totalCost = totalLiters * _pricePerLiter;

    return Scaffold(
      appBar: AppBar(title: const Text("Milk Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          CalendarWidget(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            onDaySelected: (selected) {
              setState(() {
                _selectedDay = selected;
              });
            },
          ),
          const SizedBox(height: 16),
          Text("Liters on \${_selectedDay.toLocal().toString().split(' ')[0]}: \$litersToday"),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  double newLiters = await _showLitersDialog();
                  _updateEntry(newLiters);
                },
                child: const Text("Update Liters"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _updateEntry(0),
                child: const Text("No Milk Taken"),
              )
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Price per Liter"),
            onChanged: (value) async {
              double newPrice = double.tryParse(value) ?? 0;
              await _storage.savePrice(newPrice);
              _pricePerLiter = newPrice;
              setState(() {});
            },
          ),
          const SizedBox(height: 20),
          Text("Total Liters: \$totalLiters"),
          Text("Total Cost: ₹\${totalCost.toStringAsFixed(2)}"),
        ]),
      ),
    );
  }

  Future<double> _showLitersDialog() async {
    TextEditingController litersController = TextEditingController();
    double newLiters = 0;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Enter Liters"),
          content: TextField(
            controller: litersController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "e.g., 1.5"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                newLiters = double.tryParse(litersController.text) ?? 0;
                Navigator.of(ctx).pop();
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
    return newLiters;
  }
}