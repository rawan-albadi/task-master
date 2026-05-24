import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'main.dart';

class CalendarPage extends StatefulWidget {
  final List<Task> tasks;

  const CalendarPage({super.key, required this.tasks});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Task> get tasksForSelectedDay {
    if (_selectedDay == null) return [];

    return widget.tasks.where((task) {
      return isSameDay(task.deadline, _selectedDay);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text('Calendar',
         style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 36,
                  color: Color(0xFF512DA8), // Deep Purple 700
                  letterSpacing: 1.2,
                ),),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(
            child: tasksForSelectedDay.isEmpty
                ? Center(child: Text('No tasks for this day'))
                : ListView.builder(
                    itemCount: tasksForSelectedDay.length,
                    itemBuilder: (context, index) {
                      final task = tasksForSelectedDay[index];
                      return ListTile(
                        title: Text(task.title),
                        subtitle: Text("Deadline: ${task.deadline.toLocal().toString().split(' ')[0]}"),
                        leading: Icon(Icons.task),
                        trailing: task.isDone
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : Icon(Icons.radio_button_unchecked),
                      );
                    },
                  ),
          ),
        ],
      ),
      
    );
  }
}
