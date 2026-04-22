// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evidence_local.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEvidenceLocalCollection on Isar {
  IsarCollection<EvidenceLocal> get evidenceLocals => this.collection();
}

const EvidenceLocalSchema = CollectionSchema(
  name: r'EvidenceLocal',
  id: -9157306495414199765,
  properties: {
    r'capturedAt': PropertySchema(
      id: 0,
      name: r'capturedAt',
      type: IsarType.dateTime,
    ),
    r'hash': PropertySchema(
      id: 1,
      name: r'hash',
      type: IsarType.string,
    ),
    r'isUploaded': PropertySchema(
      id: 2,
      name: r'isUploaded',
      type: IsarType.bool,
    ),
    r'localPath': PropertySchema(
      id: 3,
      name: r'localPath',
      type: IsarType.string,
    ),
    r'remoteStoragePath': PropertySchema(
      id: 4,
      name: r'remoteStoragePath',
      type: IsarType.string,
    ),
    r'sizeBytes': PropertySchema(
      id: 5,
      name: r'sizeBytes',
      type: IsarType.long,
    ),
    r'sosRemoteId': PropertySchema(
      id: 6,
      name: r'sosRemoteId',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 7,
      name: r'type',
      type: IsarType.string,
    )
  },
  estimateSize: _evidenceLocalEstimateSize,
  serialize: _evidenceLocalSerialize,
  deserialize: _evidenceLocalDeserialize,
  deserializeProp: _evidenceLocalDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _evidenceLocalGetId,
  getLinks: _evidenceLocalGetLinks,
  attach: _evidenceLocalAttach,
  version: '3.1.0+1',
);

int _evidenceLocalEstimateSize(
  EvidenceLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.hash.length * 3;
  bytesCount += 3 + object.localPath.length * 3;
  {
    final value = object.remoteStoragePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sosRemoteId.length * 3;
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _evidenceLocalSerialize(
  EvidenceLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.capturedAt);
  writer.writeString(offsets[1], object.hash);
  writer.writeBool(offsets[2], object.isUploaded);
  writer.writeString(offsets[3], object.localPath);
  writer.writeString(offsets[4], object.remoteStoragePath);
  writer.writeLong(offsets[5], object.sizeBytes);
  writer.writeString(offsets[6], object.sosRemoteId);
  writer.writeString(offsets[7], object.type);
}

EvidenceLocal _evidenceLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EvidenceLocal();
  object.capturedAt = reader.readDateTime(offsets[0]);
  object.hash = reader.readString(offsets[1]);
  object.id = id;
  object.isUploaded = reader.readBool(offsets[2]);
  object.localPath = reader.readString(offsets[3]);
  object.remoteStoragePath = reader.readStringOrNull(offsets[4]);
  object.sizeBytes = reader.readLong(offsets[5]);
  object.sosRemoteId = reader.readString(offsets[6]);
  object.type = reader.readString(offsets[7]);
  return object;
}

P _evidenceLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _evidenceLocalGetId(EvidenceLocal object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _evidenceLocalGetLinks(EvidenceLocal object) {
  return [];
}

void _evidenceLocalAttach(
    IsarCollection<dynamic> col, Id id, EvidenceLocal object) {
  object.id = id;
}

extension EvidenceLocalQueryWhereSort
    on QueryBuilder<EvidenceLocal, EvidenceLocal, QWhere> {
  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension EvidenceLocalQueryWhere
    on QueryBuilder<EvidenceLocal, EvidenceLocal, QWhereClause> {
  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterWhereClause> idBetween(
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
}

extension EvidenceLocalQueryFilter
    on QueryBuilder<EvidenceLocal, EvidenceLocal, QFilterCondition> {
  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      capturedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'capturedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      capturedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'capturedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      capturedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'capturedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      capturedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'capturedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition> hashEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      hashGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      hashLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition> hashBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      hashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      hashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      hashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition> hashMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      hashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hash',
        value: '',
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      hashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hash',
        value: '',
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
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

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition> idBetween(
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

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      isUploadedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isUploaded',
        value: value,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      localPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      localPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      localPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      localPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      localPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      localPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      localPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      localPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      localPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localPath',
        value: '',
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      localPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localPath',
        value: '',
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      remoteStoragePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remoteStoragePath',
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      remoteStoragePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remoteStoragePath',
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      remoteStoragePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteStoragePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      remoteStoragePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remoteStoragePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      remoteStoragePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remoteStoragePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      remoteStoragePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remoteStoragePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      remoteStoragePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remoteStoragePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      remoteStoragePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remoteStoragePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      remoteStoragePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remoteStoragePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      remoteStoragePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remoteStoragePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      remoteStoragePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteStoragePath',
        value: '',
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      remoteStoragePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remoteStoragePath',
        value: '',
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      sizeBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      sizeBytesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      sizeBytesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      sizeBytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sizeBytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      sosRemoteIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sosRemoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      sosRemoteIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sosRemoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      sosRemoteIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sosRemoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      sosRemoteIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sosRemoteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      sosRemoteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sosRemoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      sosRemoteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sosRemoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      sosRemoteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sosRemoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      sosRemoteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sosRemoteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      sosRemoteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sosRemoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      sosRemoteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sosRemoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition> typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition> typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition> typeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension EvidenceLocalQueryObject
    on QueryBuilder<EvidenceLocal, EvidenceLocal, QFilterCondition> {}

extension EvidenceLocalQueryLinks
    on QueryBuilder<EvidenceLocal, EvidenceLocal, QFilterCondition> {}

extension EvidenceLocalQuerySortBy
    on QueryBuilder<EvidenceLocal, EvidenceLocal, QSortBy> {
  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> sortByCapturedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capturedAt', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy>
      sortByCapturedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capturedAt', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> sortByHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> sortByHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> sortByIsUploaded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUploaded', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy>
      sortByIsUploadedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUploaded', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> sortByLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy>
      sortByLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy>
      sortByRemoteStoragePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteStoragePath', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy>
      sortByRemoteStoragePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteStoragePath', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> sortBySizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeBytes', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy>
      sortBySizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeBytes', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> sortBySosRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sosRemoteId', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy>
      sortBySosRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sosRemoteId', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension EvidenceLocalQuerySortThenBy
    on QueryBuilder<EvidenceLocal, EvidenceLocal, QSortThenBy> {
  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> thenByCapturedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capturedAt', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy>
      thenByCapturedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capturedAt', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> thenByHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> thenByHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> thenByIsUploaded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUploaded', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy>
      thenByIsUploadedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUploaded', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> thenByLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy>
      thenByLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy>
      thenByRemoteStoragePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteStoragePath', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy>
      thenByRemoteStoragePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteStoragePath', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> thenBySizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeBytes', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy>
      thenBySizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeBytes', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> thenBySosRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sosRemoteId', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy>
      thenBySosRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sosRemoteId', Sort.desc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension EvidenceLocalQueryWhereDistinct
    on QueryBuilder<EvidenceLocal, EvidenceLocal, QDistinct> {
  QueryBuilder<EvidenceLocal, EvidenceLocal, QDistinct> distinctByCapturedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'capturedAt');
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QDistinct> distinctByHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QDistinct> distinctByIsUploaded() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUploaded');
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QDistinct> distinctByLocalPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QDistinct>
      distinctByRemoteStoragePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteStoragePath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QDistinct> distinctBySizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sizeBytes');
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QDistinct> distinctBySosRemoteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sosRemoteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EvidenceLocal, EvidenceLocal, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension EvidenceLocalQueryProperty
    on QueryBuilder<EvidenceLocal, EvidenceLocal, QQueryProperty> {
  QueryBuilder<EvidenceLocal, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EvidenceLocal, DateTime, QQueryOperations> capturedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'capturedAt');
    });
  }

  QueryBuilder<EvidenceLocal, String, QQueryOperations> hashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hash');
    });
  }

  QueryBuilder<EvidenceLocal, bool, QQueryOperations> isUploadedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUploaded');
    });
  }

  QueryBuilder<EvidenceLocal, String, QQueryOperations> localPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localPath');
    });
  }

  QueryBuilder<EvidenceLocal, String?, QQueryOperations>
      remoteStoragePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteStoragePath');
    });
  }

  QueryBuilder<EvidenceLocal, int, QQueryOperations> sizeBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sizeBytes');
    });
  }

  QueryBuilder<EvidenceLocal, String, QQueryOperations> sosRemoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sosRemoteId');
    });
  }

  QueryBuilder<EvidenceLocal, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
