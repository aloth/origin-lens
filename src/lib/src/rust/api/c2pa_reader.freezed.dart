// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'c2pa_reader.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$VerificationStatus {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() verified,
    required TResult Function() signatureInvalid,
    required TResult Function() certificateExpired,
    required TResult Function() certificateUntrusted,
    required TResult Function() noManifest,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? verified,
    TResult? Function()? signatureInvalid,
    TResult? Function()? certificateExpired,
    TResult? Function()? certificateUntrusted,
    TResult? Function()? noManifest,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? verified,
    TResult Function()? signatureInvalid,
    TResult Function()? certificateExpired,
    TResult Function()? certificateUntrusted,
    TResult Function()? noManifest,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VerificationStatus_Verified value) verified,
    required TResult Function(VerificationStatus_SignatureInvalid value)
    signatureInvalid,
    required TResult Function(VerificationStatus_CertificateExpired value)
    certificateExpired,
    required TResult Function(VerificationStatus_CertificateUntrusted value)
    certificateUntrusted,
    required TResult Function(VerificationStatus_NoManifest value) noManifest,
    required TResult Function(VerificationStatus_Error value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VerificationStatus_Verified value)? verified,
    TResult? Function(VerificationStatus_SignatureInvalid value)?
    signatureInvalid,
    TResult? Function(VerificationStatus_CertificateExpired value)?
    certificateExpired,
    TResult? Function(VerificationStatus_CertificateUntrusted value)?
    certificateUntrusted,
    TResult? Function(VerificationStatus_NoManifest value)? noManifest,
    TResult? Function(VerificationStatus_Error value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VerificationStatus_Verified value)? verified,
    TResult Function(VerificationStatus_SignatureInvalid value)?
    signatureInvalid,
    TResult Function(VerificationStatus_CertificateExpired value)?
    certificateExpired,
    TResult Function(VerificationStatus_CertificateUntrusted value)?
    certificateUntrusted,
    TResult Function(VerificationStatus_NoManifest value)? noManifest,
    TResult Function(VerificationStatus_Error value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VerificationStatusCopyWith<$Res> {
  factory $VerificationStatusCopyWith(
    VerificationStatus value,
    $Res Function(VerificationStatus) then,
  ) = _$VerificationStatusCopyWithImpl<$Res, VerificationStatus>;
}

/// @nodoc
class _$VerificationStatusCopyWithImpl<$Res, $Val extends VerificationStatus>
    implements $VerificationStatusCopyWith<$Res> {
  _$VerificationStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VerificationStatus
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$VerificationStatus_VerifiedImplCopyWith<$Res> {
  factory _$$VerificationStatus_VerifiedImplCopyWith(
    _$VerificationStatus_VerifiedImpl value,
    $Res Function(_$VerificationStatus_VerifiedImpl) then,
  ) = __$$VerificationStatus_VerifiedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VerificationStatus_VerifiedImplCopyWithImpl<$Res>
    extends
        _$VerificationStatusCopyWithImpl<
          $Res,
          _$VerificationStatus_VerifiedImpl
        >
    implements _$$VerificationStatus_VerifiedImplCopyWith<$Res> {
  __$$VerificationStatus_VerifiedImplCopyWithImpl(
    _$VerificationStatus_VerifiedImpl _value,
    $Res Function(_$VerificationStatus_VerifiedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VerificationStatus
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$VerificationStatus_VerifiedImpl extends VerificationStatus_Verified {
  const _$VerificationStatus_VerifiedImpl() : super._();

  @override
  String toString() {
    return 'VerificationStatus.verified()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerificationStatus_VerifiedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() verified,
    required TResult Function() signatureInvalid,
    required TResult Function() certificateExpired,
    required TResult Function() certificateUntrusted,
    required TResult Function() noManifest,
    required TResult Function(String message) error,
  }) {
    return verified();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? verified,
    TResult? Function()? signatureInvalid,
    TResult? Function()? certificateExpired,
    TResult? Function()? certificateUntrusted,
    TResult? Function()? noManifest,
    TResult? Function(String message)? error,
  }) {
    return verified?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? verified,
    TResult Function()? signatureInvalid,
    TResult Function()? certificateExpired,
    TResult Function()? certificateUntrusted,
    TResult Function()? noManifest,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (verified != null) {
      return verified();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VerificationStatus_Verified value) verified,
    required TResult Function(VerificationStatus_SignatureInvalid value)
    signatureInvalid,
    required TResult Function(VerificationStatus_CertificateExpired value)
    certificateExpired,
    required TResult Function(VerificationStatus_CertificateUntrusted value)
    certificateUntrusted,
    required TResult Function(VerificationStatus_NoManifest value) noManifest,
    required TResult Function(VerificationStatus_Error value) error,
  }) {
    return verified(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VerificationStatus_Verified value)? verified,
    TResult? Function(VerificationStatus_SignatureInvalid value)?
    signatureInvalid,
    TResult? Function(VerificationStatus_CertificateExpired value)?
    certificateExpired,
    TResult? Function(VerificationStatus_CertificateUntrusted value)?
    certificateUntrusted,
    TResult? Function(VerificationStatus_NoManifest value)? noManifest,
    TResult? Function(VerificationStatus_Error value)? error,
  }) {
    return verified?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VerificationStatus_Verified value)? verified,
    TResult Function(VerificationStatus_SignatureInvalid value)?
    signatureInvalid,
    TResult Function(VerificationStatus_CertificateExpired value)?
    certificateExpired,
    TResult Function(VerificationStatus_CertificateUntrusted value)?
    certificateUntrusted,
    TResult Function(VerificationStatus_NoManifest value)? noManifest,
    TResult Function(VerificationStatus_Error value)? error,
    required TResult orElse(),
  }) {
    if (verified != null) {
      return verified(this);
    }
    return orElse();
  }
}

abstract class VerificationStatus_Verified extends VerificationStatus {
  const factory VerificationStatus_Verified() =
      _$VerificationStatus_VerifiedImpl;
  const VerificationStatus_Verified._() : super._();
}

/// @nodoc
abstract class _$$VerificationStatus_SignatureInvalidImplCopyWith<$Res> {
  factory _$$VerificationStatus_SignatureInvalidImplCopyWith(
    _$VerificationStatus_SignatureInvalidImpl value,
    $Res Function(_$VerificationStatus_SignatureInvalidImpl) then,
  ) = __$$VerificationStatus_SignatureInvalidImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VerificationStatus_SignatureInvalidImplCopyWithImpl<$Res>
    extends
        _$VerificationStatusCopyWithImpl<
          $Res,
          _$VerificationStatus_SignatureInvalidImpl
        >
    implements _$$VerificationStatus_SignatureInvalidImplCopyWith<$Res> {
  __$$VerificationStatus_SignatureInvalidImplCopyWithImpl(
    _$VerificationStatus_SignatureInvalidImpl _value,
    $Res Function(_$VerificationStatus_SignatureInvalidImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VerificationStatus
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$VerificationStatus_SignatureInvalidImpl
    extends VerificationStatus_SignatureInvalid {
  const _$VerificationStatus_SignatureInvalidImpl() : super._();

  @override
  String toString() {
    return 'VerificationStatus.signatureInvalid()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerificationStatus_SignatureInvalidImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() verified,
    required TResult Function() signatureInvalid,
    required TResult Function() certificateExpired,
    required TResult Function() certificateUntrusted,
    required TResult Function() noManifest,
    required TResult Function(String message) error,
  }) {
    return signatureInvalid();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? verified,
    TResult? Function()? signatureInvalid,
    TResult? Function()? certificateExpired,
    TResult? Function()? certificateUntrusted,
    TResult? Function()? noManifest,
    TResult? Function(String message)? error,
  }) {
    return signatureInvalid?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? verified,
    TResult Function()? signatureInvalid,
    TResult Function()? certificateExpired,
    TResult Function()? certificateUntrusted,
    TResult Function()? noManifest,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (signatureInvalid != null) {
      return signatureInvalid();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VerificationStatus_Verified value) verified,
    required TResult Function(VerificationStatus_SignatureInvalid value)
    signatureInvalid,
    required TResult Function(VerificationStatus_CertificateExpired value)
    certificateExpired,
    required TResult Function(VerificationStatus_CertificateUntrusted value)
    certificateUntrusted,
    required TResult Function(VerificationStatus_NoManifest value) noManifest,
    required TResult Function(VerificationStatus_Error value) error,
  }) {
    return signatureInvalid(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VerificationStatus_Verified value)? verified,
    TResult? Function(VerificationStatus_SignatureInvalid value)?
    signatureInvalid,
    TResult? Function(VerificationStatus_CertificateExpired value)?
    certificateExpired,
    TResult? Function(VerificationStatus_CertificateUntrusted value)?
    certificateUntrusted,
    TResult? Function(VerificationStatus_NoManifest value)? noManifest,
    TResult? Function(VerificationStatus_Error value)? error,
  }) {
    return signatureInvalid?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VerificationStatus_Verified value)? verified,
    TResult Function(VerificationStatus_SignatureInvalid value)?
    signatureInvalid,
    TResult Function(VerificationStatus_CertificateExpired value)?
    certificateExpired,
    TResult Function(VerificationStatus_CertificateUntrusted value)?
    certificateUntrusted,
    TResult Function(VerificationStatus_NoManifest value)? noManifest,
    TResult Function(VerificationStatus_Error value)? error,
    required TResult orElse(),
  }) {
    if (signatureInvalid != null) {
      return signatureInvalid(this);
    }
    return orElse();
  }
}

abstract class VerificationStatus_SignatureInvalid extends VerificationStatus {
  const factory VerificationStatus_SignatureInvalid() =
      _$VerificationStatus_SignatureInvalidImpl;
  const VerificationStatus_SignatureInvalid._() : super._();
}

/// @nodoc
abstract class _$$VerificationStatus_CertificateExpiredImplCopyWith<$Res> {
  factory _$$VerificationStatus_CertificateExpiredImplCopyWith(
    _$VerificationStatus_CertificateExpiredImpl value,
    $Res Function(_$VerificationStatus_CertificateExpiredImpl) then,
  ) = __$$VerificationStatus_CertificateExpiredImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VerificationStatus_CertificateExpiredImplCopyWithImpl<$Res>
    extends
        _$VerificationStatusCopyWithImpl<
          $Res,
          _$VerificationStatus_CertificateExpiredImpl
        >
    implements _$$VerificationStatus_CertificateExpiredImplCopyWith<$Res> {
  __$$VerificationStatus_CertificateExpiredImplCopyWithImpl(
    _$VerificationStatus_CertificateExpiredImpl _value,
    $Res Function(_$VerificationStatus_CertificateExpiredImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VerificationStatus
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$VerificationStatus_CertificateExpiredImpl
    extends VerificationStatus_CertificateExpired {
  const _$VerificationStatus_CertificateExpiredImpl() : super._();

  @override
  String toString() {
    return 'VerificationStatus.certificateExpired()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerificationStatus_CertificateExpiredImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() verified,
    required TResult Function() signatureInvalid,
    required TResult Function() certificateExpired,
    required TResult Function() certificateUntrusted,
    required TResult Function() noManifest,
    required TResult Function(String message) error,
  }) {
    return certificateExpired();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? verified,
    TResult? Function()? signatureInvalid,
    TResult? Function()? certificateExpired,
    TResult? Function()? certificateUntrusted,
    TResult? Function()? noManifest,
    TResult? Function(String message)? error,
  }) {
    return certificateExpired?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? verified,
    TResult Function()? signatureInvalid,
    TResult Function()? certificateExpired,
    TResult Function()? certificateUntrusted,
    TResult Function()? noManifest,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (certificateExpired != null) {
      return certificateExpired();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VerificationStatus_Verified value) verified,
    required TResult Function(VerificationStatus_SignatureInvalid value)
    signatureInvalid,
    required TResult Function(VerificationStatus_CertificateExpired value)
    certificateExpired,
    required TResult Function(VerificationStatus_CertificateUntrusted value)
    certificateUntrusted,
    required TResult Function(VerificationStatus_NoManifest value) noManifest,
    required TResult Function(VerificationStatus_Error value) error,
  }) {
    return certificateExpired(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VerificationStatus_Verified value)? verified,
    TResult? Function(VerificationStatus_SignatureInvalid value)?
    signatureInvalid,
    TResult? Function(VerificationStatus_CertificateExpired value)?
    certificateExpired,
    TResult? Function(VerificationStatus_CertificateUntrusted value)?
    certificateUntrusted,
    TResult? Function(VerificationStatus_NoManifest value)? noManifest,
    TResult? Function(VerificationStatus_Error value)? error,
  }) {
    return certificateExpired?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VerificationStatus_Verified value)? verified,
    TResult Function(VerificationStatus_SignatureInvalid value)?
    signatureInvalid,
    TResult Function(VerificationStatus_CertificateExpired value)?
    certificateExpired,
    TResult Function(VerificationStatus_CertificateUntrusted value)?
    certificateUntrusted,
    TResult Function(VerificationStatus_NoManifest value)? noManifest,
    TResult Function(VerificationStatus_Error value)? error,
    required TResult orElse(),
  }) {
    if (certificateExpired != null) {
      return certificateExpired(this);
    }
    return orElse();
  }
}

abstract class VerificationStatus_CertificateExpired
    extends VerificationStatus {
  const factory VerificationStatus_CertificateExpired() =
      _$VerificationStatus_CertificateExpiredImpl;
  const VerificationStatus_CertificateExpired._() : super._();
}

/// @nodoc
abstract class _$$VerificationStatus_CertificateUntrustedImplCopyWith<$Res> {
  factory _$$VerificationStatus_CertificateUntrustedImplCopyWith(
    _$VerificationStatus_CertificateUntrustedImpl value,
    $Res Function(_$VerificationStatus_CertificateUntrustedImpl) then,
  ) = __$$VerificationStatus_CertificateUntrustedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VerificationStatus_CertificateUntrustedImplCopyWithImpl<$Res>
    extends
        _$VerificationStatusCopyWithImpl<
          $Res,
          _$VerificationStatus_CertificateUntrustedImpl
        >
    implements _$$VerificationStatus_CertificateUntrustedImplCopyWith<$Res> {
  __$$VerificationStatus_CertificateUntrustedImplCopyWithImpl(
    _$VerificationStatus_CertificateUntrustedImpl _value,
    $Res Function(_$VerificationStatus_CertificateUntrustedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VerificationStatus
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$VerificationStatus_CertificateUntrustedImpl
    extends VerificationStatus_CertificateUntrusted {
  const _$VerificationStatus_CertificateUntrustedImpl() : super._();

  @override
  String toString() {
    return 'VerificationStatus.certificateUntrusted()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerificationStatus_CertificateUntrustedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() verified,
    required TResult Function() signatureInvalid,
    required TResult Function() certificateExpired,
    required TResult Function() certificateUntrusted,
    required TResult Function() noManifest,
    required TResult Function(String message) error,
  }) {
    return certificateUntrusted();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? verified,
    TResult? Function()? signatureInvalid,
    TResult? Function()? certificateExpired,
    TResult? Function()? certificateUntrusted,
    TResult? Function()? noManifest,
    TResult? Function(String message)? error,
  }) {
    return certificateUntrusted?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? verified,
    TResult Function()? signatureInvalid,
    TResult Function()? certificateExpired,
    TResult Function()? certificateUntrusted,
    TResult Function()? noManifest,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (certificateUntrusted != null) {
      return certificateUntrusted();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VerificationStatus_Verified value) verified,
    required TResult Function(VerificationStatus_SignatureInvalid value)
    signatureInvalid,
    required TResult Function(VerificationStatus_CertificateExpired value)
    certificateExpired,
    required TResult Function(VerificationStatus_CertificateUntrusted value)
    certificateUntrusted,
    required TResult Function(VerificationStatus_NoManifest value) noManifest,
    required TResult Function(VerificationStatus_Error value) error,
  }) {
    return certificateUntrusted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VerificationStatus_Verified value)? verified,
    TResult? Function(VerificationStatus_SignatureInvalid value)?
    signatureInvalid,
    TResult? Function(VerificationStatus_CertificateExpired value)?
    certificateExpired,
    TResult? Function(VerificationStatus_CertificateUntrusted value)?
    certificateUntrusted,
    TResult? Function(VerificationStatus_NoManifest value)? noManifest,
    TResult? Function(VerificationStatus_Error value)? error,
  }) {
    return certificateUntrusted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VerificationStatus_Verified value)? verified,
    TResult Function(VerificationStatus_SignatureInvalid value)?
    signatureInvalid,
    TResult Function(VerificationStatus_CertificateExpired value)?
    certificateExpired,
    TResult Function(VerificationStatus_CertificateUntrusted value)?
    certificateUntrusted,
    TResult Function(VerificationStatus_NoManifest value)? noManifest,
    TResult Function(VerificationStatus_Error value)? error,
    required TResult orElse(),
  }) {
    if (certificateUntrusted != null) {
      return certificateUntrusted(this);
    }
    return orElse();
  }
}

abstract class VerificationStatus_CertificateUntrusted
    extends VerificationStatus {
  const factory VerificationStatus_CertificateUntrusted() =
      _$VerificationStatus_CertificateUntrustedImpl;
  const VerificationStatus_CertificateUntrusted._() : super._();
}

/// @nodoc
abstract class _$$VerificationStatus_NoManifestImplCopyWith<$Res> {
  factory _$$VerificationStatus_NoManifestImplCopyWith(
    _$VerificationStatus_NoManifestImpl value,
    $Res Function(_$VerificationStatus_NoManifestImpl) then,
  ) = __$$VerificationStatus_NoManifestImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VerificationStatus_NoManifestImplCopyWithImpl<$Res>
    extends
        _$VerificationStatusCopyWithImpl<
          $Res,
          _$VerificationStatus_NoManifestImpl
        >
    implements _$$VerificationStatus_NoManifestImplCopyWith<$Res> {
  __$$VerificationStatus_NoManifestImplCopyWithImpl(
    _$VerificationStatus_NoManifestImpl _value,
    $Res Function(_$VerificationStatus_NoManifestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VerificationStatus
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$VerificationStatus_NoManifestImpl
    extends VerificationStatus_NoManifest {
  const _$VerificationStatus_NoManifestImpl() : super._();

  @override
  String toString() {
    return 'VerificationStatus.noManifest()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerificationStatus_NoManifestImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() verified,
    required TResult Function() signatureInvalid,
    required TResult Function() certificateExpired,
    required TResult Function() certificateUntrusted,
    required TResult Function() noManifest,
    required TResult Function(String message) error,
  }) {
    return noManifest();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? verified,
    TResult? Function()? signatureInvalid,
    TResult? Function()? certificateExpired,
    TResult? Function()? certificateUntrusted,
    TResult? Function()? noManifest,
    TResult? Function(String message)? error,
  }) {
    return noManifest?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? verified,
    TResult Function()? signatureInvalid,
    TResult Function()? certificateExpired,
    TResult Function()? certificateUntrusted,
    TResult Function()? noManifest,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (noManifest != null) {
      return noManifest();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VerificationStatus_Verified value) verified,
    required TResult Function(VerificationStatus_SignatureInvalid value)
    signatureInvalid,
    required TResult Function(VerificationStatus_CertificateExpired value)
    certificateExpired,
    required TResult Function(VerificationStatus_CertificateUntrusted value)
    certificateUntrusted,
    required TResult Function(VerificationStatus_NoManifest value) noManifest,
    required TResult Function(VerificationStatus_Error value) error,
  }) {
    return noManifest(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VerificationStatus_Verified value)? verified,
    TResult? Function(VerificationStatus_SignatureInvalid value)?
    signatureInvalid,
    TResult? Function(VerificationStatus_CertificateExpired value)?
    certificateExpired,
    TResult? Function(VerificationStatus_CertificateUntrusted value)?
    certificateUntrusted,
    TResult? Function(VerificationStatus_NoManifest value)? noManifest,
    TResult? Function(VerificationStatus_Error value)? error,
  }) {
    return noManifest?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VerificationStatus_Verified value)? verified,
    TResult Function(VerificationStatus_SignatureInvalid value)?
    signatureInvalid,
    TResult Function(VerificationStatus_CertificateExpired value)?
    certificateExpired,
    TResult Function(VerificationStatus_CertificateUntrusted value)?
    certificateUntrusted,
    TResult Function(VerificationStatus_NoManifest value)? noManifest,
    TResult Function(VerificationStatus_Error value)? error,
    required TResult orElse(),
  }) {
    if (noManifest != null) {
      return noManifest(this);
    }
    return orElse();
  }
}

abstract class VerificationStatus_NoManifest extends VerificationStatus {
  const factory VerificationStatus_NoManifest() =
      _$VerificationStatus_NoManifestImpl;
  const VerificationStatus_NoManifest._() : super._();
}

/// @nodoc
abstract class _$$VerificationStatus_ErrorImplCopyWith<$Res> {
  factory _$$VerificationStatus_ErrorImplCopyWith(
    _$VerificationStatus_ErrorImpl value,
    $Res Function(_$VerificationStatus_ErrorImpl) then,
  ) = __$$VerificationStatus_ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$VerificationStatus_ErrorImplCopyWithImpl<$Res>
    extends
        _$VerificationStatusCopyWithImpl<$Res, _$VerificationStatus_ErrorImpl>
    implements _$$VerificationStatus_ErrorImplCopyWith<$Res> {
  __$$VerificationStatus_ErrorImplCopyWithImpl(
    _$VerificationStatus_ErrorImpl _value,
    $Res Function(_$VerificationStatus_ErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VerificationStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$VerificationStatus_ErrorImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$VerificationStatus_ErrorImpl extends VerificationStatus_Error {
  const _$VerificationStatus_ErrorImpl({required this.message}) : super._();

  @override
  final String message;

  @override
  String toString() {
    return 'VerificationStatus.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerificationStatus_ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of VerificationStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VerificationStatus_ErrorImplCopyWith<_$VerificationStatus_ErrorImpl>
  get copyWith =>
      __$$VerificationStatus_ErrorImplCopyWithImpl<
        _$VerificationStatus_ErrorImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() verified,
    required TResult Function() signatureInvalid,
    required TResult Function() certificateExpired,
    required TResult Function() certificateUntrusted,
    required TResult Function() noManifest,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? verified,
    TResult? Function()? signatureInvalid,
    TResult? Function()? certificateExpired,
    TResult? Function()? certificateUntrusted,
    TResult? Function()? noManifest,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? verified,
    TResult Function()? signatureInvalid,
    TResult Function()? certificateExpired,
    TResult Function()? certificateUntrusted,
    TResult Function()? noManifest,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VerificationStatus_Verified value) verified,
    required TResult Function(VerificationStatus_SignatureInvalid value)
    signatureInvalid,
    required TResult Function(VerificationStatus_CertificateExpired value)
    certificateExpired,
    required TResult Function(VerificationStatus_CertificateUntrusted value)
    certificateUntrusted,
    required TResult Function(VerificationStatus_NoManifest value) noManifest,
    required TResult Function(VerificationStatus_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VerificationStatus_Verified value)? verified,
    TResult? Function(VerificationStatus_SignatureInvalid value)?
    signatureInvalid,
    TResult? Function(VerificationStatus_CertificateExpired value)?
    certificateExpired,
    TResult? Function(VerificationStatus_CertificateUntrusted value)?
    certificateUntrusted,
    TResult? Function(VerificationStatus_NoManifest value)? noManifest,
    TResult? Function(VerificationStatus_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VerificationStatus_Verified value)? verified,
    TResult Function(VerificationStatus_SignatureInvalid value)?
    signatureInvalid,
    TResult Function(VerificationStatus_CertificateExpired value)?
    certificateExpired,
    TResult Function(VerificationStatus_CertificateUntrusted value)?
    certificateUntrusted,
    TResult Function(VerificationStatus_NoManifest value)? noManifest,
    TResult Function(VerificationStatus_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class VerificationStatus_Error extends VerificationStatus {
  const factory VerificationStatus_Error({required final String message}) =
      _$VerificationStatus_ErrorImpl;
  const VerificationStatus_Error._() : super._();

  String get message;

  /// Create a copy of VerificationStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VerificationStatus_ErrorImplCopyWith<_$VerificationStatus_ErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}
