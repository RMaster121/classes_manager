import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/student.dart';
import '../services/database_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  // Constants
  static const List<Color> _availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  // Controllers and state
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final RegExp _phoneRegex = RegExp(r'^\+?[0-9]{9,15}$');

  List<Student> students = [];
  List<Student> archivedStudents = [];
  bool _showArchived = false;
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _cleanupInvalidUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Validation methods
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    if (!_phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number (9-15 digits)';
    }
    return null;
  }

  // Database operations
  Future<void> _loadStudents() async {
    final loadedStudents = await DatabaseService.instance.getStudents(
      includeArchived: true,
    );
    setState(() {
      students = loadedStudents.where((s) => s.active).toList();
      archivedStudents = loadedStudents.where((s) => !s.active).toList();
    });
  }

  Future<void> _cleanupInvalidUsers() async {
    final allStudents = await DatabaseService.instance.getStudents();
    for (var student in allStudents) {
      if (!_phoneRegex.hasMatch(student.phone)) {
        await DatabaseService.instance.deleteStudent(student.id);
      }
    }
    await _loadStudents();
  }

  Future<void> _addStudent() async {
    if (_formKey.currentState!.validate()) {
      final newStudent = Student(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        location: _locationController.text,
        phone: _phoneController.text,
        color: _selectedColor,
      );

      await DatabaseService.instance.addStudent(newStudent);
      _resetForm();
      await _loadStudents();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _editStudent(Student student) async {
    if (_formKey.currentState!.validate()) {
      final updatedStudent = student.copyWith(
        name: _nameController.text,
        location: _locationController.text,
        phone: _phoneController.text,
        color: _selectedColor,
      );

      await DatabaseService.instance.updateStudent(updatedStudent);
      _resetForm();
      await _loadStudents();
      if (mounted) Navigator.pop(context);
    }
  }

  // Form handling
  void _resetForm() {
    _nameController.clear();
    _locationController.clear();
    _phoneController.clear();
    _selectedColor = Colors.blue;
  }

  // Communication actions
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

  // UI Components
  Widget _buildColorPicker(StateSetter setDialogState) {
    return Wrap(
      spacing: 8,
      children:
          _availableColors.map((color) {
            return GestureDetector(
              onTap: () => setDialogState(() => _selectedColor = color),
              child: CircleAvatar(
                backgroundColor: color,
                radius: 16,
                child:
                    _selectedColor.value == color.value
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildStudentForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator:
                (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
          ),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Location'),
            validator:
                (value) =>
                    value?.isEmpty ?? true ? 'Please enter a location' : null,
          ),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              hintText: '+1234567890',
            ),
            keyboardType: TextInputType.phone,
            validator: _validatePhoneNumber,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showStudentDialog([Student? student]) {
    _selectedColor = student?.color ?? Colors.blue;

    if (student != null) {
      _nameController.text = student.name;
      _locationController.text = student.location;
      _phoneController.text = student.phone;
    } else {
      _resetForm();
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student == null ? 'Add Student' : 'Edit Student',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildStudentForm(),
                                  _buildColorPicker(setDialogState),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                              TextButton(
                                onPressed:
                                    () =>
                                        student == null
                                            ? _addStudent()
                                            : _editStudent(student),
                                child: Text(student == null ? 'Add' : 'Save'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  Future<void> _showArchiveConfirmation(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Archive Student'),
            content: Text(
              'Are you sure you want to archive "${student.name}"?\n\n'
              'The student will be hidden from new class creation but preserved for historical records.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.error,
                  ),
                ),
                child: const Text('Archive'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.archiveStudent(student.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student.name} has been archived'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await DatabaseService.instance.restoreStudent(student.id);
              await _loadStudents();
            },
          ),
        ),
      );
      await _loadStudents();
    }
  }

  Future<void> _showRestoreConfirmation(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Restore Student'),
            content: Text('Do you want to restore "${student.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restore'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.restoreStudent(student.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student.name} has been restored'),
          duration: const Duration(seconds: 4),
        ),
      );
      await _loadStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedStudents = _showArchived ? archivedStudents : students;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showArchived = !_showArchived;
              });
            },
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
          ),
        ],
      ),
      body:
          displayedStudents.isEmpty
              ? Center(
                child: Text(
                  _showArchived
                      ? 'No archived students'
                      : 'No students added yet',
                ),
              )
              : ListView.builder(
                itemCount: displayedStudents.length,
                itemBuilder: (context, index) {
                  final student = displayedStudents[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            backgroundColor: student.color.withOpacity(
                              student.active ? 1.0 : 0.5,
                            ),
                            child: Text(
                              student.name[0],
                              style: TextStyle(
                                color: Colors.white.withOpacity(
                                  student.active ? 1.0 : 0.7,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style:
                                      student.active
                                          ? Theme.of(
                                            context,
                                          ).textTheme.titleMedium
                                          : Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            color:
                                                Theme.of(context).disabledColor,
                                          ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  student.location,
                                  style:
                                      student.active
                                          ? null
                                          : TextStyle(
                                            color:
                                                Theme.of(context).disabledColor,
                                          ),
                                ),
                                Text(
                                  student.phone,
                                  style:
                                      student.active
                                          ? null
                                          : TextStyle(
                                            color:
                                                Theme.of(context).disabledColor,
                                          ),
                                ),
                              ],
                            ),
                          ),
                          // Action buttons
                          if (student.active) ...[
                            IconButton(
                              icon: const Icon(Icons.phone),
                              onPressed: () => _makePhoneCall(student.phone),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(Icons.message),
                              onPressed: () => _sendSMS(student.phone),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showStudentDialog(student),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.archive,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed:
                                  () => _showArchiveConfirmation(student),
                              visualDensity: VisualDensity.compact,
                            ),
                          ] else
                            IconButton(
                              icon: const Icon(Icons.unarchive),
                              onPressed:
                                  () => _showRestoreConfirmation(student),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton:
          !_showArchived
              ? FloatingActionButton(
                onPressed: () => _showStudentDialog(),
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}
