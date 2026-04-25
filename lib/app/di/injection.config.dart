// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i5;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i7;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:kawach/app/di/injection.dart' as _i38;
import 'package:kawach/core/config/app_config.dart' as _i3;
import 'package:kawach/core/database/local_database.dart' as _i12;
import 'package:kawach/core/security/encryption_service.dart' as _i27;
import 'package:kawach/core/security/key_manager.dart' as _i11;
import 'package:kawach/core/services/demo_mode_service.dart' as _i4;
import 'package:kawach/core/services/logger_service.dart' as _i13;
import 'package:kawach/core/services/safety_score_service.dart' as _i18;
import 'package:kawach/features/ai/guardian_ai/guardian_chat_service.dart'
    as _i8;
import 'package:kawach/features/auth/data/auth_remote_datasource.dart' as _i24;
import 'package:kawach/features/auth/data/auth_repository_impl.dart' as _i26;
import 'package:kawach/features/auth/data/profile_repository.dart' as _i16;
import 'package:kawach/features/auth/domain/auth_repository.dart' as _i25;
import 'package:kawach/features/auth/presentation/bloc/auth_bloc.dart' as _i36;
import 'package:kawach/features/diagnostics/system_health_service.dart' as _i22;
import 'package:kawach/features/evidence/evidence_capture_service.dart' as _i28;
import 'package:kawach/features/evidence/evidence_upload_service.dart' as _i29;
import 'package:kawach/features/fallback/sms_fallback_service.dart' as _i20;
import 'package:kawach/features/guardians/data/guardian_repository.dart' as _i9;
import 'package:kawach/features/guardians/live_tracking_service.dart' as _i30;
import 'package:kawach/features/map/data/escape_guidance.dart' as _i6;
import 'package:kawach/features/mesh/nearby_mesh_service.dart' as _i14;
import 'package:kawach/features/safe_walk/pin_service.dart' as _i15;
import 'package:kawach/features/safe_walk/route_deviance_monitor.dart' as _i31;
import 'package:kawach/features/safe_walk/route_deviance_service.dart' as _i17;
import 'package:kawach/features/siren/siren_service.dart' as _i19;
import 'package:kawach/features/sos/data/hardware_button_interceptor.dart'
    as _i10;
import 'package:kawach/features/sos/data/sos_queue_manager.dart' as _i32;
import 'package:kawach/features/sos/data/sos_remote_datasource.dart' as _i33;
import 'package:kawach/features/sos/data/sos_repository_impl.dart' as _i35;
import 'package:kawach/features/sos/domain/sos_repository.dart' as _i34;
import 'package:kawach/features/sos/presentation/bloc/sos_bloc.dart' as _i37;
import 'package:supabase_flutter/supabase_flutter.dart' as _i21;
import 'package:talker_flutter/talker_flutter.dart' as _i23;

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
    gh.lazySingleton<_i4.DemoModeService>(() => _i4.DemoModeService());
    gh.lazySingleton<_i5.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i6.EscapeGuidanceService>(
        () => _i6.EscapeGuidanceService());
    gh.lazySingleton<_i7.FlutterSecureStorage>(
        () => registerModule.secureStorage);
    gh.lazySingleton<_i8.GuardianChatService>(
        () => _i8.GuardianChatService(gh<_i3.AppConfig>()));
    gh.lazySingleton<_i9.GuardianRepository>(() => _i9.GuardianRepository());
    gh.lazySingleton<_i10.HardwareButtonInterceptor>(
        () => _i10.HardwareButtonInterceptor());
    gh.lazySingleton<_i11.KeyManager>(
        () => _i11.KeyManager(gh<_i7.FlutterSecureStorage>()));
    gh.lazySingleton<_i12.LocalDatabase>(() => _i12.LocalDatabase());
    gh.lazySingleton<_i13.LoggerService>(() => _i13.LoggerService());
    gh.lazySingleton<_i14.NearbyMeshService>(() => _i14.NearbyMeshService());
    gh.lazySingleton<_i15.PinService>(() => _i15.PinService());
    gh.lazySingleton<_i16.ProfileRepository>(() => _i16.ProfileRepository());
    gh.lazySingleton<_i17.RouteDevianceService>(
        () => _i17.RouteDevianceService(gh<_i5.Dio>()));
    gh.lazySingleton<_i18.SafetyScoreService>(() => _i18.SafetyScoreService());
    gh.lazySingleton<_i19.SirenService>(() => _i19.SirenService());
    gh.lazySingleton<_i20.SmsFallbackService>(() => _i20.SmsFallbackService());
    gh.lazySingleton<_i21.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i22.SystemHealthService>(
        () => _i22.SystemHealthService());
    gh.lazySingleton<_i23.Talker>(() => registerModule.talker);
    gh.lazySingleton<_i24.AuthRemoteDataSource>(
        () => _i24.AuthRemoteDataSourceImpl(gh<_i21.SupabaseClient>()));
    gh.lazySingleton<_i25.AuthRepository>(
        () => _i26.AuthRepositoryImpl(gh<_i24.AuthRemoteDataSource>()));
    gh.lazySingleton<_i27.EncryptionService>(
        () => _i27.EncryptionService(gh<_i11.KeyManager>()));
    gh.lazySingleton<_i28.EvidenceCaptureService>(
        () => _i28.EvidenceCaptureService(
              gh<_i21.SupabaseClient>(),
              gh<_i27.EncryptionService>(),
            ));
    gh.lazySingleton<_i29.EvidenceUploadService>(
        () => _i29.EvidenceUploadService(gh<_i21.SupabaseClient>()));
    gh.lazySingleton<_i30.LiveTrackingService>(
        () => _i30.LiveTrackingService(gh<_i21.SupabaseClient>()));
    gh.lazySingleton<_i31.RouteDevianceMonitor>(
        () => _i31.RouteDevianceMonitor(gh<_i17.RouteDevianceService>()));
    gh.lazySingleton<_i32.SosQueueManager>(
        () => _i32.SosQueueManager(gh<_i21.SupabaseClient>()));
    gh.lazySingleton<_i33.SosRemoteDataSource>(
        () => _i33.SosRemoteDataSourceImpl(gh<_i21.SupabaseClient>()));
    gh.lazySingleton<_i34.SosRepository>(() => _i35.SosRepositoryImpl(
          gh<_i33.SosRemoteDataSource>(),
          gh<_i12.LocalDatabase>(),
          gh<_i32.SosQueueManager>(),
          gh<_i20.SmsFallbackService>(),
          gh<_i14.NearbyMeshService>(),
          gh<_i9.GuardianRepository>(),
        ));
    gh.factory<_i36.AuthBloc>(() => _i36.AuthBloc(gh<_i25.AuthRepository>()));
    gh.factory<_i37.SosBloc>(() => _i37.SosBloc(
          gh<_i34.SosRepository>(),
          gh<_i29.EvidenceUploadService>(),
          gh<_i20.SmsFallbackService>(),
          gh<_i9.GuardianRepository>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i38.RegisterModule {}
