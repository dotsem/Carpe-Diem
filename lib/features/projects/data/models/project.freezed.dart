// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Project {

 String get id; String get name; Color get color; DateTime get createdAt; String? get description; bool get isUrgent; List<String> get labelIds; DateTime? get deadline; DateTime? get updatedAt; bool get isActive; String get sortOrder;
/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectCopyWith<Project> get copyWith => _$ProjectCopyWithImpl<Project>(this as Project, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Project&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.isUrgent, isUrgent) || other.isUrgent == isUrgent)&&const DeepCollectionEquality().equals(other.labelIds, labelIds)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,color,createdAt,description,isUrgent,const DeepCollectionEquality().hash(labelIds),deadline,updatedAt,isActive,sortOrder);

@override
String toString() {
  return 'Project(id: $id, name: $name, color: $color, createdAt: $createdAt, description: $description, isUrgent: $isUrgent, labelIds: $labelIds, deadline: $deadline, updatedAt: $updatedAt, isActive: $isActive, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ProjectCopyWith<$Res>  {
  factory $ProjectCopyWith(Project value, $Res Function(Project) _then) = _$ProjectCopyWithImpl;
@useResult
$Res call({
 String id, String name, Color color, DateTime createdAt, String? description, bool isUrgent, List<String> labelIds, DateTime? deadline, DateTime? updatedAt, bool isActive, String sortOrder
});




}
/// @nodoc
class _$ProjectCopyWithImpl<$Res>
    implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._self, this._then);

  final Project _self;
  final $Res Function(Project) _then;

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? color = null,Object? createdAt = null,Object? description = freezed,Object? isUrgent = null,Object? labelIds = null,Object? deadline = freezed,Object? updatedAt = freezed,Object? isActive = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isUrgent: null == isUrgent ? _self.isUrgent : isUrgent // ignore: cast_nullable_to_non_nullable
as bool,labelIds: null == labelIds ? _self.labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as List<String>,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Project].
extension ProjectPatterns on Project {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Project value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Project value)  $default,){
final _that = this;
switch (_that) {
case _Project():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Project value)?  $default,){
final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Color color,  DateTime createdAt,  String? description,  bool isUrgent,  List<String> labelIds,  DateTime? deadline,  DateTime? updatedAt,  bool isActive,  String sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that.id,_that.name,_that.color,_that.createdAt,_that.description,_that.isUrgent,_that.labelIds,_that.deadline,_that.updatedAt,_that.isActive,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Color color,  DateTime createdAt,  String? description,  bool isUrgent,  List<String> labelIds,  DateTime? deadline,  DateTime? updatedAt,  bool isActive,  String sortOrder)  $default,) {final _that = this;
switch (_that) {
case _Project():
return $default(_that.id,_that.name,_that.color,_that.createdAt,_that.description,_that.isUrgent,_that.labelIds,_that.deadline,_that.updatedAt,_that.isActive,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Color color,  DateTime createdAt,  String? description,  bool isUrgent,  List<String> labelIds,  DateTime? deadline,  DateTime? updatedAt,  bool isActive,  String sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that.id,_that.name,_that.color,_that.createdAt,_that.description,_that.isUrgent,_that.labelIds,_that.deadline,_that.updatedAt,_that.isActive,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc


class _Project extends Project {
  const _Project({required this.id, required this.name, required this.color, required this.createdAt, this.description, this.isUrgent = false, final  List<String> labelIds = const [], this.deadline, this.updatedAt, this.isActive = true, this.sortOrder = ''}): _labelIds = labelIds,super._();
  

@override final  String id;
@override final  String name;
@override final  Color color;
@override final  DateTime createdAt;
@override final  String? description;
@override@JsonKey() final  bool isUrgent;
 final  List<String> _labelIds;
@override@JsonKey() List<String> get labelIds {
  if (_labelIds is EqualUnmodifiableListView) return _labelIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_labelIds);
}

@override final  DateTime? deadline;
@override final  DateTime? updatedAt;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  String sortOrder;

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectCopyWith<_Project> get copyWith => __$ProjectCopyWithImpl<_Project>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Project&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.isUrgent, isUrgent) || other.isUrgent == isUrgent)&&const DeepCollectionEquality().equals(other._labelIds, _labelIds)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,color,createdAt,description,isUrgent,const DeepCollectionEquality().hash(_labelIds),deadline,updatedAt,isActive,sortOrder);

@override
String toString() {
  return 'Project(id: $id, name: $name, color: $color, createdAt: $createdAt, description: $description, isUrgent: $isUrgent, labelIds: $labelIds, deadline: $deadline, updatedAt: $updatedAt, isActive: $isActive, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ProjectCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$ProjectCopyWith(_Project value, $Res Function(_Project) _then) = __$ProjectCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Color color, DateTime createdAt, String? description, bool isUrgent, List<String> labelIds, DateTime? deadline, DateTime? updatedAt, bool isActive, String sortOrder
});




}
/// @nodoc
class __$ProjectCopyWithImpl<$Res>
    implements _$ProjectCopyWith<$Res> {
  __$ProjectCopyWithImpl(this._self, this._then);

  final _Project _self;
  final $Res Function(_Project) _then;

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? color = null,Object? createdAt = null,Object? description = freezed,Object? isUrgent = null,Object? labelIds = null,Object? deadline = freezed,Object? updatedAt = freezed,Object? isActive = null,Object? sortOrder = null,}) {
  return _then(_Project(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isUrgent: null == isUrgent ? _self.isUrgent : isUrgent // ignore: cast_nullable_to_non_nullable
as bool,labelIds: null == labelIds ? _self._labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as List<String>,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
