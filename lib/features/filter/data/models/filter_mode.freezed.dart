// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'filter_mode.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FilterMode {

 String get id; String get name; TaskFilter get filter; bool get isDefault; int? get iconCodePoint;
/// Create a copy of FilterMode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FilterModeCopyWith<FilterMode> get copyWith => _$FilterModeCopyWithImpl<FilterMode>(this as FilterMode, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FilterMode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.iconCodePoint, iconCodePoint) || other.iconCodePoint == iconCodePoint));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,filter,isDefault,iconCodePoint);

@override
String toString() {
  return 'FilterMode(id: $id, name: $name, filter: $filter, isDefault: $isDefault, iconCodePoint: $iconCodePoint)';
}


}

/// @nodoc
abstract mixin class $FilterModeCopyWith<$Res>  {
  factory $FilterModeCopyWith(FilterMode value, $Res Function(FilterMode) _then) = _$FilterModeCopyWithImpl;
@useResult
$Res call({
 String id, String name, TaskFilter filter, bool isDefault, int? iconCodePoint
});


$TaskFilterCopyWith<$Res> get filter;

}
/// @nodoc
class _$FilterModeCopyWithImpl<$Res>
    implements $FilterModeCopyWith<$Res> {
  _$FilterModeCopyWithImpl(this._self, this._then);

  final FilterMode _self;
  final $Res Function(FilterMode) _then;

/// Create a copy of FilterMode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? filter = null,Object? isDefault = null,Object? iconCodePoint = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as TaskFilter,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,iconCodePoint: freezed == iconCodePoint ? _self.iconCodePoint : iconCodePoint // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of FilterMode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskFilterCopyWith<$Res> get filter {
  
  return $TaskFilterCopyWith<$Res>(_self.filter, (value) {
    return _then(_self.copyWith(filter: value));
  });
}
}


/// Adds pattern-matching-related methods to [FilterMode].
extension FilterModePatterns on FilterMode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FilterMode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FilterMode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FilterMode value)  $default,){
final _that = this;
switch (_that) {
case _FilterMode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FilterMode value)?  $default,){
final _that = this;
switch (_that) {
case _FilterMode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  TaskFilter filter,  bool isDefault,  int? iconCodePoint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FilterMode() when $default != null:
return $default(_that.id,_that.name,_that.filter,_that.isDefault,_that.iconCodePoint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  TaskFilter filter,  bool isDefault,  int? iconCodePoint)  $default,) {final _that = this;
switch (_that) {
case _FilterMode():
return $default(_that.id,_that.name,_that.filter,_that.isDefault,_that.iconCodePoint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  TaskFilter filter,  bool isDefault,  int? iconCodePoint)?  $default,) {final _that = this;
switch (_that) {
case _FilterMode() when $default != null:
return $default(_that.id,_that.name,_that.filter,_that.isDefault,_that.iconCodePoint);case _:
  return null;

}
}

}

/// @nodoc


class _FilterMode extends FilterMode {
  const _FilterMode({required this.id, required this.name, required this.filter, this.isDefault = false, this.iconCodePoint}): super._();
  

@override final  String id;
@override final  String name;
@override final  TaskFilter filter;
@override@JsonKey() final  bool isDefault;
@override final  int? iconCodePoint;

/// Create a copy of FilterMode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FilterModeCopyWith<_FilterMode> get copyWith => __$FilterModeCopyWithImpl<_FilterMode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FilterMode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.iconCodePoint, iconCodePoint) || other.iconCodePoint == iconCodePoint));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,filter,isDefault,iconCodePoint);

@override
String toString() {
  return 'FilterMode(id: $id, name: $name, filter: $filter, isDefault: $isDefault, iconCodePoint: $iconCodePoint)';
}


}

/// @nodoc
abstract mixin class _$FilterModeCopyWith<$Res> implements $FilterModeCopyWith<$Res> {
  factory _$FilterModeCopyWith(_FilterMode value, $Res Function(_FilterMode) _then) = __$FilterModeCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, TaskFilter filter, bool isDefault, int? iconCodePoint
});


@override $TaskFilterCopyWith<$Res> get filter;

}
/// @nodoc
class __$FilterModeCopyWithImpl<$Res>
    implements _$FilterModeCopyWith<$Res> {
  __$FilterModeCopyWithImpl(this._self, this._then);

  final _FilterMode _self;
  final $Res Function(_FilterMode) _then;

/// Create a copy of FilterMode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? filter = null,Object? isDefault = null,Object? iconCodePoint = freezed,}) {
  return _then(_FilterMode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as TaskFilter,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,iconCodePoint: freezed == iconCodePoint ? _self.iconCodePoint : iconCodePoint // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of FilterMode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskFilterCopyWith<$Res> get filter {
  
  return $TaskFilterCopyWith<$Res>(_self.filter, (value) {
    return _then(_self.copyWith(filter: value));
  });
}
}

// dart format on
