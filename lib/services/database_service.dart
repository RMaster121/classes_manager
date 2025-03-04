import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subject.dart';
import '../models/student.dart';
import '../models/class.dart';

const String tableStudents = 'students';
const String tableSubjects = 'subjects';
const String tableClasses = 'classes';

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
      version: 4, // Increment version number
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.transaction((txn) async {
      if (oldVersion < 2) {
        await txn.execute(
          'ALTER TABLE students ADD COLUMN location TEXT NOT NULL DEFAULT ""',
        );
      }
      if (oldVersion < 3) {
        await txn.execute(
          'ALTER TABLE students ADD COLUMN phone TEXT NOT NULL DEFAULT ""',
        );
      }
      if (oldVersion < 4) {
        // Create temporary table
        await txn.execute('''
CREATE TABLE ${tableSubjects}_temp (
  ${SubjectFields.id} TEXT PRIMARY KEY,
  ${SubjectFields.name} TEXT NOT NULL,
  ${SubjectFields.basePricePerHour} REAL NOT NULL,
  ${SubjectFields.icon} TEXT NOT NULL,
  ${SubjectFields.active} INTEGER NOT NULL DEFAULT 1
)''');

        // Copy data with converted IDs
        await txn.execute(
          'INSERT INTO ${tableSubjects}_temp SELECT CAST(id AS TEXT) as id, name, basePricePerHour, icon, 1 as active FROM $tableSubjects',
        );

        // Drop old table and rename new one
        await txn.execute('DROP TABLE $tableSubjects');
        await txn.execute(
          'ALTER TABLE ${tableSubjects}_temp RENAME TO $tableSubjects',
        );
      }
    });
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const textNullable = 'TEXT';

    await db.execute('''
CREATE TABLE $tableStudents (
  ${StudentFields.id} $idType,
  ${StudentFields.name} $textType,
  ${StudentFields.location} $textType,
  ${StudentFields.phone} $textType,
  ${StudentFields.color} $textType
)
''');

    await db.execute('''
CREATE TABLE $tableSubjects (
  ${SubjectFields.id} $idType,
  ${SubjectFields.name} $textType,
  ${SubjectFields.basePricePerHour} $realType,
  ${SubjectFields.icon} $textType,
  ${SubjectFields.active} $integerType DEFAULT 1
)
''');

    await db.execute('''
CREATE TABLE $tableClasses (
  ${ClassFields.id} $idType,
  ${ClassFields.studentId} $textType,
  ${ClassFields.subjectId} $textType,
  ${ClassFields.dateTime} $textType,
  ${ClassFields.duration} $realType,
  ${ClassFields.status} $textType,
  ${ClassFields.notes} $textNullable,
  ${ClassFields.type} $textType,
  FOREIGN KEY (${ClassFields.studentId}) REFERENCES $tableStudents (${StudentFields.id}),
  FOREIGN KEY (${ClassFields.subjectId}) REFERENCES $tableSubjects (${SubjectFields.id})
)
''');
  }

  // Student methods
  Future<List<Student>> getStudents() async {
    final db = await instance.database;
    final result = await db.query(tableStudents);
    return result.map((map) => Student.fromJson(map)).toList();
  }

  Future<Student> getStudent(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      tableStudents,
      where: '${StudentFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Student.fromJson(maps.first);
    } else {
      throw Exception('Student not found');
    }
  }

  Future<void> addStudent(Student student) async {
    final db = await instance.database;
    await db.insert(tableStudents, student.toJson());
  }

  Future<void> updateStudent(Student student) async {
    final db = await instance.database;
    await db.update(
      tableStudents,
      student.toJson(),
      where: '${StudentFields.id} = ?',
      whereArgs: [student.id],
    );
  }

  Future<void> deleteStudent(String id) async {
    final db = await instance.database;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // Subject methods
  Future<List<Subject>> getSubjects({bool includeArchived = false}) async {
    final db = await instance.database;
    final query =
        includeArchived
            ? 'SELECT * FROM $tableSubjects'
            : 'SELECT * FROM $tableSubjects WHERE ${SubjectFields.active} = 1';
    final result = await db.rawQuery(query);
    return result.map((map) => Subject.fromJson(map)).toList();
  }

  Future<Subject> getSubject(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      tableSubjects,
      where: '${SubjectFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Subject.fromJson(maps.first);
    } else {
      throw Exception('Subject not found');
    }
  }

  Future<void> addSubject(Subject subject) async {
    final db = await instance.database;
    await db.insert(tableSubjects, subject.toJson());
  }

  Future<void> updateSubject(Subject subject) async {
    final db = await instance.database;
    await db.update(
      tableSubjects,
      subject.toJson(),
      where: '${SubjectFields.id} = ?',
      whereArgs: [subject.id],
    );
  }

  Future<void> deleteSubject(String id) async {
    final db = await instance.database;
    await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> archiveSubject(String id) async {
    final db = await instance.database;
    await db.update(
      tableSubjects,
      {SubjectFields.active: 0},
      where: '${SubjectFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreSubject(String id) async {
    final db = await instance.database;
    await db.update(
      tableSubjects,
      {SubjectFields.active: 1},
      where: '${SubjectFields.id} = ?',
      whereArgs: [id],
    );
  }

  // Class methods
  Future<List<Class>> getClasses() async {
    final db = await instance.database;
    final result = await db.query('classes');
    return Future.wait(
      result.map((map) async {
        final student = await getStudent(map['studentId'] as String);
        final subject = await getSubject(map['subjectId'] as String);
        return Class.fromJson(map, student: student, subject: subject);
      }),
    );
  }

  Future<List<Class>> getClassesForWeeks(
    DateTime startDate,
    int numberOfWeeks, {
    bool loadPastClasses = false,
  }) async {
    final db = await instance.database;
    final endDate = startDate.add(Duration(days: 7 * numberOfWeeks));

    final result = await db.rawQuery(
      '''
      SELECT 
        c.${ClassFields.id} as c_id,
        c.${ClassFields.studentId} as c_studentId,
        c.${ClassFields.subjectId} as c_subjectId,
        c.${ClassFields.dateTime} as c_dateTime,
        c.${ClassFields.duration} as c_duration,
        c.${ClassFields.status} as c_status,
        c.${ClassFields.notes} as c_notes,
        c.${ClassFields.type} as c_type,
        s.${StudentFields.id} as s_id,
        s.${StudentFields.name} as s_name,
        s.${StudentFields.location} as s_location,
        s.${StudentFields.phone} as s_phone,
        s.${StudentFields.color} as s_color,
        sub.${SubjectFields.id} as sub_id,
        sub.${SubjectFields.name} as sub_name,
        sub.${SubjectFields.basePricePerHour} as sub_basePricePerHour,
        sub.${SubjectFields.icon} as sub_icon
      FROM $tableClasses c
      JOIN $tableStudents s ON c.${ClassFields.studentId} = s.${StudentFields.id}
      JOIN $tableSubjects sub ON c.${ClassFields.subjectId} = sub.${SubjectFields.id}
      WHERE ${loadPastClasses ? 'c.${ClassFields.dateTime} < ? AND c.${ClassFields.status} = ?' : '(c.${ClassFields.dateTime} >= ? OR (c.${ClassFields.dateTime} < ? AND c.${ClassFields.status} != ?))'}
      ORDER BY c.${ClassFields.dateTime} ASC
      LIMIT 50
    ''',
      loadPastClasses
          ? [
            startDate.toIso8601String(),
            ClassStatus.completed.toString().split('.').last,
          ]
          : [
            startDate.toIso8601String(),
            startDate.toIso8601String(),
            ClassStatus.completed.toString().split('.').last,
          ],
    );

    return result.map((json) {
      final student = Student.fromJson({
        'id': json['s_id'],
        'name': json['s_name'],
        'location': json['s_location'],
        'phone': json['s_phone'],
        'color': json['s_color'],
      });

      final subject = Subject.fromJson({
        'id': json['sub_id'],
        'name': json['sub_name'],
        'basePricePerHour': json['sub_basePricePerHour'],
        'icon': json['sub_icon'],
      });

      return Class.fromJson(
        {
          ClassFields.id: json['c_id'],
          ClassFields.studentId: json['c_studentId'],
          ClassFields.subjectId: json['c_subjectId'],
          ClassFields.dateTime: json['c_dateTime'],
          ClassFields.duration: json['c_duration'],
          ClassFields.status: json['c_status'],
          ClassFields.notes: json['c_notes'],
          ClassFields.type: json['c_type'],
        },
        student: student,
        subject: subject,
      );
    }).toList();
  }

  Future<Class> addClass(Class classItem) async {
    final db = await instance.database;

    final studentJson = await db.query(
      tableStudents,
      where: '${StudentFields.id} = ?',
      whereArgs: [classItem.student.id],
    );

    final subjectJson = await db.query(
      tableSubjects,
      where: '${SubjectFields.id} = ?',
      whereArgs: [classItem.subject.id],
    );

    if (studentJson.isEmpty || subjectJson.isEmpty) {
      throw Exception('Student or Subject not found');
    }

    final id = await db.insert(tableClasses, classItem.toJson());
    return classItem.copyWith(id: id.toString());
  }

  Future<int> updateClass(Class classItem) async {
    final db = await instance.database;
    return db.update(
      tableClasses,
      classItem.toJson()..remove(ClassFields.id),
      where: '${ClassFields.id} = ?',
      whereArgs: [classItem.id],
    );
  }

  Future<int> deleteClass(String id) async {
    final db = await instance.database;
    return await db.delete(
      tableClasses,
      where: '${ClassFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> cancelFutureClasses(
    String studentId,
    String subjectId,
    DateTime fromDate,
  ) async {
    final db = await instance.database;
    await db.update(
      tableClasses,
      {ClassFields.status: ClassStatus.cancelled.toString().split('.').last},
      where: '''
        ${ClassFields.studentId} = ? AND 
        ${ClassFields.subjectId} = ? AND 
        ${ClassFields.dateTime} >= ?
      ''',
      whereArgs: [studentId, subjectId, fromDate.toIso8601String()],
    );
  }

  Future<List<Class>> getFutureClasses(
    String studentId,
    String subjectId,
    DateTime fromDate,
  ) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        c.${ClassFields.id} as c_id,
        c.${ClassFields.studentId} as c_studentId,
        c.${ClassFields.subjectId} as c_subjectId,
        c.${ClassFields.dateTime} as c_dateTime,
        c.${ClassFields.duration} as c_duration,
        c.${ClassFields.status} as c_status,
        c.${ClassFields.notes} as c_notes,
        c.${ClassFields.type} as c_type,
        s.${StudentFields.id} as s_id,
        s.${StudentFields.name} as s_name,
        s.${StudentFields.location} as s_location,
        s.${StudentFields.phone} as s_phone,
        s.${StudentFields.color} as s_color,
        sub.${SubjectFields.id} as sub_id,
        sub.${SubjectFields.name} as sub_name,
        sub.${SubjectFields.basePricePerHour} as sub_basePricePerHour,
        sub.${SubjectFields.icon} as sub_icon
      FROM $tableClasses c
      JOIN $tableStudents s ON c.${ClassFields.studentId} = s.${StudentFields.id}
      JOIN $tableSubjects sub ON c.${ClassFields.subjectId} = sub.${SubjectFields.id}
      WHERE c.${ClassFields.studentId} = ? 
      AND c.${ClassFields.subjectId} = ?
      AND c.${ClassFields.dateTime} >= ?
      ORDER BY c.${ClassFields.dateTime} ASC
    ''',
      [studentId, subjectId, fromDate.toIso8601String()],
    );

    return result.map((json) {
      final student = Student.fromJson({
        'id': json['s_id'],
        'name': json['s_name'],
        'location': json['s_location'],
        'phone': json['s_phone'],
        'color': json['s_color'],
      });

      final subject = Subject.fromJson({
        'id': json['sub_id'],
        'name': json['sub_name'],
        'basePricePerHour': json['sub_basePricePerHour'],
        'icon': json['sub_icon'],
      });

      return Class.fromJson(
        {
          ClassFields.id: json['c_id'],
          ClassFields.studentId: json['c_studentId'],
          ClassFields.subjectId: json['c_subjectId'],
          ClassFields.dateTime: json['c_dateTime'],
          ClassFields.duration: json['c_duration'],
          ClassFields.status: json['c_status'],
          ClassFields.notes: json['c_notes'],
          ClassFields.type: json['c_type'],
        },
        student: student,
        subject: subject,
      );
    }).toList();
  }

  Future<void> markClassAsCompleted(String? classId) async {
    if (classId == null) return;

    final db = await instance.database;
    await db.update(
      tableClasses,
      {ClassFields.status: ClassStatus.completed.toString().split('.').last},
      where: '${ClassFields.id} = ?',
      whereArgs: [classId],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<void> deleteAllClasses() async {
    final db = await instance.database;
    await db.delete(tableClasses);
  }
}
