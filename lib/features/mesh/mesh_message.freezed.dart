// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mesh_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MeshMessage _$MeshMessageFromJson(Map<String, dynamic> json) {
  return _MeshMessage.fromJson(json);
}

/// @nodoc
mixin _$MeshMessage {
  String get msgId => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError; // SOS / LOCATION / ACK
  String get originUserId => throw _privateConstructorUsedError;
  String get payload => throw _privateConstructorUsedError; // Encrypted base64
  int get ttl => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  String? get signature => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MeshMessageCopyWith<MeshMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MeshMessageCopyWith<$Res> {
  factory $MeshMessageCopyWith(
          MeshMessage value, $Res Function(MeshMessage) then) =
      _$MeshMessageCopyWithImpl<$Res, MeshMessage>;
  @useResult
  $Res call(
      {String msgId,
      String type,
      String originUserId,
      String payload,
      int ttl,
      DateTime timestamp,
      String? signature});
}

/// @nodoc
class _$MeshMessageCopyWithImpl<$Res, $Val extends MeshMessage>
    implements $MeshMessageCopyWith<$Res> {
  _$MeshMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? msgId = null,
    Object? type = null,
    Object? originUserId = null,
    Object? payload = null,
    Object? ttl = null,
    Object? timestamp = null,
    Object? signature = freezed,
  }) {
    return _then(_value.copyWith(
      msgId: null == msgId
          ? _value.msgId
          : msgId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      originUserId: null == originUserId
          ? _value.originUserId
          : originUserId // ignore: cast_nullable_to_non_nullable
              as String,
      payload: null == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as String,
      ttl: null == ttl
          ? _value.ttl
          : ttl // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      signature: freezed == signature
          ? _value.signature
          : signature // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MeshMessageImplCopyWith<$Res>
    implements $MeshMessageCopyWith<$Res> {
  factory _$$MeshMessageImplCopyWith(
          _$MeshMessageImpl value, $Res Function(_$MeshMessageImpl) then) =
      __$$MeshMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String msgId,
      String type,
      String originUserId,
      String payload,
      int ttl,
      DateTime timestamp,
      String? signature});
}

/// @nodoc
class __$$MeshMessageImplCopyWithImpl<$Res>
    extends _$MeshMessageCopyWithImpl<$Res, _$MeshMessageImpl>
    implements _$$MeshMessageImplCopyWith<$Res> {
  __$$MeshMessageImplCopyWithImpl(
      _$MeshMessageImpl _value, $Res Function(_$MeshMessageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? msgId = null,
    Object? type = null,
    Object? originUserId = null,
    Object? payload = null,
    Object? ttl = null,
    Object? timestamp = null,
    Object? signature = freezed,
  }) {
    return _then(_$MeshMessageImpl(
      msgId: null == msgId
          ? _value.msgId
          : msgId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      originUserId: null == originUserId
          ? _value.originUserId
          : originUserId // ignore: cast_nullable_to_non_nullable
              as String,
      payload: null == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as String,
      ttl: null == ttl
          ? _value.ttl
          : ttl // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      signature: freezed == signature
          ? _value.signature
          : signature // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MeshMessageImpl implements _MeshMessage {
  const _$MeshMessageImpl(
      {required this.msgId,
      required this.type,
      required this.originUserId,
      required this.payload,
      this.ttl = 8,
      required this.timestamp,
      this.signature});

  factory _$MeshMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$MeshMessageImplFromJson(json);

  @override
  final String msgId;
  @override
  final String type;
// SOS / LOCATION / ACK
  @override
  final String originUserId;
  @override
  final String payload;
// Encrypted base64
  @override
  @JsonKey()
  final int ttl;
  @override
  final DateTime timestamp;
  @override
  final String? signature;

  @override
  String toString() {
    return 'MeshMessage(msgId: $msgId, type: $type, originUserId: $originUserId, payload: $payload, ttl: $ttl, timestamp: $timestamp, signature: $signature)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MeshMessageImpl &&
            (identical(other.msgId, msgId) || other.msgId == msgId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.originUserId, originUserId) ||
                other.originUserId == originUserId) &&
            (identical(other.payload, payload) || other.payload == payload) &&
            (identical(other.ttl, ttl) || other.ttl == ttl) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.signature, signature) ||
                other.signature == signature));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, msgId, type, originUserId,
      payload, ttl, timestamp, signature);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MeshMessageImplCopyWith<_$MeshMessageImpl> get copyWith =>
      __$$MeshMessageImplCopyWithImpl<_$MeshMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MeshMessageImplToJson(
      this,
    );
  }
}

abstract class _MeshMessage implements MeshMessage {
  const factory _MeshMessage(
      {required final String msgId,
      required final String type,
      required final String originUserId,
      required final String payload,
      final int ttl,
      required final DateTime timestamp,
      final String? signature}) = _$MeshMessageImpl;

  factory _MeshMessage.fromJson(Map<String, dynamic> json) =
      _$MeshMessageImpl.fromJson;

  @override
  String get msgId;
  @override
  String get type;
  @override // SOS / LOCATION / ACK
  String get originUserId;
  @override
  String get payload;
  @override // Encrypted base64
  int get ttl;
  @override
  DateTime get timestamp;
  @override
  String? get signature;
  @override
  @JsonKey(ignore: true)
  _$$MeshMessageImplCopyWith<_$MeshMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
