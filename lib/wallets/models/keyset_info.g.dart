// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyset_info.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetKeysetInfoCollection on Isar {
  IsarCollection<KeysetInfo> get keysetInfos => this.collection();
}

const KeysetInfoSchema = CollectionSchema(
  name: r'KeysetInfo',
  id: 5960314508474462056,
  properties: {
    r'active': PropertySchema(
      id: 0,
      name: r'active',
      type: IsarType.bool,
    ),
    r'firstSeen': PropertySchema(
      id: 1,
      name: r'firstSeen',
      type: IsarType.long,
    ),
    r'keysetId': PropertySchema(
      id: 2,
      name: r'keysetId',
      type: IsarType.string,
    ),
    r'lastSeen': PropertySchema(
      id: 3,
      name: r'lastSeen',
      type: IsarType.long,
    ),
    r'mintURL': PropertySchema(
      id: 4,
      name: r'mintURL',
      type: IsarType.string,
    ),
    r'unit': PropertySchema(
      id: 5,
      name: r'unit',
      type: IsarType.string,
    )
  },
  estimateSize: _keysetInfoEstimateSize,
  serialize: _keysetInfoSerialize,
  deserialize: _keysetInfoDeserialize,
  deserializeProp: _keysetInfoDeserializeProp,
  idName: r'id',
  indexes: {
    r'keysetId': IndexSchema(
      id: 4539667013250561085,
      name: r'keysetId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'keysetId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _keysetInfoGetId,
  getLinks: _keysetInfoGetLinks,
  attach: _keysetInfoAttach,
  version: '3.1.0+1',
);

int _keysetInfoEstimateSize(
  KeysetInfo object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.keysetId.length * 3;
  bytesCount += 3 + object.mintURL.length * 3;
  bytesCount += 3 + object.unit.length * 3;
  return bytesCount;
}

void _keysetInfoSerialize(
  KeysetInfo object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.active);
  writer.writeLong(offsets[1], object.firstSeen);
  writer.writeString(offsets[2], object.keysetId);
  writer.writeLong(offsets[3], object.lastSeen);
  writer.writeString(offsets[4], object.mintURL);
  writer.writeString(offsets[5], object.unit);
}

KeysetInfo _keysetInfoDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = KeysetInfo(
    active: reader.readBool(offsets[0]),
    firstSeen: reader.readLong(offsets[1]),
    keysetId: reader.readString(offsets[2]),
    lastSeen: reader.readLong(offsets[3]),
    mintURL: reader.readString(offsets[4]),
    unit: reader.readString(offsets[5]),
  );
  object.id = id;
  return object;
}

P _keysetInfoDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _keysetInfoGetId(KeysetInfo object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _keysetInfoGetLinks(KeysetInfo object) {
  return [];
}

void _keysetInfoAttach(IsarCollection<dynamic> col, Id id, KeysetInfo object) {
  object.id = id;
}

extension KeysetInfoByIndex on IsarCollection<KeysetInfo> {
  Future<KeysetInfo?> getByKeysetId(String keysetId) {
    return getByIndex(r'keysetId', [keysetId]);
  }

  KeysetInfo? getByKeysetIdSync(String keysetId) {
    return getByIndexSync(r'keysetId', [keysetId]);
  }

  Future<bool> deleteByKeysetId(String keysetId) {
    return deleteByIndex(r'keysetId', [keysetId]);
  }

  bool deleteByKeysetIdSync(String keysetId) {
    return deleteByIndexSync(r'keysetId', [keysetId]);
  }

  Future<List<KeysetInfo?>> getAllByKeysetId(List<String> keysetIdValues) {
    final values = keysetIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'keysetId', values);
  }

  List<KeysetInfo?> getAllByKeysetIdSync(List<String> keysetIdValues) {
    final values = keysetIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'keysetId', values);
  }

  Future<int> deleteAllByKeysetId(List<String> keysetIdValues) {
    final values = keysetIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'keysetId', values);
  }

  int deleteAllByKeysetIdSync(List<String> keysetIdValues) {
    final values = keysetIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'keysetId', values);
  }

  Future<Id> putByKeysetId(KeysetInfo object) {
    return putByIndex(r'keysetId', object);
  }

  Id putByKeysetIdSync(KeysetInfo object, {bool saveLinks = true}) {
    return putByIndexSync(r'keysetId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKeysetId(List<KeysetInfo> objects) {
    return putAllByIndex(r'keysetId', objects);
  }

  List<Id> putAllByKeysetIdSync(List<KeysetInfo> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'keysetId', objects, saveLinks: saveLinks);
  }
}

extension KeysetInfoQueryWhereSort
    on QueryBuilder<KeysetInfo, KeysetInfo, QWhere> {
  QueryBuilder<KeysetInfo, KeysetInfo, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension KeysetInfoQueryWhere
    on QueryBuilder<KeysetInfo, KeysetInfo, QWhereClause> {
  QueryBuilder<KeysetInfo, KeysetInfo, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterWhereClause> idBetween(
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

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterWhereClause> keysetIdEqualTo(
      String keysetId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'keysetId',
        value: [keysetId],
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterWhereClause> keysetIdNotEqualTo(
      String keysetId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keysetId',
              lower: [],
              upper: [keysetId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keysetId',
              lower: [keysetId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keysetId',
              lower: [keysetId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keysetId',
              lower: [],
              upper: [keysetId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension KeysetInfoQueryFilter
    on QueryBuilder<KeysetInfo, KeysetInfo, QFilterCondition> {
  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> activeEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'active',
        value: value,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> firstSeenEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firstSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition>
      firstSeenGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'firstSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> firstSeenLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'firstSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> firstSeenBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'firstSeen',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> idBetween(
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

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> keysetIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keysetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition>
      keysetIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'keysetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> keysetIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'keysetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> keysetIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'keysetId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition>
      keysetIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'keysetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> keysetIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'keysetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> keysetIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'keysetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> keysetIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'keysetId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition>
      keysetIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keysetId',
        value: '',
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition>
      keysetIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'keysetId',
        value: '',
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> lastSeenEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition>
      lastSeenGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> lastSeenLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> lastSeenBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSeen',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> mintURLEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mintURL',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition>
      mintURLGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mintURL',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> mintURLLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mintURL',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> mintURLBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mintURL',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> mintURLStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mintURL',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> mintURLEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mintURL',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> mintURLContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mintURL',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> mintURLMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mintURL',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> mintURLIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mintURL',
        value: '',
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition>
      mintURLIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mintURL',
        value: '',
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> unitEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> unitGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> unitLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> unitBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> unitStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> unitEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> unitContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> unitMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'unit',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> unitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unit',
        value: '',
      ));
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterFilterCondition> unitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'unit',
        value: '',
      ));
    });
  }
}

extension KeysetInfoQueryObject
    on QueryBuilder<KeysetInfo, KeysetInfo, QFilterCondition> {}

extension KeysetInfoQueryLinks
    on QueryBuilder<KeysetInfo, KeysetInfo, QFilterCondition> {}

extension KeysetInfoQuerySortBy
    on QueryBuilder<KeysetInfo, KeysetInfo, QSortBy> {
  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> sortByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.asc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> sortByActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.desc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> sortByFirstSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSeen', Sort.asc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> sortByFirstSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSeen', Sort.desc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> sortByKeysetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keysetId', Sort.asc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> sortByKeysetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keysetId', Sort.desc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> sortByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.asc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> sortByLastSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.desc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> sortByMintURL() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintURL', Sort.asc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> sortByMintURLDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintURL', Sort.desc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> sortByUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.asc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> sortByUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.desc);
    });
  }
}

extension KeysetInfoQuerySortThenBy
    on QueryBuilder<KeysetInfo, KeysetInfo, QSortThenBy> {
  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> thenByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.asc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> thenByActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.desc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> thenByFirstSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSeen', Sort.asc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> thenByFirstSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSeen', Sort.desc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> thenByKeysetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keysetId', Sort.asc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> thenByKeysetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keysetId', Sort.desc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> thenByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.asc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> thenByLastSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.desc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> thenByMintURL() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintURL', Sort.asc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> thenByMintURLDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintURL', Sort.desc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> thenByUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.asc);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QAfterSortBy> thenByUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.desc);
    });
  }
}

extension KeysetInfoQueryWhereDistinct
    on QueryBuilder<KeysetInfo, KeysetInfo, QDistinct> {
  QueryBuilder<KeysetInfo, KeysetInfo, QDistinct> distinctByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'active');
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QDistinct> distinctByFirstSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firstSeen');
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QDistinct> distinctByKeysetId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'keysetId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QDistinct> distinctByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSeen');
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QDistinct> distinctByMintURL(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mintURL', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KeysetInfo, KeysetInfo, QDistinct> distinctByUnit(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unit', caseSensitive: caseSensitive);
    });
  }
}

extension KeysetInfoQueryProperty
    on QueryBuilder<KeysetInfo, KeysetInfo, QQueryProperty> {
  QueryBuilder<KeysetInfo, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<KeysetInfo, bool, QQueryOperations> activeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'active');
    });
  }

  QueryBuilder<KeysetInfo, int, QQueryOperations> firstSeenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firstSeen');
    });
  }

  QueryBuilder<KeysetInfo, String, QQueryOperations> keysetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keysetId');
    });
  }

  QueryBuilder<KeysetInfo, int, QQueryOperations> lastSeenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSeen');
    });
  }

  QueryBuilder<KeysetInfo, String, QQueryOperations> mintURLProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mintURL');
    });
  }

  QueryBuilder<KeysetInfo, String, QQueryOperations> unitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unit');
    });
  }
}
