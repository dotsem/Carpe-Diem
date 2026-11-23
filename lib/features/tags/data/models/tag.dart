import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';

@freezed
abstract class Tag with _$Tag {
  const Tag._();
  const factory Tag({required String id, required String name}) = _Tag;
  Map<String, dynamic> toMap() => {'id': id, 'name': name};
  factory Tag.fromMap(Map<String, dynamic> map) =>
      Tag(id: map['id'] as String, name: map['name'] as String);
  bool get isEmpty => id.isEmpty && name.isEmpty;
}
