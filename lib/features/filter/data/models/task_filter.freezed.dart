// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskFilter {

 bool? get isUrgent; Set<String> get projectIdsIncluded; Set<String> get labelIdsIncluded; Set<String> get tagIdsIncluded; Set<String> get projectIdsExcluded; Set<String> get labelIdsExcluded; Set<String> get tagIdsExcluded;
/// Create a copy of TaskFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskFilterCopyWith<TaskFilter> get copyWith => _$TaskFilterCopyWithImpl<TaskFilter>(this as TaskFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskFilter&&(identical(other.isUrgent, isUrgent) || other.isUrgent == isUrgent)&&const DeepCollectionEquality().equals(other.projectIdsIncluded, projectIdsIncluded)&&const DeepCollectionEquality().equals(other.labelIdsIncluded, labelIdsIncluded)&&const DeepCollectionEquality().equals(other.tagIdsIncluded, tagIdsIncluded)&&const DeepCollectionEquality().equals(other.projectIdsExcluded, projectIdsExcluded)&&const DeepCollectionEquality().equals(other.labelIdsExcluded, labelIdsExcluded)&&const DeepCollectionEquality().equals(other.tagIdsExcluded, tagIdsExcluded));
}


@override
int get hashCode => Object.hash(runtimeType,isUrgent,const DeepCollectionEquality().hash(projectIdsIncluded),const DeepCollectionEquality().hash(labelIdsIncluded),const DeepCollectionEquality().hash(tagIdsIncluded),const DeepCollectionEquality().hash(projectIdsExcluded),const DeepCollectionEquality().hash(labelIdsExcluded),const DeepCollectionEquality().hash(tagIdsExcluded));

@override
String toString() {
  return 'TaskFilter(isUrgent: $isUrgent, projectIdsIncluded: $projectIdsIncluded, labelIdsIncluded: $labelIdsIncluded, tagIdsIncluded: $tagIdsIncluded, projectIdsExcluded: $projectIdsExcluded, labelIdsExcluded: $labelIdsExcluded, tagIdsExcluded: $tagIdsExcluded)';
}


}

/// @nodoc
abstract mixin class $TaskFilterCopyWith<$Res>  {
  factory $TaskFilterCopyWith(TaskFilter value, $Res Function(TaskFilter) _then) = _$TaskFilterCopyWithImpl;
@useResult
$Res call({
 bool? isUrgent, Set<String> projectIdsIncluded, Set<String> labelIdsIncluded, Set<String> tagIdsIncluded, Set<String> projectIdsExcluded, Set<String> labelIdsExcluded, Set<String> tagIdsExcluded
});




}
/// @nodoc
class _$TaskFilterCopyWithImpl<$Res>
    implements $TaskFilterCopyWith<$Res> {
  _$TaskFilterCopyWithImpl(this._self, this._then);

  final TaskFilter _self;
  final $Res Function(TaskFilter) _then;

/// Create a copy of TaskFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isUrgent = freezed,Object? projectIdsIncluded = null,Object? labelIdsIncluded = null,Object? tagIdsIncluded = null,Object? projectIdsExcluded = null,Object? labelIdsExcluded = null,Object? tagIdsExcluded = null,}) {
  return _then(_self.copyWith(
isUrgent: freezed == isUrgent ? _self.isUrgent : isUrgent // ignore: cast_nullable_to_non_nullable
as bool?,projectIdsIncluded: null == projectIdsIncluded ? _self.projectIdsIncluded : projectIdsIncluded // ignore: cast_nullable_to_non_nullable
as Set<String>,labelIdsIncluded: null == labelIdsIncluded ? _self.labelIdsIncluded : labelIdsIncluded // ignore: cast_nullable_to_non_nullable
as Set<String>,tagIdsIncluded: null == tagIdsIncluded ? _self.tagIdsIncluded : tagIdsIncluded // ignore: cast_nullable_to_non_nullable
as Set<String>,projectIdsExcluded: null == projectIdsExcluded ? _self.projectIdsExcluded : projectIdsExcluded // ignore: cast_nullable_to_non_nullable
as Set<String>,labelIdsExcluded: null == labelIdsExcluded ? _self.labelIdsExcluded : labelIdsExcluded // ignore: cast_nullable_to_non_nullable
as Set<String>,tagIdsExcluded: null == tagIdsExcluded ? _self.tagIdsExcluded : tagIdsExcluded // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskFilter].
extension TaskFilterPatterns on TaskFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskFilter value)  $default,){
final _that = this;
switch (_that) {
case _TaskFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskFilter value)?  $default,){
final _that = this;
switch (_that) {
case _TaskFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? isUrgent,  Set<String> projectIdsIncluded,  Set<String> labelIdsIncluded,  Set<String> tagIdsIncluded,  Set<String> projectIdsExcluded,  Set<String> labelIdsExcluded,  Set<String> tagIdsExcluded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskFilter() when $default != null:
return $default(_that.isUrgent,_that.projectIdsIncluded,_that.labelIdsIncluded,_that.tagIdsIncluded,_that.projectIdsExcluded,_that.labelIdsExcluded,_that.tagIdsExcluded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? isUrgent,  Set<String> projectIdsIncluded,  Set<String> labelIdsIncluded,  Set<String> tagIdsIncluded,  Set<String> projectIdsExcluded,  Set<String> labelIdsExcluded,  Set<String> tagIdsExcluded)  $default,) {final _that = this;
switch (_that) {
case _TaskFilter():
return $default(_that.isUrgent,_that.projectIdsIncluded,_that.labelIdsIncluded,_that.tagIdsIncluded,_that.projectIdsExcluded,_that.labelIdsExcluded,_that.tagIdsExcluded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? isUrgent,  Set<String> projectIdsIncluded,  Set<String> labelIdsIncluded,  Set<String> tagIdsIncluded,  Set<String> projectIdsExcluded,  Set<String> labelIdsExcluded,  Set<String> tagIdsExcluded)?  $default,) {final _that = this;
switch (_that) {
case _TaskFilter() when $default != null:
return $default(_that.isUrgent,_that.projectIdsIncluded,_that.labelIdsIncluded,_that.tagIdsIncluded,_that.projectIdsExcluded,_that.labelIdsExcluded,_that.tagIdsExcluded);case _:
  return null;

}
}

}

/// @nodoc


class _TaskFilter extends TaskFilter {
  const _TaskFilter({this.isUrgent, final  Set<String> projectIdsIncluded = const {}, final  Set<String> labelIdsIncluded = const {}, final  Set<String> tagIdsIncluded = const {}, final  Set<String> projectIdsExcluded = const {}, final  Set<String> labelIdsExcluded = const {}, final  Set<String> tagIdsExcluded = const {}}): _projectIdsIncluded = projectIdsIncluded,_labelIdsIncluded = labelIdsIncluded,_tagIdsIncluded = tagIdsIncluded,_projectIdsExcluded = projectIdsExcluded,_labelIdsExcluded = labelIdsExcluded,_tagIdsExcluded = tagIdsExcluded,super._();
  

@override final  bool? isUrgent;
 final  Set<String> _projectIdsIncluded;
@override@JsonKey() Set<String> get projectIdsIncluded {
  if (_projectIdsIncluded is EqualUnmodifiableSetView) return _projectIdsIncluded;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_projectIdsIncluded);
}

 final  Set<String> _labelIdsIncluded;
@override@JsonKey() Set<String> get labelIdsIncluded {
  if (_labelIdsIncluded is EqualUnmodifiableSetView) return _labelIdsIncluded;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_labelIdsIncluded);
}

 final  Set<String> _tagIdsIncluded;
@override@JsonKey() Set<String> get tagIdsIncluded {
  if (_tagIdsIncluded is EqualUnmodifiableSetView) return _tagIdsIncluded;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_tagIdsIncluded);
}

 final  Set<String> _projectIdsExcluded;
@override@JsonKey() Set<String> get projectIdsExcluded {
  if (_projectIdsExcluded is EqualUnmodifiableSetView) return _projectIdsExcluded;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_projectIdsExcluded);
}

 final  Set<String> _labelIdsExcluded;
@override@JsonKey() Set<String> get labelIdsExcluded {
  if (_labelIdsExcluded is EqualUnmodifiableSetView) return _labelIdsExcluded;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_labelIdsExcluded);
}

 final  Set<String> _tagIdsExcluded;
@override@JsonKey() Set<String> get tagIdsExcluded {
  if (_tagIdsExcluded is EqualUnmodifiableSetView) return _tagIdsExcluded;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_tagIdsExcluded);
}


/// Create a copy of TaskFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskFilterCopyWith<_TaskFilter> get copyWith => __$TaskFilterCopyWithImpl<_TaskFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskFilter&&(identical(other.isUrgent, isUrgent) || other.isUrgent == isUrgent)&&const DeepCollectionEquality().equals(other._projectIdsIncluded, _projectIdsIncluded)&&const DeepCollectionEquality().equals(other._labelIdsIncluded, _labelIdsIncluded)&&const DeepCollectionEquality().equals(other._tagIdsIncluded, _tagIdsIncluded)&&const DeepCollectionEquality().equals(other._projectIdsExcluded, _projectIdsExcluded)&&const DeepCollectionEquality().equals(other._labelIdsExcluded, _labelIdsExcluded)&&const DeepCollectionEquality().equals(other._tagIdsExcluded, _tagIdsExcluded));
}


@override
int get hashCode => Object.hash(runtimeType,isUrgent,const DeepCollectionEquality().hash(_projectIdsIncluded),const DeepCollectionEquality().hash(_labelIdsIncluded),const DeepCollectionEquality().hash(_tagIdsIncluded),const DeepCollectionEquality().hash(_projectIdsExcluded),const DeepCollectionEquality().hash(_labelIdsExcluded),const DeepCollectionEquality().hash(_tagIdsExcluded));

@override
String toString() {
  return 'TaskFilter(isUrgent: $isUrgent, projectIdsIncluded: $projectIdsIncluded, labelIdsIncluded: $labelIdsIncluded, tagIdsIncluded: $tagIdsIncluded, projectIdsExcluded: $projectIdsExcluded, labelIdsExcluded: $labelIdsExcluded, tagIdsExcluded: $tagIdsExcluded)';
}


}

/// @nodoc
abstract mixin class _$TaskFilterCopyWith<$Res> implements $TaskFilterCopyWith<$Res> {
  factory _$TaskFilterCopyWith(_TaskFilter value, $Res Function(_TaskFilter) _then) = __$TaskFilterCopyWithImpl;
@override @useResult
$Res call({
 bool? isUrgent, Set<String> projectIdsIncluded, Set<String> labelIdsIncluded, Set<String> tagIdsIncluded, Set<String> projectIdsExcluded, Set<String> labelIdsExcluded, Set<String> tagIdsExcluded
});




}
/// @nodoc
class __$TaskFilterCopyWithImpl<$Res>
    implements _$TaskFilterCopyWith<$Res> {
  __$TaskFilterCopyWithImpl(this._self, this._then);

  final _TaskFilter _self;
  final $Res Function(_TaskFilter) _then;

/// Create a copy of TaskFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isUrgent = freezed,Object? projectIdsIncluded = null,Object? labelIdsIncluded = null,Object? tagIdsIncluded = null,Object? projectIdsExcluded = null,Object? labelIdsExcluded = null,Object? tagIdsExcluded = null,}) {
  return _then(_TaskFilter(
isUrgent: freezed == isUrgent ? _self.isUrgent : isUrgent // ignore: cast_nullable_to_non_nullable
as bool?,projectIdsIncluded: null == projectIdsIncluded ? _self._projectIdsIncluded : projectIdsIncluded // ignore: cast_nullable_to_non_nullable
as Set<String>,labelIdsIncluded: null == labelIdsIncluded ? _self._labelIdsIncluded : labelIdsIncluded // ignore: cast_nullable_to_non_nullable
as Set<String>,tagIdsIncluded: null == tagIdsIncluded ? _self._tagIdsIncluded : tagIdsIncluded // ignore: cast_nullable_to_non_nullable
as Set<String>,projectIdsExcluded: null == projectIdsExcluded ? _self._projectIdsExcluded : projectIdsExcluded // ignore: cast_nullable_to_non_nullable
as Set<String>,labelIdsExcluded: null == labelIdsExcluded ? _self._labelIdsExcluded : labelIdsExcluded // ignore: cast_nullable_to_non_nullable
as Set<String>,tagIdsExcluded: null == tagIdsExcluded ? _self._tagIdsExcluded : tagIdsExcluded // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
