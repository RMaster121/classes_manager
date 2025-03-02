import 'package:flutter/material.dart';
import 'subject.dart';
import 'class.dart';

class Student {
  final int? id;
  final String name;
  final Color color;
  final List<Subject> subjects;
  final List<Class> classes;

  Student({
    this.id,
    required this.name,
    required this.color,
    List<Subject>? subjects,
    List<Class>? classes,
  }) : subjects = subjects ?? [],
       classes = classes ?? [];

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'color': color.toARGB32()};
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: Color(map['color'] as int),
    );
  }

  Student copyWith({
    int? id,
    String? name,
    Color? color,
    List<Subject>? subjects,
    List<Class>? classes,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      subjects: subjects ?? List.from(this.subjects),
      classes: classes ?? List.from(this.classes),
    );
  }
}
