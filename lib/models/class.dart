import 'package:flutter/material.dart';
import 'student.dart';
import 'subject.dart';

enum ClassStatus { planned, completed, cancelled, rescheduled }

enum ClassType { oneTime, recurring }

class ClassFields {
  static const String id = 'id';
  static const String studentId = 'studentId';
  static const String subjectId = 'subjectId';
  static const String dateTime = 'dateTime';
  static const String duration = 'duration';
  static const String status = 'status';
  static const String notes = 'notes';
  static const String type = 'type';
}

class Class {
  final String? id;
  final Student student;
  final Subject subject;
  final DateTime dateTime;
  final double duration;
  final ClassStatus status;
  final String? notes;
  final ClassType type;

  const Class({
    this.id,
    required this.student,
    required this.subject,
    required this.dateTime,
    required this.duration,
    this.status = ClassStatus.planned,
    this.notes,
    this.type = ClassType.oneTime,
  });

  Class copyWith({
    String? id,
    Student? student,
    Subject? subject,
    DateTime? dateTime,
    double? duration,
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
      status: status ?? this.status,
      notes: notes ?? this.notes,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
    ClassFields.id: id,
    ClassFields.studentId: student.id,
    ClassFields.subjectId: subject.id,
    ClassFields.dateTime: dateTime.toIso8601String(),
    ClassFields.duration: duration,
    ClassFields.status: status.toString().split('.').last,
    ClassFields.notes: notes,
    ClassFields.type: type.toString().split('.').last,
  };

  static Class fromJson(
    Map<String, dynamic> json, {
    required Student student,
    required Subject subject,
  }) {
    return Class(
      id: json[ClassFields.id] as String?,
      student: student,
      subject: subject,
      dateTime: DateTime.parse(json[ClassFields.dateTime] as String),
      duration: json[ClassFields.duration] as double,
      status: ClassStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json[ClassFields.status],
      ),
      notes: json[ClassFields.notes] as String?,
      type: ClassType.values.firstWhere(
        (e) => e.toString().split('.').last == json[ClassFields.type],
      ),
    );
  }
}
