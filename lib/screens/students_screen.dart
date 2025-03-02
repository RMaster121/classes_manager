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
    final loadedStudents = await DatabaseService.instance.getStudents();
    setState(() => students = loadedStudents);
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

  Widget _buildStudentTile(Student student) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Leading - Avatar
            CircleAvatar(
              backgroundColor: student.color,
              child: Text(
                student.name[0],
                style: const TextStyle(color: Colors.white),
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
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          student.location,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        student.phone,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  Icons.sms,
                  Colors.green,
                  () => _sendSMS(student.phone),
                  'Send SMS',
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  Icons.phone,
                  Colors.blue,
                  () => _makePhoneCall(student.phone),
                  'Make call',
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  Icons.edit,
                  null,
                  () => _showStudentDialog(student),
                  'Edit student',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color? color,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        icon: Icon(icon, size: 24, color: color),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body:
          students.isEmpty
              ? const Center(child: Text('No students added yet'))
              : ListView.builder(
                itemCount: students.length,
                itemBuilder: (_, index) => _buildStudentTile(students[index]),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
