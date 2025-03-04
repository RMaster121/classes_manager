import 'package:flutter/material.dart';

class SubjectFields {
  static const String id = 'id';
  static const String name = 'name';
  static const String basePricePerHour = 'basePricePerHour';
  static const String icon = 'icon';
  static const String active = 'active';
}

class Subject {
  final String id;
  final String name;
  final double basePricePerHour;
  final String icon;
  final bool active;

  Subject({
    required this.id,
    required this.name,
    required this.basePricePerHour,
    required this.icon,
    this.active = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'basePricePerHour': basePricePerHour,
      'icon': icon,
      'active': active ? 1 : 0,
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'].toString(),
      name: json['name'] as String,
      basePricePerHour: json['basePricePerHour'] as double,
      icon: json['icon'] as String,
      active: (json['active'] as int?) == 1,
    );
  }

  Subject copyWith({
    String? id,
    String? name,
    double? basePricePerHour,
    String? icon,
    bool? active,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      basePricePerHour: basePricePerHour ?? this.basePricePerHour,
      icon: icon ?? this.icon,
      active: active ?? this.active,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subject && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
