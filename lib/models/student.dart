import 'package:flutter/material.dart';
import 'subject.dart';
import 'class.dart';

class Student {
  final String id;
  final String name;
  final String location;
  final String phone;
  final Color color;
  final List<Subject> subjects;
  final List<Class> classes;

  Student({
    required this.id,
    required this.name,
    required this.location,
    required this.phone,
    required this.color,
    List<Subject>? subjects,
    List<Class>? classes,
  }) : subjects = subjects ?? [],
       classes = classes ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'phone': phone,
      'color': color.value,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'].toString(),
      name: map['name'] as String,
      location: map['location'] as String,
      phone: map['phone'] as String,
      color: Color(map['color'] as int),
    );
  }

  Student copyWith({
    String? id,
    String? name,
    String? location,
    String? phone,
    Color? color,
    List<Subject>? subjects,
    List<Class>? classes,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      color: color ?? this.color,
      subjects: subjects ?? List.from(this.subjects),
      classes: classes ?? List.from(this.classes),
    );
  }
}
