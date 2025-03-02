import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/database_service.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<Subject> subjects = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedIcon = 'book'; // Default icon

  final List<String> _availableIcons = [
    'book',
    'science',
    'calculate',
    'language',
    'music_note',
    'sports_basketball',
    'palette',
    'computer',
  ];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final loadedSubjects = await DatabaseService.instance.getSubjects();
    setState(() {
      subjects = loadedSubjects;
    });
  }

  Future<void> _addSubject() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Subject'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price per Hour',
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedIcon,
                    decoration: const InputDecoration(labelText: 'Icon'),
                    items:
                        _availableIcons.map((String icon) {
                          return DropdownMenuItem<String>(
                            value: icon,
                            child: Row(
                              children: [
                                Icon(getIconData(icon)),
                                const SizedBox(width: 8),
                                Text(icon),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedIcon = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final newSubject = Subject(
                      name: _nameController.text,
                      basePricePerHour: double.parse(_priceController.text),
                      icon: _selectedIcon,
                    );
                    await DatabaseService.instance.addSubject(newSubject);
                    _nameController.clear();
                    _priceController.clear();
                    if (mounted) {
                      Navigator.of(context).pop();
                      _loadSubjects();
                    }
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Future<void> _editSubject(Subject subject) async {
    _nameController.text = subject.name;
    _priceController.text = subject.basePricePerHour.toString();
    _selectedIcon = subject.icon;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Subject'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price per Hour',
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedIcon,
                    decoration: const InputDecoration(labelText: 'Icon'),
                    items:
                        _availableIcons.map((String icon) {
                          return DropdownMenuItem<String>(
                            value: icon,
                            child: Row(
                              children: [
                                Icon(getIconData(icon)),
                                const SizedBox(width: 8),
                                Text(icon),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedIcon = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final updatedSubject = subject.copyWith(
                      name: _nameController.text,
                      basePricePerHour: double.parse(_priceController.text),
                      icon: _selectedIcon,
                    );
                    // TODO: Add update method to DatabaseService
                    _nameController.clear();
                    _priceController.clear();
                    if (mounted) {
                      Navigator.of(context).pop();
                      _loadSubjects();
                    }
                  }
                },
                child: const Text('Save'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      body:
          subjects.isEmpty
              ? const Center(child: Text('No subjects added yet'))
              : ListView.builder(
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ListTile(
                      leading: Icon(getIconData(subject.icon), size: 32),
                      title: Text(subject.name),
                      subtitle: Text(
                        '\$${subject.basePricePerHour.toStringAsFixed(2)} per hour',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editSubject(subject),
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubject,
        child: const Icon(Icons.add),
      ),
    );
  }
}
