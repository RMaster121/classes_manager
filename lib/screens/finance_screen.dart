import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/class.dart';
import '../services/database_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  List<Class> _allClasses = [];
  bool _isLoading = true;
  final _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final loadedClasses = await DatabaseService.instance.getClasses();
    setState(() {
      _allClasses = loadedClasses;
      _isLoading = false;
    });
  }

  double _calculateEarnings(List<Class> classes) {
    return classes.fold(
      0.0,
      (sum, cls) => sum + (cls.subject.basePricePerHour * cls.duration),
    );
  }

  List<Class> _getCompletedClassesForPeriod(DateTime start, DateTime end) {
    return _allClasses
        .where(
          (cls) =>
              cls.status == ClassStatus.completed &&
              !cls.dateTime.isBefore(start) && // inclusive start
              cls.dateTime.isBefore(end), // exclusive end
        )
        .toList();
  }

  Widget _buildEarningsCard(String title, double amount, {Color? color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currencyFormat.format(amount),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color ?? Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Calculate date ranges
    final now = DateTime.now();
    // Start of week (Monday 00:00:00)
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
    // Start of next week (following Monday 00:00:00)
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    // Get completed classes for each period
    final weeklyClasses = _getCompletedClassesForPeriod(startOfWeek, endOfWeek);
    final monthlyClasses = _getCompletedClassesForPeriod(
      startOfMonth,
      endOfMonth,
    );
    final allCompletedClasses =
        _allClasses
            .where((cls) => cls.status == ClassStatus.completed)
            .toList();

    // Calculate earnings
    final weeklyEarnings = _calculateEarnings(weeklyClasses);
    final monthlyEarnings = _calculateEarnings(monthlyClasses);
    final totalEarnings = _calculateEarnings(allCompletedClasses);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildEarningsCard(
            'This Week',
            weeklyEarnings,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          _buildEarningsCard(
            'This Month',
            monthlyEarnings,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          _buildEarningsCard(
            'Total Earnings',
            totalEarnings,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Recent Completed Classes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...allCompletedClasses
              .take(5)
              .map(
                (cls) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cls.student.color,
                      child: Text(
                        cls.student.name[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(cls.student.name),
                    subtitle: Text(
                      '${cls.subject.name} - ${DateFormat('MMM d, y').format(cls.dateTime)}',
                    ),
                    trailing: Text(
                      _currencyFormat.format(
                        cls.subject.basePricePerHour * cls.duration,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}
