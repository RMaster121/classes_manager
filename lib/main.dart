import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'services/database_service.dart';
import 'screens/students_screen.dart';
import 'screens/subjects_screen.dart';
import 'screens/classes_screen.dart';
import 'screens/finance_screen.dart';

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

  static const String _appName = 'Classes Manager';
  static const List<String> _screenTitles = [
    'Classes',
    'Students',
    'Subjects',
    'Finance',
  ];

  static const List<Widget> _screens = <Widget>[
    ClassesScreen(),
    StudentsScreen(),
    SubjectsScreen(),
    FinanceScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  _selectedIndex == 0
                      ? Icons.calendar_today
                      : _selectedIndex == 1
                      ? Icons.people
                      : _selectedIndex == 2
                      ? Icons.book
                      : Icons.attach_money,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  _screenTitles[_selectedIndex],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        toolbarHeight: 72,
        surfaceTintColor: Theme.of(context).colorScheme.background,
        shadowColor: Colors.transparent,
      ),
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
          NavigationDestination(
            icon: Icon(Icons.attach_money),
            label: 'Finance',
          ),
        ],
      ),
    );
  }
}
