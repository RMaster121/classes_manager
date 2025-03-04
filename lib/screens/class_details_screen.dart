import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/class.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../services/database_service.dart';
import './classes_screen.dart';
import 'package:intl/intl.dart';

class ClassDetailsScreen extends StatefulWidget {
  final Class classItem;

  const ClassDetailsScreen({super.key, required this.classItem});

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<Class> pastClasses = [];
  bool _isLoading = true;
  List<Student> students = [];
  List<Subject> subjects = [];

  // Edit form controllers
  Student? _selectedStudent;
  Subject? _selectedSubject;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double _duration = 1.0;
  ClassStatus _status = ClassStatus.planned;
  ClassType _type = ClassType.oneTime;

  @override
  void initState() {
    super.initState();
    _loadPastClasses();
    _loadData();
    _notesController.text = widget.classItem.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPastClasses() async {
    setState(() => _isLoading = true);

    // Load past classes for this student-subject combination
    final classes = await DatabaseService.instance.getPastClasses(
      widget.classItem.student.id,
      widget.classItem.subject.id,
      widget.classItem.dateTime,
    );

    setState(() {
      pastClasses = classes;
      _isLoading = false;
    });
  }

  Future<void> _loadData() async {
    final loadedStudents = await DatabaseService.instance.getStudents();
    final loadedSubjects = await DatabaseService.instance.getSubjects();

    setState(() {
      students = loadedStudents;
      subjects = loadedSubjects;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _saveNotes() async {
    final updatedClass = widget.classItem.copyWith(
      notes: _notesController.text,
    );
    await DatabaseService.instance.updateClass(updatedClass);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notes saved')));
  }

  Future<void> _markAsCompleted() async {
    final updatedClass = widget.classItem.copyWith(
      status: ClassStatus.completed,
    );
    await DatabaseService.instance.updateClass(updatedClass);
    if (!mounted) return;

    Navigator.pop(
      context,
      true,
    ); // Return true to indicate the class was completed
  }

  void _showEditDialog() {
    _selectedStudent = widget.classItem.student;
    _selectedSubject = widget.classItem.subject;
    _selectedDate = widget.classItem.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(widget.classItem.dateTime);
    _duration = widget.classItem.duration;
    _status = widget.classItem.status;
    _type = widget.classItem.type;

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
                              'Edit Class',
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
                                      ).format(_selectedDate),
                                    ),
                                    onPressed: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 365),
                                        ),
                                      );
                                      if (date != null) {
                                        setDialogState(
                                          () => _selectedDate = date,
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
                            // Status Selection
                            Row(
                              children: [
                                Text(
                                  'Status:',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SegmentedButton<ClassStatus>(
                                    segments: const [
                                      ButtonSegment<ClassStatus>(
                                        value: ClassStatus.planned,
                                        icon: Icon(Icons.event, size: 18),
                                        label: Text(
                                          'Planned',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      ButtonSegment<ClassStatus>(
                                        value: ClassStatus.completed,
                                        icon: Icon(
                                          Icons.check_circle,
                                          size: 18,
                                        ),
                                        label: Text(
                                          'Done',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                    selected: {_status},
                                    onSelectionChanged: (
                                      Set<ClassStatus> selected,
                                    ) {
                                      setDialogState(
                                        () => _status = selected.first,
                                      );
                                    },
                                    style: ButtonStyle(
                                      visualDensity: VisualDensity.compact,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: MaterialStateProperty.all(
                                        const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                      ),
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
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () => _updateClass(),
                                  child: const Text('Save'),
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

  Future<void> _updateClass() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStudent == null || _selectedSubject == null) return;

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final updatedClass = widget.classItem.copyWith(
      student: _selectedStudent,
      subject: _selectedSubject,
      dateTime: dateTime,
      duration: _duration,
      status: _status,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    try {
      await DatabaseService.instance.updateClass(updatedClass);
      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      Navigator.pop(
        context,
        true,
      ); // Return to classes screen with refresh flag
    } catch (e) {
      if (!mounted) return;
      // Show error dialog for overlapping classes
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Cannot Save Changes'),
              content: const Text(
                'This time slot overlaps with another class. Please choose a different time.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.classItem.student;
    final subject = widget.classItem.subject;
    final price = subject.basePricePerHour * widget.classItem.duration;
    final isCompleted = widget.classItem.status == ClassStatus.completed;
    final isCancelled = widget.classItem.status == ClassStatus.cancelled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditDialog,
            tooltip: 'Edit class',
          ),
          if (!isCompleted && !isCancelled)
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: _markAsCompleted,
              tooltip: 'Mark as completed',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Student Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: student.color,
                        child: Text(
                          student.name[0],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(student.location),
                            Text(student.phone),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone),
                            onPressed: () => _makePhoneCall(student.phone),
                          ),
                          IconButton(
                            icon: const Icon(Icons.message),
                            onPressed: () => _sendSMS(student.phone),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Class Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(getIconData(subject.icon), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        subject.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${widget.classItem.dateTime.toString().split('.')[0]}',
                  ),
                  Text('Duration: ${widget.classItem.duration} hour(s)'),
                  Text('Price: \$${price.toStringAsFixed(2)}'),
                  Text(
                    'Status: ${widget.classItem.status.toString().split('.').last}',
                    style: TextStyle(
                      color:
                          isCompleted
                              ? Colors.green
                              : isCancelled
                              ? Colors.red
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        onPressed: _saveNotes,
                      ),
                    ],
                  ),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Add notes about this class...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Past Classes Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Past Classes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (pastClasses.isEmpty)
                    const Text('No past classes')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pastClasses.length,
                      itemBuilder: (context, index) {
                        final pastClass = pastClasses[index];
                        return ListTile(
                          title: Text(
                            pastClass.dateTime.toString().split('.')[0],
                          ),
                          subtitle: Text(
                            pastClass.notes ?? 'No notes',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData getIconData(String iconName) {
    switch (iconName) {
      case 'book':
        return Icons.book;
      case 'science':
        return Icons.science;
      case 'calculate':
        return Icons.calculate;
      case 'language':
        return Icons.language;
      case 'music_note':
        return Icons.music_note;
      case 'sports_basketball':
        return Icons.sports_basketball;
      case 'palette':
        return Icons.palette;
      case 'computer':
        return Icons.computer;
      default:
        return Icons.book;
    }
  }
}
