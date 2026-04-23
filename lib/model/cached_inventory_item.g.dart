// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_inventory_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedInventoryItemCollection on Isar {
  IsarCollection<CachedInventoryItem> get cachedInventoryItems =>
      this.collection();
}

const CachedInventoryItemSchema = CollectionSchema(
  name: r'CachedInventoryItem',
  id: -6173601866538559616,
  properties: {
    r'colorId': PropertySchema(
      id: 0,
      name: r'colorId',
      type: IsarType.long,
    ),
    r'colorName': PropertySchema(
      id: 1,
      name: r'colorName',
      type: IsarType.string,
    ),
    r'imgUrl': PropertySchema(
      id: 2,
      name: r'imgUrl',
      type: IsarType.string,
    ),
    r'isSpare': PropertySchema(
      id: 3,
      name: r'isSpare',
      type: IsarType.bool,
    ),
    r'partCategoryId': PropertySchema(
      id: 4,
      name: r'partCategoryId',
      type: IsarType.long,
    ),
    r'partName': PropertySchema(
      id: 5,
      name: r'partName',
      type: IsarType.string,
    ),
    r'partNum': PropertySchema(
      id: 6,
      name: r'partNum',
      type: IsarType.string,
    ),
    r'quantity': PropertySchema(
      id: 7,
      name: r'quantity',
      type: IsarType.long,
    ),
    r'rgb': PropertySchema(
      id: 8,
      name: r'rgb',
      type: IsarType.string,
    ),
    r'sourceExternalId': PropertySchema(
      id: 9,
      name: r'sourceExternalId',
      type: IsarType.string,
    ),
    r'sourceType': PropertySchema(
      id: 10,
      name: r'sourceType',
      type: IsarType.string,
      enumMap: _CachedInventoryItemsourceTypeEnumValueMap,
    )
  },
  estimateSize: _cachedInventoryItemEstimateSize,
  serialize: _cachedInventoryItemSerialize,
  deserialize: _cachedInventoryItemDeserialize,
  deserializeProp: _cachedInventoryItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'partNum_colorId': IndexSchema(
      id: -7924447040295463174,
      name: r'partNum_colorId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'partNum',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'colorId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedInventoryItemGetId,
  getLinks: _cachedInventoryItemGetLinks,
  attach: _cachedInventoryItemAttach,
  version: '3.3.2',
);

int _cachedInventoryItemEstimateSize(
  CachedInventoryItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.colorName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.imgUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.partName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.partNum.length * 3;
  {
    final value = object.rgb;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sourceExternalId.length * 3;
  bytesCount += 3 + object.sourceType.name.length * 3;
  return bytesCount;
}

void _cachedInventoryItemSerialize(
  CachedInventoryItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.colorId);
  writer.writeString(offsets[1], object.colorName);
  writer.writeString(offsets[2], object.imgUrl);
  writer.writeBool(offsets[3], object.isSpare);
  writer.writeLong(offsets[4], object.partCategoryId);
  writer.writeString(offsets[5], object.partName);
  writer.writeString(offsets[6], object.partNum);
  writer.writeLong(offsets[7], object.quantity);
  writer.writeString(offsets[8], object.rgb);
  writer.writeString(offsets[9], object.sourceExternalId);
  writer.writeString(offsets[10], object.sourceType.name);
}

CachedInventoryItem _cachedInventoryItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedInventoryItem();
  object.colorId = reader.readLong(offsets[0]);
  object.colorName = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.imgUrl = reader.readStringOrNull(offsets[2]);
  object.isSpare = reader.readBool(offsets[3]);
  object.partCategoryId = reader.readLongOrNull(offsets[4]);
  object.partName = reader.readStringOrNull(offsets[5]);
  object.partNum = reader.readString(offsets[6]);
  object.quantity = reader.readLong(offsets[7]);
  object.rgb = reader.readStringOrNull(offsets[8]);
  object.sourceExternalId = reader.readString(offsets[9]);
  object.sourceType = _CachedInventoryItemsourceTypeValueEnumMap[
          reader.readStringOrNull(offsets[10])] ??
      CachedSourceType.set;
  return object;
}

P _cachedInventoryItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (_CachedInventoryItemsourceTypeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          CachedSourceType.set) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CachedInventoryItemsourceTypeEnumValueMap = {
  r'set': r'set',
  r'partlist': r'partlist',
};
const _CachedInventoryItemsourceTypeValueEnumMap = {
  r'set': CachedSourceType.set,
  r'partlist': CachedSourceType.partlist,
};

Id _cachedInventoryItemGetId(CachedInventoryItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedInventoryItemGetLinks(
    CachedInventoryItem object) {
  return [];
}

void _cachedInventoryItemAttach(
    IsarCollection<dynamic> col, Id id, CachedInventoryItem object) {
  object.id = id;
}

extension CachedInventoryItemQueryWhereSort
    on QueryBuilder<CachedInventoryItem, CachedInventoryItem, QWhere> {
  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedInventoryItemQueryWhere
    on QueryBuilder<CachedInventoryItem, CachedInventoryItem, QWhereClause> {
  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      partNumEqualToAnyColorId(String partNum) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'partNum_colorId',
        value: [partNum],
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      partNumNotEqualToAnyColorId(String partNum) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'partNum_colorId',
              lower: [],
              upper: [partNum],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'partNum_colorId',
              lower: [partNum],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'partNum_colorId',
              lower: [partNum],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'partNum_colorId',
              lower: [],
              upper: [partNum],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      partNumColorIdEqualTo(String partNum, int colorId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'partNum_colorId',
        value: [partNum, colorId],
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      partNumEqualToColorIdNotEqualTo(String partNum, int colorId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'partNum_colorId',
              lower: [partNum],
              upper: [partNum, colorId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'partNum_colorId',
              lower: [partNum, colorId],
              includeLower: false,
              upper: [partNum],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'partNum_colorId',
              lower: [partNum, colorId],
              includeLower: false,
              upper: [partNum],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'partNum_colorId',
              lower: [partNum],
              upper: [partNum, colorId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      partNumEqualToColorIdGreaterThan(
    String partNum,
    int colorId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'partNum_colorId',
        lower: [partNum, colorId],
        includeLower: include,
        upper: [partNum],
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      partNumEqualToColorIdLessThan(
    String partNum,
    int colorId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'partNum_colorId',
        lower: [partNum],
        upper: [partNum, colorId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      partNumEqualToColorIdBetween(
    String partNum,
    int lowerColorId,
    int upperColorId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'partNum_colorId',
        lower: [partNum, lowerColorId],
        includeLower: includeLower,
        upper: [partNum, upperColorId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CachedInventoryItemQueryFilter on QueryBuilder<CachedInventoryItem,
    CachedInventoryItem, QFilterCondition> {
  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'colorName',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'colorName',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'colorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'colorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'colorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'colorName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      colorNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'colorName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      imgUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imgUrl',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      imgUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imgUrl',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      imgUrlEqualTo(
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      imgUrlBetween(
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      imgUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imgUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      imgUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imgUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      imgUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imgUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      imgUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imgUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      isSpareEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSpare',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partCategoryIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'partCategoryId',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partCategoryIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'partCategoryId',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partCategoryIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partCategoryId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partCategoryIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'partCategoryId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partCategoryIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'partCategoryId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partCategoryIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'partCategoryId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'partName',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'partName',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'partName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'partName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'partName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'partName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'partName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'partName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'partName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'partName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNumEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partNum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNumGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'partNum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNumLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'partNum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNumBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'partNum',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNumStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'partNum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNumEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'partNum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNumContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'partNum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNumMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'partNum',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNumIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partNum',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      partNumIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'partNum',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      quantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      quantityGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      quantityLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      quantityBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      rgbIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rgb',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      rgbIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rgb',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      rgbEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rgb',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      rgbGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rgb',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      rgbLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rgb',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      rgbBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rgb',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      rgbStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rgb',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      rgbEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rgb',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      rgbContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rgb',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      rgbMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rgb',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      rgbIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rgb',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      rgbIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rgb',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceExternalIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceExternalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceExternalIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceExternalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceExternalIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceExternalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceExternalIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceExternalId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceExternalIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceExternalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceExternalIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceExternalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceExternalIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceExternalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceExternalIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceExternalId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceExternalIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceExternalId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceExternalIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceExternalId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceTypeEqualTo(
    CachedSourceType value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceTypeGreaterThan(
    CachedSourceType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceTypeLessThan(
    CachedSourceType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceTypeBetween(
    CachedSourceType lower,
    CachedSourceType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceType',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sourceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceType',
        value: '',
      ));
    });
  }
}

extension CachedInventoryItemQueryObject on QueryBuilder<CachedInventoryItem,
    CachedInventoryItem, QFilterCondition> {}

extension CachedInventoryItemQueryLinks on QueryBuilder<CachedInventoryItem,
    CachedInventoryItem, QFilterCondition> {}

extension CachedInventoryItemQuerySortBy
    on QueryBuilder<CachedInventoryItem, CachedInventoryItem, QSortBy> {
  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByColorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorId', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByColorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorId', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByColorName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorName', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByColorNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorName', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByImgUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgUrl', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByImgUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgUrl', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByIsSpare() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSpare', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByIsSpareDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSpare', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByPartCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partCategoryId', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByPartCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partCategoryId', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByPartName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partName', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByPartNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partName', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByPartNum() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partNum', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByPartNumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partNum', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByRgb() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rgb', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByRgbDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rgb', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortBySourceExternalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceExternalId', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortBySourceExternalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceExternalId', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortBySourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.desc);
    });
  }
}

extension CachedInventoryItemQuerySortThenBy
    on QueryBuilder<CachedInventoryItem, CachedInventoryItem, QSortThenBy> {
  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByColorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorId', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByColorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorId', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByColorName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorName', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByColorNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorName', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByImgUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgUrl', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByImgUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgUrl', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByIsSpare() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSpare', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByIsSpareDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSpare', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByPartCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partCategoryId', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByPartCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partCategoryId', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByPartName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partName', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByPartNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partName', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByPartNum() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partNum', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByPartNumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partNum', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByRgb() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rgb', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByRgbDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rgb', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenBySourceExternalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceExternalId', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenBySourceExternalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceExternalId', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenBySourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.desc);
    });
  }
}

extension CachedInventoryItemQueryWhereDistinct
    on QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct> {
  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByColorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorId');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByColorName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByImgUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imgUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByIsSpare() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSpare');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByPartCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partCategoryId');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByPartName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByPartNum({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partNum', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByRgb({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rgb', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctBySourceExternalId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceExternalId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctBySourceType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceType', caseSensitive: caseSensitive);
    });
  }
}

extension CachedInventoryItemQueryProperty
    on QueryBuilder<CachedInventoryItem, CachedInventoryItem, QQueryProperty> {
  QueryBuilder<CachedInventoryItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedInventoryItem, int, QQueryOperations> colorIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorId');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      colorNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorName');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      imgUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imgUrl');
    });
  }

  QueryBuilder<CachedInventoryItem, bool, QQueryOperations> isSpareProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSpare');
    });
  }

  QueryBuilder<CachedInventoryItem, int?, QQueryOperations>
      partCategoryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partCategoryId');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      partNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partName');
    });
  }

  QueryBuilder<CachedInventoryItem, String, QQueryOperations>
      partNumProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partNum');
    });
  }

  QueryBuilder<CachedInventoryItem, int, QQueryOperations> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations> rgbProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rgb');
    });
  }

  QueryBuilder<CachedInventoryItem, String, QQueryOperations>
      sourceExternalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceExternalId');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedSourceType, QQueryOperations>
      sourceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceType');
    });
  }
}
