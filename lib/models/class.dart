import 'student.dart';
import 'subject.dart';

enum ClassStatus { planned, cancelled, completed }

enum ClassType { recurring, oneTime }

class Class {
  final int? id;
  final Student student;
  final Subject subject;
  final DateTime dateTime;
  final double duration;
  final double price;
  final ClassStatus status;
  final String? notes;
  final ClassType type;

  Class({
    this.id,
    required this.student,
    required this.subject,
    required this.dateTime,
    this.duration = 1.0,
    double? price,
    this.status = ClassStatus.planned,
    this.notes,
    this.type = ClassType.oneTime,
  }) : price = price ?? subject.basePricePerHour * duration;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': student.id,
      'subjectId': subject.id,
      'dateTime': dateTime.toIso8601String(),
      'duration': duration,
      'price': price,
      'status': status.index,
      'notes': notes,
      'type': type.index,
    };
  }

  factory Class.fromMap(
    Map<String, dynamic> map,
    Student student,
    Subject subject,
  ) {
    return Class(
      id: map['id'] as int?,
      student: student,
      subject: subject,
      dateTime: DateTime.parse(map['dateTime'] as String),
      duration: map['duration'] as double,
      price: map['price'] as double,
      status: ClassStatus.values[map['status'] as int],
      notes: map['notes'] as String?,
      type: ClassType.values[map['type'] as int],
    );
  }

  Class copyWith({
    int? id,
    Student? student,
    Subject? subject,
    DateTime? dateTime,
    double? duration,
    double? price,
    ClassStatus? status,
    String? notes,
    ClassType? type,
  }) {
    return Class(
      id: id ?? this.id,
      student: student ?? this.student,
      subject: subject ?? this.subject,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      type: type ?? this.type,
    );
  }
}
