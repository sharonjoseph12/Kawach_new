import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawach/core/database/local_database.dart';
import 'package:kawach/features/sos/data/sos_remote_datasource.dart';
import 'package:kawach/features/sos/data/sos_repository_impl.dart';
import 'package:kawach/features/sos/domain/entities/sos_alert.dart';
import 'package:kawach/features/sos/data/sos_queue_manager.dart';

import 'sos_repository_test.mocks.dart';

@GenerateMocks([SosRemoteDataSource, LocalDatabase, SosQueueManager])
void main() {
  late SosRepositoryImpl repository;
  late MockSosRemoteDataSource mockRemoteDataSource;
  late MockLocalDatabase mockLocalDatabase;
  late MockSosQueueManager mockSosQueueManager;

  setUp(() {
    mockRemoteDataSource = MockSosRemoteDataSource();
    mockLocalDatabase = MockLocalDatabase();
    mockSosQueueManager = MockSosQueueManager();
    repository = SosRepositoryImpl(mockRemoteDataSource, mockLocalDatabase, mockSosQueueManager);
  });

  final tSosAlert = SosAlert(
    id: '1',
    userId: 'user_123',
    lat: 12.0,
    lng: 77.0,
    status: 'active',
    createdAt: DateTime.now(),
  );

  test('should trigger SOS remotely and save locally as synced', () async {
    // Arrange
    when(mockRemoteDataSource.triggerSOS(
      lat: anyNamed('lat'),
      lng: anyNamed('lng'),
      battery: anyNamed('battery'),
      triggerType: anyNamed('triggerType'),
    )).thenAnswer((_) async => tSosAlert);

    // Act
    final result = await repository.triggerSOS(
      lat: 12.0,
      lng: 77.0,
      battery: 80,
      triggerType: 'manual',
    );

    // Assert
    expect(result, Right(tSosAlert));
    verify(mockLocalDatabase.saveSosAlert(any)).called(2); // Once for pending, once for synced
    verify(mockRemoteDataSource.triggerSOS(
      lat: 12.0,
      lng: 77.0,
      battery: 80,
      triggerType: 'manual',
    ));
  });

  test('should return ServerFailure and keep offline record on error', () async {
    // Arrange
    when(mockRemoteDataSource.triggerSOS(
      lat: anyNamed('lat'),
      lng: anyNamed('lng'),
      battery: anyNamed('battery'),
      triggerType: anyNamed('triggerType'),
    )).thenThrow(Exception('No internet'));

    // Act
    final result = await repository.triggerSOS(
      lat: 12.0,
      lng: 77.0,
      battery: 80,
      triggerType: 'manual',
    );

    // Assert
    expect(result.isLeft(), true);
    verify(mockLocalDatabase.saveSosAlert(any)).called(1); // Only for pending
  });
}
