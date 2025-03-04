import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/theme.dart';
import 'services/database_service.dart';
import 'screens/students_screen.dart';
import 'screens/subjects_screen.dart';
import 'screens/classes_screen.dart';
import 'screens/finance_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('pl'), // Polish
      ],
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
    FinanceScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appName,
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
                  _selectedIndex == 0
                      ? l10n.classes
                      : _selectedIndex == 1
                      ? l10n.students
                      : _selectedIndex == 2
                      ? l10n.subjects
                      : l10n.finance,
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
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.calendar_today),
            label: l10n.classes,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people),
            label: l10n.students,
          ),
          NavigationDestination(
            icon: const Icon(Icons.book),
            label: l10n.subjects,
          ),
          NavigationDestination(
            icon: const Icon(Icons.attach_money),
            label: l10n.finance,
          ),
        ],
      ),
    );
  }
}
