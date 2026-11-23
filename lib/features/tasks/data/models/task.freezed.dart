// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Task {

 String get id; String get title; DateTime get createdAt; String? get description; DateTime? get scheduledDate; TaskStatus get status; String? get projectId; bool get isUrgent; DateTime? get deadline; DateTime? get updatedAt; DateTime? get completedAt; String? get blockedById; String? get parentId; String get sortOrder; String? get planSortOrder; List<String> get labelIds; List<String> get tagIds; String? get blockerTitle; TaskStatus? get blockerStatus;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.isUrgent, isUrgent) || other.isUrgent == isUrgent)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.blockedById, blockedById) || other.blockedById == blockedById)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.planSortOrder, planSortOrder) || other.planSortOrder == planSortOrder)&&const DeepCollectionEquality().equals(other.labelIds, labelIds)&&const DeepCollectionEquality().equals(other.tagIds, tagIds)&&(identical(other.blockerTitle, blockerTitle) || other.blockerTitle == blockerTitle)&&(identical(other.blockerStatus, blockerStatus) || other.blockerStatus == blockerStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,title,createdAt,description,scheduledDate,status,projectId,isUrgent,deadline,updatedAt,completedAt,blockedById,parentId,sortOrder,planSortOrder,const DeepCollectionEquality().hash(labelIds),const DeepCollectionEquality().hash(tagIds),blockerTitle,blockerStatus]);

@override
String toString() {
  return 'Task(id: $id, title: $title, createdAt: $createdAt, description: $description, scheduledDate: $scheduledDate, status: $status, projectId: $projectId, isUrgent: $isUrgent, deadline: $deadline, updatedAt: $updatedAt, completedAt: $completedAt, blockedById: $blockedById, parentId: $parentId, sortOrder: $sortOrder, planSortOrder: $planSortOrder, labelIds: $labelIds, tagIds: $tagIds, blockerTitle: $blockerTitle, blockerStatus: $blockerStatus)';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
 String id, String title, DateTime createdAt, String? description, DateTime? scheduledDate, TaskStatus status, String? projectId, bool isUrgent, DateTime? deadline, DateTime? updatedAt, DateTime? completedAt, String? blockedById, String? parentId, String sortOrder, String? planSortOrder, List<String> labelIds, List<String> tagIds, String? blockerTitle, TaskStatus? blockerStatus
});




}
/// @nodoc
class _$TaskCopyWithImpl<$Res>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? createdAt = null,Object? description = freezed,Object? scheduledDate = freezed,Object? status = null,Object? projectId = freezed,Object? isUrgent = null,Object? deadline = freezed,Object? updatedAt = freezed,Object? completedAt = freezed,Object? blockedById = freezed,Object? parentId = freezed,Object? sortOrder = null,Object? planSortOrder = freezed,Object? labelIds = null,Object? tagIds = null,Object? blockerTitle = freezed,Object? blockerStatus = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,scheduledDate: freezed == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,projectId: freezed == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String?,isUrgent: null == isUrgent ? _self.isUrgent : isUrgent // ignore: cast_nullable_to_non_nullable
as bool,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,blockedById: freezed == blockedById ? _self.blockedById : blockedById // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as String,planSortOrder: freezed == planSortOrder ? _self.planSortOrder : planSortOrder // ignore: cast_nullable_to_non_nullable
as String?,labelIds: null == labelIds ? _self.labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as List<String>,tagIds: null == tagIds ? _self.tagIds : tagIds // ignore: cast_nullable_to_non_nullable
as List<String>,blockerTitle: freezed == blockerTitle ? _self.blockerTitle : blockerTitle // ignore: cast_nullable_to_non_nullable
as String?,blockerStatus: freezed == blockerStatus ? _self.blockerStatus : blockerStatus // ignore: cast_nullable_to_non_nullable
as TaskStatus?,
  ));
}

}


/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Task value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Task value)  $default,){
final _that = this;
switch (_that) {
case _Task():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Task value)?  $default,){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  DateTime createdAt,  String? description,  DateTime? scheduledDate,  TaskStatus status,  String? projectId,  bool isUrgent,  DateTime? deadline,  DateTime? updatedAt,  DateTime? completedAt,  String? blockedById,  String? parentId,  String sortOrder,  String? planSortOrder,  List<String> labelIds,  List<String> tagIds,  String? blockerTitle,  TaskStatus? blockerStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.title,_that.createdAt,_that.description,_that.scheduledDate,_that.status,_that.projectId,_that.isUrgent,_that.deadline,_that.updatedAt,_that.completedAt,_that.blockedById,_that.parentId,_that.sortOrder,_that.planSortOrder,_that.labelIds,_that.tagIds,_that.blockerTitle,_that.blockerStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  DateTime createdAt,  String? description,  DateTime? scheduledDate,  TaskStatus status,  String? projectId,  bool isUrgent,  DateTime? deadline,  DateTime? updatedAt,  DateTime? completedAt,  String? blockedById,  String? parentId,  String sortOrder,  String? planSortOrder,  List<String> labelIds,  List<String> tagIds,  String? blockerTitle,  TaskStatus? blockerStatus)  $default,) {final _that = this;
switch (_that) {
case _Task():
return $default(_that.id,_that.title,_that.createdAt,_that.description,_that.scheduledDate,_that.status,_that.projectId,_that.isUrgent,_that.deadline,_that.updatedAt,_that.completedAt,_that.blockedById,_that.parentId,_that.sortOrder,_that.planSortOrder,_that.labelIds,_that.tagIds,_that.blockerTitle,_that.blockerStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  DateTime createdAt,  String? description,  DateTime? scheduledDate,  TaskStatus status,  String? projectId,  bool isUrgent,  DateTime? deadline,  DateTime? updatedAt,  DateTime? completedAt,  String? blockedById,  String? parentId,  String sortOrder,  String? planSortOrder,  List<String> labelIds,  List<String> tagIds,  String? blockerTitle,  TaskStatus? blockerStatus)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.title,_that.createdAt,_that.description,_that.scheduledDate,_that.status,_that.projectId,_that.isUrgent,_that.deadline,_that.updatedAt,_that.completedAt,_that.blockedById,_that.parentId,_that.sortOrder,_that.planSortOrder,_that.labelIds,_that.tagIds,_that.blockerTitle,_that.blockerStatus);case _:
  return null;

}
}

}

/// @nodoc


class _Task extends Task {
  const _Task({required this.id, required this.title, required this.createdAt, this.description, this.scheduledDate, this.status = TaskStatus.todo, this.projectId, this.isUrgent = false, this.deadline, this.updatedAt, this.completedAt, this.blockedById, this.parentId, this.sortOrder = '', this.planSortOrder, final  List<String> labelIds = const [], final  List<String> tagIds = const [], this.blockerTitle, this.blockerStatus}): _labelIds = labelIds,_tagIds = tagIds,super._();
  

@override final  String id;
@override final  String title;
@override final  DateTime createdAt;
@override final  String? description;
@override final  DateTime? scheduledDate;
@override@JsonKey() final  TaskStatus status;
@override final  String? projectId;
@override@JsonKey() final  bool isUrgent;
@override final  DateTime? deadline;
@override final  DateTime? updatedAt;
@override final  DateTime? completedAt;
@override final  String? blockedById;
@override final  String? parentId;
@override@JsonKey() final  String sortOrder;
@override final  String? planSortOrder;
 final  List<String> _labelIds;
@override@JsonKey() List<String> get labelIds {
  if (_labelIds is EqualUnmodifiableListView) return _labelIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_labelIds);
}

 final  List<String> _tagIds;
@override@JsonKey() List<String> get tagIds {
  if (_tagIds is EqualUnmodifiableListView) return _tagIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tagIds);
}

@override final  String? blockerTitle;
@override final  TaskStatus? blockerStatus;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.isUrgent, isUrgent) || other.isUrgent == isUrgent)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.blockedById, blockedById) || other.blockedById == blockedById)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.planSortOrder, planSortOrder) || other.planSortOrder == planSortOrder)&&const DeepCollectionEquality().equals(other._labelIds, _labelIds)&&const DeepCollectionEquality().equals(other._tagIds, _tagIds)&&(identical(other.blockerTitle, blockerTitle) || other.blockerTitle == blockerTitle)&&(identical(other.blockerStatus, blockerStatus) || other.blockerStatus == blockerStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,title,createdAt,description,scheduledDate,status,projectId,isUrgent,deadline,updatedAt,completedAt,blockedById,parentId,sortOrder,planSortOrder,const DeepCollectionEquality().hash(_labelIds),const DeepCollectionEquality().hash(_tagIds),blockerTitle,blockerStatus]);

@override
String toString() {
  return 'Task(id: $id, title: $title, createdAt: $createdAt, description: $description, scheduledDate: $scheduledDate, status: $status, projectId: $projectId, isUrgent: $isUrgent, deadline: $deadline, updatedAt: $updatedAt, completedAt: $completedAt, blockedById: $blockedById, parentId: $parentId, sortOrder: $sortOrder, planSortOrder: $planSortOrder, labelIds: $labelIds, tagIds: $tagIds, blockerTitle: $blockerTitle, blockerStatus: $blockerStatus)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, DateTime createdAt, String? description, DateTime? scheduledDate, TaskStatus status, String? projectId, bool isUrgent, DateTime? deadline, DateTime? updatedAt, DateTime? completedAt, String? blockedById, String? parentId, String sortOrder, String? planSortOrder, List<String> labelIds, List<String> tagIds, String? blockerTitle, TaskStatus? blockerStatus
});




}
/// @nodoc
class __$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? createdAt = null,Object? description = freezed,Object? scheduledDate = freezed,Object? status = null,Object? projectId = freezed,Object? isUrgent = null,Object? deadline = freezed,Object? updatedAt = freezed,Object? completedAt = freezed,Object? blockedById = freezed,Object? parentId = freezed,Object? sortOrder = null,Object? planSortOrder = freezed,Object? labelIds = null,Object? tagIds = null,Object? blockerTitle = freezed,Object? blockerStatus = freezed,}) {
  return _then(_Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,scheduledDate: freezed == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,projectId: freezed == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String?,isUrgent: null == isUrgent ? _self.isUrgent : isUrgent // ignore: cast_nullable_to_non_nullable
as bool,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,blockedById: freezed == blockedById ? _self.blockedById : blockedById // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as String,planSortOrder: freezed == planSortOrder ? _self.planSortOrder : planSortOrder // ignore: cast_nullable_to_non_nullable
as String?,labelIds: null == labelIds ? _self._labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as List<String>,tagIds: null == tagIds ? _self._tagIds : tagIds // ignore: cast_nullable_to_non_nullable
as List<String>,blockerTitle: freezed == blockerTitle ? _self.blockerTitle : blockerTitle // ignore: cast_nullable_to_non_nullable
as String?,blockerStatus: freezed == blockerStatus ? _self.blockerStatus : blockerStatus // ignore: cast_nullable_to_non_nullable
as TaskStatus?,
  ));
}


}

// dart format on
