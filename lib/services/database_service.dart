import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subject.dart';
import '../models/student.dart';
import '../models/class.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('classes_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        basePricePerHour REAL NOT NULL,
        icon TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        subjectId INTEGER NOT NULL,
        dateTime TEXT NOT NULL,
        duration REAL NOT NULL,
        price REAL NOT NULL,
        status INTEGER NOT NULL,
        notes TEXT,
        type INTEGER NOT NULL,
        FOREIGN KEY (studentId) REFERENCES students (id),
        FOREIGN KEY (subjectId) REFERENCES subjects (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE student_subjects (
        studentId INTEGER NOT NULL,
        subjectId INTEGER NOT NULL,
        PRIMARY KEY (studentId, subjectId),
        FOREIGN KEY (studentId) REFERENCES students (id),
        FOREIGN KEY (subjectId) REFERENCES subjects (id)
      )
    ''');
  }

  // Subject operations
  Future<Subject> createSubject(Subject subject) async {
    final db = await database;
    final id = await db.insert('subjects', subject.toMap());
    return subject.copyWith(id: id);
  }

  Future<List<Subject>> getAllSubjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('subjects');
    return List.generate(maps.length, (i) => Subject.fromMap(maps[i]));
  }

  // Student operations
  Future<Student> createStudent(Student student) async {
    final db = await database;
    final id = await db.insert('students', student.toMap());
    return student.copyWith(id: id);
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('students');
    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  // Class operations
  Future<Class> createClass(Class classItem) async {
    final db = await database;
    final id = await db.insert('classes', classItem.toMap());
    return classItem.copyWith(id: id);
  }

  Future<List<Class>> getClassesForWeek(DateTime weekStart) async {
    final db = await database;
    final weekEnd = weekStart.add(const Duration(days: 7));

    final List<Map<String, dynamic>> maps = await db.query(
      'classes',
      where: 'dateTime BETWEEN ? AND ?',
      whereArgs: [weekStart.toIso8601String(), weekEnd.toIso8601String()],
    );

    List<Class> classes = [];
    for (var map in maps) {
      final student = await getStudentById(map['studentId'] as int);
      final subject = await getSubjectById(map['subjectId'] as int);
      if (student != null && subject != null) {
        classes.add(Class.fromMap(map, student, subject));
      }
    }
    return classes;
  }

  Future<Student?> getStudentById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Student.fromMap(maps.first);
  }

  Future<Subject?> getSubjectById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Subject.fromMap(maps.first);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
