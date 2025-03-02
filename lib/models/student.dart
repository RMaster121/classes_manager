import 'package:flutter/material.dart';
import 'subject.dart';
import 'class.dart';

class StudentFields {
  static const String id = 'id';
  static const String name = 'name';
  static const String location = 'location';
  static const String phone = 'phone';
  static const String color = 'color';
}

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'phone': phone,
      'color': color.value,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'].toString(),
      name: json['name'] as String,
      location: json['location'] as String,
      phone: json['phone'] as String,
      color: Color(int.parse(json['color'] as String)),
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
