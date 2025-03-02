import 'package:flutter/material.dart';

class SubjectFields {
  static const String id = 'id';
  static const String name = 'name';
  static const String basePricePerHour = 'basePricePerHour';
  static const String icon = 'icon';
}

class Subject {
  final int? id;
  final String name;
  final double basePricePerHour;
  final String icon;

  Subject({
    this.id,
    required this.name,
    required this.basePricePerHour,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'basePricePerHour': basePricePerHour,
      'icon': icon,
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as int?,
      name: json['name'] as String,
      basePricePerHour: json['basePricePerHour'] as double,
      icon: json['icon'] as String,
    );
  }

  Subject copyWith({
    int? id,
    String? name,
    double? basePricePerHour,
    String? icon,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      basePricePerHour: basePricePerHour ?? this.basePricePerHour,
      icon: icon ?? this.icon,
    );
  }
}
