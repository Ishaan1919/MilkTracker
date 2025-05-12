import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime) onDaySelected; // Only need DateTime for selectedDay

  const CalendarWidget({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020),
      lastDay: DateTime.now(),
      focusedDay: focusedDay,
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onDaySelected: (selected, focused) {
        onDaySelected(selected); // Pass only the selected day
      },
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
        selectedDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
      ),
    );
  }
}
