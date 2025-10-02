// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mint_info.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMintInfoCollection on Isar {
  IsarCollection<MintInfo> get mintInfos => this.collection();
}

const MintInfoSchema = CollectionSchema(
  name: r'MintInfo',
  id: 6506655485091599280,
  properties: {
    r'contactJsonRaw': PropertySchema(
      id: 0,
      name: r'contactJsonRaw',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 1,
      name: r'description',
      type: IsarType.string,
    ),
    r'descriptionLong': PropertySchema(
      id: 2,
      name: r'descriptionLong',
      type: IsarType.string,
    ),
    r'mintURL': PropertySchema(
      id: 3,
      name: r'mintURL',
      type: IsarType.string,
    ),
    r'motd': PropertySchema(
      id: 4,
      name: r'motd',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    ),
    r'nutsJsonRaw': PropertySchema(
      id: 6,
      name: r'nutsJsonRaw',
      type: IsarType.string,
    ),
    r'pubkey': PropertySchema(
      id: 7,
      name: r'pubkey',
      type: IsarType.string,
    ),
    r'version': PropertySchema(
      id: 8,
      name: r'version',
      type: IsarType.string,
    )
  },
  estimateSize: _mintInfoEstimateSize,
  serialize: _mintInfoSerialize,
  deserialize: _mintInfoDeserialize,
  deserializeProp: _mintInfoDeserializeProp,
  idName: r'id',
  indexes: {
    r'mintURL': IndexSchema(
      id: 5052576169555451409,
      name: r'mintURL',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'mintURL',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _mintInfoGetId,
  getLinks: _mintInfoGetLinks,
  attach: _mintInfoAttach,
  version: '3.1.0+1',
);

int _mintInfoEstimateSize(
  MintInfo object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.contactJsonRaw.length * 3;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.descriptionLong.length * 3;
  bytesCount += 3 + object.mintURL.length * 3;
  bytesCount += 3 + object.motd.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.nutsJsonRaw.length * 3;
  bytesCount += 3 + object.pubkey.length * 3;
  bytesCount += 3 + object.version.length * 3;
  return bytesCount;
}

void _mintInfoSerialize(
  MintInfo object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.contactJsonRaw);
  writer.writeString(offsets[1], object.description);
  writer.writeString(offsets[2], object.descriptionLong);
  writer.writeString(offsets[3], object.mintURL);
  writer.writeString(offsets[4], object.motd);
  writer.writeString(offsets[5], object.name);
  writer.writeString(offsets[6], object.nutsJsonRaw);
  writer.writeString(offsets[7], object.pubkey);
  writer.writeString(offsets[8], object.version);
}

MintInfo _mintInfoDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MintInfo(
    contactJsonRaw: reader.readString(offsets[0]),
    description: reader.readString(offsets[1]),
    descriptionLong: reader.readString(offsets[2]),
    mintURL: reader.readString(offsets[3]),
    motd: reader.readString(offsets[4]),
    name: reader.readString(offsets[5]),
    nutsJsonRaw: reader.readString(offsets[6]),
    pubkey: reader.readString(offsets[7]),
    version: reader.readString(offsets[8]),
  );
  object.id = id;
  return object;
}

P _mintInfoDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _mintInfoGetId(MintInfo object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _mintInfoGetLinks(MintInfo object) {
  return [];
}

void _mintInfoAttach(IsarCollection<dynamic> col, Id id, MintInfo object) {
  object.id = id;
}

extension MintInfoByIndex on IsarCollection<MintInfo> {
  Future<MintInfo?> getByMintURL(String mintURL) {
    return getByIndex(r'mintURL', [mintURL]);
  }

  MintInfo? getByMintURLSync(String mintURL) {
    return getByIndexSync(r'mintURL', [mintURL]);
  }

  Future<bool> deleteByMintURL(String mintURL) {
    return deleteByIndex(r'mintURL', [mintURL]);
  }

  bool deleteByMintURLSync(String mintURL) {
    return deleteByIndexSync(r'mintURL', [mintURL]);
  }

  Future<List<MintInfo?>> getAllByMintURL(List<String> mintURLValues) {
    final values = mintURLValues.map((e) => [e]).toList();
    return getAllByIndex(r'mintURL', values);
  }

  List<MintInfo?> getAllByMintURLSync(List<String> mintURLValues) {
    final values = mintURLValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'mintURL', values);
  }

  Future<int> deleteAllByMintURL(List<String> mintURLValues) {
    final values = mintURLValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'mintURL', values);
  }

  int deleteAllByMintURLSync(List<String> mintURLValues) {
    final values = mintURLValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'mintURL', values);
  }

  Future<Id> putByMintURL(MintInfo object) {
    return putByIndex(r'mintURL', object);
  }

  Id putByMintURLSync(MintInfo object, {bool saveLinks = true}) {
    return putByIndexSync(r'mintURL', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMintURL(List<MintInfo> objects) {
    return putAllByIndex(r'mintURL', objects);
  }

  List<Id> putAllByMintURLSync(List<MintInfo> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'mintURL', objects, saveLinks: saveLinks);
  }
}

extension MintInfoQueryWhereSort on QueryBuilder<MintInfo, MintInfo, QWhere> {
  QueryBuilder<MintInfo, MintInfo, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MintInfoQueryWhere on QueryBuilder<MintInfo, MintInfo, QWhereClause> {
  QueryBuilder<MintInfo, MintInfo, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<MintInfo, MintInfo, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterWhereClause> idBetween(
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

  QueryBuilder<MintInfo, MintInfo, QAfterWhereClause> mintURLEqualTo(
      String mintURL) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mintURL',
        value: [mintURL],
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterWhereClause> mintURLNotEqualTo(
      String mintURL) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mintURL',
              lower: [],
              upper: [mintURL],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mintURL',
              lower: [mintURL],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mintURL',
              lower: [mintURL],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mintURL',
              lower: [],
              upper: [mintURL],
              includeUpper: false,
            ));
      }
    });
  }
}

extension MintInfoQueryFilter
    on QueryBuilder<MintInfo, MintInfo, QFilterCondition> {
  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> contactJsonRawEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactJsonRaw',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      contactJsonRawGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contactJsonRaw',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      contactJsonRawLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contactJsonRaw',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> contactJsonRawBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contactJsonRaw',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      contactJsonRawStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contactJsonRaw',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      contactJsonRawEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contactJsonRaw',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      contactJsonRawContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contactJsonRaw',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> contactJsonRawMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contactJsonRaw',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      contactJsonRawIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactJsonRaw',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      contactJsonRawIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contactJsonRaw',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> descriptionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> descriptionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      descriptionLongEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descriptionLong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      descriptionLongGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'descriptionLong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      descriptionLongLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'descriptionLong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      descriptionLongBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'descriptionLong',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      descriptionLongStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'descriptionLong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      descriptionLongEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'descriptionLong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      descriptionLongContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'descriptionLong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      descriptionLongMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'descriptionLong',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      descriptionLongIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descriptionLong',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      descriptionLongIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'descriptionLong',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> idBetween(
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

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> mintURLEqualTo(
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

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> mintURLGreaterThan(
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

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> mintURLLessThan(
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

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> mintURLBetween(
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

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> mintURLStartsWith(
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

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> mintURLEndsWith(
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

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> mintURLContains(
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

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> mintURLMatches(
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

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> mintURLIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mintURL',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> mintURLIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mintURL',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> motdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'motd',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> motdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'motd',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> motdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'motd',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> motdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'motd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> motdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'motd',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> motdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'motd',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> motdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'motd',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> motdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'motd',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> motdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'motd',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> motdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'motd',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nutsJsonRawEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nutsJsonRaw',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      nutsJsonRawGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nutsJsonRaw',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nutsJsonRawLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nutsJsonRaw',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nutsJsonRawBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nutsJsonRaw',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nutsJsonRawStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nutsJsonRaw',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nutsJsonRawEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nutsJsonRaw',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nutsJsonRawContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nutsJsonRaw',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nutsJsonRawMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nutsJsonRaw',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> nutsJsonRawIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nutsJsonRaw',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition>
      nutsJsonRawIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nutsJsonRaw',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> pubkeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> pubkeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> pubkeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> pubkeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pubkey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> pubkeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> pubkeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> pubkeyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> pubkeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pubkey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> pubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> pubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> versionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> versionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> versionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> versionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'version',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> versionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> versionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> versionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> versionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'version',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> versionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: '',
      ));
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterFilterCondition> versionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'version',
        value: '',
      ));
    });
  }
}

extension MintInfoQueryObject
    on QueryBuilder<MintInfo, MintInfo, QFilterCondition> {}

extension MintInfoQueryLinks
    on QueryBuilder<MintInfo, MintInfo, QFilterCondition> {}

extension MintInfoQuerySortBy on QueryBuilder<MintInfo, MintInfo, QSortBy> {
  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByContactJsonRaw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactJsonRaw', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByContactJsonRawDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactJsonRaw', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByDescriptionLong() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descriptionLong', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByDescriptionLongDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descriptionLong', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByMintURL() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintURL', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByMintURLDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintURL', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByMotd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'motd', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByMotdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'motd', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByNutsJsonRaw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nutsJsonRaw', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByNutsJsonRawDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nutsJsonRaw', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension MintInfoQuerySortThenBy
    on QueryBuilder<MintInfo, MintInfo, QSortThenBy> {
  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByContactJsonRaw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactJsonRaw', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByContactJsonRawDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactJsonRaw', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByDescriptionLong() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descriptionLong', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByDescriptionLongDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descriptionLong', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByMintURL() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintURL', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByMintURLDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintURL', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByMotd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'motd', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByMotdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'motd', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByNutsJsonRaw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nutsJsonRaw', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByNutsJsonRawDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nutsJsonRaw', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.desc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension MintInfoQueryWhereDistinct
    on QueryBuilder<MintInfo, MintInfo, QDistinct> {
  QueryBuilder<MintInfo, MintInfo, QDistinct> distinctByContactJsonRaw(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contactJsonRaw',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QDistinct> distinctByDescriptionLong(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'descriptionLong',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QDistinct> distinctByMintURL(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mintURL', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QDistinct> distinctByMotd(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'motd', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QDistinct> distinctByNutsJsonRaw(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nutsJsonRaw', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QDistinct> distinctByPubkey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pubkey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MintInfo, MintInfo, QDistinct> distinctByVersion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version', caseSensitive: caseSensitive);
    });
  }
}

extension MintInfoQueryProperty
    on QueryBuilder<MintInfo, MintInfo, QQueryProperty> {
  QueryBuilder<MintInfo, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MintInfo, String, QQueryOperations> contactJsonRawProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contactJsonRaw');
    });
  }

  QueryBuilder<MintInfo, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<MintInfo, String, QQueryOperations> descriptionLongProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'descriptionLong');
    });
  }

  QueryBuilder<MintInfo, String, QQueryOperations> mintURLProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mintURL');
    });
  }

  QueryBuilder<MintInfo, String, QQueryOperations> motdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'motd');
    });
  }

  QueryBuilder<MintInfo, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<MintInfo, String, QQueryOperations> nutsJsonRawProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nutsJsonRaw');
    });
  }

  QueryBuilder<MintInfo, String, QQueryOperations> pubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pubkey');
    });
  }

  QueryBuilder<MintInfo, String, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
