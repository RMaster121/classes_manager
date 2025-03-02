import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/database_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Student> students = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final loadedStudents = await DatabaseService.instance.getStudents();
    setState(() {
      students = loadedStudents;
    });
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
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _editStudent(Student student) async {
    if (_formKey.currentState!.validate()) {
      final updatedStudent = Student(
        id: student.id,
        name: _nameController.text,
        location: _locationController.text,
        phone: _phoneController.text,
        color: _selectedColor,
      );

      await DatabaseService.instance.updateStudent(updatedStudent);
      _resetForm();
      await _loadStudents();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _resetForm() {
    _nameController.clear();
    _locationController.clear();
    _phoneController.clear();
    _selectedColor = Colors.blue;
  }

  void _showStudentDialog([Student? student]) {
    // Store initial color value
    Color initialColor = student?.color ?? Colors.blue;
    _selectedColor = initialColor;

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
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Name',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a name';
                                        }
                                        return null;
                                      },
                                    ),
                                    TextFormField(
                                      controller: _locationController,
                                      decoration: const InputDecoration(
                                        labelText: 'Location',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a location';
                                        }
                                        return null;
                                      },
                                    ),
                                    TextFormField(
                                      controller: _phoneController,
                                      decoration: const InputDecoration(
                                        labelText: 'Phone',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      children:
                                          [
                                            Colors.blue,
                                            Colors.red,
                                            Colors.green,
                                            Colors.orange,
                                            Colors.purple,
                                            Colors.teal,
                                          ].map((color) {
                                            return GestureDetector(
                                              onTap: () {
                                                setDialogState(() {
                                                  _selectedColor = color;
                                                });
                                              },
                                              child: CircleAvatar(
                                                backgroundColor: color,
                                                radius: 16,
                                                child:
                                                    _selectedColor.value == color.value
                                                        ? const Icon(
                                                          Icons.check,
                                                          color: Colors.white,
                                                        )
                                                        : null,
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ],
                                ),
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
                                onPressed: () {
                                  student == null
                                      ? _addStudent()
                                      : _editStudent(student);
                                },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body:
          students.isEmpty
              ? const Center(child: Text('No students added yet'))
              : ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: student.color,
                        child: Text(
                          student.name[0],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(student.name),
                      subtitle: Text(student.location),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showStudentDialog(student),
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
