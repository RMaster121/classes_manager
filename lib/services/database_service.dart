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

    return await openDatabase(
      path,
      version: 3, // Increment version number
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE students ADD COLUMN location TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE students ADD COLUMN phone TEXT NOT NULL DEFAULT ""',
      );
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        phone TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subjects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        pricePerHour REAL NOT NULL,
        icon INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE classes (
        id TEXT PRIMARY KEY,
        studentId TEXT NOT NULL,
        subjectId TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        FOREIGN KEY (studentId) REFERENCES students (id)
          ON DELETE CASCADE,
        FOREIGN KEY (subjectId) REFERENCES subjects (id)
          ON DELETE CASCADE
      )
    ''');
  }

  // Student methods
  Future<List<Student>> getStudents() async {
    final db = await instance.database;
    final result = await db.query('students');
    return result.map((map) => Student.fromMap(map)).toList();
  }

  Future<Student> getStudent(String id) async {
    final db = await instance.database;
    final maps = await db.query('students', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    } else {
      throw Exception('Student not found');
    }
  }

  Future<void> addStudent(Student student) async {
    final db = await instance.database;
    await db.insert('students', student.toMap());
  }

  Future<void> updateStudent(Student student) async {
    final db = await instance.database;
    await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<void> deleteStudent(String id) async {
    final db = await instance.database;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // Subject methods
  Future<List<Subject>> getSubjects() async {
    final db = await instance.database;
    final result = await db.query('subjects');
    return result.map((map) => Subject.fromMap(map)).toList();
  }

  Future<Subject> getSubject(String id) async {
    final db = await instance.database;
    final maps = await db.query('subjects', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Subject.fromMap(maps.first);
    } else {
      throw Exception('Subject not found');
    }
  }

  Future<void> addSubject(Subject subject) async {
    final db = await instance.database;
    await db.insert('subjects', subject.toMap());
  }

  Future<void> updateSubject(Subject subject) async {
    final db = await instance.database;
    await db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<void> deleteSubject(String id) async {
    final db = await instance.database;
    await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  // Class methods
  Future<List<Class>> getClasses() async {
    final db = await instance.database;
    final result = await db.query('classes');
    return Future.wait(
      result.map((map) async {
        final student = await getStudent(map['studentId'] as String);
        final subject = await getSubject(map['subjectId'] as String);
        return Class.fromMap(map, student, subject);
      }),
    );
  }

  Future<List<Class>> getClassesForWeek(DateTime weekStart) async {
    final db = await instance.database;
    final weekEnd = weekStart.add(const Duration(days: 7));

    final result = await db.query(
      'classes',
      where: 'dateTime BETWEEN ? AND ?',
      whereArgs: [weekStart.toIso8601String(), weekEnd.toIso8601String()],
    );

    return Future.wait(
      result.map((map) async {
        final student = await getStudent(map['studentId'] as String);
        final subject = await getSubject(map['subjectId'] as String);
        return Class.fromMap(map, student, subject);
      }),
    );
  }

  Future<void> addClass(Class classItem) async {
    final db = await instance.database;
    await db.insert('classes', classItem.toMap());
  }

  Future<void> updateClass(Class classItem) async {
    final db = await instance.database;
    await db.update(
      'classes',
      classItem.toMap(),
      where: 'id = ?',
      whereArgs: [classItem.id],
    );
  }

  Future<void> deleteClass(String id) async {
    final db = await instance.database;
    await db.delete('classes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
