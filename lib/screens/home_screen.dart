import 'package:flutter/material.dart';
import '../models/class.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Class> weeklyClasses = [];
  DateTime selectedWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  @override
  void initState() {
    super.initState();
    _loadWeeklyClasses();
  }

  Future<void> _loadWeeklyClasses() async {
    final classes = await DatabaseService.instance.getClassesForWeek(
      selectedWeekStart,
    );
    setState(() {
      weeklyClasses = classes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // TODO: Implement calendar view
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Navigate to students list
            },
          ),
          IconButton(
            icon: const Icon(Icons.book),
            onPressed: () {
              // TODO: Navigate to subjects list
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      selectedWeekStart = selectedWeekStart.subtract(
                        const Duration(days: 7),
                      );
                      _loadWeeklyClasses();
                    });
                  },
                ),
                Text(
                  'Week of ${selectedWeekStart.day}/${selectedWeekStart.month}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      selectedWeekStart = selectedWeekStart.add(
                        const Duration(days: 7),
                      );
                      _loadWeeklyClasses();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child:
                weeklyClasses.isEmpty
                    ? const Center(
                      child: Text('No classes scheduled for this week'),
                    )
                    : ListView.builder(
                      itemCount: weeklyClasses.length,
                      itemBuilder: (context, index) {
                        final classItem = weeklyClasses[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: classItem.student.color,
                              child: Text(
                                classItem.student.name[0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(classItem.student.name),
                            subtitle: Text(classItem.subject.name),
                            trailing: Text(
                              '${classItem.dateTime.hour}:${classItem.dateTime.minute.toString().padLeft(2, '0')}',
                            ),
                            onTap: () {
                              // TODO: Navigate to class details
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new class
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
