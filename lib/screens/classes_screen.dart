import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/class.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../services/database_service.dart';
import '../screens/class_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  List<Class> classes = [];
  List<Class> pastClasses = [];
  List<Student> students = [];
  List<Subject> subjects = [];
  DateTime selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  bool _showingAllClasses = false;
  bool _loadingPastClasses = false;
  final ScrollController _scrollController = ScrollController();
  bool _canLoadPastClasses = true;

  // Controllers
  final _notesController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Student? _selectedStudent;
  Subject? _selectedSubject;
  double _duration = 1.0;
  ClassStatus _status = ClassStatus.planned;
  ClassType _type = ClassType.oneTime;
  int _recurringWeeks = 8;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Only trigger when user deliberately pulls down at the top
    if (_scrollController.position.pixels < -50 &&
        !_loadingPastClasses &&
        _canLoadPastClasses) {
      _loadPastClasses();
      // Prevent multiple triggers until next reset
      _canLoadPastClasses = false;
    }

    // Reset the ability to load past classes when user scrolls back down
    if (_scrollController.position.pixels > 0) {
      _canLoadPastClasses = true;
    }
  }

  Future<void> _loadPastClasses() async {
    if (_loadingPastClasses) return;

    setState(() {
      _loadingPastClasses = true;
    });

    final loadedPastClasses = await DatabaseService.instance.getClassesForWeeks(
      DateTime.now(),
      52, // Load up to a year of past classes
      loadPastClasses: true,
    );

    setState(() {
      pastClasses = loadedPastClasses;
      _loadingPastClasses = false;
    });
  }

  Future<void> _loadData() async {
    final loadedStudents = await DatabaseService.instance.getStudents();
    final loadedSubjects = await DatabaseService.instance.getSubjects();

    // Get the start of the current week
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final loadedClasses = await DatabaseService.instance.getClassesForWeeks(
      startOfWeek,
      _showingAllClasses ? 52 : 2,
      loadPastClasses: false, // Only load future and non-completed classes
    );

    setState(() {
      students = loadedStudents;
      subjects = loadedSubjects;
      classes = loadedClasses;
      if (!_loadingPastClasses) {
        pastClasses = []; // Reset past classes when loading new data
      }
    });
  }

  void _toggleShowAllClasses() {
    setState(() {
      _showingAllClasses = !_showingAllClasses;
    });
    _loadData();
  }

  void _showClassOptionsMenu(BuildContext context, Class classItem) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l10n.edit),
                onTap: () {
                  Navigator.pop(context);
                  _showEditClassDialog(classItem);
                },
              ),
              if (classItem.type == ClassType.recurring)
                ListTile(
                  leading: const Icon(Icons.edit_calendar),
                  title: Text(l10n.editFutureClasses),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditClassDialog(classItem, editFuture: true);
                  },
                ),
              if (classItem.status != ClassStatus.completed)
                ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: Text(l10n.markAsCompleted),
                  onTap: () async {
                    Navigator.pop(context);
                    await DatabaseService.instance.markClassAsCompleted(
                      classItem.id,
                    );
                    await _loadData();
                  },
                ),
              if (classItem.status != ClassStatus.completed)
                ListTile(
                  leading: Icon(
                    Icons.cancel,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    l10n.cancelClass,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    _showCancelClassDialog(classItem);
                  },
                ),
              if (classItem.type == ClassType.recurring &&
                  classItem.status != ClassStatus.completed)
                ListTile(
                  leading: Icon(
                    Icons.cancel_schedule_send,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    l10n.cancelAllFutureClasses,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    _showCancelClassDialog(classItem, cancelFuture: true);
                  },
                ),
            ],
          ),
    );
  }

  Future<void> _showCancelClassDialog(
    Class classItem, {
    bool cancelFuture = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              cancelFuture ? l10n.cancelAllFutureClasses : l10n.cancelClass,
            ),
            content: Text(
              cancelFuture
                  ? l10n.cancelAllFutureClassesConfirm
                  : l10n.cancelClassConfirm,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.no),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.yes),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      if (cancelFuture) {
        // Cancel all future classes including this one
        await DatabaseService.instance.cancelFutureClasses(
          classItem.student.id,
          classItem.subject.id,
          classItem.dateTime,
        );
      } else {
        // Cancel just this class
        await DatabaseService.instance.updateClass(
          classItem.copyWith(status: ClassStatus.cancelled),
        );
      }
      await _loadData();
    }
  }

  void _showAddClassDialog() {
    final l10n = AppLocalizations.of(context)!;
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
                              l10n.addNewClass,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            // Student Selection
                            DropdownButtonFormField<Student>(
                              value: _selectedStudent,
                              decoration: InputDecoration(
                                labelText: l10n.student,
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
                                          ? l10n.pleaseSelectStudent
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            // Subject Selection
                            DropdownButtonFormField<Subject>(
                              value: _selectedSubject,
                              decoration: InputDecoration(
                                labelText: l10n.subject,
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
                                          ? l10n.pleaseSelectSubject
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
                                      DateFormat.yMMMd(
                                        Localizations.localeOf(
                                          context,
                                        ).languageCode,
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
                                Text('${l10n.duration}:'),
                                Expanded(
                                  child: Slider(
                                    value: _duration,
                                    min: 0.5,
                                    max: 3.0,
                                    divisions: 5,
                                    label: '$_duration ${l10n.hours}',
                                    onChanged: (value) {
                                      setDialogState(() => _duration = value);
                                    },
                                  ),
                                ),
                                Text(
                                  '${_duration.toStringAsFixed(1)}${l10n.hours}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Class Type Selection
                            Row(
                              children: [
                                Text(
                                  '${l10n.type}:',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SegmentedButton<ClassType>(
                                    segments: [
                                      ButtonSegment<ClassType>(
                                        value: ClassType.oneTime,
                                        icon: const Icon(Icons.event),
                                        label: Text(l10n.single),
                                      ),
                                      ButtonSegment<ClassType>(
                                        value: ClassType.recurring,
                                        icon: const Icon(Icons.repeat),
                                        label: Text(l10n.weekly),
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
                            // Add after the Class Type Selection:
                            if (_type == ClassType.recurring) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    l10n.repeatFor,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: _recurringWeeks,
                                      decoration: InputDecoration(
                                        labelText: l10n.numberOfWeeks,
                                      ),
                                      items:
                                          [4, 8, 12, 16, 24].map((weeks) {
                                            return DropdownMenuItem(
                                              value: weeks,
                                              child: Text(
                                                '$weeks ${l10n.weeks}',
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setDialogState(
                                            () => _recurringWeeks = value,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            // Notes
                            TextFormField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                labelText: l10n.notes,
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
                                  child: Text(l10n.cancel),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: _addClass,
                                  child: Text(l10n.addClass),
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
    _recurringWeeks = 8;
    _notesController.clear();
  }

  Future<void> _addClass() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStudent == null || _selectedSubject == null) return;

    final dateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      if (_type == ClassType.oneTime) {
        final newClass = Class(
          id: const Uuid().v4(),
          student: _selectedStudent!,
          subject: _selectedSubject!,
          dateTime: dateTime,
          duration: _duration,
          status: ClassStatus.planned,
          type: _type,
        );
        await DatabaseService.instance.addClass(newClass);
      } else {
        // For recurring classes, create multiple instances
        for (int i = 0; i < _recurringWeeks; i++) {
          final recurringDateTime = dateTime.add(Duration(days: i * 7));
          final newClass = Class(
            id: const Uuid().v4(),
            student: _selectedStudent!,
            subject: _selectedSubject!,
            dateTime: recurringDateTime,
            duration: _duration,
            status: ClassStatus.planned,
            type: _type,
          );
          await DatabaseService.instance.addClass(newClass);
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      // Show error dialog for overlapping classes
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(l10n.cannotAddClass),
              content: Text(l10n.timeSlotOverlaps),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.ok),
                ),
              ],
            ),
      );
    }
  }

  void _showEditClassDialog(Class classItem, {bool editFuture = false}) {
    final l10n = AppLocalizations.of(context)!;
    _selectedStudent = classItem.student;
    _selectedSubject = classItem.subject;
    selectedDate = classItem.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(classItem.dateTime);
    _duration = classItem.duration;
    _status = classItem.status;
    _type = classItem.type;
    _notesController.text = classItem.notes ?? '';

    // For recurring classes, initialize with the current day of week
    int _selectedDayOfWeek = classItem.dateTime.weekday;

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
                              editFuture ? l10n.editFutureClasses : l10n.edit,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            // Student Selection
                            DropdownButtonFormField<Student>(
                              value: _selectedStudent,
                              decoration: InputDecoration(
                                labelText: l10n.student,
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
                                          ? l10n.pleaseSelectStudent
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            // Subject Selection
                            DropdownButtonFormField<Subject>(
                              value: _selectedSubject,
                              decoration: InputDecoration(
                                labelText: l10n.subject,
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
                                          ? l10n.pleaseSelectSubject
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            // Day of Week and Time Selection for future classes
                            if (editFuture) ...[
                              Text(
                                l10n.changeScheduleForFutureClasses,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: _selectedDayOfWeek,
                                      decoration: InputDecoration(
                                        labelText: l10n.dayOfWeek,
                                      ),
                                      items: [
                                        for (int i = 1; i <= 7; i++)
                                          DropdownMenuItem(
                                            value: i,
                                            child: Text(
                                              DateFormat(
                                                'EEEE',
                                              ).format(DateTime(2024, 1, i)),
                                            ),
                                          ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setDialogState(
                                            () => _selectedDayOfWeek = value,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Duration Slider
                            Row(
                              children: [
                                Text('${l10n.duration}:'),
                                Expanded(
                                  child: Slider(
                                    value: _duration,
                                    min: 0.5,
                                    max: 3.0,
                                    divisions: 5,
                                    label: '$_duration ${l10n.hours}',
                                    onChanged: (value) {
                                      setDialogState(() => _duration = value);
                                    },
                                  ),
                                ),
                                Text(
                                  '${_duration.toStringAsFixed(1)}${l10n.hours}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Status Selection - only show for single class edit
                            if (!editFuture)
                              Row(
                                children: [
                                  Text(
                                    '${l10n.status}:',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SegmentedButton<ClassStatus>(
                                      segments: [
                                        ButtonSegment<ClassStatus>(
                                          value: ClassStatus.planned,
                                          icon: const Icon(
                                            Icons.event,
                                            size: 18,
                                          ),
                                          label: Text(
                                            l10n.planned,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        ButtonSegment<ClassStatus>(
                                          value: ClassStatus.completed,
                                          icon: const Icon(
                                            Icons.check_circle,
                                            size: 18,
                                          ),
                                          label: Text(
                                            l10n.done,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
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
                            // Notes - only show for single class edit
                            if (!editFuture)
                              TextFormField(
                                controller: _notesController,
                                decoration: InputDecoration(
                                  labelText: l10n.notes,
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
                                  child: Text(l10n.cancel),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed:
                                      () => _updateClass(
                                        classItem,
                                        editFuture,
                                        editFuture ? _selectedDayOfWeek : null,
                                      ),
                                  child: Text(l10n.save),
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

  Future<void> _updateClass(
    Class classItem,
    bool editFuture, [
    int? newDayOfWeek,
  ]) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStudent == null || _selectedSubject == null) {
      return;
    }

    final dateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      if (editFuture) {
        // Update all future classes
        final classes = await DatabaseService.instance.getFutureClasses(
          _selectedStudent!.id,
          _selectedSubject!.id,
          classItem.dateTime,
        );

        for (final cls in classes) {
          // Calculate the new date while preserving the week structure
          DateTime newDateTime = cls.dateTime;
          if (newDayOfWeek != null) {
            // Calculate days to add/subtract to reach the target day of week
            final currentDayOfWeek = cls.dateTime.weekday;
            final daysToAdd = (newDayOfWeek - currentDayOfWeek) % 7;
            newDateTime = cls.dateTime.add(Duration(days: daysToAdd));
          }
          // Apply the new time while keeping the calculated date
          newDateTime = DateTime(
            newDateTime.year,
            newDateTime.month,
            newDateTime.day,
            _selectedTime.hour,
            _selectedTime.minute,
          );

          final updatedClass = cls.copyWith(
            student: _selectedStudent,
            subject: _selectedSubject,
            duration: _duration,
            dateTime: newDateTime,
            // Don't update status and notes for future classes
          );
          await DatabaseService.instance.updateClass(updatedClass);
        }
      } else {
        // Update single class
        final updatedClass = classItem.copyWith(
          student: _selectedStudent,
          subject: _selectedSubject,
          dateTime: dateTime,
          duration: _duration,
          status: _status,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
        await DatabaseService.instance.updateClass(updatedClass);
      }

      await _loadData();
      if (mounted) {
        Navigator.pop(context);
        _resetForm();
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      // Show error dialog for overlapping classes
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(l10n.cannotSaveChanges),
              content: Text(l10n.timeSlotOverlaps),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.ok),
                ),
              ],
            ),
      );
    }
  }

  Widget _buildClassTile(Class classItem) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat(
      'EEEE, d MMM',
      Localizations.localeOf(context).languageCode,
    );
    final timeFormat = DateFormat.Hm(
      Localizations.localeOf(context).languageCode,
    );
    final isPolish = Localizations.localeOf(context).languageCode == 'pl';
    final currencyFormat = NumberFormat.currency(
      symbol: isPolish ? 'zł' : '\$',
      decimalDigits: 2,
      customPattern: isPolish ? '#,##0.00¤' : '¤#,##0.00',
    );
    final now = DateTime.now();
    final isPast = classItem.dateTime.isBefore(now);
    final isCompleted = classItem.status == ClassStatus.completed;
    final shouldFade = isPast || isCompleted;

    // Calculate price
    final price = classItem.subject.basePricePerHour * classItem.duration;

    // Format date with capitalized first letter
    final formattedDate = dateFormat.format(classItem.dateTime);
    final capitalizedDate =
        formattedDate[0].toUpperCase() + formattedDate.substring(1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassDetailsScreen(classItem: classItem),
            ),
          ).then((wasCompleted) {
            if (wasCompleted == true) {
              _loadData();
            }
          });
        },
        child: ListTile(
          horizontalTitleGap: 12,
          minLeadingWidth: 40,
          contentPadding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: classItem.student.color.withOpacity(
                  shouldFade ? 0.6 : 1.0,
                ),
                child: Text(
                  classItem.student.name[0],
                  style: TextStyle(
                    color: Colors.white.withOpacity(shouldFade ? 0.8 : 1.0),
                  ),
                ),
              ),
              if (classItem.type == ClassType.recurring)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(shouldFade ? 0.6 : 1.0),
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
          title: Text(
            classItem.student.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(shouldFade ? 0.6 : 1.0),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      '$capitalizedDate •${timeFormat.format(classItem.dateTime)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary
                            .withOpacity(shouldFade ? 0.6 : 1.0),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currencyFormat.format(price),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(shouldFade ? 0.6 : 1.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                classItem.subject.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(shouldFade ? 0.6 : 1.0),
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showClassOptionsMenu(context, classItem),
            color: Theme.of(
              context,
            ).colorScheme.secondary.withOpacity(shouldFade ? 0.6 : 1.0),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Only show past completed classes from pastClasses list
    final filteredPastClasses =
        pastClasses
            .where(
              (c) =>
                  c.dateTime.isBefore(DateTime.now()) &&
                  c.status == ClassStatus.completed,
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Only show non-completed/non-cancelled classes and future classes from the regular list
    final filteredClasses =
        classes
            .where(
              (c) =>
                  (c.dateTime.isAfter(DateTime.now()) ||
                      c.status != ClassStatus.completed) &&
                  c.status != ClassStatus.cancelled,
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final allClasses = [...filteredPastClasses, ...filteredClasses];

    // If not showing all classes, limit to next 2 weeks
    if (!_showingAllClasses) {
      final twoWeeksFromNow = DateTime.now().add(const Duration(days: 14));
      allClasses.removeWhere((c) => c.dateTime.isAfter(twoWeeksFromNow));
    }

    return Scaffold(
      appBar: AppBar(),
      body:
          allClasses.isEmpty
              ? Center(child: Text(l10n.noClassesScheduled))
              : RefreshIndicator(
                onRefresh: () async {
                  if (!_loadingPastClasses) {
                    await _loadPastClasses();
                  }
                },
                child: Column(
                  children: [
                    if (_loadingPastClasses)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: LinearProgressIndicator(),
                      ),
                    if (pastClasses.isEmpty && !_loadingPastClasses)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          l10n.pullToLoadPastClasses,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount:
                            allClasses.length + (_showingAllClasses ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (index < allClasses.length) {
                            return _buildClassTile(allClasses[index]);
                          } else {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: _toggleShowAllClasses,
                                  icon: Icon(
                                    _showingAllClasses
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                  label: Text(
                                    _showingAllClasses
                                        ? l10n.showLess
                                        : l10n.seeMore,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
