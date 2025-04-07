// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moc.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMocCollection on Isar {
  IsarCollection<Moc> get mocs => this.collection();
}

const MocSchema = CollectionSchema(
  name: r'Moc',
  id: 6603530842437396853,
  properties: {
    r'collectedCount': PropertySchema(
      id: 0,
      name: r'collectedCount',
      type: IsarType.long,
    ),
    r'groupSort': PropertySchema(
      id: 1,
      name: r'groupSort',
      type: IsarType.string,
      enumMap: _MocgroupSortEnumValueMap,
    ),
    r'hideComplete': PropertySchema(
      id: 2,
      name: r'hideComplete',
      type: IsarType.bool,
    ),
    r'hideCompleteGroup': PropertySchema(
      id: 3,
      name: r'hideCompleteGroup',
      type: IsarType.bool,
    ),
    r'imageUrl': PropertySchema(
      id: 4,
      name: r'imageUrl',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    ),
    r'parts': PropertySchema(
      id: 6,
      name: r'parts',
      type: IsarType.objectList,
      target: r'CollectablePart',
    ),
    r'quantity': PropertySchema(
      id: 7,
      name: r'quantity',
      type: IsarType.long,
    ),
    r'sort': PropertySchema(
      id: 8,
      name: r'sort',
      type: IsarType.string,
      enumMap: _MocsortEnumValueMap,
    )
  },
  estimateSize: _mocEstimateSize,
  serialize: _mocSerialize,
  deserialize: _mocDeserialize,
  deserializeProp: _mocDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {
    r'CollectablePart': CollectablePartSchema,
    r'RebrickablePart': RebrickablePartSchema
  },
  getId: _mocGetId,
  getLinks: _mocGetLinks,
  attach: _mocAttach,
  version: '3.1.0+1',
);

int _mocEstimateSize(
  Moc object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.groupSort.name.length * 3;
  {
    final value = object.imageUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final list = object.parts;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[CollectablePart]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              CollectablePartSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  bytesCount += 3 + object.sort.name.length * 3;
  return bytesCount;
}

void _mocSerialize(
  Moc object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.collectedCount);
  writer.writeString(offsets[1], object.groupSort.name);
  writer.writeBool(offsets[2], object.hideComplete);
  writer.writeBool(offsets[3], object.hideCompleteGroup);
  writer.writeString(offsets[4], object.imageUrl);
  writer.writeString(offsets[5], object.name);
  writer.writeObjectList<CollectablePart>(
    offsets[6],
    allOffsets,
    CollectablePartSchema.serialize,
    object.parts,
  );
  writer.writeLong(offsets[7], object.quantity);
  writer.writeString(offsets[8], object.sort.name);
}

Moc _mocDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Moc(
    name: reader.readString(offsets[5]),
  );
  object.groupSort =
      _MocgroupSortValueEnumMap[reader.readStringOrNull(offsets[1])] ??
          PartSort.nameDesc;
  object.hideComplete = reader.readBool(offsets[2]);
  object.hideCompleteGroup = reader.readBool(offsets[3]);
  object.id = id;
  object.imageUrl = reader.readStringOrNull(offsets[4]);
  object.parts = reader.readObjectList<CollectablePart>(
    offsets[6],
    CollectablePartSchema.deserialize,
    allOffsets,
    CollectablePart(),
  );
  object.sort = _MocsortValueEnumMap[reader.readStringOrNull(offsets[8])] ??
      PartSort.nameDesc;
  return object;
}

P _mocDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (_MocgroupSortValueEnumMap[reader.readStringOrNull(offset)] ??
          PartSort.nameDesc) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readObjectList<CollectablePart>(
        offset,
        CollectablePartSchema.deserialize,
        allOffsets,
        CollectablePart(),
      )) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (_MocsortValueEnumMap[reader.readStringOrNull(offset)] ??
          PartSort.nameDesc) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _MocgroupSortEnumValueMap = {
  r'nameDesc': r'nameDesc',
  r'nameAsc': r'nameAsc',
  r'collectedAsc': r'collectedAsc',
  r'collectedDesc': r'collectedDesc',
  r'quantityAsc': r'quantityAsc',
  r'quantityDesc': r'quantityDesc',
};
const _MocgroupSortValueEnumMap = {
  r'nameDesc': PartSort.nameDesc,
  r'nameAsc': PartSort.nameAsc,
  r'collectedAsc': PartSort.collectedAsc,
  r'collectedDesc': PartSort.collectedDesc,
  r'quantityAsc': PartSort.quantityAsc,
  r'quantityDesc': PartSort.quantityDesc,
};
const _MocsortEnumValueMap = {
  r'nameDesc': r'nameDesc',
  r'nameAsc': r'nameAsc',
  r'collectedAsc': r'collectedAsc',
  r'collectedDesc': r'collectedDesc',
  r'quantityAsc': r'quantityAsc',
  r'quantityDesc': r'quantityDesc',
};
const _MocsortValueEnumMap = {
  r'nameDesc': PartSort.nameDesc,
  r'nameAsc': PartSort.nameAsc,
  r'collectedAsc': PartSort.collectedAsc,
  r'collectedDesc': PartSort.collectedDesc,
  r'quantityAsc': PartSort.quantityAsc,
  r'quantityDesc': PartSort.quantityDesc,
};

Id _mocGetId(Moc object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _mocGetLinks(Moc object) {
  return [];
}

void _mocAttach(IsarCollection<dynamic> col, Id id, Moc object) {
  object.id = id;
}

extension MocQueryWhereSort on QueryBuilder<Moc, Moc, QWhere> {
  QueryBuilder<Moc, Moc, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MocQueryWhere on QueryBuilder<Moc, Moc, QWhereClause> {
  QueryBuilder<Moc, Moc, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Moc, Moc, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Moc, Moc, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Moc, Moc, QAfterWhereClause> idBetween(
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

extension MocQueryFilter on QueryBuilder<Moc, Moc, QFilterCondition> {
  QueryBuilder<Moc, Moc, QAfterFilterCondition> collectedCountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'collectedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> collectedCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'collectedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> collectedCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'collectedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> collectedCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'collectedCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> groupSortEqualTo(
    PartSort value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupSort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> groupSortGreaterThan(
    PartSort value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'groupSort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> groupSortLessThan(
    PartSort value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'groupSort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> groupSortBetween(
    PartSort lower,
    PartSort upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'groupSort',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> groupSortStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'groupSort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> groupSortEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'groupSort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> groupSortContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'groupSort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> groupSortMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'groupSort',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> groupSortIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupSort',
        value: '',
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> groupSortIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'groupSort',
        value: '',
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> hideCompleteEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hideComplete',
        value: value,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> hideCompleteGroupEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hideCompleteGroup',
        value: value,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Moc, Moc, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Moc, Moc, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Moc, Moc, QAfterFilterCondition> imageUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imageUrl',
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> imageUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imageUrl',
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> imageUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> imageUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> imageUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> imageUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imageUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> imageUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> imageUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> imageUrlContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> imageUrlMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imageUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> imageUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> imageUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<Moc, Moc, QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<Moc, Moc, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<Moc, Moc, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<Moc, Moc, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<Moc, Moc, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<Moc, Moc, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> nameMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> partsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'parts',
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> partsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'parts',
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> partsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'parts',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> partsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'parts',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> partsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'parts',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> partsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'parts',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> partsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'parts',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> partsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'parts',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> quantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> quantityGreaterThan(
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

  QueryBuilder<Moc, Moc, QAfterFilterCondition> quantityLessThan(
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

  QueryBuilder<Moc, Moc, QAfterFilterCondition> quantityBetween(
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

  QueryBuilder<Moc, Moc, QAfterFilterCondition> sortEqualTo(
    PartSort value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> sortGreaterThan(
    PartSort value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> sortLessThan(
    PartSort value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> sortBetween(
    PartSort lower,
    PartSort upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sort',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> sortStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> sortEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> sortContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> sortMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sort',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> sortIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sort',
        value: '',
      ));
    });
  }

  QueryBuilder<Moc, Moc, QAfterFilterCondition> sortIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sort',
        value: '',
      ));
    });
  }
}

extension MocQueryObject on QueryBuilder<Moc, Moc, QFilterCondition> {
  QueryBuilder<Moc, Moc, QAfterFilterCondition> partsElement(
      FilterQuery<CollectablePart> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'parts');
    });
  }
}

extension MocQueryLinks on QueryBuilder<Moc, Moc, QFilterCondition> {}

extension MocQuerySortBy on QueryBuilder<Moc, Moc, QSortBy> {
  QueryBuilder<Moc, Moc, QAfterSortBy> sortByCollectedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectedCount', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortByCollectedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectedCount', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortByGroupSort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupSort', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortByGroupSortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupSort', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortByHideComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideComplete', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortByHideCompleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideComplete', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortByHideCompleteGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideCompleteGroup', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortByHideCompleteGroupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideCompleteGroup', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortBySort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sort', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> sortBySortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sort', Sort.desc);
    });
  }
}

extension MocQuerySortThenBy on QueryBuilder<Moc, Moc, QSortThenBy> {
  QueryBuilder<Moc, Moc, QAfterSortBy> thenByCollectedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectedCount', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenByCollectedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectedCount', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenByGroupSort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupSort', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenByGroupSortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupSort', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenByHideComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideComplete', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenByHideCompleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideComplete', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenByHideCompleteGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideCompleteGroup', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenByHideCompleteGroupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideCompleteGroup', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenBySort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sort', Sort.asc);
    });
  }

  QueryBuilder<Moc, Moc, QAfterSortBy> thenBySortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sort', Sort.desc);
    });
  }
}

extension MocQueryWhereDistinct on QueryBuilder<Moc, Moc, QDistinct> {
  QueryBuilder<Moc, Moc, QDistinct> distinctByCollectedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'collectedCount');
    });
  }

  QueryBuilder<Moc, Moc, QDistinct> distinctByGroupSort(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupSort', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Moc, Moc, QDistinct> distinctByHideComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hideComplete');
    });
  }

  QueryBuilder<Moc, Moc, QDistinct> distinctByHideCompleteGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hideCompleteGroup');
    });
  }

  QueryBuilder<Moc, Moc, QDistinct> distinctByImageUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Moc, Moc, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Moc, Moc, QDistinct> distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }

  QueryBuilder<Moc, Moc, QDistinct> distinctBySort(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sort', caseSensitive: caseSensitive);
    });
  }
}

extension MocQueryProperty on QueryBuilder<Moc, Moc, QQueryProperty> {
  QueryBuilder<Moc, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Moc, int, QQueryOperations> collectedCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'collectedCount');
    });
  }

  QueryBuilder<Moc, PartSort, QQueryOperations> groupSortProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupSort');
    });
  }

  QueryBuilder<Moc, bool, QQueryOperations> hideCompleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hideComplete');
    });
  }

  QueryBuilder<Moc, bool, QQueryOperations> hideCompleteGroupProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hideCompleteGroup');
    });
  }

  QueryBuilder<Moc, String?, QQueryOperations> imageUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageUrl');
    });
  }

  QueryBuilder<Moc, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Moc, List<CollectablePart>?, QQueryOperations> partsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parts');
    });
  }

  QueryBuilder<Moc, int, QQueryOperations> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<Moc, PartSort, QQueryOperations> sortProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sort');
    });
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Moc _$MocFromJson(Map<String, dynamic> json) => Moc(
      name: json['name'] as String,
    )
      ..id = (json['id'] as num).toInt()
      ..imageUrl = json['imageUrl'] as String?
      ..parts = (json['parts'] as List<dynamic>?)
          ?.map((e) => CollectablePart.fromJson(e as Map<String, dynamic>))
          .toList()
      ..sort = $enumDecode(_$PartSortEnumMap, json['sort'])
      ..groupSort = $enumDecode(_$PartSortEnumMap, json['groupSort'])
      ..hideComplete = json['hideComplete'] as bool? ?? false
      ..hideCompleteGroup = json['hideCompleteGroup'] as bool? ?? false;

Map<String, dynamic> _$MocToJson(Moc instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'imageUrl': instance.imageUrl,
      'parts': instance.parts?.map((e) => e.toJson()).toList(),
      'sort': _$PartSortEnumMap[instance.sort]!,
      'groupSort': _$PartSortEnumMap[instance.groupSort]!,
      'hideComplete': instance.hideComplete,
      'hideCompleteGroup': instance.hideCompleteGroup,
    };

const _$PartSortEnumMap = {
  PartSort.nameDesc: 'nameDesc',
  PartSort.nameAsc: 'nameAsc',
  PartSort.collectedAsc: 'collectedAsc',
  PartSort.collectedDesc: 'collectedDesc',
  PartSort.quantityAsc: 'quantityAsc',
  PartSort.quantityDesc: 'quantityDesc',
};
