import 'package:flutter/material.dart';
import '../models/class.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  List<Class> classes = [];
  List<Student> students = [];
  List<Subject> subjects = [];
  DateTime selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _notesController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Student? _selectedStudent;
  Subject? _selectedSubject;
  double _duration = 1.0;
  ClassStatus _status = ClassStatus.planned;
  ClassType _type = ClassType.oneTime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final loadedStudents = await DatabaseService.instance.getStudents();
    final loadedSubjects = await DatabaseService.instance.getSubjects();
    final loadedClasses = await DatabaseService.instance.getClassesForWeek(
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
    );

    setState(() {
      students = loadedStudents;
      subjects = loadedSubjects;
      classes = loadedClasses;
    });
  }

  void _showAddClassDialog() {
    _resetForm();
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Class',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            // Student Selection
                            DropdownButtonFormField<Student>(
                              value: _selectedStudent,
                              decoration: const InputDecoration(
                                labelText: 'Student',
                              ),
                              items:
                                  students.map((student) {
                                    return DropdownMenuItem(
                                      value: student,
                                      child: Text(student.name),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setDialogState(() => _selectedStudent = value);
                              },
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Please select a student'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            // Subject Selection
                            DropdownButtonFormField<Subject>(
                              value: _selectedSubject,
                              decoration: const InputDecoration(
                                labelText: 'Subject',
                              ),
                              items:
                                  subjects.map((subject) {
                                    return DropdownMenuItem(
                                      value: subject,
                                      child: Text(subject.name),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setDialogState(() => _selectedSubject = value);
                              },
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Please select a subject'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            // Date Selection
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(
                                      DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(selectedDate),
                                    ),
                                    onPressed: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 365),
                                        ),
                                      );
                                      if (date != null) {
                                        setDialogState(
                                          () => selectedDate = date,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.access_time),
                                    label: Text(_selectedTime.format(context)),
                                    onPressed: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: _selectedTime,
                                      );
                                      if (time != null) {
                                        setDialogState(
                                          () => _selectedTime = time,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Duration Slider
                            Row(
                              children: [
                                const Text('Duration:'),
                                Expanded(
                                  child: Slider(
                                    value: _duration,
                                    min: 0.5,
                                    max: 3.0,
                                    divisions: 5,
                                    label: '$_duration hours',
                                    onChanged: (value) {
                                      setDialogState(() => _duration = value);
                                    },
                                  ),
                                ),
                                Text('${_duration.toStringAsFixed(1)}h'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Class Type Selection
                            Row(
                              children: [
                                const Text('Type:'),
                                const SizedBox(width: 16),
                                ChoiceChip(
                                  label: const Text('One-time'),
                                  selected: _type == ClassType.oneTime,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(
                                        () => _type = ClassType.oneTime,
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Recurring'),
                                  selected: _type == ClassType.recurring,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(
                                        () => _type = ClassType.recurring,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Notes
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notes',
                                alignLabelWithHint: true,
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),
                            // Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _resetForm();
                                  },
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: _addClass,
                                  child: const Text('Add Class'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  void _resetForm() {
    _selectedStudent = null;
    _selectedSubject = null;
    selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _duration = 1.0;
    _status = ClassStatus.planned;
    _type = ClassType.oneTime;
    _notesController.clear();
  }

  Future<void> _addClass() async {
    if (!_formKey.currentState!.validate()) return;

    final dateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newClass = Class(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      student: _selectedStudent!,
      subject: _selectedSubject!,
      dateTime: dateTime,
      duration: _duration,
      status: _status,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      type: _type,
    );

    await DatabaseService.instance.addClass(newClass);
    await _loadData();
    if (mounted) {
      Navigator.pop(context);
      _resetForm();
    }
  }

  Widget _buildClassTile(Class classItem) {
    final timeFormat = DateFormat('HH:mm');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: classItem.student.color,
          child: Text(
            classItem.student.name[0],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(classItem.student.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(classItem.subject.name),
            Text(
              '${timeFormat.format(classItem.dateTime)} - ${classItem.duration}h',
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${(classItem.subject.basePricePerHour * classItem.duration).toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Show class options menu
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          classes.isEmpty
              ? const Center(child: Text('No classes scheduled'))
              : ListView.builder(
                itemCount: classes.length,
                itemBuilder:
                    (context, index) => _buildClassTile(classes[index]),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
