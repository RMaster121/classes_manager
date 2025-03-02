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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'basePricePerHour': basePricePerHour,
      'icon': icon,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int?,
      name: map['name'] as String,
      basePricePerHour: map['basePricePerHour'] as double,
      icon: map['icon'] as String,
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
