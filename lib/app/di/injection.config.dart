// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i4;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i6;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:kawach/app/di/injection.dart' as _i35;
import 'package:kawach/core/config/app_config.dart' as _i3;
import 'package:kawach/core/database/local_database.dart' as _i11;
import 'package:kawach/core/security/encryption_service.dart' as _i24;
import 'package:kawach/core/security/key_manager.dart' as _i10;
import 'package:kawach/core/services/logger_service.dart' as _i12;
import 'package:kawach/features/ai/guardian_ai/guardian_chat_service.dart'
    as _i7;
import 'package:kawach/features/auth/data/auth_remote_datasource.dart' as _i21;
import 'package:kawach/features/auth/data/auth_repository_impl.dart' as _i23;
import 'package:kawach/features/auth/data/profile_repository.dart' as _i15;
import 'package:kawach/features/auth/domain/auth_repository.dart' as _i22;
import 'package:kawach/features/auth/presentation/bloc/auth_bloc.dart' as _i33;
import 'package:kawach/features/diagnostics/system_health_service.dart' as _i20;
import 'package:kawach/features/evidence/evidence_capture_service.dart' as _i25;
import 'package:kawach/features/evidence/evidence_upload_service.dart' as _i26;
import 'package:kawach/features/fallback/sms_fallback_service.dart' as _i18;
import 'package:kawach/features/guardians/data/guardian_repository.dart' as _i8;
import 'package:kawach/features/guardians/live_tracking_service.dart' as _i27;
import 'package:kawach/features/map/data/escape_guidance.dart' as _i5;
import 'package:kawach/features/mesh/nearby_mesh_service.dart' as _i13;
import 'package:kawach/features/safe_walk/pin_service.dart' as _i14;
import 'package:kawach/features/safe_walk/route_deviance_monitor.dart' as _i28;
import 'package:kawach/features/safe_walk/route_deviance_service.dart' as _i16;
import 'package:kawach/features/siren/siren_service.dart' as _i17;
import 'package:kawach/features/sos/data/hardware_button_interceptor.dart'
    as _i9;
import 'package:kawach/features/sos/data/sos_queue_manager.dart' as _i29;
import 'package:kawach/features/sos/data/sos_remote_datasource.dart' as _i30;
import 'package:kawach/features/sos/data/sos_repository_impl.dart' as _i32;
import 'package:kawach/features/sos/domain/sos_repository.dart' as _i31;
import 'package:kawach/features/sos/presentation/bloc/sos_bloc.dart' as _i34;
import 'package:supabase_flutter/supabase_flutter.dart' as _i19;

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
    gh.lazySingleton<_i4.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i5.EscapeGuidanceService>(
        () => _i5.EscapeGuidanceService());
    gh.lazySingleton<_i6.FlutterSecureStorage>(
        () => registerModule.secureStorage);
    gh.lazySingleton<_i7.GuardianChatService>(
        () => _i7.GuardianChatService(gh<_i3.AppConfig>()));
    gh.lazySingleton<_i8.GuardianRepository>(() => _i8.GuardianRepository());
    gh.lazySingleton<_i9.HardwareButtonInterceptor>(
        () => _i9.HardwareButtonInterceptor());
    gh.lazySingleton<_i10.KeyManager>(
        () => _i10.KeyManager(gh<_i6.FlutterSecureStorage>()));
    gh.lazySingleton<_i11.LocalDatabase>(() => _i11.LocalDatabase());
    gh.lazySingleton<_i12.LoggerService>(() => _i12.LoggerService());
    gh.lazySingleton<_i13.NearbyMeshService>(() => _i13.NearbyMeshService());
    gh.lazySingleton<_i14.PinService>(() => _i14.PinService());
    gh.lazySingleton<_i15.ProfileRepository>(() => _i15.ProfileRepository());
    gh.lazySingleton<_i16.RouteDevianceService>(
        () => _i16.RouteDevianceService(gh<_i4.Dio>()));
    gh.lazySingleton<_i17.SirenService>(() => _i17.SirenService());
    gh.lazySingleton<_i18.SmsFallbackService>(() => _i18.SmsFallbackService());
    gh.lazySingleton<_i19.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i20.SystemHealthService>(
        () => _i20.SystemHealthService());
    gh.lazySingleton<_i21.AuthRemoteDataSource>(
        () => _i21.AuthRemoteDataSourceImpl(gh<_i19.SupabaseClient>()));
    gh.lazySingleton<_i22.AuthRepository>(
        () => _i23.AuthRepositoryImpl(gh<_i21.AuthRemoteDataSource>()));
    gh.lazySingleton<_i24.EncryptionService>(
        () => _i24.EncryptionService(gh<_i10.KeyManager>()));
    gh.lazySingleton<_i25.EvidenceCaptureService>(
        () => _i25.EvidenceCaptureService(
              gh<_i19.SupabaseClient>(),
              gh<_i24.EncryptionService>(),
            ));
    gh.lazySingleton<_i26.EvidenceUploadService>(
        () => _i26.EvidenceUploadService(gh<_i19.SupabaseClient>()));
    gh.lazySingleton<_i27.LiveTrackingService>(
        () => _i27.LiveTrackingService(gh<_i19.SupabaseClient>()));
    gh.lazySingleton<_i28.RouteDevianceMonitor>(
        () => _i28.RouteDevianceMonitor(gh<_i16.RouteDevianceService>()));
    gh.lazySingleton<_i29.SosQueueManager>(
        () => _i29.SosQueueManager(gh<_i19.SupabaseClient>()));
    gh.lazySingleton<_i30.SosRemoteDataSource>(
        () => _i30.SosRemoteDataSourceImpl(gh<_i19.SupabaseClient>()));
    gh.lazySingleton<_i31.SosRepository>(() => _i32.SosRepositoryImpl(
          gh<_i30.SosRemoteDataSource>(),
          gh<_i11.LocalDatabase>(),
          gh<_i29.SosQueueManager>(),
          gh<_i18.SmsFallbackService>(),
          gh<_i13.NearbyMeshService>(),
          gh<_i8.GuardianRepository>(),
        ));
    gh.factory<_i33.AuthBloc>(() => _i33.AuthBloc(gh<_i22.AuthRepository>()));
    gh.factory<_i34.SosBloc>(() => _i34.SosBloc(
          gh<_i31.SosRepository>(),
          gh<_i26.EvidenceUploadService>(),
          gh<_i18.SmsFallbackService>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i35.RegisterModule {}
