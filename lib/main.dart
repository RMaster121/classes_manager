import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'services/database_service.dart';
import 'screens/students_screen.dart';
import 'screens/subjects_screen.dart';
import 'screens/classes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.instance.database;

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classes Manager',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    ClassesScreen(),
    StudentsScreen(),
    SubjectsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Classes',
          ),
          NavigationDestination(icon: Icon(Icons.people), label: 'Students'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Subjects'),
        ],
      ),
    );
  }
}
