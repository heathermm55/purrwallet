// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProofCollection on Isar {
  IsarCollection<Proof> get proofs => this.collection();
}

const ProofSchema = CollectionSchema(
  name: r'Proof',
  id: -1495092469851836306,
  properties: {
    r'C': PropertySchema(
      id: 0,
      name: r'C',
      type: IsarType.string,
    ),
    r'amount': PropertySchema(
      id: 1,
      name: r'amount',
      type: IsarType.string,
    ),
    r'amountNum': PropertySchema(
      id: 2,
      name: r'amountNum',
      type: IsarType.long,
    ),
    r'dleqPlainText': PropertySchema(
      id: 3,
      name: r'dleqPlainText',
      type: IsarType.string,
    ),
    r'keysetId': PropertySchema(
      id: 4,
      name: r'keysetId',
      type: IsarType.string,
    ),
    r'secret': PropertySchema(
      id: 5,
      name: r'secret',
      type: IsarType.string,
    ),
    r'witness': PropertySchema(
      id: 6,
      name: r'witness',
      type: IsarType.string,
    )
  },
  estimateSize: _proofEstimateSize,
  serialize: _proofSerialize,
  deserialize: _proofDeserialize,
  deserializeProp: _proofDeserializeProp,
  idName: r'id',
  indexes: {
    r'keysetId_secret': IndexSchema(
      id: 5932644301613953306,
      name: r'keysetId_secret',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'keysetId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'secret',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _proofGetId,
  getLinks: _proofGetLinks,
  attach: _proofAttach,
  version: '3.1.0+1',
);

int _proofEstimateSize(
  Proof object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.C.length * 3;
  bytesCount += 3 + object.amount.length * 3;
  bytesCount += 3 + object.dleqPlainText.length * 3;
  bytesCount += 3 + object.keysetId.length * 3;
  bytesCount += 3 + object.secret.length * 3;
  bytesCount += 3 + object.witness.length * 3;
  return bytesCount;
}

void _proofSerialize(
  Proof object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.C);
  writer.writeString(offsets[1], object.amount);
  writer.writeLong(offsets[2], object.amountNum);
  writer.writeString(offsets[3], object.dleqPlainText);
  writer.writeString(offsets[4], object.keysetId);
  writer.writeString(offsets[5], object.secret);
  writer.writeString(offsets[6], object.witness);
}

Proof _proofDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Proof(
    C: reader.readString(offsets[0]),
    amount: reader.readString(offsets[1]),
    dleqPlainText: reader.readStringOrNull(offsets[3]) ?? '',
    keysetId: reader.readString(offsets[4]),
    secret: reader.readString(offsets[5]),
    witness: reader.readStringOrNull(offsets[6]) ?? '',
  );
  object.id = id;
  return object;
}

P _proofDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset) ?? '') as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _proofGetId(Proof object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _proofGetLinks(Proof object) {
  return [];
}

void _proofAttach(IsarCollection<dynamic> col, Id id, Proof object) {
  object.id = id;
}

extension ProofByIndex on IsarCollection<Proof> {
  Future<Proof?> getByKeysetIdSecret(String keysetId, String secret) {
    return getByIndex(r'keysetId_secret', [keysetId, secret]);
  }

  Proof? getByKeysetIdSecretSync(String keysetId, String secret) {
    return getByIndexSync(r'keysetId_secret', [keysetId, secret]);
  }

  Future<bool> deleteByKeysetIdSecret(String keysetId, String secret) {
    return deleteByIndex(r'keysetId_secret', [keysetId, secret]);
  }

  bool deleteByKeysetIdSecretSync(String keysetId, String secret) {
    return deleteByIndexSync(r'keysetId_secret', [keysetId, secret]);
  }

  Future<List<Proof?>> getAllByKeysetIdSecret(
      List<String> keysetIdValues, List<String> secretValues) {
    final len = keysetIdValues.length;
    assert(secretValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([keysetIdValues[i], secretValues[i]]);
    }

    return getAllByIndex(r'keysetId_secret', values);
  }

  List<Proof?> getAllByKeysetIdSecretSync(
      List<String> keysetIdValues, List<String> secretValues) {
    final len = keysetIdValues.length;
    assert(secretValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([keysetIdValues[i], secretValues[i]]);
    }

    return getAllByIndexSync(r'keysetId_secret', values);
  }

  Future<int> deleteAllByKeysetIdSecret(
      List<String> keysetIdValues, List<String> secretValues) {
    final len = keysetIdValues.length;
    assert(secretValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([keysetIdValues[i], secretValues[i]]);
    }

    return deleteAllByIndex(r'keysetId_secret', values);
  }

  int deleteAllByKeysetIdSecretSync(
      List<String> keysetIdValues, List<String> secretValues) {
    final len = keysetIdValues.length;
    assert(secretValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([keysetIdValues[i], secretValues[i]]);
    }

    return deleteAllByIndexSync(r'keysetId_secret', values);
  }

  Future<Id> putByKeysetIdSecret(Proof object) {
    return putByIndex(r'keysetId_secret', object);
  }

  Id putByKeysetIdSecretSync(Proof object, {bool saveLinks = true}) {
    return putByIndexSync(r'keysetId_secret', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKeysetIdSecret(List<Proof> objects) {
    return putAllByIndex(r'keysetId_secret', objects);
  }

  List<Id> putAllByKeysetIdSecretSync(List<Proof> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'keysetId_secret', objects, saveLinks: saveLinks);
  }
}

extension ProofQueryWhereSort on QueryBuilder<Proof, Proof, QWhere> {
  QueryBuilder<Proof, Proof, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ProofQueryWhere on QueryBuilder<Proof, Proof, QWhereClause> {
  QueryBuilder<Proof, Proof, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Proof, Proof, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Proof, Proof, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Proof, Proof, QAfterWhereClause> idBetween(
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

  QueryBuilder<Proof, Proof, QAfterWhereClause> keysetIdEqualToAnySecret(
      String keysetId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'keysetId_secret',
        value: [keysetId],
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterWhereClause> keysetIdNotEqualToAnySecret(
      String keysetId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keysetId_secret',
              lower: [],
              upper: [keysetId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keysetId_secret',
              lower: [keysetId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keysetId_secret',
              lower: [keysetId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keysetId_secret',
              lower: [],
              upper: [keysetId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Proof, Proof, QAfterWhereClause> keysetIdSecretEqualTo(
      String keysetId, String secret) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'keysetId_secret',
        value: [keysetId, secret],
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterWhereClause> keysetIdEqualToSecretNotEqualTo(
      String keysetId, String secret) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keysetId_secret',
              lower: [keysetId],
              upper: [keysetId, secret],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keysetId_secret',
              lower: [keysetId, secret],
              includeLower: false,
              upper: [keysetId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keysetId_secret',
              lower: [keysetId, secret],
              includeLower: false,
              upper: [keysetId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keysetId_secret',
              lower: [keysetId],
              upper: [keysetId, secret],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ProofQueryFilter on QueryBuilder<Proof, Proof, QFilterCondition> {
  QueryBuilder<Proof, Proof, QAfterFilterCondition> cEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'C',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> cGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'C',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> cLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'C',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> cBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'C',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> cStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'C',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> cEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'C',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> cContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'C',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> cMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'C',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> cIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'C',
        value: '',
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> cIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'C',
        value: '',
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> amountEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> amountGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> amountLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> amountBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> amountStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'amount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> amountEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'amount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> amountContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'amount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> amountMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'amount',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> amountIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: '',
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> amountIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'amount',
        value: '',
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> amountNumEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amountNum',
        value: value,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> amountNumGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amountNum',
        value: value,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> amountNumLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amountNum',
        value: value,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> amountNumBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amountNum',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> dleqPlainTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dleqPlainText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> dleqPlainTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dleqPlainText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> dleqPlainTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dleqPlainText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> dleqPlainTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dleqPlainText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> dleqPlainTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dleqPlainText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> dleqPlainTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dleqPlainText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> dleqPlainTextContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dleqPlainText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> dleqPlainTextMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dleqPlainText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> dleqPlainTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dleqPlainText',
        value: '',
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> dleqPlainTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dleqPlainText',
        value: '',
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Proof, Proof, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Proof, Proof, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Proof, Proof, QAfterFilterCondition> keysetIdEqualTo(
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

  QueryBuilder<Proof, Proof, QAfterFilterCondition> keysetIdGreaterThan(
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

  QueryBuilder<Proof, Proof, QAfterFilterCondition> keysetIdLessThan(
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

  QueryBuilder<Proof, Proof, QAfterFilterCondition> keysetIdBetween(
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

  QueryBuilder<Proof, Proof, QAfterFilterCondition> keysetIdStartsWith(
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

  QueryBuilder<Proof, Proof, QAfterFilterCondition> keysetIdEndsWith(
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

  QueryBuilder<Proof, Proof, QAfterFilterCondition> keysetIdContains(
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

  QueryBuilder<Proof, Proof, QAfterFilterCondition> keysetIdMatches(
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

  QueryBuilder<Proof, Proof, QAfterFilterCondition> keysetIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keysetId',
        value: '',
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> keysetIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'keysetId',
        value: '',
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> secretEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'secret',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> secretGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'secret',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> secretLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'secret',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> secretBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'secret',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> secretStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'secret',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> secretEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'secret',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> secretContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'secret',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> secretMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'secret',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> secretIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'secret',
        value: '',
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> secretIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'secret',
        value: '',
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> witnessEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'witness',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> witnessGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'witness',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> witnessLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'witness',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> witnessBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'witness',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> witnessStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'witness',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> witnessEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'witness',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> witnessContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'witness',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> witnessMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'witness',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> witnessIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'witness',
        value: '',
      ));
    });
  }

  QueryBuilder<Proof, Proof, QAfterFilterCondition> witnessIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'witness',
        value: '',
      ));
    });
  }
}

extension ProofQueryObject on QueryBuilder<Proof, Proof, QFilterCondition> {}

extension ProofQueryLinks on QueryBuilder<Proof, Proof, QFilterCondition> {}

extension ProofQuerySortBy on QueryBuilder<Proof, Proof, QSortBy> {
  QueryBuilder<Proof, Proof, QAfterSortBy> sortByC() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'C', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> sortByCDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'C', Sort.desc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> sortByAmountNum() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountNum', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> sortByAmountNumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountNum', Sort.desc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> sortByDleqPlainText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dleqPlainText', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> sortByDleqPlainTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dleqPlainText', Sort.desc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> sortByKeysetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keysetId', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> sortByKeysetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keysetId', Sort.desc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> sortBySecret() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secret', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> sortBySecretDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secret', Sort.desc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> sortByWitness() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'witness', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> sortByWitnessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'witness', Sort.desc);
    });
  }
}

extension ProofQuerySortThenBy on QueryBuilder<Proof, Proof, QSortThenBy> {
  QueryBuilder<Proof, Proof, QAfterSortBy> thenByC() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'C', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenByCDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'C', Sort.desc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenByAmountNum() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountNum', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenByAmountNumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountNum', Sort.desc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenByDleqPlainText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dleqPlainText', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenByDleqPlainTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dleqPlainText', Sort.desc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenByKeysetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keysetId', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenByKeysetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keysetId', Sort.desc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenBySecret() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secret', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenBySecretDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secret', Sort.desc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenByWitness() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'witness', Sort.asc);
    });
  }

  QueryBuilder<Proof, Proof, QAfterSortBy> thenByWitnessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'witness', Sort.desc);
    });
  }
}

extension ProofQueryWhereDistinct on QueryBuilder<Proof, Proof, QDistinct> {
  QueryBuilder<Proof, Proof, QDistinct> distinctByC(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'C', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Proof, Proof, QDistinct> distinctByAmount(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Proof, Proof, QDistinct> distinctByAmountNum() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountNum');
    });
  }

  QueryBuilder<Proof, Proof, QDistinct> distinctByDleqPlainText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dleqPlainText',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Proof, Proof, QDistinct> distinctByKeysetId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'keysetId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Proof, Proof, QDistinct> distinctBySecret(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'secret', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Proof, Proof, QDistinct> distinctByWitness(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'witness', caseSensitive: caseSensitive);
    });
  }
}

extension ProofQueryProperty on QueryBuilder<Proof, Proof, QQueryProperty> {
  QueryBuilder<Proof, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Proof, String, QQueryOperations> CProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'C');
    });
  }

  QueryBuilder<Proof, String, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<Proof, int, QQueryOperations> amountNumProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountNum');
    });
  }

  QueryBuilder<Proof, String, QQueryOperations> dleqPlainTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dleqPlainText');
    });
  }

  QueryBuilder<Proof, String, QQueryOperations> keysetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keysetId');
    });
  }

  QueryBuilder<Proof, String, QQueryOperations> secretProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'secret');
    });
  }

  QueryBuilder<Proof, String, QQueryOperations> witnessProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'witness');
    });
  }
}
