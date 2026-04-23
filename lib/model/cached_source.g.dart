// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_source.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedSourceCollection on Isar {
  IsarCollection<CachedSource> get cachedSources => this.collection();
}

const CachedSourceSchema = CollectionSchema(
  name: r'CachedSource',
  id: -2910616488437474326,
  properties: {
    r'externalId': PropertySchema(
      id: 0,
      name: r'externalId',
      type: IsarType.string,
    ),
    r'imgUrl': PropertySchema(
      id: 1,
      name: r'imgUrl',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 2,
      name: r'name',
      type: IsarType.string,
    ),
    r'numParts': PropertySchema(
      id: 3,
      name: r'numParts',
      type: IsarType.long,
    ),
    r'ownedQuantity': PropertySchema(
      id: 4,
      name: r'ownedQuantity',
      type: IsarType.long,
    ),
    r'type': PropertySchema(
      id: 5,
      name: r'type',
      type: IsarType.string,
      enumMap: _CachedSourcetypeEnumValueMap,
    ),
    r'year': PropertySchema(
      id: 6,
      name: r'year',
      type: IsarType.long,
    )
  },
  estimateSize: _cachedSourceEstimateSize,
  serialize: _cachedSourceSerialize,
  deserialize: _cachedSourceDeserialize,
  deserializeProp: _cachedSourceDeserializeProp,
  idName: r'id',
  indexes: {
    r'type_externalId': IndexSchema(
      id: -4529828081145771561,
      name: r'type_externalId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'type',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'externalId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedSourceGetId,
  getLinks: _cachedSourceGetLinks,
  attach: _cachedSourceAttach,
  version: '3.3.2',
);

int _cachedSourceEstimateSize(
  CachedSource object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.externalId.length * 3;
  {
    final value = object.imgUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.type.name.length * 3;
  return bytesCount;
}

void _cachedSourceSerialize(
  CachedSource object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.externalId);
  writer.writeString(offsets[1], object.imgUrl);
  writer.writeString(offsets[2], object.name);
  writer.writeLong(offsets[3], object.numParts);
  writer.writeLong(offsets[4], object.ownedQuantity);
  writer.writeString(offsets[5], object.type.name);
  writer.writeLong(offsets[6], object.year);
}

CachedSource _cachedSourceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedSource();
  object.externalId = reader.readString(offsets[0]);
  object.id = id;
  object.imgUrl = reader.readStringOrNull(offsets[1]);
  object.name = reader.readString(offsets[2]);
  object.numParts = reader.readLong(offsets[3]);
  object.ownedQuantity = reader.readLong(offsets[4]);
  object.type =
      _CachedSourcetypeValueEnumMap[reader.readStringOrNull(offsets[5])] ??
          CachedSourceType.set;
  object.year = reader.readLong(offsets[6]);
  return object;
}

P _cachedSourceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (_CachedSourcetypeValueEnumMap[reader.readStringOrNull(offset)] ??
          CachedSourceType.set) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CachedSourcetypeEnumValueMap = {
  r'set': r'set',
  r'partlist': r'partlist',
};
const _CachedSourcetypeValueEnumMap = {
  r'set': CachedSourceType.set,
  r'partlist': CachedSourceType.partlist,
};

Id _cachedSourceGetId(CachedSource object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedSourceGetLinks(CachedSource object) {
  return [];
}

void _cachedSourceAttach(
    IsarCollection<dynamic> col, Id id, CachedSource object) {
  object.id = id;
}

extension CachedSourceByIndex on IsarCollection<CachedSource> {
  Future<CachedSource?> getByTypeExternalId(
      CachedSourceType type, String externalId) {
    return getByIndex(r'type_externalId', [type, externalId]);
  }

  CachedSource? getByTypeExternalIdSync(
      CachedSourceType type, String externalId) {
    return getByIndexSync(r'type_externalId', [type, externalId]);
  }

  Future<bool> deleteByTypeExternalId(
      CachedSourceType type, String externalId) {
    return deleteByIndex(r'type_externalId', [type, externalId]);
  }

  bool deleteByTypeExternalIdSync(CachedSourceType type, String externalId) {
    return deleteByIndexSync(r'type_externalId', [type, externalId]);
  }

  Future<List<CachedSource?>> getAllByTypeExternalId(
      List<CachedSourceType> typeValues, List<String> externalIdValues) {
    final len = typeValues.length;
    assert(externalIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([typeValues[i], externalIdValues[i]]);
    }

    return getAllByIndex(r'type_externalId', values);
  }

  List<CachedSource?> getAllByTypeExternalIdSync(
      List<CachedSourceType> typeValues, List<String> externalIdValues) {
    final len = typeValues.length;
    assert(externalIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([typeValues[i], externalIdValues[i]]);
    }

    return getAllByIndexSync(r'type_externalId', values);
  }

  Future<int> deleteAllByTypeExternalId(
      List<CachedSourceType> typeValues, List<String> externalIdValues) {
    final len = typeValues.length;
    assert(externalIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([typeValues[i], externalIdValues[i]]);
    }

    return deleteAllByIndex(r'type_externalId', values);
  }

  int deleteAllByTypeExternalIdSync(
      List<CachedSourceType> typeValues, List<String> externalIdValues) {
    final len = typeValues.length;
    assert(externalIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([typeValues[i], externalIdValues[i]]);
    }

    return deleteAllByIndexSync(r'type_externalId', values);
  }

  Future<Id> putByTypeExternalId(CachedSource object) {
    return putByIndex(r'type_externalId', object);
  }

  Id putByTypeExternalIdSync(CachedSource object, {bool saveLinks = true}) {
    return putByIndexSync(r'type_externalId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTypeExternalId(List<CachedSource> objects) {
    return putAllByIndex(r'type_externalId', objects);
  }

  List<Id> putAllByTypeExternalIdSync(List<CachedSource> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'type_externalId', objects, saveLinks: saveLinks);
  }
}

extension CachedSourceQueryWhereSort
    on QueryBuilder<CachedSource, CachedSource, QWhere> {
  QueryBuilder<CachedSource, CachedSource, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedSourceQueryWhere
    on QueryBuilder<CachedSource, CachedSource, QWhereClause> {
  QueryBuilder<CachedSource, CachedSource, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<CachedSource, CachedSource, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterWhereClause> idBetween(
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

  QueryBuilder<CachedSource, CachedSource, QAfterWhereClause>
      typeEqualToAnyExternalId(CachedSourceType type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'type_externalId',
        value: [type],
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterWhereClause>
      typeNotEqualToAnyExternalId(CachedSourceType type) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type_externalId',
              lower: [],
              upper: [type],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type_externalId',
              lower: [type],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type_externalId',
              lower: [type],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type_externalId',
              lower: [],
              upper: [type],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterWhereClause>
      typeExternalIdEqualTo(CachedSourceType type, String externalId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'type_externalId',
        value: [type, externalId],
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterWhereClause>
      typeEqualToExternalIdNotEqualTo(
          CachedSourceType type, String externalId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type_externalId',
              lower: [type],
              upper: [type, externalId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type_externalId',
              lower: [type, externalId],
              includeLower: false,
              upper: [type],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type_externalId',
              lower: [type, externalId],
              includeLower: false,
              upper: [type],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type_externalId',
              lower: [type],
              upper: [type, externalId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedSourceQueryFilter
    on QueryBuilder<CachedSource, CachedSource, QFilterCondition> {
  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      externalIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'externalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      externalIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'externalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      externalIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'externalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      externalIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'externalId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      externalIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'externalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      externalIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'externalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      externalIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'externalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      externalIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'externalId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      externalIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'externalId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      externalIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'externalId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      imgUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imgUrl',
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      imgUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imgUrl',
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> imgUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imgUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      imgUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imgUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      imgUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imgUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> imgUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imgUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      imgUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imgUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      imgUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imgUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      imgUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imgUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> imgUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imgUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      imgUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imgUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      imgUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imgUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      nameGreaterThan(
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      nameStartsWith(
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> nameContains(
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      numPartsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numParts',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      numPartsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'numParts',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      numPartsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'numParts',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      numPartsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'numParts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      ownedQuantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownedQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      ownedQuantityGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownedQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      ownedQuantityLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownedQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      ownedQuantityBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownedQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> typeEqualTo(
    CachedSourceType value, {
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      typeGreaterThan(
    CachedSourceType value, {
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> typeLessThan(
    CachedSourceType value, {
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> typeBetween(
    CachedSourceType lower,
    CachedSourceType upper, {
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> typeEndsWith(
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> typeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> typeMatches(
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

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> yearEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'year',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition>
      yearGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'year',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> yearLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'year',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterFilterCondition> yearBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'year',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CachedSourceQueryObject
    on QueryBuilder<CachedSource, CachedSource, QFilterCondition> {}

extension CachedSourceQueryLinks
    on QueryBuilder<CachedSource, CachedSource, QFilterCondition> {}

extension CachedSourceQuerySortBy
    on QueryBuilder<CachedSource, CachedSource, QSortBy> {
  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> sortByExternalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'externalId', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy>
      sortByExternalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'externalId', Sort.desc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> sortByImgUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgUrl', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> sortByImgUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgUrl', Sort.desc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> sortByNumParts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numParts', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> sortByNumPartsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numParts', Sort.desc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> sortByOwnedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownedQuantity', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy>
      sortByOwnedQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownedQuantity', Sort.desc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> sortByYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> sortByYearDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.desc);
    });
  }
}

extension CachedSourceQuerySortThenBy
    on QueryBuilder<CachedSource, CachedSource, QSortThenBy> {
  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> thenByExternalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'externalId', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy>
      thenByExternalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'externalId', Sort.desc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> thenByImgUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgUrl', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> thenByImgUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgUrl', Sort.desc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> thenByNumParts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numParts', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> thenByNumPartsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numParts', Sort.desc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> thenByOwnedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownedQuantity', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy>
      thenByOwnedQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownedQuantity', Sort.desc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> thenByYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.asc);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QAfterSortBy> thenByYearDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.desc);
    });
  }
}

extension CachedSourceQueryWhereDistinct
    on QueryBuilder<CachedSource, CachedSource, QDistinct> {
  QueryBuilder<CachedSource, CachedSource, QDistinct> distinctByExternalId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'externalId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QDistinct> distinctByImgUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imgUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QDistinct> distinctByNumParts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numParts');
    });
  }

  QueryBuilder<CachedSource, CachedSource, QDistinct>
      distinctByOwnedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownedQuantity');
    });
  }

  QueryBuilder<CachedSource, CachedSource, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedSource, CachedSource, QDistinct> distinctByYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'year');
    });
  }
}

extension CachedSourceQueryProperty
    on QueryBuilder<CachedSource, CachedSource, QQueryProperty> {
  QueryBuilder<CachedSource, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedSource, String, QQueryOperations> externalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'externalId');
    });
  }

  QueryBuilder<CachedSource, String?, QQueryOperations> imgUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imgUrl');
    });
  }

  QueryBuilder<CachedSource, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<CachedSource, int, QQueryOperations> numPartsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numParts');
    });
  }

  QueryBuilder<CachedSource, int, QQueryOperations> ownedQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownedQuantity');
    });
  }

  QueryBuilder<CachedSource, CachedSourceType, QQueryOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<CachedSource, int, QQueryOperations> yearProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'year');
    });
  }
}
