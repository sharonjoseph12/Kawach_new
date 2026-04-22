// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i6;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:kawach/app/di/injection.dart' as _i28;
import 'package:kawach/core/config/app_config.dart' as _i3;
import 'package:kawach/core/database/local_database.dart' as _i9;
import 'package:kawach/core/security/encryption_service.dart' as _i18;
import 'package:kawach/core/security/key_manager.dart' as _i8;
import 'package:kawach/core/services/logger_service.dart' as _i10;
import 'package:kawach/features/ai/guardian_ai/guardian_chat_service.dart'
    as _i7;
import 'package:kawach/features/auth/data/auth_remote_datasource.dart' as _i15;
import 'package:kawach/features/auth/data/auth_repository_impl.dart' as _i17;
import 'package:kawach/features/auth/domain/auth_repository.dart' as _i16;
import 'package:kawach/features/auth/presentation/bloc/auth_bloc.dart' as _i26;
import 'package:kawach/features/diagnostics/system_health_service.dart' as _i14;
import 'package:kawach/features/evidence/evidence_capture_service.dart' as _i19;
import 'package:kawach/features/evidence/evidence_upload_service.dart' as _i20;
import 'package:kawach/features/guardians/live_tracking_service.dart' as _i21;
import 'package:kawach/features/map/data/escape_guidance.dart' as _i5;
import 'package:kawach/features/mesh/ble_mesh_service.dart' as _i4;
import 'package:kawach/features/safe_walk/pin_service.dart' as _i11;
import 'package:kawach/features/siren/siren_service.dart' as _i12;
import 'package:kawach/features/sos/data/sos_queue_manager.dart' as _i22;
import 'package:kawach/features/sos/data/sos_remote_datasource.dart' as _i23;
import 'package:kawach/features/sos/data/sos_repository_impl.dart' as _i25;
import 'package:kawach/features/sos/domain/sos_repository.dart' as _i24;
import 'package:kawach/features/sos/presentation/bloc/sos_bloc.dart' as _i27;
import 'package:supabase_flutter/supabase_flutter.dart' as _i13;

extension GetItInjectableX on _i1.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i1.GetIt init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i3.AppConfig>(() => _i3.AppConfig.dev());
    gh.lazySingleton<_i4.BleMeshService>(() => _i4.BleMeshService());
    gh.lazySingleton<_i5.EscapeGuidanceService>(
        () => _i5.EscapeGuidanceService());
    gh.lazySingleton<_i6.FlutterSecureStorage>(
        () => registerModule.secureStorage);
    gh.lazySingleton<_i7.GuardianChatService>(
        () => _i7.GuardianChatService(gh<_i3.AppConfig>()));
    gh.lazySingleton<_i8.KeyManager>(
        () => _i8.KeyManager(gh<_i6.FlutterSecureStorage>()));
    gh.lazySingleton<_i9.LocalDatabase>(() => _i9.LocalDatabase());
    gh.lazySingleton<_i10.LoggerService>(() => _i10.LoggerService());
    gh.lazySingleton<_i11.PinService>(() => _i11.PinService());
    gh.lazySingleton<_i12.SirenService>(() => _i12.SirenService());
    gh.lazySingleton<_i13.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i14.SystemHealthService>(
        () => _i14.SystemHealthService());
    gh.lazySingleton<_i15.AuthRemoteDataSource>(
        () => _i15.AuthRemoteDataSourceImpl(gh<_i13.SupabaseClient>()));
    gh.lazySingleton<_i16.AuthRepository>(
        () => _i17.AuthRepositoryImpl(gh<_i15.AuthRemoteDataSource>()));
    gh.lazySingleton<_i18.EncryptionService>(
        () => _i18.EncryptionService(gh<_i8.KeyManager>()));
    gh.lazySingleton<_i19.EvidenceCaptureService>(
        () => _i19.EvidenceCaptureService(
              gh<_i13.SupabaseClient>(),
              gh<_i18.EncryptionService>(),
            ));
    gh.lazySingleton<_i20.EvidenceUploadService>(
        () => _i20.EvidenceUploadService(gh<_i13.SupabaseClient>()));
    gh.lazySingleton<_i21.LiveTrackingService>(
        () => _i21.LiveTrackingService(gh<_i13.SupabaseClient>()));
    gh.lazySingleton<_i22.SosQueueManager>(
        () => _i22.SosQueueManager(gh<_i13.SupabaseClient>()));
    gh.lazySingleton<_i23.SosRemoteDataSource>(
        () => _i23.SosRemoteDataSourceImpl(gh<_i13.SupabaseClient>()));
    gh.lazySingleton<_i24.SosRepository>(() => _i25.SosRepositoryImpl(
          gh<_i23.SosRemoteDataSource>(),
          gh<_i9.LocalDatabase>(),
          gh<_i22.SosQueueManager>(),
        ));
    gh.factory<_i26.AuthBloc>(() => _i26.AuthBloc(gh<_i16.AuthRepository>()));
    gh.factory<_i27.SosBloc>(() => _i27.SosBloc(
          gh<_i24.SosRepository>(),
          gh<_i20.EvidenceUploadService>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i28.RegisterModule {}
