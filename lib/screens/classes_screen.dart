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
                                Text(
                                  'Type:',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SegmentedButton<ClassType>(
                                    segments: const [
                                      ButtonSegment<ClassType>(
                                        value: ClassType.oneTime,
                                        icon: Icon(Icons.event),
                                        label: Text('Single'),
                                      ),
                                      ButtonSegment<ClassType>(
                                        value: ClassType.recurring,
                                        icon: Icon(Icons.repeat),
                                        label: Text('Weekly'),
                                      ),
                                    ],
                                    selected: {_type},
                                    onSelectionChanged: (
                                      Set<ClassType> selected,
                                    ) {
                                      setDialogState(
                                        () => _type = selected.first,
                                      );
                                    },
                                    style: ButtonStyle(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
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

    // For recurring classes, create instances for the next 8 weeks
    if (_type == ClassType.recurring) {
      for (int i = 0; i < 8; i++) {
        final classDateTime = dateTime.add(Duration(days: 7 * i));
        final newClass = Class(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          student: _selectedStudent!,
          subject: _selectedSubject!,
          dateTime: classDateTime,
          duration: _duration,
          status: _status,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          type: _type,
        );
        await DatabaseService.instance.addClass(newClass);
      }
    } else {
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
    }

    await _loadData();
    if (mounted) {
      Navigator.pop(context);
      _resetForm();
    }
  }

  Widget _buildClassTile(Class classItem) {
    final dateFormat = DateFormat('EEE, d MMM');
    final timeFormat = DateFormat('HH:mm');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Leading avatar
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: classItem.student.color,
                  child: Text(
                    classItem.student.name[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (classItem.type == ClassType.recurring)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.repeat,
                        size: 12,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          classItem.student.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          dateFormat.format(classItem.dateTime),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '•',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 8,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: Text(
                          timeFormat.format(classItem.dateTime),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Icon(
                          Icons.book_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          classItem.subject.name,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${classItem.duration}h',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Price and menu
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${(classItem.subject.basePricePerHour * classItem.duration).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // TODO: Show class options menu
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
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
