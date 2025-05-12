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
  TextEditingController _defaultLitersController = TextEditingController();
  double _defaultLiters = 0.0;
  double _calculatedTotalLiters = 0.0;
  double _calculatedTotalCost = 0.0;

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
  final rawEntries = await _storage.getAllEntries();
  _entries = {
    for (var entry in rawEntries.entries)
      DateTime(entry.key.year, entry.key.month, entry.key.day): entry.value
  };

  _pricePerLiter = await _storage.getPrice();
  _defaultLiters = await _storage.getDefaultLiters();

  _priceController.text = _pricePerLiter.toString();
  _defaultLitersController.text = _defaultLiters.toString();

  setState(() {});
}



void _updateEntry(double liters) async {
  DateTime normalizedDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
  _entries[normalizedDay] = liters;
  await _storage.saveEntry(MilkEntry(date: normalizedDay, liters: liters));

  setState(() {
    _calculateTotalsForMonth(); // <-- now after the new entry is in place
  });
}






double _getLitersForDay(DateTime day) {
  DateTime normalized = DateTime(day.year, day.month, day.day);
  return _entries[normalized] ?? _defaultLiters;
}



  double _getDefaultFromPrevious(DateTime day) {
    DateTime previousDay = day.subtract(const Duration(days: 1));
    return _entries[previousDay] ?? _defaultLiters;

  }

double _calculateTotalLitersForMonth(DateTime month) {
  DateTime firstDayOfMonth = DateTime(month.year, month.month, 1);
  DateTime lastDay = DateTime(month.year, month.month + 1, 0);

  double total = 0.0;
  for (DateTime day = firstDayOfMonth;
      day.isBefore(lastDay.add(const Duration(days: 1)));
      day = day.add(const Duration(days: 1))) {
    
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    total += _entries[normalizedDay] ?? _defaultLiters;
  }

  return total;
}


  @override
  Widget build(BuildContext context) {
    double litersToday = _getLitersForDay(_selectedDay);
    // Removed live calculation, values now come from _calculatedTotalLiters and _calculatedTotalCost


    return Scaffold(
      appBar: AppBar(title: const Text("Milk Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Row(
            children: [
              Expanded(
                child: Text("Price per Liter: ₹${_pricePerLiter.toStringAsFixed(2)}"),
              ),
              ElevatedButton(
                onPressed: () => _showUpdateDialog(
                  title: "Update Price per Liter",
                  initialValue: _pricePerLiter,
                  onSave: (value) async {
                    await _storage.savePrice(value);
                    setState(() {
                      _pricePerLiter = value;
                    });
                  },
                ),
                child: const Text("Update"),
              )
            ],
          ),
          const SizedBox(height: 10),
          Row(
  children: [
    Expanded(
      child: Text("Default Liters Per Day: ${_defaultLiters.toStringAsFixed(2)}"),
    ),
    ElevatedButton(
      onPressed: () => _showUpdateDialog(
        title: "Update Default Liters",
        initialValue: _defaultLiters,
        onSave: (value) async {
          await _storage.saveDefaultLiters(value);
          setState(() {
            _defaultLiters = value;
            _calculateTotalsForMonth();
          });
        },
      ),
      child: const Text("Update"),
    )
  ],
),


          const SizedBox(height: 20),

          CalendarWidget(
  focusedDay: _focusedDay,
  selectedDay: _selectedDay,
  onDaySelected: (selected) {
    setState(() {
      _selectedDay = selected;
      // You can also update focusedDay if you want to track it
      _focusedDay = selected; // Optionally, set focusedDay to selected
    });
  },
),

          const SizedBox(height: 16),

          Text("Liters on ${_selectedDay.toLocal().toString().split(' ')[0]}: ${litersToday.toStringAsFixed(2)} liters"),
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
                onPressed: () async {
                  bool confirm = await _confirmNoMilkDialog();
                  if (confirm) {
                    _updateEntry(0);
                  }
                },
                child: const Text("No Milk Taken"),
              ),
            ],
          ),

          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _showMonthlyDetails,
            child: const Text("View Monthly Milk Log"),
          ),

          const SizedBox(height: 20),

          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _calculateTotalsForMonth,
            child: const Text("Calculate Total"),
          ),
          Text("Total Liters: ${_calculatedTotalLiters.toStringAsFixed(2)}"),
          Text("Total Cost: ₹${_calculatedTotalCost.toStringAsFixed(2)}"),

        ]),
      ),
    );
  }

  Future<bool> _confirmNoMilkDialog() async {
  bool confirmed = false;

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Confirm"),
      content: Text("Are you sure no milk was taken on ${_formatDate(_selectedDay)}?"),
      actions: [
        TextButton(
          onPressed: () {
            confirmed = false;
            Navigator.of(ctx).pop();
          },
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            confirmed = true;
            Navigator.of(ctx).pop();
          },
          child: const Text("Yes"),
        ),
      ],
    ),
  );

  return confirmed;
}


void _showMonthlyDetails() {
  DateTime firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
  DateTime lastDayOfMonth = DateTime.now(); // up to today
  List<MapEntry<DateTime, double>> monthlyEntries = [];

  for (DateTime date = firstDayOfMonth;
    date.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
    date = date.add(const Duration(days: 1))) {

  DateTime normalized = DateTime(date.year, date.month, date.day);
  double litersForDay = _entries[normalized] ?? _defaultLiters;

  monthlyEntries.add(MapEntry(normalized, litersForDay));
}


  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Milk Log for This Month"),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: monthlyEntries.map((entry) {
            String dateStr = _formatDate(entry.key);
            return ListTile(
              title: Text("$dateStr: ${entry.value.toStringAsFixed(2)} liters"),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text("Close"),
        ),
      ],
    ),
  );
}





Future<double> _showLitersDialog() async {
  DateTime normalizedDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
  double currentValue = _entries[normalizedDay] ?? _defaultLiters;

  TextEditingController litersController = TextEditingController(
    text: currentValue.toString(),
  );

  double newLiters = currentValue;

  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text("Enter Liters"),
        content: TextField(
          controller: litersController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "e.g., 1.0"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              newLiters = double.tryParse(litersController.text) ?? currentValue;
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



  String _formatDate(DateTime date) {
  int day = date.day;
  String suffix;
  if (day >= 11 && day <= 13) {
    suffix = 'th';
  } else {
    switch (day % 10) {
      case 1:
        suffix = 'st';
        break;
      case 2:
        suffix = 'nd';
        break;
      case 3:
        suffix = 'rd';
        break;
      default:
        suffix = 'th';
    }
  }

  String month = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ][date.month - 1];

  return "$day$suffix $month ${date.year}";
}

Future<void> _showUpdateDialog({
  required String title,
  required double initialValue,
  required Function(double) onSave,
}) async {
  TextEditingController controller = TextEditingController(text: initialValue.toString());

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: "Enter value"),
      ),
      actions: [
        TextButton(
          onPressed: () {
            double value = double.tryParse(controller.text) ?? initialValue;
            onSave(value);
            Navigator.of(ctx).pop();
          },
          child: const Text("Save"),
        )
      ],
    ),
  );
}

void _calculateTotalsForMonth() {
  DateTime firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
  DateTime today = DateTime.now();
  DateTime lastDayOfMonth = DateTime(
    _focusedDay.year,
    _focusedDay.month + 1,
    0,
  );

  // Ensure we don't go past today
  if (lastDayOfMonth.isAfter(today)) {
    lastDayOfMonth = today;
  }

  double totalLiters = 0.0;

  for (DateTime day = firstDay;
      !day.isAfter(lastDayOfMonth);
      day = day.add(const Duration(days: 1))) {
    DateTime normalized = DateTime(day.year, day.month, day.day);
    totalLiters += _entries[normalized] ?? _defaultLiters;
  }

  double totalCost = totalLiters * _pricePerLiter;

  setState(() {
    _calculatedTotalLiters = totalLiters;
    _calculatedTotalCost = totalCost;
  });
}



}