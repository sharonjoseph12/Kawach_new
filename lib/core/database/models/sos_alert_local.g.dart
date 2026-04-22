// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_alert_local.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSosAlertLocalCollection on Isar {
  IsarCollection<SosAlertLocal> get sosAlertLocals => this.collection();
}

const SosAlertLocalSchema = CollectionSchema(
  name: r'SosAlertLocal',
  id: -7205876650076615852,
  properties: {
    r'batteryPct': PropertySchema(
      id: 0,
      name: r'batteryPct',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isSynced': PropertySchema(
      id: 2,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lat': PropertySchema(
      id: 3,
      name: r'lat',
      type: IsarType.double,
    ),
    r'lng': PropertySchema(
      id: 4,
      name: r'lng',
      type: IsarType.double,
    ),
    r'remoteId': PropertySchema(
      id: 5,
      name: r'remoteId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 6,
      name: r'status',
      type: IsarType.string,
    ),
    r'syncedAt': PropertySchema(
      id: 7,
      name: r'syncedAt',
      type: IsarType.dateTime,
    ),
    r'triggerType': PropertySchema(
      id: 8,
      name: r'triggerType',
      type: IsarType.string,
    )
  },
  estimateSize: _sosAlertLocalEstimateSize,
  serialize: _sosAlertLocalSerialize,
  deserialize: _sosAlertLocalDeserialize,
  deserializeProp: _sosAlertLocalDeserializeProp,
  idName: r'id',
  indexes: {
    r'remoteId': IndexSchema(
      id: 6301175856541681032,
      name: r'remoteId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'remoteId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _sosAlertLocalGetId,
  getLinks: _sosAlertLocalGetLinks,
  attach: _sosAlertLocalAttach,
  version: '3.1.0+1',
);

int _sosAlertLocalEstimateSize(
  SosAlertLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.remoteId.length * 3;
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.triggerType.length * 3;
  return bytesCount;
}

void _sosAlertLocalSerialize(
  SosAlertLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.batteryPct);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeBool(offsets[2], object.isSynced);
  writer.writeDouble(offsets[3], object.lat);
  writer.writeDouble(offsets[4], object.lng);
  writer.writeString(offsets[5], object.remoteId);
  writer.writeString(offsets[6], object.status);
  writer.writeDateTime(offsets[7], object.syncedAt);
  writer.writeString(offsets[8], object.triggerType);
}

SosAlertLocal _sosAlertLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SosAlertLocal();
  object.batteryPct = reader.readLong(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[2]);
  object.lat = reader.readDouble(offsets[3]);
  object.lng = reader.readDouble(offsets[4]);
  object.remoteId = reader.readString(offsets[5]);
  object.status = reader.readString(offsets[6]);
  object.syncedAt = reader.readDateTimeOrNull(offsets[7]);
  object.triggerType = reader.readString(offsets[8]);
  return object;
}

P _sosAlertLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _sosAlertLocalGetId(SosAlertLocal object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _sosAlertLocalGetLinks(SosAlertLocal object) {
  return [];
}

void _sosAlertLocalAttach(
    IsarCollection<dynamic> col, Id id, SosAlertLocal object) {
  object.id = id;
}

extension SosAlertLocalByIndex on IsarCollection<SosAlertLocal> {
  Future<SosAlertLocal?> getByRemoteId(String remoteId) {
    return getByIndex(r'remoteId', [remoteId]);
  }

  SosAlertLocal? getByRemoteIdSync(String remoteId) {
    return getByIndexSync(r'remoteId', [remoteId]);
  }

  Future<bool> deleteByRemoteId(String remoteId) {
    return deleteByIndex(r'remoteId', [remoteId]);
  }

  bool deleteByRemoteIdSync(String remoteId) {
    return deleteByIndexSync(r'remoteId', [remoteId]);
  }

  Future<List<SosAlertLocal?>> getAllByRemoteId(List<String> remoteIdValues) {
    final values = remoteIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'remoteId', values);
  }

  List<SosAlertLocal?> getAllByRemoteIdSync(List<String> remoteIdValues) {
    final values = remoteIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'remoteId', values);
  }

  Future<int> deleteAllByRemoteId(List<String> remoteIdValues) {
    final values = remoteIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'remoteId', values);
  }

  int deleteAllByRemoteIdSync(List<String> remoteIdValues) {
    final values = remoteIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'remoteId', values);
  }

  Future<Id> putByRemoteId(SosAlertLocal object) {
    return putByIndex(r'remoteId', object);
  }

  Id putByRemoteIdSync(SosAlertLocal object, {bool saveLinks = true}) {
    return putByIndexSync(r'remoteId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRemoteId(List<SosAlertLocal> objects) {
    return putAllByIndex(r'remoteId', objects);
  }

  List<Id> putAllByRemoteIdSync(List<SosAlertLocal> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'remoteId', objects, saveLinks: saveLinks);
  }
}

extension SosAlertLocalQueryWhereSort
    on QueryBuilder<SosAlertLocal, SosAlertLocal, QWhere> {
  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SosAlertLocalQueryWhere
    on QueryBuilder<SosAlertLocal, SosAlertLocal, QWhereClause> {
  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterWhereClause> remoteIdEqualTo(
      String remoteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'remoteId',
        value: [remoteId],
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterWhereClause>
      remoteIdNotEqualTo(String remoteId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [],
              upper: [remoteId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [remoteId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [remoteId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [],
              upper: [remoteId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension SosAlertLocalQueryFilter
    on QueryBuilder<SosAlertLocal, SosAlertLocal, QFilterCondition> {
  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      batteryPctEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'batteryPct',
        value: value,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      batteryPctGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'batteryPct',
        value: value,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      batteryPctLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'batteryPct',
        value: value,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      batteryPctBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'batteryPct',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition> latEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      latGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition> latLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition> latBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition> lngEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      lngGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition> lngLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition> lngBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lng',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      remoteIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      remoteIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      remoteIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      remoteIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remoteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      remoteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      remoteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      remoteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      remoteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remoteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      remoteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      remoteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      syncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'syncedAt',
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      syncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'syncedAt',
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      syncedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      syncedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      syncedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      syncedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      triggerTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'triggerType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      triggerTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'triggerType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      triggerTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'triggerType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      triggerTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'triggerType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      triggerTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'triggerType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      triggerTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'triggerType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      triggerTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'triggerType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      triggerTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'triggerType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      triggerTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'triggerType',
        value: '',
      ));
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterFilterCondition>
      triggerTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'triggerType',
        value: '',
      ));
    });
  }
}

extension SosAlertLocalQueryObject
    on QueryBuilder<SosAlertLocal, SosAlertLocal, QFilterCondition> {}

extension SosAlertLocalQueryLinks
    on QueryBuilder<SosAlertLocal, SosAlertLocal, QFilterCondition> {}

extension SosAlertLocalQuerySortBy
    on QueryBuilder<SosAlertLocal, SosAlertLocal, QSortBy> {
  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> sortByBatteryPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batteryPct', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy>
      sortByBatteryPctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batteryPct', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> sortByLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> sortByLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> sortByLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lng', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> sortByLngDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lng', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy>
      sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> sortBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy>
      sortBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> sortByTriggerType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'triggerType', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy>
      sortByTriggerTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'triggerType', Sort.desc);
    });
  }
}

extension SosAlertLocalQuerySortThenBy
    on QueryBuilder<SosAlertLocal, SosAlertLocal, QSortThenBy> {
  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> thenByBatteryPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batteryPct', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy>
      thenByBatteryPctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batteryPct', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> thenByLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> thenByLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> thenByLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lng', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> thenByLngDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lng', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy>
      thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> thenBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy>
      thenBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy> thenByTriggerType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'triggerType', Sort.asc);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QAfterSortBy>
      thenByTriggerTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'triggerType', Sort.desc);
    });
  }
}

extension SosAlertLocalQueryWhereDistinct
    on QueryBuilder<SosAlertLocal, SosAlertLocal, QDistinct> {
  QueryBuilder<SosAlertLocal, SosAlertLocal, QDistinct> distinctByBatteryPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'batteryPct');
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QDistinct> distinctByLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lat');
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QDistinct> distinctByLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lng');
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QDistinct> distinctByRemoteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QDistinct> distinctBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedAt');
    });
  }

  QueryBuilder<SosAlertLocal, SosAlertLocal, QDistinct> distinctByTriggerType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'triggerType', caseSensitive: caseSensitive);
    });
  }
}

extension SosAlertLocalQueryProperty
    on QueryBuilder<SosAlertLocal, SosAlertLocal, QQueryProperty> {
  QueryBuilder<SosAlertLocal, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SosAlertLocal, int, QQueryOperations> batteryPctProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'batteryPct');
    });
  }

  QueryBuilder<SosAlertLocal, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<SosAlertLocal, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<SosAlertLocal, double, QQueryOperations> latProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lat');
    });
  }

  QueryBuilder<SosAlertLocal, double, QQueryOperations> lngProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lng');
    });
  }

  QueryBuilder<SosAlertLocal, String, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<SosAlertLocal, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<SosAlertLocal, DateTime?, QQueryOperations> syncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedAt');
    });
  }

  QueryBuilder<SosAlertLocal, String, QQueryOperations> triggerTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'triggerType');
    });
  }
}
