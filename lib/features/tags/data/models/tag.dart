class Tag {
  final String id;
  final String name;

  const Tag({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory Tag.fromMap(Map<String, dynamic> map) => Tag(id: map['id'] as String, name: map['name'] as String);

  Tag copyWith({String? name}) => Tag(id: id, name: name ?? this.name);

  bool get isEmpty => id.isEmpty && name.isEmpty;
}
