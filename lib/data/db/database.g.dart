// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CommercialQuotasTable extends CommercialQuotas
    with TableInfo<$CommercialQuotasTable, CommercialQuotaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommercialQuotasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitMeta = const VerificationMeta('limit');
  @override
  late final GeneratedColumn<double> limit = GeneratedColumn<double>(
    'limit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voucherPatternMeta = const VerificationMeta(
    'voucherPattern',
  );
  @override
  late final GeneratedColumn<String> voucherPattern = GeneratedColumn<String>(
    'voucher_pattern',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('store'),
  );
  static const VerificationMeta _cutoffDayMeta = const VerificationMeta(
    'cutoffDay',
  );
  @override
  late final GeneratedColumn<int> cutoffDay = GeneratedColumn<int>(
    'cutoff_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentOffsetDaysMeta = const VerificationMeta(
    'paymentOffsetDays',
  );
  @override
  late final GeneratedColumn<int> paymentOffsetDays = GeneratedColumn<int>(
    'payment_offset_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _managementFeeMeta = const VerificationMeta(
    'managementFee',
  );
  @override
  late final GeneratedColumn<double> managementFee = GeneratedColumn<double>(
    'management_fee',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _managementFeeFrequencyMeta =
      const VerificationMeta('managementFeeFrequency');
  @override
  late final GeneratedColumn<String> managementFeeFrequency =
      GeneratedColumn<String>(
        'management_fee_frequency',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    brand,
    limit,
    notes,
    voucherPattern,
    entityType,
    cutoffDay,
    paymentOffsetDays,
    managementFee,
    managementFeeFrequency,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'commercial_quotas';
  @override
  VerificationContext validateIntegrity(
    Insertable<CommercialQuotaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    } else if (isInserting) {
      context.missing(_brandMeta);
    }
    if (data.containsKey('limit')) {
      context.handle(
        _limitMeta,
        limit.isAcceptableOrUnknown(data['limit']!, _limitMeta),
      );
    } else if (isInserting) {
      context.missing(_limitMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('voucher_pattern')) {
      context.handle(
        _voucherPatternMeta,
        voucherPattern.isAcceptableOrUnknown(
          data['voucher_pattern']!,
          _voucherPatternMeta,
        ),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    }
    if (data.containsKey('cutoff_day')) {
      context.handle(
        _cutoffDayMeta,
        cutoffDay.isAcceptableOrUnknown(data['cutoff_day']!, _cutoffDayMeta),
      );
    }
    if (data.containsKey('payment_offset_days')) {
      context.handle(
        _paymentOffsetDaysMeta,
        paymentOffsetDays.isAcceptableOrUnknown(
          data['payment_offset_days']!,
          _paymentOffsetDaysMeta,
        ),
      );
    }
    if (data.containsKey('management_fee')) {
      context.handle(
        _managementFeeMeta,
        managementFee.isAcceptableOrUnknown(
          data['management_fee']!,
          _managementFeeMeta,
        ),
      );
    }
    if (data.containsKey('management_fee_frequency')) {
      context.handle(
        _managementFeeFrequencyMeta,
        managementFeeFrequency.isAcceptableOrUnknown(
          data['management_fee_frequency']!,
          _managementFeeFrequencyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CommercialQuotaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommercialQuotaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      limit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}limit'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      voucherPattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voucher_pattern'],
      ),
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      cutoffDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cutoff_day'],
      ),
      paymentOffsetDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_offset_days'],
      ),
      managementFee: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}management_fee'],
      ),
      managementFeeFrequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}management_fee_frequency'],
      ),
    );
  }

  @override
  $CommercialQuotasTable createAlias(String alias) {
    return $CommercialQuotasTable(attachedDatabase, alias);
  }
}

class CommercialQuotaRow extends DataClass
    implements Insertable<CommercialQuotaRow> {
  final String id;
  final String brand;
  final double limit;
  final String? notes;

  /// [VoucherPattern.name] chosen for every purchase under this quota —
  /// per-quota, never a single app-wide setting: two different cupos
  /// (e.g. "Joy" and "Totto") can each show a different abstract pattern
  /// on their vouchers. Null means "not chosen yet", falls back to the
  /// first pattern in code (see VoucherPattern.fromName).
  final String? voucherPattern;

  /// 'store' | 'bank' | 'app' — distinguishes credit stores (Totto),
  /// bank cards (Bancolombia), and app lenders (Addi). Default 'store'
  /// so all rows created before v8 are correctly classified.
  final String entityType;
  final int? cutoffDay;
  final int? paymentOffsetDays;
  final double? managementFee;
  final String? managementFeeFrequency;
  const CommercialQuotaRow({
    required this.id,
    required this.brand,
    required this.limit,
    this.notes,
    this.voucherPattern,
    required this.entityType,
    this.cutoffDay,
    this.paymentOffsetDays,
    this.managementFee,
    this.managementFeeFrequency,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['brand'] = Variable<String>(brand);
    map['limit'] = Variable<double>(limit);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || voucherPattern != null) {
      map['voucher_pattern'] = Variable<String>(voucherPattern);
    }
    map['entity_type'] = Variable<String>(entityType);
    if (!nullToAbsent || cutoffDay != null) {
      map['cutoff_day'] = Variable<int>(cutoffDay);
    }
    if (!nullToAbsent || paymentOffsetDays != null) {
      map['payment_offset_days'] = Variable<int>(paymentOffsetDays);
    }
    if (!nullToAbsent || managementFee != null) {
      map['management_fee'] = Variable<double>(managementFee);
    }
    if (!nullToAbsent || managementFeeFrequency != null) {
      map['management_fee_frequency'] = Variable<String>(
        managementFeeFrequency,
      );
    }
    return map;
  }

  CommercialQuotasCompanion toCompanion(bool nullToAbsent) {
    return CommercialQuotasCompanion(
      id: Value(id),
      brand: Value(brand),
      limit: Value(limit),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      voucherPattern: voucherPattern == null && nullToAbsent
          ? const Value.absent()
          : Value(voucherPattern),
      entityType: Value(entityType),
      cutoffDay: cutoffDay == null && nullToAbsent
          ? const Value.absent()
          : Value(cutoffDay),
      paymentOffsetDays: paymentOffsetDays == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentOffsetDays),
      managementFee: managementFee == null && nullToAbsent
          ? const Value.absent()
          : Value(managementFee),
      managementFeeFrequency: managementFeeFrequency == null && nullToAbsent
          ? const Value.absent()
          : Value(managementFeeFrequency),
    );
  }

  factory CommercialQuotaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommercialQuotaRow(
      id: serializer.fromJson<String>(json['id']),
      brand: serializer.fromJson<String>(json['brand']),
      limit: serializer.fromJson<double>(json['limit']),
      notes: serializer.fromJson<String?>(json['notes']),
      voucherPattern: serializer.fromJson<String?>(json['voucherPattern']),
      entityType: serializer.fromJson<String>(json['entityType']),
      cutoffDay: serializer.fromJson<int?>(json['cutoffDay']),
      paymentOffsetDays: serializer.fromJson<int?>(json['paymentOffsetDays']),
      managementFee: serializer.fromJson<double?>(json['managementFee']),
      managementFeeFrequency: serializer.fromJson<String?>(
        json['managementFeeFrequency'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'brand': serializer.toJson<String>(brand),
      'limit': serializer.toJson<double>(limit),
      'notes': serializer.toJson<String?>(notes),
      'voucherPattern': serializer.toJson<String?>(voucherPattern),
      'entityType': serializer.toJson<String>(entityType),
      'cutoffDay': serializer.toJson<int?>(cutoffDay),
      'paymentOffsetDays': serializer.toJson<int?>(paymentOffsetDays),
      'managementFee': serializer.toJson<double?>(managementFee),
      'managementFeeFrequency': serializer.toJson<String?>(
        managementFeeFrequency,
      ),
    };
  }

  CommercialQuotaRow copyWith({
    String? id,
    String? brand,
    double? limit,
    Value<String?> notes = const Value.absent(),
    Value<String?> voucherPattern = const Value.absent(),
    String? entityType,
    Value<int?> cutoffDay = const Value.absent(),
    Value<int?> paymentOffsetDays = const Value.absent(),
    Value<double?> managementFee = const Value.absent(),
    Value<String?> managementFeeFrequency = const Value.absent(),
  }) => CommercialQuotaRow(
    id: id ?? this.id,
    brand: brand ?? this.brand,
    limit: limit ?? this.limit,
    notes: notes.present ? notes.value : this.notes,
    voucherPattern: voucherPattern.present
        ? voucherPattern.value
        : this.voucherPattern,
    entityType: entityType ?? this.entityType,
    cutoffDay: cutoffDay.present ? cutoffDay.value : this.cutoffDay,
    paymentOffsetDays: paymentOffsetDays.present
        ? paymentOffsetDays.value
        : this.paymentOffsetDays,
    managementFee: managementFee.present
        ? managementFee.value
        : this.managementFee,
    managementFeeFrequency: managementFeeFrequency.present
        ? managementFeeFrequency.value
        : this.managementFeeFrequency,
  );
  CommercialQuotaRow copyWithCompanion(CommercialQuotasCompanion data) {
    return CommercialQuotaRow(
      id: data.id.present ? data.id.value : this.id,
      brand: data.brand.present ? data.brand.value : this.brand,
      limit: data.limit.present ? data.limit.value : this.limit,
      notes: data.notes.present ? data.notes.value : this.notes,
      voucherPattern: data.voucherPattern.present
          ? data.voucherPattern.value
          : this.voucherPattern,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      cutoffDay: data.cutoffDay.present ? data.cutoffDay.value : this.cutoffDay,
      paymentOffsetDays: data.paymentOffsetDays.present
          ? data.paymentOffsetDays.value
          : this.paymentOffsetDays,
      managementFee: data.managementFee.present
          ? data.managementFee.value
          : this.managementFee,
      managementFeeFrequency: data.managementFeeFrequency.present
          ? data.managementFeeFrequency.value
          : this.managementFeeFrequency,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommercialQuotaRow(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('limit: $limit, ')
          ..write('notes: $notes, ')
          ..write('voucherPattern: $voucherPattern, ')
          ..write('entityType: $entityType, ')
          ..write('cutoffDay: $cutoffDay, ')
          ..write('paymentOffsetDays: $paymentOffsetDays, ')
          ..write('managementFee: $managementFee, ')
          ..write('managementFeeFrequency: $managementFeeFrequency')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    brand,
    limit,
    notes,
    voucherPattern,
    entityType,
    cutoffDay,
    paymentOffsetDays,
    managementFee,
    managementFeeFrequency,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommercialQuotaRow &&
          other.id == this.id &&
          other.brand == this.brand &&
          other.limit == this.limit &&
          other.notes == this.notes &&
          other.voucherPattern == this.voucherPattern &&
          other.entityType == this.entityType &&
          other.cutoffDay == this.cutoffDay &&
          other.paymentOffsetDays == this.paymentOffsetDays &&
          other.managementFee == this.managementFee &&
          other.managementFeeFrequency == this.managementFeeFrequency);
}

class CommercialQuotasCompanion extends UpdateCompanion<CommercialQuotaRow> {
  final Value<String> id;
  final Value<String> brand;
  final Value<double> limit;
  final Value<String?> notes;
  final Value<String?> voucherPattern;
  final Value<String> entityType;
  final Value<int?> cutoffDay;
  final Value<int?> paymentOffsetDays;
  final Value<double?> managementFee;
  final Value<String?> managementFeeFrequency;
  final Value<int> rowid;
  const CommercialQuotasCompanion({
    this.id = const Value.absent(),
    this.brand = const Value.absent(),
    this.limit = const Value.absent(),
    this.notes = const Value.absent(),
    this.voucherPattern = const Value.absent(),
    this.entityType = const Value.absent(),
    this.cutoffDay = const Value.absent(),
    this.paymentOffsetDays = const Value.absent(),
    this.managementFee = const Value.absent(),
    this.managementFeeFrequency = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommercialQuotasCompanion.insert({
    required String id,
    required String brand,
    required double limit,
    this.notes = const Value.absent(),
    this.voucherPattern = const Value.absent(),
    this.entityType = const Value.absent(),
    this.cutoffDay = const Value.absent(),
    this.paymentOffsetDays = const Value.absent(),
    this.managementFee = const Value.absent(),
    this.managementFeeFrequency = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       brand = Value(brand),
       limit = Value(limit);
  static Insertable<CommercialQuotaRow> custom({
    Expression<String>? id,
    Expression<String>? brand,
    Expression<double>? limit,
    Expression<String>? notes,
    Expression<String>? voucherPattern,
    Expression<String>? entityType,
    Expression<int>? cutoffDay,
    Expression<int>? paymentOffsetDays,
    Expression<double>? managementFee,
    Expression<String>? managementFeeFrequency,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brand != null) 'brand': brand,
      if (limit != null) 'limit': limit,
      if (notes != null) 'notes': notes,
      if (voucherPattern != null) 'voucher_pattern': voucherPattern,
      if (entityType != null) 'entity_type': entityType,
      if (cutoffDay != null) 'cutoff_day': cutoffDay,
      if (paymentOffsetDays != null) 'payment_offset_days': paymentOffsetDays,
      if (managementFee != null) 'management_fee': managementFee,
      if (managementFeeFrequency != null)
        'management_fee_frequency': managementFeeFrequency,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommercialQuotasCompanion copyWith({
    Value<String>? id,
    Value<String>? brand,
    Value<double>? limit,
    Value<String?>? notes,
    Value<String?>? voucherPattern,
    Value<String>? entityType,
    Value<int?>? cutoffDay,
    Value<int?>? paymentOffsetDays,
    Value<double?>? managementFee,
    Value<String?>? managementFeeFrequency,
    Value<int>? rowid,
  }) {
    return CommercialQuotasCompanion(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      limit: limit ?? this.limit,
      notes: notes ?? this.notes,
      voucherPattern: voucherPattern ?? this.voucherPattern,
      entityType: entityType ?? this.entityType,
      cutoffDay: cutoffDay ?? this.cutoffDay,
      paymentOffsetDays: paymentOffsetDays ?? this.paymentOffsetDays,
      managementFee: managementFee ?? this.managementFee,
      managementFeeFrequency:
          managementFeeFrequency ?? this.managementFeeFrequency,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (limit.present) {
      map['limit'] = Variable<double>(limit.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (voucherPattern.present) {
      map['voucher_pattern'] = Variable<String>(voucherPattern.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (cutoffDay.present) {
      map['cutoff_day'] = Variable<int>(cutoffDay.value);
    }
    if (paymentOffsetDays.present) {
      map['payment_offset_days'] = Variable<int>(paymentOffsetDays.value);
    }
    if (managementFee.present) {
      map['management_fee'] = Variable<double>(managementFee.value);
    }
    if (managementFeeFrequency.present) {
      map['management_fee_frequency'] = Variable<String>(
        managementFeeFrequency.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommercialQuotasCompanion(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('limit: $limit, ')
          ..write('notes: $notes, ')
          ..write('voucherPattern: $voucherPattern, ')
          ..write('entityType: $entityType, ')
          ..write('cutoffDay: $cutoffDay, ')
          ..write('paymentOffsetDays: $paymentOffsetDays, ')
          ..write('managementFee: $managementFee, ')
          ..write('managementFeeFrequency: $managementFeeFrequency, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CreditsTable extends Credits with TableInfo<$CreditsTable, CreditRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreditsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lenderMeta = const VerificationMeta('lender');
  @override
  late final GeneratedColumn<String> lender = GeneratedColumn<String>(
    'lender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardMeta = const VerificationMeta('card');
  @override
  late final GeneratedColumn<String> card = GeneratedColumn<String>(
    'card',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quotaAmountMeta = const VerificationMeta(
    'quotaAmount',
  );
  @override
  late final GeneratedColumn<double> quotaAmount = GeneratedColumn<double>(
    'quota_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalInstallmentsMeta = const VerificationMeta(
    'totalInstallments',
  );
  @override
  late final GeneratedColumn<int> totalInstallments = GeneratedColumn<int>(
    'total_installments',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _interestRateMeta = const VerificationMeta(
    'interestRate',
  );
  @override
  late final GeneratedColumn<double> interestRate = GeneratedColumn<double>(
    'interest_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduleManuallyAdjustedMeta =
      const VerificationMeta('scheduleManuallyAdjusted');
  @override
  late final GeneratedColumn<bool> scheduleManuallyAdjusted =
      GeneratedColumn<bool>(
        'schedule_manually_adjusted',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("schedule_manually_adjusted" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _interestRateTypeMeta = const VerificationMeta(
    'interestRateType',
  );
  @override
  late final GeneratedColumn<String> interestRateType = GeneratedColumn<String>(
    'interest_rate_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<double> creditLimit = GeneratedColumn<double>(
    'credit_limit',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentBalanceMeta = const VerificationMeta(
    'currentBalance',
  );
  @override
  late final GeneratedColumn<double> currentBalance = GeneratedColumn<double>(
    'current_balance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cutoffDayMeta = const VerificationMeta(
    'cutoffDay',
  );
  @override
  late final GeneratedColumn<int> cutoffDay = GeneratedColumn<int>(
    'cutoff_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentDueOffsetDaysMeta =
      const VerificationMeta('paymentDueOffsetDays');
  @override
  late final GeneratedColumn<int> paymentDueOffsetDays = GeneratedColumn<int>(
    'payment_due_offset_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _managementFeeMeta = const VerificationMeta(
    'managementFee',
  );
  @override
  late final GeneratedColumn<double> managementFee = GeneratedColumn<double>(
    'management_fee',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _managementFeeFrequencyMeta =
      const VerificationMeta('managementFeeFrequency');
  @override
  late final GeneratedColumn<String> managementFeeFrequency =
      GeneratedColumn<String>(
        'management_fee_frequency',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cycleCountMeta = const VerificationMeta(
    'cycleCount',
  );
  @override
  late final GeneratedColumn<int> cycleCount = GeneratedColumn<int>(
    'cycle_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAccrualCutoffMeta = const VerificationMeta(
    'lastAccrualCutoff',
  );
  @override
  late final GeneratedColumn<String> lastAccrualCutoff =
      GeneratedColumn<String>(
        'last_accrual_cutoff',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _quotaIdMeta = const VerificationMeta(
    'quotaId',
  );
  @override
  late final GeneratedColumn<String> quotaId = GeneratedColumn<String>(
    'quota_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES commercial_quotas (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _interestUnknownMeta = const VerificationMeta(
    'interestUnknown',
  );
  @override
  late final GeneratedColumn<bool> interestUnknown = GeneratedColumn<bool>(
    'interest_unknown',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("interest_unknown" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _earlyPaymentWaivesInterestMeta =
      const VerificationMeta('earlyPaymentWaivesInterest');
  @override
  late final GeneratedColumn<bool> earlyPaymentWaivesInterest =
      GeneratedColumn<bool>(
        'early_payment_waives_interest',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("early_payment_waives_interest" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _cardDesignMeta = const VerificationMeta(
    'cardDesign',
  );
  @override
  late final GeneratedColumn<String> cardDesign = GeneratedColumn<String>(
    'card_design',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentDueDayMeta = const VerificationMeta(
    'paymentDueDay',
  );
  @override
  late final GeneratedColumn<int> paymentDueDay = GeneratedColumn<int>(
    'payment_due_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _oneInstallmentInterestPolicyMeta =
      const VerificationMeta('oneInstallmentInterestPolicy');
  @override
  late final GeneratedColumn<bool> oneInstallmentInterestPolicy =
      GeneratedColumn<bool>(
        'one_installment_interest_policy',
        aliasedName,
        true,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("one_installment_interest_policy" IN (0, 1))',
        ),
      );
  static const VerificationMeta _notificationDaysBeforeMeta =
      const VerificationMeta('notificationDaysBefore');
  @override
  late final GeneratedColumn<int> notificationDaysBefore = GeneratedColumn<int>(
    'notification_days_before',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    name,
    lender,
    color,
    notes,
    location,
    card,
    totalAmount,
    quotaAmount,
    totalInstallments,
    frequency,
    startDate,
    interestRate,
    scheduleManuallyAdjusted,
    interestRateType,
    creditLimit,
    currentBalance,
    cutoffDay,
    paymentDueOffsetDays,
    managementFee,
    managementFeeFrequency,
    cycleCount,
    lastAccrualCutoff,
    quotaId,
    interestUnknown,
    earlyPaymentWaivesInterest,
    cardDesign,
    paymentDueDay,
    oneInstallmentInterestPolicy,
    notificationDaysBefore,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credits';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreditRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('lender')) {
      context.handle(
        _lenderMeta,
        lender.isAcceptableOrUnknown(data['lender']!, _lenderMeta),
      );
    } else if (isInserting) {
      context.missing(_lenderMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('card')) {
      context.handle(
        _cardMeta,
        card.isAcceptableOrUnknown(data['card']!, _cardMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('quota_amount')) {
      context.handle(
        _quotaAmountMeta,
        quotaAmount.isAcceptableOrUnknown(
          data['quota_amount']!,
          _quotaAmountMeta,
        ),
      );
    }
    if (data.containsKey('total_installments')) {
      context.handle(
        _totalInstallmentsMeta,
        totalInstallments.isAcceptableOrUnknown(
          data['total_installments']!,
          _totalInstallmentsMeta,
        ),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('interest_rate')) {
      context.handle(
        _interestRateMeta,
        interestRate.isAcceptableOrUnknown(
          data['interest_rate']!,
          _interestRateMeta,
        ),
      );
    }
    if (data.containsKey('schedule_manually_adjusted')) {
      context.handle(
        _scheduleManuallyAdjustedMeta,
        scheduleManuallyAdjusted.isAcceptableOrUnknown(
          data['schedule_manually_adjusted']!,
          _scheduleManuallyAdjustedMeta,
        ),
      );
    }
    if (data.containsKey('interest_rate_type')) {
      context.handle(
        _interestRateTypeMeta,
        interestRateType.isAcceptableOrUnknown(
          data['interest_rate_type']!,
          _interestRateTypeMeta,
        ),
      );
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    }
    if (data.containsKey('current_balance')) {
      context.handle(
        _currentBalanceMeta,
        currentBalance.isAcceptableOrUnknown(
          data['current_balance']!,
          _currentBalanceMeta,
        ),
      );
    }
    if (data.containsKey('cutoff_day')) {
      context.handle(
        _cutoffDayMeta,
        cutoffDay.isAcceptableOrUnknown(data['cutoff_day']!, _cutoffDayMeta),
      );
    }
    if (data.containsKey('payment_due_offset_days')) {
      context.handle(
        _paymentDueOffsetDaysMeta,
        paymentDueOffsetDays.isAcceptableOrUnknown(
          data['payment_due_offset_days']!,
          _paymentDueOffsetDaysMeta,
        ),
      );
    }
    if (data.containsKey('management_fee')) {
      context.handle(
        _managementFeeMeta,
        managementFee.isAcceptableOrUnknown(
          data['management_fee']!,
          _managementFeeMeta,
        ),
      );
    }
    if (data.containsKey('management_fee_frequency')) {
      context.handle(
        _managementFeeFrequencyMeta,
        managementFeeFrequency.isAcceptableOrUnknown(
          data['management_fee_frequency']!,
          _managementFeeFrequencyMeta,
        ),
      );
    }
    if (data.containsKey('cycle_count')) {
      context.handle(
        _cycleCountMeta,
        cycleCount.isAcceptableOrUnknown(data['cycle_count']!, _cycleCountMeta),
      );
    }
    if (data.containsKey('last_accrual_cutoff')) {
      context.handle(
        _lastAccrualCutoffMeta,
        lastAccrualCutoff.isAcceptableOrUnknown(
          data['last_accrual_cutoff']!,
          _lastAccrualCutoffMeta,
        ),
      );
    }
    if (data.containsKey('quota_id')) {
      context.handle(
        _quotaIdMeta,
        quotaId.isAcceptableOrUnknown(data['quota_id']!, _quotaIdMeta),
      );
    }
    if (data.containsKey('interest_unknown')) {
      context.handle(
        _interestUnknownMeta,
        interestUnknown.isAcceptableOrUnknown(
          data['interest_unknown']!,
          _interestUnknownMeta,
        ),
      );
    }
    if (data.containsKey('early_payment_waives_interest')) {
      context.handle(
        _earlyPaymentWaivesInterestMeta,
        earlyPaymentWaivesInterest.isAcceptableOrUnknown(
          data['early_payment_waives_interest']!,
          _earlyPaymentWaivesInterestMeta,
        ),
      );
    }
    if (data.containsKey('card_design')) {
      context.handle(
        _cardDesignMeta,
        cardDesign.isAcceptableOrUnknown(data['card_design']!, _cardDesignMeta),
      );
    }
    if (data.containsKey('payment_due_day')) {
      context.handle(
        _paymentDueDayMeta,
        paymentDueDay.isAcceptableOrUnknown(
          data['payment_due_day']!,
          _paymentDueDayMeta,
        ),
      );
    }
    if (data.containsKey('one_installment_interest_policy')) {
      context.handle(
        _oneInstallmentInterestPolicyMeta,
        oneInstallmentInterestPolicy.isAcceptableOrUnknown(
          data['one_installment_interest_policy']!,
          _oneInstallmentInterestPolicyMeta,
        ),
      );
    }
    if (data.containsKey('notification_days_before')) {
      context.handle(
        _notificationDaysBeforeMeta,
        notificationDaysBefore.isAcceptableOrUnknown(
          data['notification_days_before']!,
          _notificationDaysBeforeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CreditRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreditRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      lender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lender'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      card: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card'],
      ),
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      ),
      quotaAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quota_amount'],
      ),
      totalInstallments: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_installments'],
      ),
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      ),
      interestRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interest_rate'],
      ),
      scheduleManuallyAdjusted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}schedule_manually_adjusted'],
      )!,
      interestRateType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interest_rate_type'],
      ),
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}credit_limit'],
      ),
      currentBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_balance'],
      ),
      cutoffDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cutoff_day'],
      ),
      paymentDueOffsetDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_due_offset_days'],
      ),
      managementFee: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}management_fee'],
      ),
      managementFeeFrequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}management_fee_frequency'],
      ),
      cycleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_count'],
      ),
      lastAccrualCutoff: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_accrual_cutoff'],
      ),
      quotaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quota_id'],
      ),
      interestUnknown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}interest_unknown'],
      )!,
      earlyPaymentWaivesInterest: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}early_payment_waives_interest'],
      )!,
      cardDesign: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_design'],
      ),
      paymentDueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_due_day'],
      )!,
      oneInstallmentInterestPolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}one_installment_interest_policy'],
      ),
      notificationDaysBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_days_before'],
      ),
    );
  }

  @override
  $CreditsTable createAlias(String alias) {
    return $CreditsTable(attachedDatabase, alias);
  }
}

class CreditRow extends DataClass implements Insertable<CreditRow> {
  final String id;
  final String type;
  final String name;
  final String lender;
  final String? color;
  final String? notes;
  final String? location;
  final String? card;
  final double? totalAmount;
  final double? quotaAmount;
  final int? totalInstallments;
  final String? frequency;
  final String? startDate;
  final double? interestRate;

  /// True once this loan's installment schedule has diverged from the pure
  /// French amortization derived from its base fields (totalAmount,
  /// quotaAmount, totalInstallments, interestRate/Type) — e.g. via
  /// applyLoanAbono's reamortization or registerInstallmentActualPayment's
  /// principal adjustment. `recomputeLoanInstallments` must NEVER be run
  /// again on a loan with this flag set: it would silently discard the
  /// manual adjustment and rebuild the original pre-adjustment schedule.
  /// See CreditsNotifier.build() in lib/providers/credits_provider.dart.
  final bool scheduleManuallyAdjusted;
  final String? interestRateType;
  final double? creditLimit;
  final double? currentBalance;
  final int? cutoffDay;
  final int? paymentDueOffsetDays;
  final double? managementFee;
  final String? managementFeeFrequency;
  final int? cycleCount;
  final String? lastAccrualCutoff;

  /// Links this loan/cupo purchase to its parent CommercialQuota, or null
  /// for a normal bank loan/card unrelated to any commercial quota.
  /// onDelete: restrict — deleting a quota with active purchases must fail
  /// loudly rather than silently orphan or cascade-delete real credit data.
  final String? quotaId;

  /// True when the user chose not to provide/know the interest rate for
  /// this purchase — suppresses rate display, never synthesizes a fake 0%.
  final bool interestUnknown;

  /// True when this purchase's brand waives interest if paid before the
  /// due date (e.g. Lili Pink's CrediPink) — always a manual per-purchase
  /// flag, never assumed by default.
  final bool earlyPaymentWaivesInterest;

  /// Card background design identifier — one of the 8 CardDesign enum values
  /// serialized as String (e.g. 'gradiente', 'swissGrid', 'liquido', etc.).
  /// Null means 'gradiente' (default gradient look).
  final String? cardDesign;

  /// Día del mes (1–31) en que vence el pago de la tarjeta.
  /// Reemplaza paymentDueOffsetDays en la UI y lógica nueva.
  /// 0 = no migrado aún — usa paymentDueOffsetDays como fallback.
  final int paymentDueDay;

  /// null = desconocido, true = sin interés a 1 cuota, false = con interés.
  final bool? oneInstallmentInterestPolicy;

  /// Días de antelación para notificar vencimientos de ESTE crédito.
  /// null = usar el ajuste global (notificationSettingsProvider.daysBefore).
  final int? notificationDaysBefore;
  const CreditRow({
    required this.id,
    required this.type,
    required this.name,
    required this.lender,
    this.color,
    this.notes,
    this.location,
    this.card,
    this.totalAmount,
    this.quotaAmount,
    this.totalInstallments,
    this.frequency,
    this.startDate,
    this.interestRate,
    required this.scheduleManuallyAdjusted,
    this.interestRateType,
    this.creditLimit,
    this.currentBalance,
    this.cutoffDay,
    this.paymentDueOffsetDays,
    this.managementFee,
    this.managementFeeFrequency,
    this.cycleCount,
    this.lastAccrualCutoff,
    this.quotaId,
    required this.interestUnknown,
    required this.earlyPaymentWaivesInterest,
    this.cardDesign,
    required this.paymentDueDay,
    this.oneInstallmentInterestPolicy,
    this.notificationDaysBefore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    map['lender'] = Variable<String>(lender);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || card != null) {
      map['card'] = Variable<String>(card);
    }
    if (!nullToAbsent || totalAmount != null) {
      map['total_amount'] = Variable<double>(totalAmount);
    }
    if (!nullToAbsent || quotaAmount != null) {
      map['quota_amount'] = Variable<double>(quotaAmount);
    }
    if (!nullToAbsent || totalInstallments != null) {
      map['total_installments'] = Variable<int>(totalInstallments);
    }
    if (!nullToAbsent || frequency != null) {
      map['frequency'] = Variable<String>(frequency);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<String>(startDate);
    }
    if (!nullToAbsent || interestRate != null) {
      map['interest_rate'] = Variable<double>(interestRate);
    }
    map['schedule_manually_adjusted'] = Variable<bool>(
      scheduleManuallyAdjusted,
    );
    if (!nullToAbsent || interestRateType != null) {
      map['interest_rate_type'] = Variable<String>(interestRateType);
    }
    if (!nullToAbsent || creditLimit != null) {
      map['credit_limit'] = Variable<double>(creditLimit);
    }
    if (!nullToAbsent || currentBalance != null) {
      map['current_balance'] = Variable<double>(currentBalance);
    }
    if (!nullToAbsent || cutoffDay != null) {
      map['cutoff_day'] = Variable<int>(cutoffDay);
    }
    if (!nullToAbsent || paymentDueOffsetDays != null) {
      map['payment_due_offset_days'] = Variable<int>(paymentDueOffsetDays);
    }
    if (!nullToAbsent || managementFee != null) {
      map['management_fee'] = Variable<double>(managementFee);
    }
    if (!nullToAbsent || managementFeeFrequency != null) {
      map['management_fee_frequency'] = Variable<String>(
        managementFeeFrequency,
      );
    }
    if (!nullToAbsent || cycleCount != null) {
      map['cycle_count'] = Variable<int>(cycleCount);
    }
    if (!nullToAbsent || lastAccrualCutoff != null) {
      map['last_accrual_cutoff'] = Variable<String>(lastAccrualCutoff);
    }
    if (!nullToAbsent || quotaId != null) {
      map['quota_id'] = Variable<String>(quotaId);
    }
    map['interest_unknown'] = Variable<bool>(interestUnknown);
    map['early_payment_waives_interest'] = Variable<bool>(
      earlyPaymentWaivesInterest,
    );
    if (!nullToAbsent || cardDesign != null) {
      map['card_design'] = Variable<String>(cardDesign);
    }
    map['payment_due_day'] = Variable<int>(paymentDueDay);
    if (!nullToAbsent || oneInstallmentInterestPolicy != null) {
      map['one_installment_interest_policy'] = Variable<bool>(
        oneInstallmentInterestPolicy,
      );
    }
    if (!nullToAbsent || notificationDaysBefore != null) {
      map['notification_days_before'] = Variable<int>(notificationDaysBefore);
    }
    return map;
  }

  CreditsCompanion toCompanion(bool nullToAbsent) {
    return CreditsCompanion(
      id: Value(id),
      type: Value(type),
      name: Value(name),
      lender: Value(lender),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      card: card == null && nullToAbsent ? const Value.absent() : Value(card),
      totalAmount: totalAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(totalAmount),
      quotaAmount: quotaAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(quotaAmount),
      totalInstallments: totalInstallments == null && nullToAbsent
          ? const Value.absent()
          : Value(totalInstallments),
      frequency: frequency == null && nullToAbsent
          ? const Value.absent()
          : Value(frequency),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      interestRate: interestRate == null && nullToAbsent
          ? const Value.absent()
          : Value(interestRate),
      scheduleManuallyAdjusted: Value(scheduleManuallyAdjusted),
      interestRateType: interestRateType == null && nullToAbsent
          ? const Value.absent()
          : Value(interestRateType),
      creditLimit: creditLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimit),
      currentBalance: currentBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(currentBalance),
      cutoffDay: cutoffDay == null && nullToAbsent
          ? const Value.absent()
          : Value(cutoffDay),
      paymentDueOffsetDays: paymentDueOffsetDays == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentDueOffsetDays),
      managementFee: managementFee == null && nullToAbsent
          ? const Value.absent()
          : Value(managementFee),
      managementFeeFrequency: managementFeeFrequency == null && nullToAbsent
          ? const Value.absent()
          : Value(managementFeeFrequency),
      cycleCount: cycleCount == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleCount),
      lastAccrualCutoff: lastAccrualCutoff == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAccrualCutoff),
      quotaId: quotaId == null && nullToAbsent
          ? const Value.absent()
          : Value(quotaId),
      interestUnknown: Value(interestUnknown),
      earlyPaymentWaivesInterest: Value(earlyPaymentWaivesInterest),
      cardDesign: cardDesign == null && nullToAbsent
          ? const Value.absent()
          : Value(cardDesign),
      paymentDueDay: Value(paymentDueDay),
      oneInstallmentInterestPolicy:
          oneInstallmentInterestPolicy == null && nullToAbsent
          ? const Value.absent()
          : Value(oneInstallmentInterestPolicy),
      notificationDaysBefore: notificationDaysBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(notificationDaysBefore),
    );
  }

  factory CreditRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreditRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      lender: serializer.fromJson<String>(json['lender']),
      color: serializer.fromJson<String?>(json['color']),
      notes: serializer.fromJson<String?>(json['notes']),
      location: serializer.fromJson<String?>(json['location']),
      card: serializer.fromJson<String?>(json['card']),
      totalAmount: serializer.fromJson<double?>(json['totalAmount']),
      quotaAmount: serializer.fromJson<double?>(json['quotaAmount']),
      totalInstallments: serializer.fromJson<int?>(json['totalInstallments']),
      frequency: serializer.fromJson<String?>(json['frequency']),
      startDate: serializer.fromJson<String?>(json['startDate']),
      interestRate: serializer.fromJson<double?>(json['interestRate']),
      scheduleManuallyAdjusted: serializer.fromJson<bool>(
        json['scheduleManuallyAdjusted'],
      ),
      interestRateType: serializer.fromJson<String?>(json['interestRateType']),
      creditLimit: serializer.fromJson<double?>(json['creditLimit']),
      currentBalance: serializer.fromJson<double?>(json['currentBalance']),
      cutoffDay: serializer.fromJson<int?>(json['cutoffDay']),
      paymentDueOffsetDays: serializer.fromJson<int?>(
        json['paymentDueOffsetDays'],
      ),
      managementFee: serializer.fromJson<double?>(json['managementFee']),
      managementFeeFrequency: serializer.fromJson<String?>(
        json['managementFeeFrequency'],
      ),
      cycleCount: serializer.fromJson<int?>(json['cycleCount']),
      lastAccrualCutoff: serializer.fromJson<String?>(
        json['lastAccrualCutoff'],
      ),
      quotaId: serializer.fromJson<String?>(json['quotaId']),
      interestUnknown: serializer.fromJson<bool>(json['interestUnknown']),
      earlyPaymentWaivesInterest: serializer.fromJson<bool>(
        json['earlyPaymentWaivesInterest'],
      ),
      cardDesign: serializer.fromJson<String?>(json['cardDesign']),
      paymentDueDay: serializer.fromJson<int>(json['paymentDueDay']),
      oneInstallmentInterestPolicy: serializer.fromJson<bool?>(
        json['oneInstallmentInterestPolicy'],
      ),
      notificationDaysBefore: serializer.fromJson<int?>(
        json['notificationDaysBefore'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'lender': serializer.toJson<String>(lender),
      'color': serializer.toJson<String?>(color),
      'notes': serializer.toJson<String?>(notes),
      'location': serializer.toJson<String?>(location),
      'card': serializer.toJson<String?>(card),
      'totalAmount': serializer.toJson<double?>(totalAmount),
      'quotaAmount': serializer.toJson<double?>(quotaAmount),
      'totalInstallments': serializer.toJson<int?>(totalInstallments),
      'frequency': serializer.toJson<String?>(frequency),
      'startDate': serializer.toJson<String?>(startDate),
      'interestRate': serializer.toJson<double?>(interestRate),
      'scheduleManuallyAdjusted': serializer.toJson<bool>(
        scheduleManuallyAdjusted,
      ),
      'interestRateType': serializer.toJson<String?>(interestRateType),
      'creditLimit': serializer.toJson<double?>(creditLimit),
      'currentBalance': serializer.toJson<double?>(currentBalance),
      'cutoffDay': serializer.toJson<int?>(cutoffDay),
      'paymentDueOffsetDays': serializer.toJson<int?>(paymentDueOffsetDays),
      'managementFee': serializer.toJson<double?>(managementFee),
      'managementFeeFrequency': serializer.toJson<String?>(
        managementFeeFrequency,
      ),
      'cycleCount': serializer.toJson<int?>(cycleCount),
      'lastAccrualCutoff': serializer.toJson<String?>(lastAccrualCutoff),
      'quotaId': serializer.toJson<String?>(quotaId),
      'interestUnknown': serializer.toJson<bool>(interestUnknown),
      'earlyPaymentWaivesInterest': serializer.toJson<bool>(
        earlyPaymentWaivesInterest,
      ),
      'cardDesign': serializer.toJson<String?>(cardDesign),
      'paymentDueDay': serializer.toJson<int>(paymentDueDay),
      'oneInstallmentInterestPolicy': serializer.toJson<bool?>(
        oneInstallmentInterestPolicy,
      ),
      'notificationDaysBefore': serializer.toJson<int?>(notificationDaysBefore),
    };
  }

  CreditRow copyWith({
    String? id,
    String? type,
    String? name,
    String? lender,
    Value<String?> color = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> card = const Value.absent(),
    Value<double?> totalAmount = const Value.absent(),
    Value<double?> quotaAmount = const Value.absent(),
    Value<int?> totalInstallments = const Value.absent(),
    Value<String?> frequency = const Value.absent(),
    Value<String?> startDate = const Value.absent(),
    Value<double?> interestRate = const Value.absent(),
    bool? scheduleManuallyAdjusted,
    Value<String?> interestRateType = const Value.absent(),
    Value<double?> creditLimit = const Value.absent(),
    Value<double?> currentBalance = const Value.absent(),
    Value<int?> cutoffDay = const Value.absent(),
    Value<int?> paymentDueOffsetDays = const Value.absent(),
    Value<double?> managementFee = const Value.absent(),
    Value<String?> managementFeeFrequency = const Value.absent(),
    Value<int?> cycleCount = const Value.absent(),
    Value<String?> lastAccrualCutoff = const Value.absent(),
    Value<String?> quotaId = const Value.absent(),
    bool? interestUnknown,
    bool? earlyPaymentWaivesInterest,
    Value<String?> cardDesign = const Value.absent(),
    int? paymentDueDay,
    Value<bool?> oneInstallmentInterestPolicy = const Value.absent(),
    Value<int?> notificationDaysBefore = const Value.absent(),
  }) => CreditRow(
    id: id ?? this.id,
    type: type ?? this.type,
    name: name ?? this.name,
    lender: lender ?? this.lender,
    color: color.present ? color.value : this.color,
    notes: notes.present ? notes.value : this.notes,
    location: location.present ? location.value : this.location,
    card: card.present ? card.value : this.card,
    totalAmount: totalAmount.present ? totalAmount.value : this.totalAmount,
    quotaAmount: quotaAmount.present ? quotaAmount.value : this.quotaAmount,
    totalInstallments: totalInstallments.present
        ? totalInstallments.value
        : this.totalInstallments,
    frequency: frequency.present ? frequency.value : this.frequency,
    startDate: startDate.present ? startDate.value : this.startDate,
    interestRate: interestRate.present ? interestRate.value : this.interestRate,
    scheduleManuallyAdjusted:
        scheduleManuallyAdjusted ?? this.scheduleManuallyAdjusted,
    interestRateType: interestRateType.present
        ? interestRateType.value
        : this.interestRateType,
    creditLimit: creditLimit.present ? creditLimit.value : this.creditLimit,
    currentBalance: currentBalance.present
        ? currentBalance.value
        : this.currentBalance,
    cutoffDay: cutoffDay.present ? cutoffDay.value : this.cutoffDay,
    paymentDueOffsetDays: paymentDueOffsetDays.present
        ? paymentDueOffsetDays.value
        : this.paymentDueOffsetDays,
    managementFee: managementFee.present
        ? managementFee.value
        : this.managementFee,
    managementFeeFrequency: managementFeeFrequency.present
        ? managementFeeFrequency.value
        : this.managementFeeFrequency,
    cycleCount: cycleCount.present ? cycleCount.value : this.cycleCount,
    lastAccrualCutoff: lastAccrualCutoff.present
        ? lastAccrualCutoff.value
        : this.lastAccrualCutoff,
    quotaId: quotaId.present ? quotaId.value : this.quotaId,
    interestUnknown: interestUnknown ?? this.interestUnknown,
    earlyPaymentWaivesInterest:
        earlyPaymentWaivesInterest ?? this.earlyPaymentWaivesInterest,
    cardDesign: cardDesign.present ? cardDesign.value : this.cardDesign,
    paymentDueDay: paymentDueDay ?? this.paymentDueDay,
    oneInstallmentInterestPolicy: oneInstallmentInterestPolicy.present
        ? oneInstallmentInterestPolicy.value
        : this.oneInstallmentInterestPolicy,
    notificationDaysBefore: notificationDaysBefore.present
        ? notificationDaysBefore.value
        : this.notificationDaysBefore,
  );
  CreditRow copyWithCompanion(CreditsCompanion data) {
    return CreditRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      lender: data.lender.present ? data.lender.value : this.lender,
      color: data.color.present ? data.color.value : this.color,
      notes: data.notes.present ? data.notes.value : this.notes,
      location: data.location.present ? data.location.value : this.location,
      card: data.card.present ? data.card.value : this.card,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      quotaAmount: data.quotaAmount.present
          ? data.quotaAmount.value
          : this.quotaAmount,
      totalInstallments: data.totalInstallments.present
          ? data.totalInstallments.value
          : this.totalInstallments,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      interestRate: data.interestRate.present
          ? data.interestRate.value
          : this.interestRate,
      scheduleManuallyAdjusted: data.scheduleManuallyAdjusted.present
          ? data.scheduleManuallyAdjusted.value
          : this.scheduleManuallyAdjusted,
      interestRateType: data.interestRateType.present
          ? data.interestRateType.value
          : this.interestRateType,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      cutoffDay: data.cutoffDay.present ? data.cutoffDay.value : this.cutoffDay,
      paymentDueOffsetDays: data.paymentDueOffsetDays.present
          ? data.paymentDueOffsetDays.value
          : this.paymentDueOffsetDays,
      managementFee: data.managementFee.present
          ? data.managementFee.value
          : this.managementFee,
      managementFeeFrequency: data.managementFeeFrequency.present
          ? data.managementFeeFrequency.value
          : this.managementFeeFrequency,
      cycleCount: data.cycleCount.present
          ? data.cycleCount.value
          : this.cycleCount,
      lastAccrualCutoff: data.lastAccrualCutoff.present
          ? data.lastAccrualCutoff.value
          : this.lastAccrualCutoff,
      quotaId: data.quotaId.present ? data.quotaId.value : this.quotaId,
      interestUnknown: data.interestUnknown.present
          ? data.interestUnknown.value
          : this.interestUnknown,
      earlyPaymentWaivesInterest: data.earlyPaymentWaivesInterest.present
          ? data.earlyPaymentWaivesInterest.value
          : this.earlyPaymentWaivesInterest,
      cardDesign: data.cardDesign.present
          ? data.cardDesign.value
          : this.cardDesign,
      paymentDueDay: data.paymentDueDay.present
          ? data.paymentDueDay.value
          : this.paymentDueDay,
      oneInstallmentInterestPolicy: data.oneInstallmentInterestPolicy.present
          ? data.oneInstallmentInterestPolicy.value
          : this.oneInstallmentInterestPolicy,
      notificationDaysBefore: data.notificationDaysBefore.present
          ? data.notificationDaysBefore.value
          : this.notificationDaysBefore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreditRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('lender: $lender, ')
          ..write('color: $color, ')
          ..write('notes: $notes, ')
          ..write('location: $location, ')
          ..write('card: $card, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('quotaAmount: $quotaAmount, ')
          ..write('totalInstallments: $totalInstallments, ')
          ..write('frequency: $frequency, ')
          ..write('startDate: $startDate, ')
          ..write('interestRate: $interestRate, ')
          ..write('scheduleManuallyAdjusted: $scheduleManuallyAdjusted, ')
          ..write('interestRateType: $interestRateType, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('cutoffDay: $cutoffDay, ')
          ..write('paymentDueOffsetDays: $paymentDueOffsetDays, ')
          ..write('managementFee: $managementFee, ')
          ..write('managementFeeFrequency: $managementFeeFrequency, ')
          ..write('cycleCount: $cycleCount, ')
          ..write('lastAccrualCutoff: $lastAccrualCutoff, ')
          ..write('quotaId: $quotaId, ')
          ..write('interestUnknown: $interestUnknown, ')
          ..write('earlyPaymentWaivesInterest: $earlyPaymentWaivesInterest, ')
          ..write('cardDesign: $cardDesign, ')
          ..write('paymentDueDay: $paymentDueDay, ')
          ..write(
            'oneInstallmentInterestPolicy: $oneInstallmentInterestPolicy, ',
          )
          ..write('notificationDaysBefore: $notificationDaysBefore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    type,
    name,
    lender,
    color,
    notes,
    location,
    card,
    totalAmount,
    quotaAmount,
    totalInstallments,
    frequency,
    startDate,
    interestRate,
    scheduleManuallyAdjusted,
    interestRateType,
    creditLimit,
    currentBalance,
    cutoffDay,
    paymentDueOffsetDays,
    managementFee,
    managementFeeFrequency,
    cycleCount,
    lastAccrualCutoff,
    quotaId,
    interestUnknown,
    earlyPaymentWaivesInterest,
    cardDesign,
    paymentDueDay,
    oneInstallmentInterestPolicy,
    notificationDaysBefore,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.name == this.name &&
          other.lender == this.lender &&
          other.color == this.color &&
          other.notes == this.notes &&
          other.location == this.location &&
          other.card == this.card &&
          other.totalAmount == this.totalAmount &&
          other.quotaAmount == this.quotaAmount &&
          other.totalInstallments == this.totalInstallments &&
          other.frequency == this.frequency &&
          other.startDate == this.startDate &&
          other.interestRate == this.interestRate &&
          other.scheduleManuallyAdjusted == this.scheduleManuallyAdjusted &&
          other.interestRateType == this.interestRateType &&
          other.creditLimit == this.creditLimit &&
          other.currentBalance == this.currentBalance &&
          other.cutoffDay == this.cutoffDay &&
          other.paymentDueOffsetDays == this.paymentDueOffsetDays &&
          other.managementFee == this.managementFee &&
          other.managementFeeFrequency == this.managementFeeFrequency &&
          other.cycleCount == this.cycleCount &&
          other.lastAccrualCutoff == this.lastAccrualCutoff &&
          other.quotaId == this.quotaId &&
          other.interestUnknown == this.interestUnknown &&
          other.earlyPaymentWaivesInterest == this.earlyPaymentWaivesInterest &&
          other.cardDesign == this.cardDesign &&
          other.paymentDueDay == this.paymentDueDay &&
          other.oneInstallmentInterestPolicy ==
              this.oneInstallmentInterestPolicy &&
          other.notificationDaysBefore == this.notificationDaysBefore);
}

class CreditsCompanion extends UpdateCompanion<CreditRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> name;
  final Value<String> lender;
  final Value<String?> color;
  final Value<String?> notes;
  final Value<String?> location;
  final Value<String?> card;
  final Value<double?> totalAmount;
  final Value<double?> quotaAmount;
  final Value<int?> totalInstallments;
  final Value<String?> frequency;
  final Value<String?> startDate;
  final Value<double?> interestRate;
  final Value<bool> scheduleManuallyAdjusted;
  final Value<String?> interestRateType;
  final Value<double?> creditLimit;
  final Value<double?> currentBalance;
  final Value<int?> cutoffDay;
  final Value<int?> paymentDueOffsetDays;
  final Value<double?> managementFee;
  final Value<String?> managementFeeFrequency;
  final Value<int?> cycleCount;
  final Value<String?> lastAccrualCutoff;
  final Value<String?> quotaId;
  final Value<bool> interestUnknown;
  final Value<bool> earlyPaymentWaivesInterest;
  final Value<String?> cardDesign;
  final Value<int> paymentDueDay;
  final Value<bool?> oneInstallmentInterestPolicy;
  final Value<int?> notificationDaysBefore;
  final Value<int> rowid;
  const CreditsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.lender = const Value.absent(),
    this.color = const Value.absent(),
    this.notes = const Value.absent(),
    this.location = const Value.absent(),
    this.card = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.quotaAmount = const Value.absent(),
    this.totalInstallments = const Value.absent(),
    this.frequency = const Value.absent(),
    this.startDate = const Value.absent(),
    this.interestRate = const Value.absent(),
    this.scheduleManuallyAdjusted = const Value.absent(),
    this.interestRateType = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.cutoffDay = const Value.absent(),
    this.paymentDueOffsetDays = const Value.absent(),
    this.managementFee = const Value.absent(),
    this.managementFeeFrequency = const Value.absent(),
    this.cycleCount = const Value.absent(),
    this.lastAccrualCutoff = const Value.absent(),
    this.quotaId = const Value.absent(),
    this.interestUnknown = const Value.absent(),
    this.earlyPaymentWaivesInterest = const Value.absent(),
    this.cardDesign = const Value.absent(),
    this.paymentDueDay = const Value.absent(),
    this.oneInstallmentInterestPolicy = const Value.absent(),
    this.notificationDaysBefore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CreditsCompanion.insert({
    required String id,
    required String type,
    required String name,
    required String lender,
    this.color = const Value.absent(),
    this.notes = const Value.absent(),
    this.location = const Value.absent(),
    this.card = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.quotaAmount = const Value.absent(),
    this.totalInstallments = const Value.absent(),
    this.frequency = const Value.absent(),
    this.startDate = const Value.absent(),
    this.interestRate = const Value.absent(),
    this.scheduleManuallyAdjusted = const Value.absent(),
    this.interestRateType = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.cutoffDay = const Value.absent(),
    this.paymentDueOffsetDays = const Value.absent(),
    this.managementFee = const Value.absent(),
    this.managementFeeFrequency = const Value.absent(),
    this.cycleCount = const Value.absent(),
    this.lastAccrualCutoff = const Value.absent(),
    this.quotaId = const Value.absent(),
    this.interestUnknown = const Value.absent(),
    this.earlyPaymentWaivesInterest = const Value.absent(),
    this.cardDesign = const Value.absent(),
    this.paymentDueDay = const Value.absent(),
    this.oneInstallmentInterestPolicy = const Value.absent(),
    this.notificationDaysBefore = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       name = Value(name),
       lender = Value(lender);
  static Insertable<CreditRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? lender,
    Expression<String>? color,
    Expression<String>? notes,
    Expression<String>? location,
    Expression<String>? card,
    Expression<double>? totalAmount,
    Expression<double>? quotaAmount,
    Expression<int>? totalInstallments,
    Expression<String>? frequency,
    Expression<String>? startDate,
    Expression<double>? interestRate,
    Expression<bool>? scheduleManuallyAdjusted,
    Expression<String>? interestRateType,
    Expression<double>? creditLimit,
    Expression<double>? currentBalance,
    Expression<int>? cutoffDay,
    Expression<int>? paymentDueOffsetDays,
    Expression<double>? managementFee,
    Expression<String>? managementFeeFrequency,
    Expression<int>? cycleCount,
    Expression<String>? lastAccrualCutoff,
    Expression<String>? quotaId,
    Expression<bool>? interestUnknown,
    Expression<bool>? earlyPaymentWaivesInterest,
    Expression<String>? cardDesign,
    Expression<int>? paymentDueDay,
    Expression<bool>? oneInstallmentInterestPolicy,
    Expression<int>? notificationDaysBefore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (lender != null) 'lender': lender,
      if (color != null) 'color': color,
      if (notes != null) 'notes': notes,
      if (location != null) 'location': location,
      if (card != null) 'card': card,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (quotaAmount != null) 'quota_amount': quotaAmount,
      if (totalInstallments != null) 'total_installments': totalInstallments,
      if (frequency != null) 'frequency': frequency,
      if (startDate != null) 'start_date': startDate,
      if (interestRate != null) 'interest_rate': interestRate,
      if (scheduleManuallyAdjusted != null)
        'schedule_manually_adjusted': scheduleManuallyAdjusted,
      if (interestRateType != null) 'interest_rate_type': interestRateType,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (cutoffDay != null) 'cutoff_day': cutoffDay,
      if (paymentDueOffsetDays != null)
        'payment_due_offset_days': paymentDueOffsetDays,
      if (managementFee != null) 'management_fee': managementFee,
      if (managementFeeFrequency != null)
        'management_fee_frequency': managementFeeFrequency,
      if (cycleCount != null) 'cycle_count': cycleCount,
      if (lastAccrualCutoff != null) 'last_accrual_cutoff': lastAccrualCutoff,
      if (quotaId != null) 'quota_id': quotaId,
      if (interestUnknown != null) 'interest_unknown': interestUnknown,
      if (earlyPaymentWaivesInterest != null)
        'early_payment_waives_interest': earlyPaymentWaivesInterest,
      if (cardDesign != null) 'card_design': cardDesign,
      if (paymentDueDay != null) 'payment_due_day': paymentDueDay,
      if (oneInstallmentInterestPolicy != null)
        'one_installment_interest_policy': oneInstallmentInterestPolicy,
      if (notificationDaysBefore != null)
        'notification_days_before': notificationDaysBefore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CreditsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? name,
    Value<String>? lender,
    Value<String?>? color,
    Value<String?>? notes,
    Value<String?>? location,
    Value<String?>? card,
    Value<double?>? totalAmount,
    Value<double?>? quotaAmount,
    Value<int?>? totalInstallments,
    Value<String?>? frequency,
    Value<String?>? startDate,
    Value<double?>? interestRate,
    Value<bool>? scheduleManuallyAdjusted,
    Value<String?>? interestRateType,
    Value<double?>? creditLimit,
    Value<double?>? currentBalance,
    Value<int?>? cutoffDay,
    Value<int?>? paymentDueOffsetDays,
    Value<double?>? managementFee,
    Value<String?>? managementFeeFrequency,
    Value<int?>? cycleCount,
    Value<String?>? lastAccrualCutoff,
    Value<String?>? quotaId,
    Value<bool>? interestUnknown,
    Value<bool>? earlyPaymentWaivesInterest,
    Value<String?>? cardDesign,
    Value<int>? paymentDueDay,
    Value<bool?>? oneInstallmentInterestPolicy,
    Value<int?>? notificationDaysBefore,
    Value<int>? rowid,
  }) {
    return CreditsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      lender: lender ?? this.lender,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      card: card ?? this.card,
      totalAmount: totalAmount ?? this.totalAmount,
      quotaAmount: quotaAmount ?? this.quotaAmount,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      interestRate: interestRate ?? this.interestRate,
      scheduleManuallyAdjusted:
          scheduleManuallyAdjusted ?? this.scheduleManuallyAdjusted,
      interestRateType: interestRateType ?? this.interestRateType,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      cutoffDay: cutoffDay ?? this.cutoffDay,
      paymentDueOffsetDays: paymentDueOffsetDays ?? this.paymentDueOffsetDays,
      managementFee: managementFee ?? this.managementFee,
      managementFeeFrequency:
          managementFeeFrequency ?? this.managementFeeFrequency,
      cycleCount: cycleCount ?? this.cycleCount,
      lastAccrualCutoff: lastAccrualCutoff ?? this.lastAccrualCutoff,
      quotaId: quotaId ?? this.quotaId,
      interestUnknown: interestUnknown ?? this.interestUnknown,
      earlyPaymentWaivesInterest:
          earlyPaymentWaivesInterest ?? this.earlyPaymentWaivesInterest,
      cardDesign: cardDesign ?? this.cardDesign,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
      oneInstallmentInterestPolicy:
          oneInstallmentInterestPolicy ?? this.oneInstallmentInterestPolicy,
      notificationDaysBefore:
          notificationDaysBefore ?? this.notificationDaysBefore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lender.present) {
      map['lender'] = Variable<String>(lender.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (card.present) {
      map['card'] = Variable<String>(card.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (quotaAmount.present) {
      map['quota_amount'] = Variable<double>(quotaAmount.value);
    }
    if (totalInstallments.present) {
      map['total_installments'] = Variable<int>(totalInstallments.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (interestRate.present) {
      map['interest_rate'] = Variable<double>(interestRate.value);
    }
    if (scheduleManuallyAdjusted.present) {
      map['schedule_manually_adjusted'] = Variable<bool>(
        scheduleManuallyAdjusted.value,
      );
    }
    if (interestRateType.present) {
      map['interest_rate_type'] = Variable<String>(interestRateType.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<double>(creditLimit.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<double>(currentBalance.value);
    }
    if (cutoffDay.present) {
      map['cutoff_day'] = Variable<int>(cutoffDay.value);
    }
    if (paymentDueOffsetDays.present) {
      map['payment_due_offset_days'] = Variable<int>(
        paymentDueOffsetDays.value,
      );
    }
    if (managementFee.present) {
      map['management_fee'] = Variable<double>(managementFee.value);
    }
    if (managementFeeFrequency.present) {
      map['management_fee_frequency'] = Variable<String>(
        managementFeeFrequency.value,
      );
    }
    if (cycleCount.present) {
      map['cycle_count'] = Variable<int>(cycleCount.value);
    }
    if (lastAccrualCutoff.present) {
      map['last_accrual_cutoff'] = Variable<String>(lastAccrualCutoff.value);
    }
    if (quotaId.present) {
      map['quota_id'] = Variable<String>(quotaId.value);
    }
    if (interestUnknown.present) {
      map['interest_unknown'] = Variable<bool>(interestUnknown.value);
    }
    if (earlyPaymentWaivesInterest.present) {
      map['early_payment_waives_interest'] = Variable<bool>(
        earlyPaymentWaivesInterest.value,
      );
    }
    if (cardDesign.present) {
      map['card_design'] = Variable<String>(cardDesign.value);
    }
    if (paymentDueDay.present) {
      map['payment_due_day'] = Variable<int>(paymentDueDay.value);
    }
    if (oneInstallmentInterestPolicy.present) {
      map['one_installment_interest_policy'] = Variable<bool>(
        oneInstallmentInterestPolicy.value,
      );
    }
    if (notificationDaysBefore.present) {
      map['notification_days_before'] = Variable<int>(
        notificationDaysBefore.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreditsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('lender: $lender, ')
          ..write('color: $color, ')
          ..write('notes: $notes, ')
          ..write('location: $location, ')
          ..write('card: $card, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('quotaAmount: $quotaAmount, ')
          ..write('totalInstallments: $totalInstallments, ')
          ..write('frequency: $frequency, ')
          ..write('startDate: $startDate, ')
          ..write('interestRate: $interestRate, ')
          ..write('scheduleManuallyAdjusted: $scheduleManuallyAdjusted, ')
          ..write('interestRateType: $interestRateType, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('cutoffDay: $cutoffDay, ')
          ..write('paymentDueOffsetDays: $paymentDueOffsetDays, ')
          ..write('managementFee: $managementFee, ')
          ..write('managementFeeFrequency: $managementFeeFrequency, ')
          ..write('cycleCount: $cycleCount, ')
          ..write('lastAccrualCutoff: $lastAccrualCutoff, ')
          ..write('quotaId: $quotaId, ')
          ..write('interestUnknown: $interestUnknown, ')
          ..write('earlyPaymentWaivesInterest: $earlyPaymentWaivesInterest, ')
          ..write('cardDesign: $cardDesign, ')
          ..write('paymentDueDay: $paymentDueDay, ')
          ..write(
            'oneInstallmentInterestPolicy: $oneInstallmentInterestPolicy, ',
          )
          ..write('notificationDaysBefore: $notificationDaysBefore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstallmentsTable extends Installments
    with TableInfo<$InstallmentsTable, InstallmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstallmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _creditIdMeta = const VerificationMeta(
    'creditId',
  );
  @override
  late final GeneratedColumn<String> creditId = GeneratedColumn<String>(
    'credit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES credits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _principalMeta = const VerificationMeta(
    'principal',
  );
  @override
  late final GeneratedColumn<double> principal = GeneratedColumn<double>(
    'principal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _interestMeta = const VerificationMeta(
    'interest',
  );
  @override
  late final GeneratedColumn<double> interest = GeneratedColumn<double>(
    'interest',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidMeta = const VerificationMeta('paid');
  @override
  late final GeneratedColumn<bool> paid = GeneratedColumn<bool>(
    'paid',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("paid" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _paymentDateMeta = const VerificationMeta(
    'paymentDate',
  );
  @override
  late final GeneratedColumn<String> paymentDate = GeneratedColumn<String>(
    'payment_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _interestWaivedMeta = const VerificationMeta(
    'interestWaived',
  );
  @override
  late final GeneratedColumn<bool> interestWaived = GeneratedColumn<bool>(
    'interest_waived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("interest_waived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    creditId,
    number,
    dueDate,
    amount,
    principal,
    interest,
    paid,
    paymentDate,
    interestWaived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installments';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstallmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('credit_id')) {
      context.handle(
        _creditIdMeta,
        creditId.isAcceptableOrUnknown(data['credit_id']!, _creditIdMeta),
      );
    } else if (isInserting) {
      context.missing(_creditIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('principal')) {
      context.handle(
        _principalMeta,
        principal.isAcceptableOrUnknown(data['principal']!, _principalMeta),
      );
    } else if (isInserting) {
      context.missing(_principalMeta);
    }
    if (data.containsKey('interest')) {
      context.handle(
        _interestMeta,
        interest.isAcceptableOrUnknown(data['interest']!, _interestMeta),
      );
    } else if (isInserting) {
      context.missing(_interestMeta);
    }
    if (data.containsKey('paid')) {
      context.handle(
        _paidMeta,
        paid.isAcceptableOrUnknown(data['paid']!, _paidMeta),
      );
    }
    if (data.containsKey('payment_date')) {
      context.handle(
        _paymentDateMeta,
        paymentDate.isAcceptableOrUnknown(
          data['payment_date']!,
          _paymentDateMeta,
        ),
      );
    }
    if (data.containsKey('interest_waived')) {
      context.handle(
        _interestWaivedMeta,
        interestWaived.isAcceptableOrUnknown(
          data['interest_waived']!,
          _interestWaivedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  InstallmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstallmentRow(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      creditId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      principal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}principal'],
      )!,
      interest: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interest'],
      )!,
      paid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paid'],
      )!,
      paymentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_date'],
      ),
      interestWaived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}interest_waived'],
      )!,
    );
  }

  @override
  $InstallmentsTable createAlias(String alias) {
    return $InstallmentsTable(attachedDatabase, alias);
  }
}

class InstallmentRow extends DataClass implements Insertable<InstallmentRow> {
  final int rowId;
  final String creditId;
  final int number;
  final String dueDate;
  final double amount;
  final double principal;
  final double interest;
  final bool paid;
  final String? paymentDate;
  final bool interestWaived;
  const InstallmentRow({
    required this.rowId,
    required this.creditId,
    required this.number,
    required this.dueDate,
    required this.amount,
    required this.principal,
    required this.interest,
    required this.paid,
    this.paymentDate,
    required this.interestWaived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['credit_id'] = Variable<String>(creditId);
    map['number'] = Variable<int>(number);
    map['due_date'] = Variable<String>(dueDate);
    map['amount'] = Variable<double>(amount);
    map['principal'] = Variable<double>(principal);
    map['interest'] = Variable<double>(interest);
    map['paid'] = Variable<bool>(paid);
    if (!nullToAbsent || paymentDate != null) {
      map['payment_date'] = Variable<String>(paymentDate);
    }
    map['interest_waived'] = Variable<bool>(interestWaived);
    return map;
  }

  InstallmentsCompanion toCompanion(bool nullToAbsent) {
    return InstallmentsCompanion(
      rowId: Value(rowId),
      creditId: Value(creditId),
      number: Value(number),
      dueDate: Value(dueDate),
      amount: Value(amount),
      principal: Value(principal),
      interest: Value(interest),
      paid: Value(paid),
      paymentDate: paymentDate == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentDate),
      interestWaived: Value(interestWaived),
    );
  }

  factory InstallmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstallmentRow(
      rowId: serializer.fromJson<int>(json['rowId']),
      creditId: serializer.fromJson<String>(json['creditId']),
      number: serializer.fromJson<int>(json['number']),
      dueDate: serializer.fromJson<String>(json['dueDate']),
      amount: serializer.fromJson<double>(json['amount']),
      principal: serializer.fromJson<double>(json['principal']),
      interest: serializer.fromJson<double>(json['interest']),
      paid: serializer.fromJson<bool>(json['paid']),
      paymentDate: serializer.fromJson<String?>(json['paymentDate']),
      interestWaived: serializer.fromJson<bool>(json['interestWaived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'creditId': serializer.toJson<String>(creditId),
      'number': serializer.toJson<int>(number),
      'dueDate': serializer.toJson<String>(dueDate),
      'amount': serializer.toJson<double>(amount),
      'principal': serializer.toJson<double>(principal),
      'interest': serializer.toJson<double>(interest),
      'paid': serializer.toJson<bool>(paid),
      'paymentDate': serializer.toJson<String?>(paymentDate),
      'interestWaived': serializer.toJson<bool>(interestWaived),
    };
  }

  InstallmentRow copyWith({
    int? rowId,
    String? creditId,
    int? number,
    String? dueDate,
    double? amount,
    double? principal,
    double? interest,
    bool? paid,
    Value<String?> paymentDate = const Value.absent(),
    bool? interestWaived,
  }) => InstallmentRow(
    rowId: rowId ?? this.rowId,
    creditId: creditId ?? this.creditId,
    number: number ?? this.number,
    dueDate: dueDate ?? this.dueDate,
    amount: amount ?? this.amount,
    principal: principal ?? this.principal,
    interest: interest ?? this.interest,
    paid: paid ?? this.paid,
    paymentDate: paymentDate.present ? paymentDate.value : this.paymentDate,
    interestWaived: interestWaived ?? this.interestWaived,
  );
  InstallmentRow copyWithCompanion(InstallmentsCompanion data) {
    return InstallmentRow(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      creditId: data.creditId.present ? data.creditId.value : this.creditId,
      number: data.number.present ? data.number.value : this.number,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      amount: data.amount.present ? data.amount.value : this.amount,
      principal: data.principal.present ? data.principal.value : this.principal,
      interest: data.interest.present ? data.interest.value : this.interest,
      paid: data.paid.present ? data.paid.value : this.paid,
      paymentDate: data.paymentDate.present
          ? data.paymentDate.value
          : this.paymentDate,
      interestWaived: data.interestWaived.present
          ? data.interestWaived.value
          : this.interestWaived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentRow(')
          ..write('rowId: $rowId, ')
          ..write('creditId: $creditId, ')
          ..write('number: $number, ')
          ..write('dueDate: $dueDate, ')
          ..write('amount: $amount, ')
          ..write('principal: $principal, ')
          ..write('interest: $interest, ')
          ..write('paid: $paid, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('interestWaived: $interestWaived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    creditId,
    number,
    dueDate,
    amount,
    principal,
    interest,
    paid,
    paymentDate,
    interestWaived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstallmentRow &&
          other.rowId == this.rowId &&
          other.creditId == this.creditId &&
          other.number == this.number &&
          other.dueDate == this.dueDate &&
          other.amount == this.amount &&
          other.principal == this.principal &&
          other.interest == this.interest &&
          other.paid == this.paid &&
          other.paymentDate == this.paymentDate &&
          other.interestWaived == this.interestWaived);
}

class InstallmentsCompanion extends UpdateCompanion<InstallmentRow> {
  final Value<int> rowId;
  final Value<String> creditId;
  final Value<int> number;
  final Value<String> dueDate;
  final Value<double> amount;
  final Value<double> principal;
  final Value<double> interest;
  final Value<bool> paid;
  final Value<String?> paymentDate;
  final Value<bool> interestWaived;
  const InstallmentsCompanion({
    this.rowId = const Value.absent(),
    this.creditId = const Value.absent(),
    this.number = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.amount = const Value.absent(),
    this.principal = const Value.absent(),
    this.interest = const Value.absent(),
    this.paid = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.interestWaived = const Value.absent(),
  });
  InstallmentsCompanion.insert({
    this.rowId = const Value.absent(),
    required String creditId,
    required int number,
    required String dueDate,
    required double amount,
    required double principal,
    required double interest,
    this.paid = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.interestWaived = const Value.absent(),
  }) : creditId = Value(creditId),
       number = Value(number),
       dueDate = Value(dueDate),
       amount = Value(amount),
       principal = Value(principal),
       interest = Value(interest);
  static Insertable<InstallmentRow> custom({
    Expression<int>? rowId,
    Expression<String>? creditId,
    Expression<int>? number,
    Expression<String>? dueDate,
    Expression<double>? amount,
    Expression<double>? principal,
    Expression<double>? interest,
    Expression<bool>? paid,
    Expression<String>? paymentDate,
    Expression<bool>? interestWaived,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (creditId != null) 'credit_id': creditId,
      if (number != null) 'number': number,
      if (dueDate != null) 'due_date': dueDate,
      if (amount != null) 'amount': amount,
      if (principal != null) 'principal': principal,
      if (interest != null) 'interest': interest,
      if (paid != null) 'paid': paid,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (interestWaived != null) 'interest_waived': interestWaived,
    });
  }

  InstallmentsCompanion copyWith({
    Value<int>? rowId,
    Value<String>? creditId,
    Value<int>? number,
    Value<String>? dueDate,
    Value<double>? amount,
    Value<double>? principal,
    Value<double>? interest,
    Value<bool>? paid,
    Value<String?>? paymentDate,
    Value<bool>? interestWaived,
  }) {
    return InstallmentsCompanion(
      rowId: rowId ?? this.rowId,
      creditId: creditId ?? this.creditId,
      number: number ?? this.number,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      principal: principal ?? this.principal,
      interest: interest ?? this.interest,
      paid: paid ?? this.paid,
      paymentDate: paymentDate ?? this.paymentDate,
      interestWaived: interestWaived ?? this.interestWaived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (creditId.present) {
      map['credit_id'] = Variable<String>(creditId.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (principal.present) {
      map['principal'] = Variable<double>(principal.value);
    }
    if (interest.present) {
      map['interest'] = Variable<double>(interest.value);
    }
    if (paid.present) {
      map['paid'] = Variable<bool>(paid.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<String>(paymentDate.value);
    }
    if (interestWaived.present) {
      map['interest_waived'] = Variable<bool>(interestWaived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentsCompanion(')
          ..write('rowId: $rowId, ')
          ..write('creditId: $creditId, ')
          ..write('number: $number, ')
          ..write('dueDate: $dueDate, ')
          ..write('amount: $amount, ')
          ..write('principal: $principal, ')
          ..write('interest: $interest, ')
          ..write('paid: $paid, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('interestWaived: $interestWaived')
          ..write(')'))
        .toString();
  }
}

class $CardMovementsTable extends CardMovements
    with TableInfo<$CardMovementsTable, CardMovementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _creditIdMeta = const VerificationMeta(
    'creditId',
  );
  @override
  late final GeneratedColumn<String> creditId = GeneratedColumn<String>(
    'credit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES credits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _advanceInstallmentsMeta =
      const VerificationMeta('advanceInstallments');
  @override
  late final GeneratedColumn<int> advanceInstallments = GeneratedColumn<int>(
    'advance_installments',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _advanceInterestRateMeta =
      const VerificationMeta('advanceInterestRate');
  @override
  late final GeneratedColumn<double> advanceInterestRate =
      GeneratedColumn<double>(
        'advance_interest_rate',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _advanceInterestRateTypeMeta =
      const VerificationMeta('advanceInterestRateType');
  @override
  late final GeneratedColumn<String> advanceInterestRateType =
      GeneratedColumn<String>(
        'advance_interest_rate_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _advanceCommissionMeta = const VerificationMeta(
    'advanceCommission',
  );
  @override
  late final GeneratedColumn<double> advanceCommission =
      GeneratedColumn<double>(
        'advance_commission',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _advanceFirstPaymentDateMeta =
      const VerificationMeta('advanceFirstPaymentDate');
  @override
  late final GeneratedColumn<String> advanceFirstPaymentDate =
      GeneratedColumn<String>(
        'advance_first_payment_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _advanceDestinationMeta =
      const VerificationMeta('advanceDestination');
  @override
  late final GeneratedColumn<String> advanceDestination =
      GeneratedColumn<String>(
        'advance_destination',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    creditId,
    date,
    type,
    amount,
    note,
    advanceInstallments,
    advanceInterestRate,
    advanceInterestRateType,
    advanceCommission,
    advanceFirstPaymentDate,
    advanceDestination,
    categoria,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardMovementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('credit_id')) {
      context.handle(
        _creditIdMeta,
        creditId.isAcceptableOrUnknown(data['credit_id']!, _creditIdMeta),
      );
    } else if (isInserting) {
      context.missing(_creditIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('advance_installments')) {
      context.handle(
        _advanceInstallmentsMeta,
        advanceInstallments.isAcceptableOrUnknown(
          data['advance_installments']!,
          _advanceInstallmentsMeta,
        ),
      );
    }
    if (data.containsKey('advance_interest_rate')) {
      context.handle(
        _advanceInterestRateMeta,
        advanceInterestRate.isAcceptableOrUnknown(
          data['advance_interest_rate']!,
          _advanceInterestRateMeta,
        ),
      );
    }
    if (data.containsKey('advance_interest_rate_type')) {
      context.handle(
        _advanceInterestRateTypeMeta,
        advanceInterestRateType.isAcceptableOrUnknown(
          data['advance_interest_rate_type']!,
          _advanceInterestRateTypeMeta,
        ),
      );
    }
    if (data.containsKey('advance_commission')) {
      context.handle(
        _advanceCommissionMeta,
        advanceCommission.isAcceptableOrUnknown(
          data['advance_commission']!,
          _advanceCommissionMeta,
        ),
      );
    }
    if (data.containsKey('advance_first_payment_date')) {
      context.handle(
        _advanceFirstPaymentDateMeta,
        advanceFirstPaymentDate.isAcceptableOrUnknown(
          data['advance_first_payment_date']!,
          _advanceFirstPaymentDateMeta,
        ),
      );
    }
    if (data.containsKey('advance_destination')) {
      context.handle(
        _advanceDestinationMeta,
        advanceDestination.isAcceptableOrUnknown(
          data['advance_destination']!,
          _advanceDestinationMeta,
        ),
      );
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  CardMovementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardMovementRow(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      creditId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      advanceInstallments: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}advance_installments'],
      ),
      advanceInterestRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}advance_interest_rate'],
      ),
      advanceInterestRateType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}advance_interest_rate_type'],
      ),
      advanceCommission: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}advance_commission'],
      ),
      advanceFirstPaymentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}advance_first_payment_date'],
      ),
      advanceDestination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}advance_destination'],
      ),
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      ),
    );
  }

  @override
  $CardMovementsTable createAlias(String alias) {
    return $CardMovementsTable(attachedDatabase, alias);
  }
}

class CardMovementRow extends DataClass implements Insertable<CardMovementRow> {
  final int rowId;
  final String creditId;
  final String date;
  final String type;
  final double amount;
  final String note;
  final int? advanceInstallments;
  final double? advanceInterestRate;
  final String? advanceInterestRateType;
  final double? advanceCommission;
  final String? advanceFirstPaymentDate;
  final String? advanceDestination;

  /// Categoría del movimiento — null para movimientos anteriores a v12.
  /// Valores sugeridos: 'alimentacion' | 'transporte' | 'salud' | 'ropa' |
  /// 'entretenimiento' | 'servicios' | 'viajes' | 'otro'.
  final String? categoria;
  const CardMovementRow({
    required this.rowId,
    required this.creditId,
    required this.date,
    required this.type,
    required this.amount,
    required this.note,
    this.advanceInstallments,
    this.advanceInterestRate,
    this.advanceInterestRateType,
    this.advanceCommission,
    this.advanceFirstPaymentDate,
    this.advanceDestination,
    this.categoria,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['credit_id'] = Variable<String>(creditId);
    map['date'] = Variable<String>(date);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<double>(amount);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || advanceInstallments != null) {
      map['advance_installments'] = Variable<int>(advanceInstallments);
    }
    if (!nullToAbsent || advanceInterestRate != null) {
      map['advance_interest_rate'] = Variable<double>(advanceInterestRate);
    }
    if (!nullToAbsent || advanceInterestRateType != null) {
      map['advance_interest_rate_type'] = Variable<String>(
        advanceInterestRateType,
      );
    }
    if (!nullToAbsent || advanceCommission != null) {
      map['advance_commission'] = Variable<double>(advanceCommission);
    }
    if (!nullToAbsent || advanceFirstPaymentDate != null) {
      map['advance_first_payment_date'] = Variable<String>(
        advanceFirstPaymentDate,
      );
    }
    if (!nullToAbsent || advanceDestination != null) {
      map['advance_destination'] = Variable<String>(advanceDestination);
    }
    if (!nullToAbsent || categoria != null) {
      map['categoria'] = Variable<String>(categoria);
    }
    return map;
  }

  CardMovementsCompanion toCompanion(bool nullToAbsent) {
    return CardMovementsCompanion(
      rowId: Value(rowId),
      creditId: Value(creditId),
      date: Value(date),
      type: Value(type),
      amount: Value(amount),
      note: Value(note),
      advanceInstallments: advanceInstallments == null && nullToAbsent
          ? const Value.absent()
          : Value(advanceInstallments),
      advanceInterestRate: advanceInterestRate == null && nullToAbsent
          ? const Value.absent()
          : Value(advanceInterestRate),
      advanceInterestRateType: advanceInterestRateType == null && nullToAbsent
          ? const Value.absent()
          : Value(advanceInterestRateType),
      advanceCommission: advanceCommission == null && nullToAbsent
          ? const Value.absent()
          : Value(advanceCommission),
      advanceFirstPaymentDate: advanceFirstPaymentDate == null && nullToAbsent
          ? const Value.absent()
          : Value(advanceFirstPaymentDate),
      advanceDestination: advanceDestination == null && nullToAbsent
          ? const Value.absent()
          : Value(advanceDestination),
      categoria: categoria == null && nullToAbsent
          ? const Value.absent()
          : Value(categoria),
    );
  }

  factory CardMovementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardMovementRow(
      rowId: serializer.fromJson<int>(json['rowId']),
      creditId: serializer.fromJson<String>(json['creditId']),
      date: serializer.fromJson<String>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<double>(json['amount']),
      note: serializer.fromJson<String>(json['note']),
      advanceInstallments: serializer.fromJson<int?>(
        json['advanceInstallments'],
      ),
      advanceInterestRate: serializer.fromJson<double?>(
        json['advanceInterestRate'],
      ),
      advanceInterestRateType: serializer.fromJson<String?>(
        json['advanceInterestRateType'],
      ),
      advanceCommission: serializer.fromJson<double?>(
        json['advanceCommission'],
      ),
      advanceFirstPaymentDate: serializer.fromJson<String?>(
        json['advanceFirstPaymentDate'],
      ),
      advanceDestination: serializer.fromJson<String?>(
        json['advanceDestination'],
      ),
      categoria: serializer.fromJson<String?>(json['categoria']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'creditId': serializer.toJson<String>(creditId),
      'date': serializer.toJson<String>(date),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<double>(amount),
      'note': serializer.toJson<String>(note),
      'advanceInstallments': serializer.toJson<int?>(advanceInstallments),
      'advanceInterestRate': serializer.toJson<double?>(advanceInterestRate),
      'advanceInterestRateType': serializer.toJson<String?>(
        advanceInterestRateType,
      ),
      'advanceCommission': serializer.toJson<double?>(advanceCommission),
      'advanceFirstPaymentDate': serializer.toJson<String?>(
        advanceFirstPaymentDate,
      ),
      'advanceDestination': serializer.toJson<String?>(advanceDestination),
      'categoria': serializer.toJson<String?>(categoria),
    };
  }

  CardMovementRow copyWith({
    int? rowId,
    String? creditId,
    String? date,
    String? type,
    double? amount,
    String? note,
    Value<int?> advanceInstallments = const Value.absent(),
    Value<double?> advanceInterestRate = const Value.absent(),
    Value<String?> advanceInterestRateType = const Value.absent(),
    Value<double?> advanceCommission = const Value.absent(),
    Value<String?> advanceFirstPaymentDate = const Value.absent(),
    Value<String?> advanceDestination = const Value.absent(),
    Value<String?> categoria = const Value.absent(),
  }) => CardMovementRow(
    rowId: rowId ?? this.rowId,
    creditId: creditId ?? this.creditId,
    date: date ?? this.date,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    note: note ?? this.note,
    advanceInstallments: advanceInstallments.present
        ? advanceInstallments.value
        : this.advanceInstallments,
    advanceInterestRate: advanceInterestRate.present
        ? advanceInterestRate.value
        : this.advanceInterestRate,
    advanceInterestRateType: advanceInterestRateType.present
        ? advanceInterestRateType.value
        : this.advanceInterestRateType,
    advanceCommission: advanceCommission.present
        ? advanceCommission.value
        : this.advanceCommission,
    advanceFirstPaymentDate: advanceFirstPaymentDate.present
        ? advanceFirstPaymentDate.value
        : this.advanceFirstPaymentDate,
    advanceDestination: advanceDestination.present
        ? advanceDestination.value
        : this.advanceDestination,
    categoria: categoria.present ? categoria.value : this.categoria,
  );
  CardMovementRow copyWithCompanion(CardMovementsCompanion data) {
    return CardMovementRow(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      creditId: data.creditId.present ? data.creditId.value : this.creditId,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      note: data.note.present ? data.note.value : this.note,
      advanceInstallments: data.advanceInstallments.present
          ? data.advanceInstallments.value
          : this.advanceInstallments,
      advanceInterestRate: data.advanceInterestRate.present
          ? data.advanceInterestRate.value
          : this.advanceInterestRate,
      advanceInterestRateType: data.advanceInterestRateType.present
          ? data.advanceInterestRateType.value
          : this.advanceInterestRateType,
      advanceCommission: data.advanceCommission.present
          ? data.advanceCommission.value
          : this.advanceCommission,
      advanceFirstPaymentDate: data.advanceFirstPaymentDate.present
          ? data.advanceFirstPaymentDate.value
          : this.advanceFirstPaymentDate,
      advanceDestination: data.advanceDestination.present
          ? data.advanceDestination.value
          : this.advanceDestination,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardMovementRow(')
          ..write('rowId: $rowId, ')
          ..write('creditId: $creditId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('advanceInstallments: $advanceInstallments, ')
          ..write('advanceInterestRate: $advanceInterestRate, ')
          ..write('advanceInterestRateType: $advanceInterestRateType, ')
          ..write('advanceCommission: $advanceCommission, ')
          ..write('advanceFirstPaymentDate: $advanceFirstPaymentDate, ')
          ..write('advanceDestination: $advanceDestination, ')
          ..write('categoria: $categoria')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    creditId,
    date,
    type,
    amount,
    note,
    advanceInstallments,
    advanceInterestRate,
    advanceInterestRateType,
    advanceCommission,
    advanceFirstPaymentDate,
    advanceDestination,
    categoria,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardMovementRow &&
          other.rowId == this.rowId &&
          other.creditId == this.creditId &&
          other.date == this.date &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.note == this.note &&
          other.advanceInstallments == this.advanceInstallments &&
          other.advanceInterestRate == this.advanceInterestRate &&
          other.advanceInterestRateType == this.advanceInterestRateType &&
          other.advanceCommission == this.advanceCommission &&
          other.advanceFirstPaymentDate == this.advanceFirstPaymentDate &&
          other.advanceDestination == this.advanceDestination &&
          other.categoria == this.categoria);
}

class CardMovementsCompanion extends UpdateCompanion<CardMovementRow> {
  final Value<int> rowId;
  final Value<String> creditId;
  final Value<String> date;
  final Value<String> type;
  final Value<double> amount;
  final Value<String> note;
  final Value<int?> advanceInstallments;
  final Value<double?> advanceInterestRate;
  final Value<String?> advanceInterestRateType;
  final Value<double?> advanceCommission;
  final Value<String?> advanceFirstPaymentDate;
  final Value<String?> advanceDestination;
  final Value<String?> categoria;
  const CardMovementsCompanion({
    this.rowId = const Value.absent(),
    this.creditId = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
    this.advanceInstallments = const Value.absent(),
    this.advanceInterestRate = const Value.absent(),
    this.advanceInterestRateType = const Value.absent(),
    this.advanceCommission = const Value.absent(),
    this.advanceFirstPaymentDate = const Value.absent(),
    this.advanceDestination = const Value.absent(),
    this.categoria = const Value.absent(),
  });
  CardMovementsCompanion.insert({
    this.rowId = const Value.absent(),
    required String creditId,
    required String date,
    required String type,
    required double amount,
    this.note = const Value.absent(),
    this.advanceInstallments = const Value.absent(),
    this.advanceInterestRate = const Value.absent(),
    this.advanceInterestRateType = const Value.absent(),
    this.advanceCommission = const Value.absent(),
    this.advanceFirstPaymentDate = const Value.absent(),
    this.advanceDestination = const Value.absent(),
    this.categoria = const Value.absent(),
  }) : creditId = Value(creditId),
       date = Value(date),
       type = Value(type),
       amount = Value(amount);
  static Insertable<CardMovementRow> custom({
    Expression<int>? rowId,
    Expression<String>? creditId,
    Expression<String>? date,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<String>? note,
    Expression<int>? advanceInstallments,
    Expression<double>? advanceInterestRate,
    Expression<String>? advanceInterestRateType,
    Expression<double>? advanceCommission,
    Expression<String>? advanceFirstPaymentDate,
    Expression<String>? advanceDestination,
    Expression<String>? categoria,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (creditId != null) 'credit_id': creditId,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (note != null) 'note': note,
      if (advanceInstallments != null)
        'advance_installments': advanceInstallments,
      if (advanceInterestRate != null)
        'advance_interest_rate': advanceInterestRate,
      if (advanceInterestRateType != null)
        'advance_interest_rate_type': advanceInterestRateType,
      if (advanceCommission != null) 'advance_commission': advanceCommission,
      if (advanceFirstPaymentDate != null)
        'advance_first_payment_date': advanceFirstPaymentDate,
      if (advanceDestination != null) 'advance_destination': advanceDestination,
      if (categoria != null) 'categoria': categoria,
    });
  }

  CardMovementsCompanion copyWith({
    Value<int>? rowId,
    Value<String>? creditId,
    Value<String>? date,
    Value<String>? type,
    Value<double>? amount,
    Value<String>? note,
    Value<int?>? advanceInstallments,
    Value<double?>? advanceInterestRate,
    Value<String?>? advanceInterestRateType,
    Value<double?>? advanceCommission,
    Value<String?>? advanceFirstPaymentDate,
    Value<String?>? advanceDestination,
    Value<String?>? categoria,
  }) {
    return CardMovementsCompanion(
      rowId: rowId ?? this.rowId,
      creditId: creditId ?? this.creditId,
      date: date ?? this.date,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      advanceInstallments: advanceInstallments ?? this.advanceInstallments,
      advanceInterestRate: advanceInterestRate ?? this.advanceInterestRate,
      advanceInterestRateType:
          advanceInterestRateType ?? this.advanceInterestRateType,
      advanceCommission: advanceCommission ?? this.advanceCommission,
      advanceFirstPaymentDate:
          advanceFirstPaymentDate ?? this.advanceFirstPaymentDate,
      advanceDestination: advanceDestination ?? this.advanceDestination,
      categoria: categoria ?? this.categoria,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (creditId.present) {
      map['credit_id'] = Variable<String>(creditId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (advanceInstallments.present) {
      map['advance_installments'] = Variable<int>(advanceInstallments.value);
    }
    if (advanceInterestRate.present) {
      map['advance_interest_rate'] = Variable<double>(
        advanceInterestRate.value,
      );
    }
    if (advanceInterestRateType.present) {
      map['advance_interest_rate_type'] = Variable<String>(
        advanceInterestRateType.value,
      );
    }
    if (advanceCommission.present) {
      map['advance_commission'] = Variable<double>(advanceCommission.value);
    }
    if (advanceFirstPaymentDate.present) {
      map['advance_first_payment_date'] = Variable<String>(
        advanceFirstPaymentDate.value,
      );
    }
    if (advanceDestination.present) {
      map['advance_destination'] = Variable<String>(advanceDestination.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardMovementsCompanion(')
          ..write('rowId: $rowId, ')
          ..write('creditId: $creditId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('advanceInstallments: $advanceInstallments, ')
          ..write('advanceInterestRate: $advanceInterestRate, ')
          ..write('advanceInterestRateType: $advanceInterestRateType, ')
          ..write('advanceCommission: $advanceCommission, ')
          ..write('advanceFirstPaymentDate: $advanceFirstPaymentDate, ')
          ..write('advanceDestination: $advanceDestination, ')
          ..write('categoria: $categoria')
          ..write(')'))
        .toString();
  }
}

class $LoanAbonosTable extends LoanAbonos
    with TableInfo<$LoanAbonosTable, LoanAbonoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoanAbonosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _creditIdMeta = const VerificationMeta(
    'creditId',
  );
  @override
  late final GeneratedColumn<String> creditId = GeneratedColumn<String>(
    'credit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES credits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _installmentsSkippedMeta =
      const VerificationMeta('installmentsSkipped');
  @override
  late final GeneratedColumn<int> installmentsSkipped = GeneratedColumn<int>(
    'installments_skipped',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _previousQuotaAmountMeta =
      const VerificationMeta('previousQuotaAmount');
  @override
  late final GeneratedColumn<double> previousQuotaAmount =
      GeneratedColumn<double>(
        'previous_quota_amount',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _previousInstallmentsSnapshotMeta =
      const VerificationMeta('previousInstallmentsSnapshot');
  @override
  late final GeneratedColumn<String> previousInstallmentsSnapshot =
      GeneratedColumn<String>(
        'previous_installments_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    creditId,
    date,
    amount,
    note,
    installmentsSkipped,
    previousQuotaAmount,
    previousInstallmentsSnapshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loan_abonos';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoanAbonoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('credit_id')) {
      context.handle(
        _creditIdMeta,
        creditId.isAcceptableOrUnknown(data['credit_id']!, _creditIdMeta),
      );
    } else if (isInserting) {
      context.missing(_creditIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('installments_skipped')) {
      context.handle(
        _installmentsSkippedMeta,
        installmentsSkipped.isAcceptableOrUnknown(
          data['installments_skipped']!,
          _installmentsSkippedMeta,
        ),
      );
    }
    if (data.containsKey('previous_quota_amount')) {
      context.handle(
        _previousQuotaAmountMeta,
        previousQuotaAmount.isAcceptableOrUnknown(
          data['previous_quota_amount']!,
          _previousQuotaAmountMeta,
        ),
      );
    }
    if (data.containsKey('previous_installments_snapshot')) {
      context.handle(
        _previousInstallmentsSnapshotMeta,
        previousInstallmentsSnapshot.isAcceptableOrUnknown(
          data['previous_installments_snapshot']!,
          _previousInstallmentsSnapshotMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  LoanAbonoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoanAbonoRow(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      creditId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      installmentsSkipped: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installments_skipped'],
      )!,
      previousQuotaAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}previous_quota_amount'],
      ),
      previousInstallmentsSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_installments_snapshot'],
      ),
    );
  }

  @override
  $LoanAbonosTable createAlias(String alias) {
    return $LoanAbonosTable(attachedDatabase, alias);
  }
}

class LoanAbonoRow extends DataClass implements Insertable<LoanAbonoRow> {
  final int rowId;
  final String creditId;
  final String date;
  final double amount;
  final String note;
  final int installmentsSkipped;

  /// `loan.quotaAmount` immediately before this abono reamortized the
  /// schedule — null for abonos predating this column, or for the
  /// settle-the-whole-loan case. See LoanAbono.previousQuotaAmount.
  final double? previousQuotaAmount;

  /// JSON-encoded list of the unpaid installments' pre-abono state — null
  /// for abonos predating this column, or for the settle-the-whole-loan
  /// case. See LoanAbono.previousInstallmentsSnapshot.
  final String? previousInstallmentsSnapshot;
  const LoanAbonoRow({
    required this.rowId,
    required this.creditId,
    required this.date,
    required this.amount,
    required this.note,
    required this.installmentsSkipped,
    this.previousQuotaAmount,
    this.previousInstallmentsSnapshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['credit_id'] = Variable<String>(creditId);
    map['date'] = Variable<String>(date);
    map['amount'] = Variable<double>(amount);
    map['note'] = Variable<String>(note);
    map['installments_skipped'] = Variable<int>(installmentsSkipped);
    if (!nullToAbsent || previousQuotaAmount != null) {
      map['previous_quota_amount'] = Variable<double>(previousQuotaAmount);
    }
    if (!nullToAbsent || previousInstallmentsSnapshot != null) {
      map['previous_installments_snapshot'] = Variable<String>(
        previousInstallmentsSnapshot,
      );
    }
    return map;
  }

  LoanAbonosCompanion toCompanion(bool nullToAbsent) {
    return LoanAbonosCompanion(
      rowId: Value(rowId),
      creditId: Value(creditId),
      date: Value(date),
      amount: Value(amount),
      note: Value(note),
      installmentsSkipped: Value(installmentsSkipped),
      previousQuotaAmount: previousQuotaAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(previousQuotaAmount),
      previousInstallmentsSnapshot:
          previousInstallmentsSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(previousInstallmentsSnapshot),
    );
  }

  factory LoanAbonoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoanAbonoRow(
      rowId: serializer.fromJson<int>(json['rowId']),
      creditId: serializer.fromJson<String>(json['creditId']),
      date: serializer.fromJson<String>(json['date']),
      amount: serializer.fromJson<double>(json['amount']),
      note: serializer.fromJson<String>(json['note']),
      installmentsSkipped: serializer.fromJson<int>(
        json['installmentsSkipped'],
      ),
      previousQuotaAmount: serializer.fromJson<double?>(
        json['previousQuotaAmount'],
      ),
      previousInstallmentsSnapshot: serializer.fromJson<String?>(
        json['previousInstallmentsSnapshot'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'creditId': serializer.toJson<String>(creditId),
      'date': serializer.toJson<String>(date),
      'amount': serializer.toJson<double>(amount),
      'note': serializer.toJson<String>(note),
      'installmentsSkipped': serializer.toJson<int>(installmentsSkipped),
      'previousQuotaAmount': serializer.toJson<double?>(previousQuotaAmount),
      'previousInstallmentsSnapshot': serializer.toJson<String?>(
        previousInstallmentsSnapshot,
      ),
    };
  }

  LoanAbonoRow copyWith({
    int? rowId,
    String? creditId,
    String? date,
    double? amount,
    String? note,
    int? installmentsSkipped,
    Value<double?> previousQuotaAmount = const Value.absent(),
    Value<String?> previousInstallmentsSnapshot = const Value.absent(),
  }) => LoanAbonoRow(
    rowId: rowId ?? this.rowId,
    creditId: creditId ?? this.creditId,
    date: date ?? this.date,
    amount: amount ?? this.amount,
    note: note ?? this.note,
    installmentsSkipped: installmentsSkipped ?? this.installmentsSkipped,
    previousQuotaAmount: previousQuotaAmount.present
        ? previousQuotaAmount.value
        : this.previousQuotaAmount,
    previousInstallmentsSnapshot: previousInstallmentsSnapshot.present
        ? previousInstallmentsSnapshot.value
        : this.previousInstallmentsSnapshot,
  );
  LoanAbonoRow copyWithCompanion(LoanAbonosCompanion data) {
    return LoanAbonoRow(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      creditId: data.creditId.present ? data.creditId.value : this.creditId,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
      note: data.note.present ? data.note.value : this.note,
      installmentsSkipped: data.installmentsSkipped.present
          ? data.installmentsSkipped.value
          : this.installmentsSkipped,
      previousQuotaAmount: data.previousQuotaAmount.present
          ? data.previousQuotaAmount.value
          : this.previousQuotaAmount,
      previousInstallmentsSnapshot: data.previousInstallmentsSnapshot.present
          ? data.previousInstallmentsSnapshot.value
          : this.previousInstallmentsSnapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoanAbonoRow(')
          ..write('rowId: $rowId, ')
          ..write('creditId: $creditId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('installmentsSkipped: $installmentsSkipped, ')
          ..write('previousQuotaAmount: $previousQuotaAmount, ')
          ..write('previousInstallmentsSnapshot: $previousInstallmentsSnapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    creditId,
    date,
    amount,
    note,
    installmentsSkipped,
    previousQuotaAmount,
    previousInstallmentsSnapshot,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoanAbonoRow &&
          other.rowId == this.rowId &&
          other.creditId == this.creditId &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.note == this.note &&
          other.installmentsSkipped == this.installmentsSkipped &&
          other.previousQuotaAmount == this.previousQuotaAmount &&
          other.previousInstallmentsSnapshot ==
              this.previousInstallmentsSnapshot);
}

class LoanAbonosCompanion extends UpdateCompanion<LoanAbonoRow> {
  final Value<int> rowId;
  final Value<String> creditId;
  final Value<String> date;
  final Value<double> amount;
  final Value<String> note;
  final Value<int> installmentsSkipped;
  final Value<double?> previousQuotaAmount;
  final Value<String?> previousInstallmentsSnapshot;
  const LoanAbonosCompanion({
    this.rowId = const Value.absent(),
    this.creditId = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
    this.installmentsSkipped = const Value.absent(),
    this.previousQuotaAmount = const Value.absent(),
    this.previousInstallmentsSnapshot = const Value.absent(),
  });
  LoanAbonosCompanion.insert({
    this.rowId = const Value.absent(),
    required String creditId,
    required String date,
    required double amount,
    this.note = const Value.absent(),
    this.installmentsSkipped = const Value.absent(),
    this.previousQuotaAmount = const Value.absent(),
    this.previousInstallmentsSnapshot = const Value.absent(),
  }) : creditId = Value(creditId),
       date = Value(date),
       amount = Value(amount);
  static Insertable<LoanAbonoRow> custom({
    Expression<int>? rowId,
    Expression<String>? creditId,
    Expression<String>? date,
    Expression<double>? amount,
    Expression<String>? note,
    Expression<int>? installmentsSkipped,
    Expression<double>? previousQuotaAmount,
    Expression<String>? previousInstallmentsSnapshot,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (creditId != null) 'credit_id': creditId,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (note != null) 'note': note,
      if (installmentsSkipped != null)
        'installments_skipped': installmentsSkipped,
      if (previousQuotaAmount != null)
        'previous_quota_amount': previousQuotaAmount,
      if (previousInstallmentsSnapshot != null)
        'previous_installments_snapshot': previousInstallmentsSnapshot,
    });
  }

  LoanAbonosCompanion copyWith({
    Value<int>? rowId,
    Value<String>? creditId,
    Value<String>? date,
    Value<double>? amount,
    Value<String>? note,
    Value<int>? installmentsSkipped,
    Value<double?>? previousQuotaAmount,
    Value<String?>? previousInstallmentsSnapshot,
  }) {
    return LoanAbonosCompanion(
      rowId: rowId ?? this.rowId,
      creditId: creditId ?? this.creditId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      installmentsSkipped: installmentsSkipped ?? this.installmentsSkipped,
      previousQuotaAmount: previousQuotaAmount ?? this.previousQuotaAmount,
      previousInstallmentsSnapshot:
          previousInstallmentsSnapshot ?? this.previousInstallmentsSnapshot,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (creditId.present) {
      map['credit_id'] = Variable<String>(creditId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (installmentsSkipped.present) {
      map['installments_skipped'] = Variable<int>(installmentsSkipped.value);
    }
    if (previousQuotaAmount.present) {
      map['previous_quota_amount'] = Variable<double>(
        previousQuotaAmount.value,
      );
    }
    if (previousInstallmentsSnapshot.present) {
      map['previous_installments_snapshot'] = Variable<String>(
        previousInstallmentsSnapshot.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoanAbonosCompanion(')
          ..write('rowId: $rowId, ')
          ..write('creditId: $creditId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('installmentsSkipped: $installmentsSkipped, ')
          ..write('previousQuotaAmount: $previousQuotaAmount, ')
          ..write('previousInstallmentsSnapshot: $previousInstallmentsSnapshot')
          ..write(')'))
        .toString();
  }
}

class $PagosRealizadosTable extends PagosRealizados
    with TableInfo<$PagosRealizadosTable, PagoRealizadoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PagosRealizadosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _creditIdMeta = const VerificationMeta(
    'creditId',
  );
  @override
  late final GeneratedColumn<String> creditId = GeneratedColumn<String>(
    'credit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES credits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numeroCuotaMeta = const VerificationMeta(
    'numeroCuota',
  );
  @override
  late final GeneratedColumn<int> numeroCuota = GeneratedColumn<int>(
    'numero_cuota',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notaMeta = const VerificationMeta('nota');
  @override
  late final GeneratedColumn<String> nota = GeneratedColumn<String>(
    'nota',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    creditId,
    fecha,
    monto,
    tipo,
    numeroCuota,
    nota,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pagos_realizados';
  @override
  VerificationContext validateIntegrity(
    Insertable<PagoRealizadoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('credit_id')) {
      context.handle(
        _creditIdMeta,
        creditId.isAcceptableOrUnknown(data['credit_id']!, _creditIdMeta),
      );
    } else if (isInserting) {
      context.missing(_creditIdMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('numero_cuota')) {
      context.handle(
        _numeroCuotaMeta,
        numeroCuota.isAcceptableOrUnknown(
          data['numero_cuota']!,
          _numeroCuotaMeta,
        ),
      );
    }
    if (data.containsKey('nota')) {
      context.handle(
        _notaMeta,
        nota.isAcceptableOrUnknown(data['nota']!, _notaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  PagoRealizadoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PagoRealizadoRow(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      creditId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_id'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      numeroCuota: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}numero_cuota'],
      ),
      nota: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nota'],
      )!,
    );
  }

  @override
  $PagosRealizadosTable createAlias(String alias) {
    return $PagosRealizadosTable(attachedDatabase, alias);
  }
}

class PagoRealizadoRow extends DataClass
    implements Insertable<PagoRealizadoRow> {
  final int rowId;
  final String creditId;

  /// Fecha real del pago — "YYYY-MM-DD".
  final String fecha;

  /// Monto real pagado (puede diferir del calculado por la app).
  final double monto;

  /// 'cuota' para préstamos, 'pago_tarjeta' para tarjetas.
  final String tipo;

  /// Número de cuota asociada (solo cuando tipo == 'cuota'), o null.
  final int? numeroCuota;

  /// Nota libre del usuario.
  final String nota;
  const PagoRealizadoRow({
    required this.rowId,
    required this.creditId,
    required this.fecha,
    required this.monto,
    required this.tipo,
    this.numeroCuota,
    required this.nota,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['credit_id'] = Variable<String>(creditId);
    map['fecha'] = Variable<String>(fecha);
    map['monto'] = Variable<double>(monto);
    map['tipo'] = Variable<String>(tipo);
    if (!nullToAbsent || numeroCuota != null) {
      map['numero_cuota'] = Variable<int>(numeroCuota);
    }
    map['nota'] = Variable<String>(nota);
    return map;
  }

  PagosRealizadosCompanion toCompanion(bool nullToAbsent) {
    return PagosRealizadosCompanion(
      rowId: Value(rowId),
      creditId: Value(creditId),
      fecha: Value(fecha),
      monto: Value(monto),
      tipo: Value(tipo),
      numeroCuota: numeroCuota == null && nullToAbsent
          ? const Value.absent()
          : Value(numeroCuota),
      nota: Value(nota),
    );
  }

  factory PagoRealizadoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PagoRealizadoRow(
      rowId: serializer.fromJson<int>(json['rowId']),
      creditId: serializer.fromJson<String>(json['creditId']),
      fecha: serializer.fromJson<String>(json['fecha']),
      monto: serializer.fromJson<double>(json['monto']),
      tipo: serializer.fromJson<String>(json['tipo']),
      numeroCuota: serializer.fromJson<int?>(json['numeroCuota']),
      nota: serializer.fromJson<String>(json['nota']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'creditId': serializer.toJson<String>(creditId),
      'fecha': serializer.toJson<String>(fecha),
      'monto': serializer.toJson<double>(monto),
      'tipo': serializer.toJson<String>(tipo),
      'numeroCuota': serializer.toJson<int?>(numeroCuota),
      'nota': serializer.toJson<String>(nota),
    };
  }

  PagoRealizadoRow copyWith({
    int? rowId,
    String? creditId,
    String? fecha,
    double? monto,
    String? tipo,
    Value<int?> numeroCuota = const Value.absent(),
    String? nota,
  }) => PagoRealizadoRow(
    rowId: rowId ?? this.rowId,
    creditId: creditId ?? this.creditId,
    fecha: fecha ?? this.fecha,
    monto: monto ?? this.monto,
    tipo: tipo ?? this.tipo,
    numeroCuota: numeroCuota.present ? numeroCuota.value : this.numeroCuota,
    nota: nota ?? this.nota,
  );
  PagoRealizadoRow copyWithCompanion(PagosRealizadosCompanion data) {
    return PagoRealizadoRow(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      creditId: data.creditId.present ? data.creditId.value : this.creditId,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      monto: data.monto.present ? data.monto.value : this.monto,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      numeroCuota: data.numeroCuota.present
          ? data.numeroCuota.value
          : this.numeroCuota,
      nota: data.nota.present ? data.nota.value : this.nota,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PagoRealizadoRow(')
          ..write('rowId: $rowId, ')
          ..write('creditId: $creditId, ')
          ..write('fecha: $fecha, ')
          ..write('monto: $monto, ')
          ..write('tipo: $tipo, ')
          ..write('numeroCuota: $numeroCuota, ')
          ..write('nota: $nota')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(rowId, creditId, fecha, monto, tipo, numeroCuota, nota);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PagoRealizadoRow &&
          other.rowId == this.rowId &&
          other.creditId == this.creditId &&
          other.fecha == this.fecha &&
          other.monto == this.monto &&
          other.tipo == this.tipo &&
          other.numeroCuota == this.numeroCuota &&
          other.nota == this.nota);
}

class PagosRealizadosCompanion extends UpdateCompanion<PagoRealizadoRow> {
  final Value<int> rowId;
  final Value<String> creditId;
  final Value<String> fecha;
  final Value<double> monto;
  final Value<String> tipo;
  final Value<int?> numeroCuota;
  final Value<String> nota;
  const PagosRealizadosCompanion({
    this.rowId = const Value.absent(),
    this.creditId = const Value.absent(),
    this.fecha = const Value.absent(),
    this.monto = const Value.absent(),
    this.tipo = const Value.absent(),
    this.numeroCuota = const Value.absent(),
    this.nota = const Value.absent(),
  });
  PagosRealizadosCompanion.insert({
    this.rowId = const Value.absent(),
    required String creditId,
    required String fecha,
    required double monto,
    required String tipo,
    this.numeroCuota = const Value.absent(),
    this.nota = const Value.absent(),
  }) : creditId = Value(creditId),
       fecha = Value(fecha),
       monto = Value(monto),
       tipo = Value(tipo);
  static Insertable<PagoRealizadoRow> custom({
    Expression<int>? rowId,
    Expression<String>? creditId,
    Expression<String>? fecha,
    Expression<double>? monto,
    Expression<String>? tipo,
    Expression<int>? numeroCuota,
    Expression<String>? nota,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (creditId != null) 'credit_id': creditId,
      if (fecha != null) 'fecha': fecha,
      if (monto != null) 'monto': monto,
      if (tipo != null) 'tipo': tipo,
      if (numeroCuota != null) 'numero_cuota': numeroCuota,
      if (nota != null) 'nota': nota,
    });
  }

  PagosRealizadosCompanion copyWith({
    Value<int>? rowId,
    Value<String>? creditId,
    Value<String>? fecha,
    Value<double>? monto,
    Value<String>? tipo,
    Value<int?>? numeroCuota,
    Value<String>? nota,
  }) {
    return PagosRealizadosCompanion(
      rowId: rowId ?? this.rowId,
      creditId: creditId ?? this.creditId,
      fecha: fecha ?? this.fecha,
      monto: monto ?? this.monto,
      tipo: tipo ?? this.tipo,
      numeroCuota: numeroCuota ?? this.numeroCuota,
      nota: nota ?? this.nota,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (creditId.present) {
      map['credit_id'] = Variable<String>(creditId.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (numeroCuota.present) {
      map['numero_cuota'] = Variable<int>(numeroCuota.value);
    }
    if (nota.present) {
      map['nota'] = Variable<String>(nota.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PagosRealizadosCompanion(')
          ..write('rowId: $rowId, ')
          ..write('creditId: $creditId, ')
          ..write('fecha: $fecha, ')
          ..write('monto: $monto, ')
          ..write('tipo: $tipo, ')
          ..write('numeroCuota: $numeroCuota, ')
          ..write('nota: $nota')
          ..write(')'))
        .toString();
  }
}

class $FinanceAccountsTable extends FinanceAccounts
    with TableInfo<$FinanceAccountsTable, FinanceAccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinanceAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconoMeta = const VerificationMeta('icono');
  @override
  late final GeneratedColumn<String> icono = GeneratedColumn<String>(
    'icono',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saldoInicialMeta = const VerificationMeta(
    'saldoInicial',
  );
  @override
  late final GeneratedColumn<double> saldoInicial = GeneratedColumn<double>(
    'saldo_inicial',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _activaMeta = const VerificationMeta('activa');
  @override
  late final GeneratedColumn<bool> activa = GeneratedColumn<bool>(
    'activa',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activa" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<String> orden = GeneratedColumn<String>(
    'orden',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0'),
  );
  static const VerificationMeta _esFavoritoMeta = const VerificationMeta(
    'esFavorito',
  );
  @override
  late final GeneratedColumn<bool> esFavorito = GeneratedColumn<bool>(
    'es_favorito',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("es_favorito" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    tipo,
    icono,
    color,
    saldoInicial,
    activa,
    orden,
    esFavorito,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finance_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinanceAccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('icono')) {
      context.handle(
        _iconoMeta,
        icono.isAcceptableOrUnknown(data['icono']!, _iconoMeta),
      );
    } else if (isInserting) {
      context.missing(_iconoMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('saldo_inicial')) {
      context.handle(
        _saldoInicialMeta,
        saldoInicial.isAcceptableOrUnknown(
          data['saldo_inicial']!,
          _saldoInicialMeta,
        ),
      );
    }
    if (data.containsKey('activa')) {
      context.handle(
        _activaMeta,
        activa.isAcceptableOrUnknown(data['activa']!, _activaMeta),
      );
    }
    if (data.containsKey('orden')) {
      context.handle(
        _ordenMeta,
        orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta),
      );
    }
    if (data.containsKey('es_favorito')) {
      context.handle(
        _esFavoritoMeta,
        esFavorito.isAcceptableOrUnknown(data['es_favorito']!, _esFavoritoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinanceAccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinanceAccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      icono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icono'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      saldoInicial: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}saldo_inicial'],
      )!,
      activa: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activa'],
      )!,
      orden: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}orden'],
      )!,
      esFavorito: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}es_favorito'],
      )!,
    );
  }

  @override
  $FinanceAccountsTable createAlias(String alias) {
    return $FinanceAccountsTable(attachedDatabase, alias);
  }
}

class FinanceAccountRow extends DataClass
    implements Insertable<FinanceAccountRow> {
  final String id;
  final String nombre;
  final String tipo;
  final String icono;
  final String color;
  final double saldoInicial;
  final bool activa;
  final String orden;
  final bool esFavorito;
  const FinanceAccountRow({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.icono,
    required this.color,
    required this.saldoInicial,
    required this.activa,
    required this.orden,
    required this.esFavorito,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    map['tipo'] = Variable<String>(tipo);
    map['icono'] = Variable<String>(icono);
    map['color'] = Variable<String>(color);
    map['saldo_inicial'] = Variable<double>(saldoInicial);
    map['activa'] = Variable<bool>(activa);
    map['orden'] = Variable<String>(orden);
    map['es_favorito'] = Variable<bool>(esFavorito);
    return map;
  }

  FinanceAccountsCompanion toCompanion(bool nullToAbsent) {
    return FinanceAccountsCompanion(
      id: Value(id),
      nombre: Value(nombre),
      tipo: Value(tipo),
      icono: Value(icono),
      color: Value(color),
      saldoInicial: Value(saldoInicial),
      activa: Value(activa),
      orden: Value(orden),
      esFavorito: Value(esFavorito),
    );
  }

  factory FinanceAccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinanceAccountRow(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      tipo: serializer.fromJson<String>(json['tipo']),
      icono: serializer.fromJson<String>(json['icono']),
      color: serializer.fromJson<String>(json['color']),
      saldoInicial: serializer.fromJson<double>(json['saldoInicial']),
      activa: serializer.fromJson<bool>(json['activa']),
      orden: serializer.fromJson<String>(json['orden']),
      esFavorito: serializer.fromJson<bool>(json['esFavorito']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'tipo': serializer.toJson<String>(tipo),
      'icono': serializer.toJson<String>(icono),
      'color': serializer.toJson<String>(color),
      'saldoInicial': serializer.toJson<double>(saldoInicial),
      'activa': serializer.toJson<bool>(activa),
      'orden': serializer.toJson<String>(orden),
      'esFavorito': serializer.toJson<bool>(esFavorito),
    };
  }

  FinanceAccountRow copyWith({
    String? id,
    String? nombre,
    String? tipo,
    String? icono,
    String? color,
    double? saldoInicial,
    bool? activa,
    String? orden,
    bool? esFavorito,
  }) => FinanceAccountRow(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    tipo: tipo ?? this.tipo,
    icono: icono ?? this.icono,
    color: color ?? this.color,
    saldoInicial: saldoInicial ?? this.saldoInicial,
    activa: activa ?? this.activa,
    orden: orden ?? this.orden,
    esFavorito: esFavorito ?? this.esFavorito,
  );
  FinanceAccountRow copyWithCompanion(FinanceAccountsCompanion data) {
    return FinanceAccountRow(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      icono: data.icono.present ? data.icono.value : this.icono,
      color: data.color.present ? data.color.value : this.color,
      saldoInicial: data.saldoInicial.present
          ? data.saldoInicial.value
          : this.saldoInicial,
      activa: data.activa.present ? data.activa.value : this.activa,
      orden: data.orden.present ? data.orden.value : this.orden,
      esFavorito: data.esFavorito.present
          ? data.esFavorito.value
          : this.esFavorito,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinanceAccountRow(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('tipo: $tipo, ')
          ..write('icono: $icono, ')
          ..write('color: $color, ')
          ..write('saldoInicial: $saldoInicial, ')
          ..write('activa: $activa, ')
          ..write('orden: $orden, ')
          ..write('esFavorito: $esFavorito')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombre,
    tipo,
    icono,
    color,
    saldoInicial,
    activa,
    orden,
    esFavorito,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinanceAccountRow &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.tipo == this.tipo &&
          other.icono == this.icono &&
          other.color == this.color &&
          other.saldoInicial == this.saldoInicial &&
          other.activa == this.activa &&
          other.orden == this.orden &&
          other.esFavorito == this.esFavorito);
}

class FinanceAccountsCompanion extends UpdateCompanion<FinanceAccountRow> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<String> tipo;
  final Value<String> icono;
  final Value<String> color;
  final Value<double> saldoInicial;
  final Value<bool> activa;
  final Value<String> orden;
  final Value<bool> esFavorito;
  final Value<int> rowid;
  const FinanceAccountsCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.tipo = const Value.absent(),
    this.icono = const Value.absent(),
    this.color = const Value.absent(),
    this.saldoInicial = const Value.absent(),
    this.activa = const Value.absent(),
    this.orden = const Value.absent(),
    this.esFavorito = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinanceAccountsCompanion.insert({
    required String id,
    required String nombre,
    required String tipo,
    required String icono,
    required String color,
    this.saldoInicial = const Value.absent(),
    this.activa = const Value.absent(),
    this.orden = const Value.absent(),
    this.esFavorito = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       tipo = Value(tipo),
       icono = Value(icono),
       color = Value(color);
  static Insertable<FinanceAccountRow> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? tipo,
    Expression<String>? icono,
    Expression<String>? color,
    Expression<double>? saldoInicial,
    Expression<bool>? activa,
    Expression<String>? orden,
    Expression<bool>? esFavorito,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (tipo != null) 'tipo': tipo,
      if (icono != null) 'icono': icono,
      if (color != null) 'color': color,
      if (saldoInicial != null) 'saldo_inicial': saldoInicial,
      if (activa != null) 'activa': activa,
      if (orden != null) 'orden': orden,
      if (esFavorito != null) 'es_favorito': esFavorito,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinanceAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<String>? tipo,
    Value<String>? icono,
    Value<String>? color,
    Value<double>? saldoInicial,
    Value<bool>? activa,
    Value<String>? orden,
    Value<bool>? esFavorito,
    Value<int>? rowid,
  }) {
    return FinanceAccountsCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      saldoInicial: saldoInicial ?? this.saldoInicial,
      activa: activa ?? this.activa,
      orden: orden ?? this.orden,
      esFavorito: esFavorito ?? this.esFavorito,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (icono.present) {
      map['icono'] = Variable<String>(icono.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (saldoInicial.present) {
      map['saldo_inicial'] = Variable<double>(saldoInicial.value);
    }
    if (activa.present) {
      map['activa'] = Variable<bool>(activa.value);
    }
    if (orden.present) {
      map['orden'] = Variable<String>(orden.value);
    }
    if (esFavorito.present) {
      map['es_favorito'] = Variable<bool>(esFavorito.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinanceAccountsCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('tipo: $tipo, ')
          ..write('icono: $icono, ')
          ..write('color: $color, ')
          ..write('saldoInicial: $saldoInicial, ')
          ..write('activa: $activa, ')
          ..write('orden: $orden, ')
          ..write('esFavorito: $esFavorito, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinanceCategoriesTable extends FinanceCategories
    with TableInfo<$FinanceCategoriesTable, FinanceCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinanceCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconoMeta = const VerificationMeta('icono');
  @override
  late final GeneratedColumn<String> icono = GeneratedColumn<String>(
    'icono',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivadaMeta = const VerificationMeta(
    'archivada',
  );
  @override
  late final GeneratedColumn<bool> archivada = GeneratedColumn<bool>(
    'archivada',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archivada" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES finance_categories (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    icono,
    color,
    tipo,
    archivada,
    parentId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finance_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinanceCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('icono')) {
      context.handle(
        _iconoMeta,
        icono.isAcceptableOrUnknown(data['icono']!, _iconoMeta),
      );
    } else if (isInserting) {
      context.missing(_iconoMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('archivada')) {
      context.handle(
        _archivadaMeta,
        archivada.isAcceptableOrUnknown(data['archivada']!, _archivadaMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinanceCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinanceCategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      icono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icono'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      archivada: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archivada'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
    );
  }

  @override
  $FinanceCategoriesTable createAlias(String alias) {
    return $FinanceCategoriesTable(attachedDatabase, alias);
  }
}

class FinanceCategoryRow extends DataClass
    implements Insertable<FinanceCategoryRow> {
  final String id;
  final String nombre;
  final String icono;
  final String color;
  final String tipo;
  final bool archivada;
  final String? parentId;
  const FinanceCategoryRow({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.color,
    required this.tipo,
    required this.archivada,
    this.parentId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    map['icono'] = Variable<String>(icono);
    map['color'] = Variable<String>(color);
    map['tipo'] = Variable<String>(tipo);
    map['archivada'] = Variable<bool>(archivada);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    return map;
  }

  FinanceCategoriesCompanion toCompanion(bool nullToAbsent) {
    return FinanceCategoriesCompanion(
      id: Value(id),
      nombre: Value(nombre),
      icono: Value(icono),
      color: Value(color),
      tipo: Value(tipo),
      archivada: Value(archivada),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
    );
  }

  factory FinanceCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinanceCategoryRow(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      icono: serializer.fromJson<String>(json['icono']),
      color: serializer.fromJson<String>(json['color']),
      tipo: serializer.fromJson<String>(json['tipo']),
      archivada: serializer.fromJson<bool>(json['archivada']),
      parentId: serializer.fromJson<String?>(json['parentId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'icono': serializer.toJson<String>(icono),
      'color': serializer.toJson<String>(color),
      'tipo': serializer.toJson<String>(tipo),
      'archivada': serializer.toJson<bool>(archivada),
      'parentId': serializer.toJson<String?>(parentId),
    };
  }

  FinanceCategoryRow copyWith({
    String? id,
    String? nombre,
    String? icono,
    String? color,
    String? tipo,
    bool? archivada,
    Value<String?> parentId = const Value.absent(),
  }) => FinanceCategoryRow(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    icono: icono ?? this.icono,
    color: color ?? this.color,
    tipo: tipo ?? this.tipo,
    archivada: archivada ?? this.archivada,
    parentId: parentId.present ? parentId.value : this.parentId,
  );
  FinanceCategoryRow copyWithCompanion(FinanceCategoriesCompanion data) {
    return FinanceCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      icono: data.icono.present ? data.icono.value : this.icono,
      color: data.color.present ? data.color.value : this.color,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      archivada: data.archivada.present ? data.archivada.value : this.archivada,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinanceCategoryRow(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('icono: $icono, ')
          ..write('color: $color, ')
          ..write('tipo: $tipo, ')
          ..write('archivada: $archivada, ')
          ..write('parentId: $parentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nombre, icono, color, tipo, archivada, parentId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinanceCategoryRow &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.icono == this.icono &&
          other.color == this.color &&
          other.tipo == this.tipo &&
          other.archivada == this.archivada &&
          other.parentId == this.parentId);
}

class FinanceCategoriesCompanion extends UpdateCompanion<FinanceCategoryRow> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<String> icono;
  final Value<String> color;
  final Value<String> tipo;
  final Value<bool> archivada;
  final Value<String?> parentId;
  final Value<int> rowid;
  const FinanceCategoriesCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.icono = const Value.absent(),
    this.color = const Value.absent(),
    this.tipo = const Value.absent(),
    this.archivada = const Value.absent(),
    this.parentId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinanceCategoriesCompanion.insert({
    required String id,
    required String nombre,
    required String icono,
    required String color,
    required String tipo,
    this.archivada = const Value.absent(),
    this.parentId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       icono = Value(icono),
       color = Value(color),
       tipo = Value(tipo);
  static Insertable<FinanceCategoryRow> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? icono,
    Expression<String>? color,
    Expression<String>? tipo,
    Expression<bool>? archivada,
    Expression<String>? parentId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (icono != null) 'icono': icono,
      if (color != null) 'color': color,
      if (tipo != null) 'tipo': tipo,
      if (archivada != null) 'archivada': archivada,
      if (parentId != null) 'parent_id': parentId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinanceCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<String>? icono,
    Value<String>? color,
    Value<String>? tipo,
    Value<bool>? archivada,
    Value<String?>? parentId,
    Value<int>? rowid,
  }) {
    return FinanceCategoriesCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      tipo: tipo ?? this.tipo,
      archivada: archivada ?? this.archivada,
      parentId: parentId ?? this.parentId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (icono.present) {
      map['icono'] = Variable<String>(icono.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (archivada.present) {
      map['archivada'] = Variable<bool>(archivada.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinanceCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('icono: $icono, ')
          ..write('color: $color, ')
          ..write('tipo: $tipo, ')
          ..write('archivada: $archivada, ')
          ..write('parentId: $parentId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinanceTransactionsTable extends FinanceTransactions
    with TableInfo<$FinanceTransactionsTable, FinanceTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinanceTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES finance_accounts (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notaMeta = const VerificationMeta('nota');
  @override
  late final GeneratedColumn<String> nota = GeneratedColumn<String>(
    'nota',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _esRecurrenteMeta = const VerificationMeta(
    'esRecurrente',
  );
  @override
  late final GeneratedColumn<bool> esRecurrente = GeneratedColumn<bool>(
    'es_recurrente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("es_recurrente" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recurrenciaConfigMeta = const VerificationMeta(
    'recurrenciaConfig',
  );
  @override
  late final GeneratedColumn<String> recurrenciaConfig =
      GeneratedColumn<String>(
        'recurrencia_config',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _personaSitioMeta = const VerificationMeta(
    'personaSitio',
  );
  @override
  late final GeneratedColumn<String> personaSitio = GeneratedColumn<String>(
    'persona_sitio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _horaMeta = const VerificationMeta('hora');
  @override
  late final GeneratedColumn<String> hora = GeneratedColumn<String>(
    'hora',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transferToAccountIdMeta =
      const VerificationMeta('transferToAccountId');
  @override
  late final GeneratedColumn<String> transferToAccountId =
      GeneratedColumn<String>(
        'transfer_to_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES finance_accounts (id) ON DELETE SET NULL',
        ),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    categoryId,
    tipo,
    monto,
    fecha,
    nota,
    esRecurrente,
    recurrenciaConfig,
    personaSitio,
    hora,
    transferToAccountId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finance_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinanceTransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('nota')) {
      context.handle(
        _notaMeta,
        nota.isAcceptableOrUnknown(data['nota']!, _notaMeta),
      );
    }
    if (data.containsKey('es_recurrente')) {
      context.handle(
        _esRecurrenteMeta,
        esRecurrente.isAcceptableOrUnknown(
          data['es_recurrente']!,
          _esRecurrenteMeta,
        ),
      );
    }
    if (data.containsKey('recurrencia_config')) {
      context.handle(
        _recurrenciaConfigMeta,
        recurrenciaConfig.isAcceptableOrUnknown(
          data['recurrencia_config']!,
          _recurrenciaConfigMeta,
        ),
      );
    }
    if (data.containsKey('persona_sitio')) {
      context.handle(
        _personaSitioMeta,
        personaSitio.isAcceptableOrUnknown(
          data['persona_sitio']!,
          _personaSitioMeta,
        ),
      );
    }
    if (data.containsKey('hora')) {
      context.handle(
        _horaMeta,
        hora.isAcceptableOrUnknown(data['hora']!, _horaMeta),
      );
    }
    if (data.containsKey('transfer_to_account_id')) {
      context.handle(
        _transferToAccountIdMeta,
        transferToAccountId.isAcceptableOrUnknown(
          data['transfer_to_account_id']!,
          _transferToAccountIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinanceTransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinanceTransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha'],
      )!,
      nota: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nota'],
      )!,
      esRecurrente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}es_recurrente'],
      )!,
      recurrenciaConfig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrencia_config'],
      ),
      personaSitio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}persona_sitio'],
      ),
      hora: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hora'],
      ),
      transferToAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_to_account_id'],
      ),
    );
  }

  @override
  $FinanceTransactionsTable createAlias(String alias) {
    return $FinanceTransactionsTable(attachedDatabase, alias);
  }
}

class FinanceTransactionRow extends DataClass
    implements Insertable<FinanceTransactionRow> {
  final String id;
  final String accountId;
  final String categoryId;
  final String tipo;
  final double monto;
  final String fecha;
  final String nota;
  final bool esRecurrente;
  final String? recurrenciaConfig;
  final String? personaSitio;
  final String? hora;
  final String? transferToAccountId;
  const FinanceTransactionRow({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.tipo,
    required this.monto,
    required this.fecha,
    required this.nota,
    required this.esRecurrente,
    this.recurrenciaConfig,
    this.personaSitio,
    this.hora,
    this.transferToAccountId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['category_id'] = Variable<String>(categoryId);
    map['tipo'] = Variable<String>(tipo);
    map['monto'] = Variable<double>(monto);
    map['fecha'] = Variable<String>(fecha);
    map['nota'] = Variable<String>(nota);
    map['es_recurrente'] = Variable<bool>(esRecurrente);
    if (!nullToAbsent || recurrenciaConfig != null) {
      map['recurrencia_config'] = Variable<String>(recurrenciaConfig);
    }
    if (!nullToAbsent || personaSitio != null) {
      map['persona_sitio'] = Variable<String>(personaSitio);
    }
    if (!nullToAbsent || hora != null) {
      map['hora'] = Variable<String>(hora);
    }
    if (!nullToAbsent || transferToAccountId != null) {
      map['transfer_to_account_id'] = Variable<String>(transferToAccountId);
    }
    return map;
  }

  FinanceTransactionsCompanion toCompanion(bool nullToAbsent) {
    return FinanceTransactionsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      categoryId: Value(categoryId),
      tipo: Value(tipo),
      monto: Value(monto),
      fecha: Value(fecha),
      nota: Value(nota),
      esRecurrente: Value(esRecurrente),
      recurrenciaConfig: recurrenciaConfig == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenciaConfig),
      personaSitio: personaSitio == null && nullToAbsent
          ? const Value.absent()
          : Value(personaSitio),
      hora: hora == null && nullToAbsent ? const Value.absent() : Value(hora),
      transferToAccountId: transferToAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(transferToAccountId),
    );
  }

  factory FinanceTransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinanceTransactionRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      monto: serializer.fromJson<double>(json['monto']),
      fecha: serializer.fromJson<String>(json['fecha']),
      nota: serializer.fromJson<String>(json['nota']),
      esRecurrente: serializer.fromJson<bool>(json['esRecurrente']),
      recurrenciaConfig: serializer.fromJson<String?>(
        json['recurrenciaConfig'],
      ),
      personaSitio: serializer.fromJson<String?>(json['personaSitio']),
      hora: serializer.fromJson<String?>(json['hora']),
      transferToAccountId: serializer.fromJson<String?>(
        json['transferToAccountId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'categoryId': serializer.toJson<String>(categoryId),
      'tipo': serializer.toJson<String>(tipo),
      'monto': serializer.toJson<double>(monto),
      'fecha': serializer.toJson<String>(fecha),
      'nota': serializer.toJson<String>(nota),
      'esRecurrente': serializer.toJson<bool>(esRecurrente),
      'recurrenciaConfig': serializer.toJson<String?>(recurrenciaConfig),
      'personaSitio': serializer.toJson<String?>(personaSitio),
      'hora': serializer.toJson<String?>(hora),
      'transferToAccountId': serializer.toJson<String?>(transferToAccountId),
    };
  }

  FinanceTransactionRow copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    String? tipo,
    double? monto,
    String? fecha,
    String? nota,
    bool? esRecurrente,
    Value<String?> recurrenciaConfig = const Value.absent(),
    Value<String?> personaSitio = const Value.absent(),
    Value<String?> hora = const Value.absent(),
    Value<String?> transferToAccountId = const Value.absent(),
  }) => FinanceTransactionRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    categoryId: categoryId ?? this.categoryId,
    tipo: tipo ?? this.tipo,
    monto: monto ?? this.monto,
    fecha: fecha ?? this.fecha,
    nota: nota ?? this.nota,
    esRecurrente: esRecurrente ?? this.esRecurrente,
    recurrenciaConfig: recurrenciaConfig.present
        ? recurrenciaConfig.value
        : this.recurrenciaConfig,
    personaSitio: personaSitio.present ? personaSitio.value : this.personaSitio,
    hora: hora.present ? hora.value : this.hora,
    transferToAccountId: transferToAccountId.present
        ? transferToAccountId.value
        : this.transferToAccountId,
  );
  FinanceTransactionRow copyWithCompanion(FinanceTransactionsCompanion data) {
    return FinanceTransactionRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      monto: data.monto.present ? data.monto.value : this.monto,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      nota: data.nota.present ? data.nota.value : this.nota,
      esRecurrente: data.esRecurrente.present
          ? data.esRecurrente.value
          : this.esRecurrente,
      recurrenciaConfig: data.recurrenciaConfig.present
          ? data.recurrenciaConfig.value
          : this.recurrenciaConfig,
      personaSitio: data.personaSitio.present
          ? data.personaSitio.value
          : this.personaSitio,
      hora: data.hora.present ? data.hora.value : this.hora,
      transferToAccountId: data.transferToAccountId.present
          ? data.transferToAccountId.value
          : this.transferToAccountId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinanceTransactionRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('tipo: $tipo, ')
          ..write('monto: $monto, ')
          ..write('fecha: $fecha, ')
          ..write('nota: $nota, ')
          ..write('esRecurrente: $esRecurrente, ')
          ..write('recurrenciaConfig: $recurrenciaConfig, ')
          ..write('personaSitio: $personaSitio, ')
          ..write('hora: $hora, ')
          ..write('transferToAccountId: $transferToAccountId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    categoryId,
    tipo,
    monto,
    fecha,
    nota,
    esRecurrente,
    recurrenciaConfig,
    personaSitio,
    hora,
    transferToAccountId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinanceTransactionRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.categoryId == this.categoryId &&
          other.tipo == this.tipo &&
          other.monto == this.monto &&
          other.fecha == this.fecha &&
          other.nota == this.nota &&
          other.esRecurrente == this.esRecurrente &&
          other.recurrenciaConfig == this.recurrenciaConfig &&
          other.personaSitio == this.personaSitio &&
          other.hora == this.hora &&
          other.transferToAccountId == this.transferToAccountId);
}

class FinanceTransactionsCompanion
    extends UpdateCompanion<FinanceTransactionRow> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> categoryId;
  final Value<String> tipo;
  final Value<double> monto;
  final Value<String> fecha;
  final Value<String> nota;
  final Value<bool> esRecurrente;
  final Value<String?> recurrenciaConfig;
  final Value<String?> personaSitio;
  final Value<String?> hora;
  final Value<String?> transferToAccountId;
  final Value<int> rowid;
  const FinanceTransactionsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.monto = const Value.absent(),
    this.fecha = const Value.absent(),
    this.nota = const Value.absent(),
    this.esRecurrente = const Value.absent(),
    this.recurrenciaConfig = const Value.absent(),
    this.personaSitio = const Value.absent(),
    this.hora = const Value.absent(),
    this.transferToAccountId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinanceTransactionsCompanion.insert({
    required String id,
    required String accountId,
    required String categoryId,
    required String tipo,
    required double monto,
    required String fecha,
    this.nota = const Value.absent(),
    this.esRecurrente = const Value.absent(),
    this.recurrenciaConfig = const Value.absent(),
    this.personaSitio = const Value.absent(),
    this.hora = const Value.absent(),
    this.transferToAccountId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       categoryId = Value(categoryId),
       tipo = Value(tipo),
       monto = Value(monto),
       fecha = Value(fecha);
  static Insertable<FinanceTransactionRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? categoryId,
    Expression<String>? tipo,
    Expression<double>? monto,
    Expression<String>? fecha,
    Expression<String>? nota,
    Expression<bool>? esRecurrente,
    Expression<String>? recurrenciaConfig,
    Expression<String>? personaSitio,
    Expression<String>? hora,
    Expression<String>? transferToAccountId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (categoryId != null) 'category_id': categoryId,
      if (tipo != null) 'tipo': tipo,
      if (monto != null) 'monto': monto,
      if (fecha != null) 'fecha': fecha,
      if (nota != null) 'nota': nota,
      if (esRecurrente != null) 'es_recurrente': esRecurrente,
      if (recurrenciaConfig != null) 'recurrencia_config': recurrenciaConfig,
      if (personaSitio != null) 'persona_sitio': personaSitio,
      if (hora != null) 'hora': hora,
      if (transferToAccountId != null)
        'transfer_to_account_id': transferToAccountId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinanceTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? categoryId,
    Value<String>? tipo,
    Value<double>? monto,
    Value<String>? fecha,
    Value<String>? nota,
    Value<bool>? esRecurrente,
    Value<String?>? recurrenciaConfig,
    Value<String?>? personaSitio,
    Value<String?>? hora,
    Value<String?>? transferToAccountId,
    Value<int>? rowid,
  }) {
    return FinanceTransactionsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      tipo: tipo ?? this.tipo,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      nota: nota ?? this.nota,
      esRecurrente: esRecurrente ?? this.esRecurrente,
      recurrenciaConfig: recurrenciaConfig ?? this.recurrenciaConfig,
      personaSitio: personaSitio ?? this.personaSitio,
      hora: hora ?? this.hora,
      transferToAccountId: transferToAccountId ?? this.transferToAccountId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    if (nota.present) {
      map['nota'] = Variable<String>(nota.value);
    }
    if (esRecurrente.present) {
      map['es_recurrente'] = Variable<bool>(esRecurrente.value);
    }
    if (recurrenciaConfig.present) {
      map['recurrencia_config'] = Variable<String>(recurrenciaConfig.value);
    }
    if (personaSitio.present) {
      map['persona_sitio'] = Variable<String>(personaSitio.value);
    }
    if (hora.present) {
      map['hora'] = Variable<String>(hora.value);
    }
    if (transferToAccountId.present) {
      map['transfer_to_account_id'] = Variable<String>(
        transferToAccountId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinanceTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('tipo: $tipo, ')
          ..write('monto: $monto, ')
          ..write('fecha: $fecha, ')
          ..write('nota: $nota, ')
          ..write('esRecurrente: $esRecurrente, ')
          ..write('recurrenciaConfig: $recurrenciaConfig, ')
          ..write('personaSitio: $personaSitio, ')
          ..write('hora: $hora, ')
          ..write('transferToAccountId: $transferToAccountId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinanceBudgetsTable extends FinanceBudgets
    with TableInfo<$FinanceBudgetsTable, FinanceBudgetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinanceBudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anioMeta = const VerificationMeta('anio');
  @override
  late final GeneratedColumn<int> anio = GeneratedColumn<int>(
    'anio',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mesMeta = const VerificationMeta('mes');
  @override
  late final GeneratedColumn<int> mes = GeneratedColumn<int>(
    'mes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoLimiteMeta = const VerificationMeta(
    'montoLimite',
  );
  @override
  late final GeneratedColumn<double> montoLimite = GeneratedColumn<double>(
    'monto_limite',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    categoryId,
    anio,
    mes,
    montoLimite,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finance_budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinanceBudgetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('anio')) {
      context.handle(
        _anioMeta,
        anio.isAcceptableOrUnknown(data['anio']!, _anioMeta),
      );
    } else if (isInserting) {
      context.missing(_anioMeta);
    }
    if (data.containsKey('mes')) {
      context.handle(
        _mesMeta,
        mes.isAcceptableOrUnknown(data['mes']!, _mesMeta),
      );
    } else if (isInserting) {
      context.missing(_mesMeta);
    }
    if (data.containsKey('monto_limite')) {
      context.handle(
        _montoLimiteMeta,
        montoLimite.isAcceptableOrUnknown(
          data['monto_limite']!,
          _montoLimiteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montoLimiteMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  FinanceBudgetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinanceBudgetRow(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      anio: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anio'],
      )!,
      mes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mes'],
      )!,
      montoLimite: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto_limite'],
      )!,
    );
  }

  @override
  $FinanceBudgetsTable createAlias(String alias) {
    return $FinanceBudgetsTable(attachedDatabase, alias);
  }
}

class FinanceBudgetRow extends DataClass
    implements Insertable<FinanceBudgetRow> {
  final int rowId;
  final String categoryId;
  final int anio;
  final int mes;
  final double montoLimite;
  const FinanceBudgetRow({
    required this.rowId,
    required this.categoryId,
    required this.anio,
    required this.mes,
    required this.montoLimite,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['category_id'] = Variable<String>(categoryId);
    map['anio'] = Variable<int>(anio);
    map['mes'] = Variable<int>(mes);
    map['monto_limite'] = Variable<double>(montoLimite);
    return map;
  }

  FinanceBudgetsCompanion toCompanion(bool nullToAbsent) {
    return FinanceBudgetsCompanion(
      rowId: Value(rowId),
      categoryId: Value(categoryId),
      anio: Value(anio),
      mes: Value(mes),
      montoLimite: Value(montoLimite),
    );
  }

  factory FinanceBudgetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinanceBudgetRow(
      rowId: serializer.fromJson<int>(json['rowId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      anio: serializer.fromJson<int>(json['anio']),
      mes: serializer.fromJson<int>(json['mes']),
      montoLimite: serializer.fromJson<double>(json['montoLimite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'categoryId': serializer.toJson<String>(categoryId),
      'anio': serializer.toJson<int>(anio),
      'mes': serializer.toJson<int>(mes),
      'montoLimite': serializer.toJson<double>(montoLimite),
    };
  }

  FinanceBudgetRow copyWith({
    int? rowId,
    String? categoryId,
    int? anio,
    int? mes,
    double? montoLimite,
  }) => FinanceBudgetRow(
    rowId: rowId ?? this.rowId,
    categoryId: categoryId ?? this.categoryId,
    anio: anio ?? this.anio,
    mes: mes ?? this.mes,
    montoLimite: montoLimite ?? this.montoLimite,
  );
  FinanceBudgetRow copyWithCompanion(FinanceBudgetsCompanion data) {
    return FinanceBudgetRow(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      anio: data.anio.present ? data.anio.value : this.anio,
      mes: data.mes.present ? data.mes.value : this.mes,
      montoLimite: data.montoLimite.present
          ? data.montoLimite.value
          : this.montoLimite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinanceBudgetRow(')
          ..write('rowId: $rowId, ')
          ..write('categoryId: $categoryId, ')
          ..write('anio: $anio, ')
          ..write('mes: $mes, ')
          ..write('montoLimite: $montoLimite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, categoryId, anio, mes, montoLimite);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinanceBudgetRow &&
          other.rowId == this.rowId &&
          other.categoryId == this.categoryId &&
          other.anio == this.anio &&
          other.mes == this.mes &&
          other.montoLimite == this.montoLimite);
}

class FinanceBudgetsCompanion extends UpdateCompanion<FinanceBudgetRow> {
  final Value<int> rowId;
  final Value<String> categoryId;
  final Value<int> anio;
  final Value<int> mes;
  final Value<double> montoLimite;
  const FinanceBudgetsCompanion({
    this.rowId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.anio = const Value.absent(),
    this.mes = const Value.absent(),
    this.montoLimite = const Value.absent(),
  });
  FinanceBudgetsCompanion.insert({
    this.rowId = const Value.absent(),
    required String categoryId,
    required int anio,
    required int mes,
    required double montoLimite,
  }) : categoryId = Value(categoryId),
       anio = Value(anio),
       mes = Value(mes),
       montoLimite = Value(montoLimite);
  static Insertable<FinanceBudgetRow> custom({
    Expression<int>? rowId,
    Expression<String>? categoryId,
    Expression<int>? anio,
    Expression<int>? mes,
    Expression<double>? montoLimite,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (categoryId != null) 'category_id': categoryId,
      if (anio != null) 'anio': anio,
      if (mes != null) 'mes': mes,
      if (montoLimite != null) 'monto_limite': montoLimite,
    });
  }

  FinanceBudgetsCompanion copyWith({
    Value<int>? rowId,
    Value<String>? categoryId,
    Value<int>? anio,
    Value<int>? mes,
    Value<double>? montoLimite,
  }) {
    return FinanceBudgetsCompanion(
      rowId: rowId ?? this.rowId,
      categoryId: categoryId ?? this.categoryId,
      anio: anio ?? this.anio,
      mes: mes ?? this.mes,
      montoLimite: montoLimite ?? this.montoLimite,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (anio.present) {
      map['anio'] = Variable<int>(anio.value);
    }
    if (mes.present) {
      map['mes'] = Variable<int>(mes.value);
    }
    if (montoLimite.present) {
      map['monto_limite'] = Variable<double>(montoLimite.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinanceBudgetsCompanion(')
          ..write('rowId: $rowId, ')
          ..write('categoryId: $categoryId, ')
          ..write('anio: $anio, ')
          ..write('mes: $mes, ')
          ..write('montoLimite: $montoLimite')
          ..write(')'))
        .toString();
  }
}

class $FinancePlacesTable extends FinancePlaces
    with TableInfo<$FinancePlacesTable, FinancePlaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancePlacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usadosMeta = const VerificationMeta('usados');
  @override
  late final GeneratedColumn<int> usados = GeneratedColumn<int>(
    'usados',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, nombre, usados];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finance_places';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinancePlaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('usados')) {
      context.handle(
        _usadosMeta,
        usados.isAcceptableOrUnknown(data['usados']!, _usadosMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinancePlaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinancePlaceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      usados: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usados'],
      )!,
    );
  }

  @override
  $FinancePlacesTable createAlias(String alias) {
    return $FinancePlacesTable(attachedDatabase, alias);
  }
}

class FinancePlaceRow extends DataClass implements Insertable<FinancePlaceRow> {
  final String id;
  final String nombre;
  final int usados;
  const FinancePlaceRow({
    required this.id,
    required this.nombre,
    required this.usados,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    map['usados'] = Variable<int>(usados);
    return map;
  }

  FinancePlacesCompanion toCompanion(bool nullToAbsent) {
    return FinancePlacesCompanion(
      id: Value(id),
      nombre: Value(nombre),
      usados: Value(usados),
    );
  }

  factory FinancePlaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinancePlaceRow(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      usados: serializer.fromJson<int>(json['usados']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'usados': serializer.toJson<int>(usados),
    };
  }

  FinancePlaceRow copyWith({String? id, String? nombre, int? usados}) =>
      FinancePlaceRow(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        usados: usados ?? this.usados,
      );
  FinancePlaceRow copyWithCompanion(FinancePlacesCompanion data) {
    return FinancePlaceRow(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      usados: data.usados.present ? data.usados.value : this.usados,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinancePlaceRow(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('usados: $usados')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre, usados);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancePlaceRow &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.usados == this.usados);
}

class FinancePlacesCompanion extends UpdateCompanion<FinancePlaceRow> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<int> usados;
  final Value<int> rowid;
  const FinancePlacesCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.usados = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinancePlacesCompanion.insert({
    required String id,
    required String nombre,
    this.usados = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre);
  static Insertable<FinancePlaceRow> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<int>? usados,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (usados != null) 'usados': usados,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinancePlacesCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<int>? usados,
    Value<int>? rowid,
  }) {
    return FinancePlacesCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      usados: usados ?? this.usados,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (usados.present) {
      map['usados'] = Variable<int>(usados.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinancePlacesCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('usados: $usados, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinanceTemplatesTable extends FinanceTemplates
    with TableInfo<$FinanceTemplatesTable, FinanceTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinanceTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _libroIdMeta = const VerificationMeta(
    'libroId',
  );
  @override
  late final GeneratedColumn<String> libroId = GeneratedColumn<String>(
    'libro_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES finance_accounts (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personaSitioMeta = const VerificationMeta(
    'personaSitio',
  );
  @override
  late final GeneratedColumn<String> personaSitio = GeneratedColumn<String>(
    'persona_sitio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notaMeta = const VerificationMeta('nota');
  @override
  late final GeneratedColumn<String> nota = GeneratedColumn<String>(
    'nota',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    libroId,
    categoryId,
    tipo,
    monto,
    personaSitio,
    nota,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finance_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinanceTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('libro_id')) {
      context.handle(
        _libroIdMeta,
        libroId.isAcceptableOrUnknown(data['libro_id']!, _libroIdMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    }
    if (data.containsKey('persona_sitio')) {
      context.handle(
        _personaSitioMeta,
        personaSitio.isAcceptableOrUnknown(
          data['persona_sitio']!,
          _personaSitioMeta,
        ),
      );
    }
    if (data.containsKey('nota')) {
      context.handle(
        _notaMeta,
        nota.isAcceptableOrUnknown(data['nota']!, _notaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinanceTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinanceTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      libroId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}libro_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      ),
      personaSitio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}persona_sitio'],
      ),
      nota: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nota'],
      ),
    );
  }

  @override
  $FinanceTemplatesTable createAlias(String alias) {
    return $FinanceTemplatesTable(attachedDatabase, alias);
  }
}

class FinanceTemplateRow extends DataClass
    implements Insertable<FinanceTemplateRow> {
  final String id;
  final String nombre;
  final String? libroId;
  final String categoryId;
  final String tipo;
  final double? monto;
  final String? personaSitio;
  final String? nota;
  const FinanceTemplateRow({
    required this.id,
    required this.nombre,
    this.libroId,
    required this.categoryId,
    required this.tipo,
    this.monto,
    this.personaSitio,
    this.nota,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || libroId != null) {
      map['libro_id'] = Variable<String>(libroId);
    }
    map['category_id'] = Variable<String>(categoryId);
    map['tipo'] = Variable<String>(tipo);
    if (!nullToAbsent || monto != null) {
      map['monto'] = Variable<double>(monto);
    }
    if (!nullToAbsent || personaSitio != null) {
      map['persona_sitio'] = Variable<String>(personaSitio);
    }
    if (!nullToAbsent || nota != null) {
      map['nota'] = Variable<String>(nota);
    }
    return map;
  }

  FinanceTemplatesCompanion toCompanion(bool nullToAbsent) {
    return FinanceTemplatesCompanion(
      id: Value(id),
      nombre: Value(nombre),
      libroId: libroId == null && nullToAbsent
          ? const Value.absent()
          : Value(libroId),
      categoryId: Value(categoryId),
      tipo: Value(tipo),
      monto: monto == null && nullToAbsent
          ? const Value.absent()
          : Value(monto),
      personaSitio: personaSitio == null && nullToAbsent
          ? const Value.absent()
          : Value(personaSitio),
      nota: nota == null && nullToAbsent ? const Value.absent() : Value(nota),
    );
  }

  factory FinanceTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinanceTemplateRow(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      libroId: serializer.fromJson<String?>(json['libroId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      monto: serializer.fromJson<double?>(json['monto']),
      personaSitio: serializer.fromJson<String?>(json['personaSitio']),
      nota: serializer.fromJson<String?>(json['nota']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'libroId': serializer.toJson<String?>(libroId),
      'categoryId': serializer.toJson<String>(categoryId),
      'tipo': serializer.toJson<String>(tipo),
      'monto': serializer.toJson<double?>(monto),
      'personaSitio': serializer.toJson<String?>(personaSitio),
      'nota': serializer.toJson<String?>(nota),
    };
  }

  FinanceTemplateRow copyWith({
    String? id,
    String? nombre,
    Value<String?> libroId = const Value.absent(),
    String? categoryId,
    String? tipo,
    Value<double?> monto = const Value.absent(),
    Value<String?> personaSitio = const Value.absent(),
    Value<String?> nota = const Value.absent(),
  }) => FinanceTemplateRow(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    libroId: libroId.present ? libroId.value : this.libroId,
    categoryId: categoryId ?? this.categoryId,
    tipo: tipo ?? this.tipo,
    monto: monto.present ? monto.value : this.monto,
    personaSitio: personaSitio.present ? personaSitio.value : this.personaSitio,
    nota: nota.present ? nota.value : this.nota,
  );
  FinanceTemplateRow copyWithCompanion(FinanceTemplatesCompanion data) {
    return FinanceTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      libroId: data.libroId.present ? data.libroId.value : this.libroId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      monto: data.monto.present ? data.monto.value : this.monto,
      personaSitio: data.personaSitio.present
          ? data.personaSitio.value
          : this.personaSitio,
      nota: data.nota.present ? data.nota.value : this.nota,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinanceTemplateRow(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('libroId: $libroId, ')
          ..write('categoryId: $categoryId, ')
          ..write('tipo: $tipo, ')
          ..write('monto: $monto, ')
          ..write('personaSitio: $personaSitio, ')
          ..write('nota: $nota')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombre,
    libroId,
    categoryId,
    tipo,
    monto,
    personaSitio,
    nota,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinanceTemplateRow &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.libroId == this.libroId &&
          other.categoryId == this.categoryId &&
          other.tipo == this.tipo &&
          other.monto == this.monto &&
          other.personaSitio == this.personaSitio &&
          other.nota == this.nota);
}

class FinanceTemplatesCompanion extends UpdateCompanion<FinanceTemplateRow> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<String?> libroId;
  final Value<String> categoryId;
  final Value<String> tipo;
  final Value<double?> monto;
  final Value<String?> personaSitio;
  final Value<String?> nota;
  final Value<int> rowid;
  const FinanceTemplatesCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.libroId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.monto = const Value.absent(),
    this.personaSitio = const Value.absent(),
    this.nota = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinanceTemplatesCompanion.insert({
    required String id,
    required String nombre,
    this.libroId = const Value.absent(),
    required String categoryId,
    required String tipo,
    this.monto = const Value.absent(),
    this.personaSitio = const Value.absent(),
    this.nota = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       categoryId = Value(categoryId),
       tipo = Value(tipo);
  static Insertable<FinanceTemplateRow> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? libroId,
    Expression<String>? categoryId,
    Expression<String>? tipo,
    Expression<double>? monto,
    Expression<String>? personaSitio,
    Expression<String>? nota,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (libroId != null) 'libro_id': libroId,
      if (categoryId != null) 'category_id': categoryId,
      if (tipo != null) 'tipo': tipo,
      if (monto != null) 'monto': monto,
      if (personaSitio != null) 'persona_sitio': personaSitio,
      if (nota != null) 'nota': nota,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinanceTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<String?>? libroId,
    Value<String>? categoryId,
    Value<String>? tipo,
    Value<double?>? monto,
    Value<String?>? personaSitio,
    Value<String?>? nota,
    Value<int>? rowid,
  }) {
    return FinanceTemplatesCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      libroId: libroId ?? this.libroId,
      categoryId: categoryId ?? this.categoryId,
      tipo: tipo ?? this.tipo,
      monto: monto ?? this.monto,
      personaSitio: personaSitio ?? this.personaSitio,
      nota: nota ?? this.nota,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (libroId.present) {
      map['libro_id'] = Variable<String>(libroId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (personaSitio.present) {
      map['persona_sitio'] = Variable<String>(personaSitio.value);
    }
    if (nota.present) {
      map['nota'] = Variable<String>(nota.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinanceTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('libroId: $libroId, ')
          ..write('categoryId: $categoryId, ')
          ..write('tipo: $tipo, ')
          ..write('monto: $monto, ')
          ..write('personaSitio: $personaSitio, ')
          ..write('nota: $nota, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CommercialQuotasTable commercialQuotas = $CommercialQuotasTable(
    this,
  );
  late final $CreditsTable credits = $CreditsTable(this);
  late final $InstallmentsTable installments = $InstallmentsTable(this);
  late final $CardMovementsTable cardMovements = $CardMovementsTable(this);
  late final $LoanAbonosTable loanAbonos = $LoanAbonosTable(this);
  late final $PagosRealizadosTable pagosRealizados = $PagosRealizadosTable(
    this,
  );
  late final $FinanceAccountsTable financeAccounts = $FinanceAccountsTable(
    this,
  );
  late final $FinanceCategoriesTable financeCategories =
      $FinanceCategoriesTable(this);
  late final $FinanceTransactionsTable financeTransactions =
      $FinanceTransactionsTable(this);
  late final $FinanceBudgetsTable financeBudgets = $FinanceBudgetsTable(this);
  late final $FinancePlacesTable financePlaces = $FinancePlacesTable(this);
  late final $FinanceTemplatesTable financeTemplates = $FinanceTemplatesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    commercialQuotas,
    credits,
    installments,
    cardMovements,
    loanAbonos,
    pagosRealizados,
    financeAccounts,
    financeCategories,
    financeTransactions,
    financeBudgets,
    financePlaces,
    financeTemplates,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'credits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('installments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'credits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('card_movements', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'credits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('loan_abonos', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'credits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pagos_realizados', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'finance_categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('finance_categories', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'finance_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('finance_transactions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'finance_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('finance_templates', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$CommercialQuotasTableCreateCompanionBuilder =
    CommercialQuotasCompanion Function({
      required String id,
      required String brand,
      required double limit,
      Value<String?> notes,
      Value<String?> voucherPattern,
      Value<String> entityType,
      Value<int?> cutoffDay,
      Value<int?> paymentOffsetDays,
      Value<double?> managementFee,
      Value<String?> managementFeeFrequency,
      Value<int> rowid,
    });
typedef $$CommercialQuotasTableUpdateCompanionBuilder =
    CommercialQuotasCompanion Function({
      Value<String> id,
      Value<String> brand,
      Value<double> limit,
      Value<String?> notes,
      Value<String?> voucherPattern,
      Value<String> entityType,
      Value<int?> cutoffDay,
      Value<int?> paymentOffsetDays,
      Value<double?> managementFee,
      Value<String?> managementFeeFrequency,
      Value<int> rowid,
    });

final class $$CommercialQuotasTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CommercialQuotasTable,
          CommercialQuotaRow
        > {
  $$CommercialQuotasTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$CreditsTable, List<CreditRow>> _creditsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.credits,
    aliasName: 'commercial_quotas__id__credits__quota_id',
  );

  $$CreditsTableProcessedTableManager get creditsRefs {
    final manager = $$CreditsTableTableManager(
      $_db,
      $_db.credits,
    ).filter((f) => f.quotaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_creditsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CommercialQuotasTableFilterComposer
    extends Composer<_$AppDatabase, $CommercialQuotasTable> {
  $$CommercialQuotasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get limit => $composableBuilder(
    column: $table.limit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voucherPattern => $composableBuilder(
    column: $table.voucherPattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cutoffDay => $composableBuilder(
    column: $table.cutoffDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentOffsetDays => $composableBuilder(
    column: $table.paymentOffsetDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get managementFee => $composableBuilder(
    column: $table.managementFee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get managementFeeFrequency => $composableBuilder(
    column: $table.managementFeeFrequency,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> creditsRefs(
    Expression<bool> Function($$CreditsTableFilterComposer f) f,
  ) {
    final $$CreditsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credits,
      getReferencedColumn: (t) => t.quotaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditsTableFilterComposer(
            $db: $db,
            $table: $db.credits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CommercialQuotasTableOrderingComposer
    extends Composer<_$AppDatabase, $CommercialQuotasTable> {
  $$CommercialQuotasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get limit => $composableBuilder(
    column: $table.limit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voucherPattern => $composableBuilder(
    column: $table.voucherPattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cutoffDay => $composableBuilder(
    column: $table.cutoffDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentOffsetDays => $composableBuilder(
    column: $table.paymentOffsetDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get managementFee => $composableBuilder(
    column: $table.managementFee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get managementFeeFrequency => $composableBuilder(
    column: $table.managementFeeFrequency,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CommercialQuotasTableAnnotationComposer
    extends Composer<_$AppDatabase, $CommercialQuotasTable> {
  $$CommercialQuotasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<double> get limit =>
      $composableBuilder(column: $table.limit, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get voucherPattern => $composableBuilder(
    column: $table.voucherPattern,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cutoffDay =>
      $composableBuilder(column: $table.cutoffDay, builder: (column) => column);

  GeneratedColumn<int> get paymentOffsetDays => $composableBuilder(
    column: $table.paymentOffsetDays,
    builder: (column) => column,
  );

  GeneratedColumn<double> get managementFee => $composableBuilder(
    column: $table.managementFee,
    builder: (column) => column,
  );

  GeneratedColumn<String> get managementFeeFrequency => $composableBuilder(
    column: $table.managementFeeFrequency,
    builder: (column) => column,
  );

  Expression<T> creditsRefs<T extends Object>(
    Expression<T> Function($$CreditsTableAnnotationComposer a) f,
  ) {
    final $$CreditsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credits,
      getReferencedColumn: (t) => t.quotaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditsTableAnnotationComposer(
            $db: $db,
            $table: $db.credits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CommercialQuotasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CommercialQuotasTable,
          CommercialQuotaRow,
          $$CommercialQuotasTableFilterComposer,
          $$CommercialQuotasTableOrderingComposer,
          $$CommercialQuotasTableAnnotationComposer,
          $$CommercialQuotasTableCreateCompanionBuilder,
          $$CommercialQuotasTableUpdateCompanionBuilder,
          (CommercialQuotaRow, $$CommercialQuotasTableReferences),
          CommercialQuotaRow,
          PrefetchHooks Function({bool creditsRefs})
        > {
  $$CommercialQuotasTableTableManager(
    _$AppDatabase db,
    $CommercialQuotasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommercialQuotasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommercialQuotasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommercialQuotasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<double> limit = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> voucherPattern = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<int?> cutoffDay = const Value.absent(),
                Value<int?> paymentOffsetDays = const Value.absent(),
                Value<double?> managementFee = const Value.absent(),
                Value<String?> managementFeeFrequency = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommercialQuotasCompanion(
                id: id,
                brand: brand,
                limit: limit,
                notes: notes,
                voucherPattern: voucherPattern,
                entityType: entityType,
                cutoffDay: cutoffDay,
                paymentOffsetDays: paymentOffsetDays,
                managementFee: managementFee,
                managementFeeFrequency: managementFeeFrequency,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String brand,
                required double limit,
                Value<String?> notes = const Value.absent(),
                Value<String?> voucherPattern = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<int?> cutoffDay = const Value.absent(),
                Value<int?> paymentOffsetDays = const Value.absent(),
                Value<double?> managementFee = const Value.absent(),
                Value<String?> managementFeeFrequency = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommercialQuotasCompanion.insert(
                id: id,
                brand: brand,
                limit: limit,
                notes: notes,
                voucherPattern: voucherPattern,
                entityType: entityType,
                cutoffDay: cutoffDay,
                paymentOffsetDays: paymentOffsetDays,
                managementFee: managementFee,
                managementFeeFrequency: managementFeeFrequency,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CommercialQuotasTable, CommercialQuotaRow>(
                    table,
                  ),
                  $$CommercialQuotasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({creditsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (creditsRefs) db.credits],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (creditsRefs)
                    await $_getPrefetchedData<
                      CommercialQuotaRow,
                      $CommercialQuotasTable,
                      CreditRow
                    >(
                      currentTable: table,
                      referencedTable: $$CommercialQuotasTableReferences
                          ._creditsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CommercialQuotasTableReferences(
                            db,
                            table,
                            p0,
                          ).creditsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.quotaId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CommercialQuotasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CommercialQuotasTable,
      CommercialQuotaRow,
      $$CommercialQuotasTableFilterComposer,
      $$CommercialQuotasTableOrderingComposer,
      $$CommercialQuotasTableAnnotationComposer,
      $$CommercialQuotasTableCreateCompanionBuilder,
      $$CommercialQuotasTableUpdateCompanionBuilder,
      (CommercialQuotaRow, $$CommercialQuotasTableReferences),
      CommercialQuotaRow,
      PrefetchHooks Function({bool creditsRefs})
    >;
typedef $$CreditsTableCreateCompanionBuilder =
    CreditsCompanion Function({
      required String id,
      required String type,
      required String name,
      required String lender,
      Value<String?> color,
      Value<String?> notes,
      Value<String?> location,
      Value<String?> card,
      Value<double?> totalAmount,
      Value<double?> quotaAmount,
      Value<int?> totalInstallments,
      Value<String?> frequency,
      Value<String?> startDate,
      Value<double?> interestRate,
      Value<bool> scheduleManuallyAdjusted,
      Value<String?> interestRateType,
      Value<double?> creditLimit,
      Value<double?> currentBalance,
      Value<int?> cutoffDay,
      Value<int?> paymentDueOffsetDays,
      Value<double?> managementFee,
      Value<String?> managementFeeFrequency,
      Value<int?> cycleCount,
      Value<String?> lastAccrualCutoff,
      Value<String?> quotaId,
      Value<bool> interestUnknown,
      Value<bool> earlyPaymentWaivesInterest,
      Value<String?> cardDesign,
      Value<int> paymentDueDay,
      Value<bool?> oneInstallmentInterestPolicy,
      Value<int?> notificationDaysBefore,
      Value<int> rowid,
    });
typedef $$CreditsTableUpdateCompanionBuilder =
    CreditsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> name,
      Value<String> lender,
      Value<String?> color,
      Value<String?> notes,
      Value<String?> location,
      Value<String?> card,
      Value<double?> totalAmount,
      Value<double?> quotaAmount,
      Value<int?> totalInstallments,
      Value<String?> frequency,
      Value<String?> startDate,
      Value<double?> interestRate,
      Value<bool> scheduleManuallyAdjusted,
      Value<String?> interestRateType,
      Value<double?> creditLimit,
      Value<double?> currentBalance,
      Value<int?> cutoffDay,
      Value<int?> paymentDueOffsetDays,
      Value<double?> managementFee,
      Value<String?> managementFeeFrequency,
      Value<int?> cycleCount,
      Value<String?> lastAccrualCutoff,
      Value<String?> quotaId,
      Value<bool> interestUnknown,
      Value<bool> earlyPaymentWaivesInterest,
      Value<String?> cardDesign,
      Value<int> paymentDueDay,
      Value<bool?> oneInstallmentInterestPolicy,
      Value<int?> notificationDaysBefore,
      Value<int> rowid,
    });

final class $$CreditsTableReferences
    extends BaseReferences<_$AppDatabase, $CreditsTable, CreditRow> {
  $$CreditsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CommercialQuotasTable _quotaIdTable(_$AppDatabase db) => db
      .commercialQuotas
      .createAlias('credits__quota_id__commercial_quotas__id');

  $$CommercialQuotasTableProcessedTableManager? get quotaId {
    final $_column = $_itemColumn<String>('quota_id');
    if ($_column == null) return null;
    final manager = $$CommercialQuotasTableTableManager(
      $_db,
      $_db.commercialQuotas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_quotaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$InstallmentsTable, List<InstallmentRow>>
  _installmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.installments,
    aliasName: 'credits__id__installments__credit_id',
  );

  $$InstallmentsTableProcessedTableManager get installmentsRefs {
    final manager = $$InstallmentsTableTableManager(
      $_db,
      $_db.installments,
    ).filter((f) => f.creditId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_installmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CardMovementsTable, List<CardMovementRow>>
  _cardMovementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cardMovements,
    aliasName: 'credits__id__card_movements__credit_id',
  );

  $$CardMovementsTableProcessedTableManager get cardMovementsRefs {
    final manager = $$CardMovementsTableTableManager(
      $_db,
      $_db.cardMovements,
    ).filter((f) => f.creditId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardMovementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LoanAbonosTable, List<LoanAbonoRow>>
  _loanAbonosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.loanAbonos,
    aliasName: 'credits__id__loan_abonos__credit_id',
  );

  $$LoanAbonosTableProcessedTableManager get loanAbonosRefs {
    final manager = $$LoanAbonosTableTableManager(
      $_db,
      $_db.loanAbonos,
    ).filter((f) => f.creditId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_loanAbonosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PagosRealizadosTable, List<PagoRealizadoRow>>
  _pagosRealizadosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pagosRealizados,
    aliasName: 'credits__id__pagos_realizados__credit_id',
  );

  $$PagosRealizadosTableProcessedTableManager get pagosRealizadosRefs {
    final manager = $$PagosRealizadosTableTableManager(
      $_db,
      $_db.pagosRealizados,
    ).filter((f) => f.creditId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _pagosRealizadosRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CreditsTableFilterComposer
    extends Composer<_$AppDatabase, $CreditsTable> {
  $$CreditsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lender => $composableBuilder(
    column: $table.lender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get card => $composableBuilder(
    column: $table.card,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quotaAmount => $composableBuilder(
    column: $table.quotaAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalInstallments => $composableBuilder(
    column: $table.totalInstallments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get scheduleManuallyAdjusted => $composableBuilder(
    column: $table.scheduleManuallyAdjusted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get interestRateType => $composableBuilder(
    column: $table.interestRateType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cutoffDay => $composableBuilder(
    column: $table.cutoffDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentDueOffsetDays => $composableBuilder(
    column: $table.paymentDueOffsetDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get managementFee => $composableBuilder(
    column: $table.managementFee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get managementFeeFrequency => $composableBuilder(
    column: $table.managementFeeFrequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cycleCount => $composableBuilder(
    column: $table.cycleCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastAccrualCutoff => $composableBuilder(
    column: $table.lastAccrualCutoff,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get interestUnknown => $composableBuilder(
    column: $table.interestUnknown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get earlyPaymentWaivesInterest => $composableBuilder(
    column: $table.earlyPaymentWaivesInterest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardDesign => $composableBuilder(
    column: $table.cardDesign,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentDueDay => $composableBuilder(
    column: $table.paymentDueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get oneInstallmentInterestPolicy => $composableBuilder(
    column: $table.oneInstallmentInterestPolicy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notificationDaysBefore => $composableBuilder(
    column: $table.notificationDaysBefore,
    builder: (column) => ColumnFilters(column),
  );

  $$CommercialQuotasTableFilterComposer get quotaId {
    final $$CommercialQuotasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.quotaId,
      referencedTable: $db.commercialQuotas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommercialQuotasTableFilterComposer(
            $db: $db,
            $table: $db.commercialQuotas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> installmentsRefs(
    Expression<bool> Function($$InstallmentsTableFilterComposer f) f,
  ) {
    final $$InstallmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.installments,
      getReferencedColumn: (t) => t.creditId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstallmentsTableFilterComposer(
            $db: $db,
            $table: $db.installments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cardMovementsRefs(
    Expression<bool> Function($$CardMovementsTableFilterComposer f) f,
  ) {
    final $$CardMovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cardMovements,
      getReferencedColumn: (t) => t.creditId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardMovementsTableFilterComposer(
            $db: $db,
            $table: $db.cardMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> loanAbonosRefs(
    Expression<bool> Function($$LoanAbonosTableFilterComposer f) f,
  ) {
    final $$LoanAbonosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loanAbonos,
      getReferencedColumn: (t) => t.creditId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoanAbonosTableFilterComposer(
            $db: $db,
            $table: $db.loanAbonos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pagosRealizadosRefs(
    Expression<bool> Function($$PagosRealizadosTableFilterComposer f) f,
  ) {
    final $$PagosRealizadosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pagosRealizados,
      getReferencedColumn: (t) => t.creditId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagosRealizadosTableFilterComposer(
            $db: $db,
            $table: $db.pagosRealizados,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CreditsTableOrderingComposer
    extends Composer<_$AppDatabase, $CreditsTable> {
  $$CreditsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lender => $composableBuilder(
    column: $table.lender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get card => $composableBuilder(
    column: $table.card,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quotaAmount => $composableBuilder(
    column: $table.quotaAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalInstallments => $composableBuilder(
    column: $table.totalInstallments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get scheduleManuallyAdjusted => $composableBuilder(
    column: $table.scheduleManuallyAdjusted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get interestRateType => $composableBuilder(
    column: $table.interestRateType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cutoffDay => $composableBuilder(
    column: $table.cutoffDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentDueOffsetDays => $composableBuilder(
    column: $table.paymentDueOffsetDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get managementFee => $composableBuilder(
    column: $table.managementFee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get managementFeeFrequency => $composableBuilder(
    column: $table.managementFeeFrequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleCount => $composableBuilder(
    column: $table.cycleCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAccrualCutoff => $composableBuilder(
    column: $table.lastAccrualCutoff,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get interestUnknown => $composableBuilder(
    column: $table.interestUnknown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get earlyPaymentWaivesInterest => $composableBuilder(
    column: $table.earlyPaymentWaivesInterest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardDesign => $composableBuilder(
    column: $table.cardDesign,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentDueDay => $composableBuilder(
    column: $table.paymentDueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get oneInstallmentInterestPolicy => $composableBuilder(
    column: $table.oneInstallmentInterestPolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notificationDaysBefore => $composableBuilder(
    column: $table.notificationDaysBefore,
    builder: (column) => ColumnOrderings(column),
  );

  $$CommercialQuotasTableOrderingComposer get quotaId {
    final $$CommercialQuotasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.quotaId,
      referencedTable: $db.commercialQuotas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommercialQuotasTableOrderingComposer(
            $db: $db,
            $table: $db.commercialQuotas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CreditsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CreditsTable> {
  $$CreditsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get lender =>
      $composableBuilder(column: $table.lender, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get card =>
      $composableBuilder(column: $table.card, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quotaAmount => $composableBuilder(
    column: $table.quotaAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalInstallments => $composableBuilder(
    column: $table.totalInstallments,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get scheduleManuallyAdjusted => $composableBuilder(
    column: $table.scheduleManuallyAdjusted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get interestRateType => $composableBuilder(
    column: $table.interestRateType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cutoffDay =>
      $composableBuilder(column: $table.cutoffDay, builder: (column) => column);

  GeneratedColumn<int> get paymentDueOffsetDays => $composableBuilder(
    column: $table.paymentDueOffsetDays,
    builder: (column) => column,
  );

  GeneratedColumn<double> get managementFee => $composableBuilder(
    column: $table.managementFee,
    builder: (column) => column,
  );

  GeneratedColumn<String> get managementFeeFrequency => $composableBuilder(
    column: $table.managementFeeFrequency,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cycleCount => $composableBuilder(
    column: $table.cycleCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastAccrualCutoff => $composableBuilder(
    column: $table.lastAccrualCutoff,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get interestUnknown => $composableBuilder(
    column: $table.interestUnknown,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get earlyPaymentWaivesInterest => $composableBuilder(
    column: $table.earlyPaymentWaivesInterest,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cardDesign => $composableBuilder(
    column: $table.cardDesign,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentDueDay => $composableBuilder(
    column: $table.paymentDueDay,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get oneInstallmentInterestPolicy => $composableBuilder(
    column: $table.oneInstallmentInterestPolicy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notificationDaysBefore => $composableBuilder(
    column: $table.notificationDaysBefore,
    builder: (column) => column,
  );

  $$CommercialQuotasTableAnnotationComposer get quotaId {
    final $$CommercialQuotasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.quotaId,
      referencedTable: $db.commercialQuotas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommercialQuotasTableAnnotationComposer(
            $db: $db,
            $table: $db.commercialQuotas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> installmentsRefs<T extends Object>(
    Expression<T> Function($$InstallmentsTableAnnotationComposer a) f,
  ) {
    final $$InstallmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.installments,
      getReferencedColumn: (t) => t.creditId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstallmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.installments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cardMovementsRefs<T extends Object>(
    Expression<T> Function($$CardMovementsTableAnnotationComposer a) f,
  ) {
    final $$CardMovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cardMovements,
      getReferencedColumn: (t) => t.creditId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardMovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.cardMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> loanAbonosRefs<T extends Object>(
    Expression<T> Function($$LoanAbonosTableAnnotationComposer a) f,
  ) {
    final $$LoanAbonosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loanAbonos,
      getReferencedColumn: (t) => t.creditId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoanAbonosTableAnnotationComposer(
            $db: $db,
            $table: $db.loanAbonos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pagosRealizadosRefs<T extends Object>(
    Expression<T> Function($$PagosRealizadosTableAnnotationComposer a) f,
  ) {
    final $$PagosRealizadosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pagosRealizados,
      getReferencedColumn: (t) => t.creditId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagosRealizadosTableAnnotationComposer(
            $db: $db,
            $table: $db.pagosRealizados,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CreditsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CreditsTable,
          CreditRow,
          $$CreditsTableFilterComposer,
          $$CreditsTableOrderingComposer,
          $$CreditsTableAnnotationComposer,
          $$CreditsTableCreateCompanionBuilder,
          $$CreditsTableUpdateCompanionBuilder,
          (CreditRow, $$CreditsTableReferences),
          CreditRow,
          PrefetchHooks Function({
            bool quotaId,
            bool installmentsRefs,
            bool cardMovementsRefs,
            bool loanAbonosRefs,
            bool pagosRealizadosRefs,
          })
        > {
  $$CreditsTableTableManager(_$AppDatabase db, $CreditsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreditsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreditsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreditsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> lender = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> card = const Value.absent(),
                Value<double?> totalAmount = const Value.absent(),
                Value<double?> quotaAmount = const Value.absent(),
                Value<int?> totalInstallments = const Value.absent(),
                Value<String?> frequency = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<double?> interestRate = const Value.absent(),
                Value<bool> scheduleManuallyAdjusted = const Value.absent(),
                Value<String?> interestRateType = const Value.absent(),
                Value<double?> creditLimit = const Value.absent(),
                Value<double?> currentBalance = const Value.absent(),
                Value<int?> cutoffDay = const Value.absent(),
                Value<int?> paymentDueOffsetDays = const Value.absent(),
                Value<double?> managementFee = const Value.absent(),
                Value<String?> managementFeeFrequency = const Value.absent(),
                Value<int?> cycleCount = const Value.absent(),
                Value<String?> lastAccrualCutoff = const Value.absent(),
                Value<String?> quotaId = const Value.absent(),
                Value<bool> interestUnknown = const Value.absent(),
                Value<bool> earlyPaymentWaivesInterest = const Value.absent(),
                Value<String?> cardDesign = const Value.absent(),
                Value<int> paymentDueDay = const Value.absent(),
                Value<bool?> oneInstallmentInterestPolicy =
                    const Value.absent(),
                Value<int?> notificationDaysBefore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreditsCompanion(
                id: id,
                type: type,
                name: name,
                lender: lender,
                color: color,
                notes: notes,
                location: location,
                card: card,
                totalAmount: totalAmount,
                quotaAmount: quotaAmount,
                totalInstallments: totalInstallments,
                frequency: frequency,
                startDate: startDate,
                interestRate: interestRate,
                scheduleManuallyAdjusted: scheduleManuallyAdjusted,
                interestRateType: interestRateType,
                creditLimit: creditLimit,
                currentBalance: currentBalance,
                cutoffDay: cutoffDay,
                paymentDueOffsetDays: paymentDueOffsetDays,
                managementFee: managementFee,
                managementFeeFrequency: managementFeeFrequency,
                cycleCount: cycleCount,
                lastAccrualCutoff: lastAccrualCutoff,
                quotaId: quotaId,
                interestUnknown: interestUnknown,
                earlyPaymentWaivesInterest: earlyPaymentWaivesInterest,
                cardDesign: cardDesign,
                paymentDueDay: paymentDueDay,
                oneInstallmentInterestPolicy: oneInstallmentInterestPolicy,
                notificationDaysBefore: notificationDaysBefore,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String name,
                required String lender,
                Value<String?> color = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> card = const Value.absent(),
                Value<double?> totalAmount = const Value.absent(),
                Value<double?> quotaAmount = const Value.absent(),
                Value<int?> totalInstallments = const Value.absent(),
                Value<String?> frequency = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<double?> interestRate = const Value.absent(),
                Value<bool> scheduleManuallyAdjusted = const Value.absent(),
                Value<String?> interestRateType = const Value.absent(),
                Value<double?> creditLimit = const Value.absent(),
                Value<double?> currentBalance = const Value.absent(),
                Value<int?> cutoffDay = const Value.absent(),
                Value<int?> paymentDueOffsetDays = const Value.absent(),
                Value<double?> managementFee = const Value.absent(),
                Value<String?> managementFeeFrequency = const Value.absent(),
                Value<int?> cycleCount = const Value.absent(),
                Value<String?> lastAccrualCutoff = const Value.absent(),
                Value<String?> quotaId = const Value.absent(),
                Value<bool> interestUnknown = const Value.absent(),
                Value<bool> earlyPaymentWaivesInterest = const Value.absent(),
                Value<String?> cardDesign = const Value.absent(),
                Value<int> paymentDueDay = const Value.absent(),
                Value<bool?> oneInstallmentInterestPolicy =
                    const Value.absent(),
                Value<int?> notificationDaysBefore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreditsCompanion.insert(
                id: id,
                type: type,
                name: name,
                lender: lender,
                color: color,
                notes: notes,
                location: location,
                card: card,
                totalAmount: totalAmount,
                quotaAmount: quotaAmount,
                totalInstallments: totalInstallments,
                frequency: frequency,
                startDate: startDate,
                interestRate: interestRate,
                scheduleManuallyAdjusted: scheduleManuallyAdjusted,
                interestRateType: interestRateType,
                creditLimit: creditLimit,
                currentBalance: currentBalance,
                cutoffDay: cutoffDay,
                paymentDueOffsetDays: paymentDueOffsetDays,
                managementFee: managementFee,
                managementFeeFrequency: managementFeeFrequency,
                cycleCount: cycleCount,
                lastAccrualCutoff: lastAccrualCutoff,
                quotaId: quotaId,
                interestUnknown: interestUnknown,
                earlyPaymentWaivesInterest: earlyPaymentWaivesInterest,
                cardDesign: cardDesign,
                paymentDueDay: paymentDueDay,
                oneInstallmentInterestPolicy: oneInstallmentInterestPolicy,
                notificationDaysBefore: notificationDaysBefore,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CreditsTable, CreditRow>(table),
                  $$CreditsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                quotaId = false,
                installmentsRefs = false,
                cardMovementsRefs = false,
                loanAbonosRefs = false,
                pagosRealizadosRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (installmentsRefs) db.installments,
                    if (cardMovementsRefs) db.cardMovements,
                    if (loanAbonosRefs) db.loanAbonos,
                    if (pagosRealizadosRefs) db.pagosRealizados,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (quotaId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.quotaId,
                                    referencedTable: $$CreditsTableReferences
                                        ._quotaIdTable(db),
                                    referencedColumn: $$CreditsTableReferences
                                        ._quotaIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (installmentsRefs)
                        await $_getPrefetchedData<
                          CreditRow,
                          $CreditsTable,
                          InstallmentRow
                        >(
                          currentTable: table,
                          referencedTable: $$CreditsTableReferences
                              ._installmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CreditsTableReferences(
                                db,
                                table,
                                p0,
                              ).installmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.creditId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cardMovementsRefs)
                        await $_getPrefetchedData<
                          CreditRow,
                          $CreditsTable,
                          CardMovementRow
                        >(
                          currentTable: table,
                          referencedTable: $$CreditsTableReferences
                              ._cardMovementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CreditsTableReferences(
                                db,
                                table,
                                p0,
                              ).cardMovementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.creditId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (loanAbonosRefs)
                        await $_getPrefetchedData<
                          CreditRow,
                          $CreditsTable,
                          LoanAbonoRow
                        >(
                          currentTable: table,
                          referencedTable: $$CreditsTableReferences
                              ._loanAbonosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CreditsTableReferences(
                                db,
                                table,
                                p0,
                              ).loanAbonosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.creditId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pagosRealizadosRefs)
                        await $_getPrefetchedData<
                          CreditRow,
                          $CreditsTable,
                          PagoRealizadoRow
                        >(
                          currentTable: table,
                          referencedTable: $$CreditsTableReferences
                              ._pagosRealizadosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CreditsTableReferences(
                                db,
                                table,
                                p0,
                              ).pagosRealizadosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.creditId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CreditsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CreditsTable,
      CreditRow,
      $$CreditsTableFilterComposer,
      $$CreditsTableOrderingComposer,
      $$CreditsTableAnnotationComposer,
      $$CreditsTableCreateCompanionBuilder,
      $$CreditsTableUpdateCompanionBuilder,
      (CreditRow, $$CreditsTableReferences),
      CreditRow,
      PrefetchHooks Function({
        bool quotaId,
        bool installmentsRefs,
        bool cardMovementsRefs,
        bool loanAbonosRefs,
        bool pagosRealizadosRefs,
      })
    >;
typedef $$InstallmentsTableCreateCompanionBuilder =
    InstallmentsCompanion Function({
      Value<int> rowId,
      required String creditId,
      required int number,
      required String dueDate,
      required double amount,
      required double principal,
      required double interest,
      Value<bool> paid,
      Value<String?> paymentDate,
      Value<bool> interestWaived,
    });
typedef $$InstallmentsTableUpdateCompanionBuilder =
    InstallmentsCompanion Function({
      Value<int> rowId,
      Value<String> creditId,
      Value<int> number,
      Value<String> dueDate,
      Value<double> amount,
      Value<double> principal,
      Value<double> interest,
      Value<bool> paid,
      Value<String?> paymentDate,
      Value<bool> interestWaived,
    });

final class $$InstallmentsTableReferences
    extends BaseReferences<_$AppDatabase, $InstallmentsTable, InstallmentRow> {
  $$InstallmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CreditsTable _creditIdTable(_$AppDatabase db) =>
      db.credits.createAlias('installments__credit_id__credits__id');

  $$CreditsTableProcessedTableManager get creditId {
    final $_column = $_itemColumn<String>('credit_id')!;

    final manager = $$CreditsTableTableManager(
      $_db,
      $_db.credits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_creditIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InstallmentsTableFilterComposer
    extends Composer<_$AppDatabase, $InstallmentsTable> {
  $$InstallmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get principal => $composableBuilder(
    column: $table.principal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get interest => $composableBuilder(
    column: $table.interest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paid => $composableBuilder(
    column: $table.paid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get interestWaived => $composableBuilder(
    column: $table.interestWaived,
    builder: (column) => ColumnFilters(column),
  );

  $$CreditsTableFilterComposer get creditId {
    final $$CreditsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditId,
      referencedTable: $db.credits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditsTableFilterComposer(
            $db: $db,
            $table: $db.credits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstallmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstallmentsTable> {
  $$InstallmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get principal => $composableBuilder(
    column: $table.principal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get interest => $composableBuilder(
    column: $table.interest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paid => $composableBuilder(
    column: $table.paid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get interestWaived => $composableBuilder(
    column: $table.interestWaived,
    builder: (column) => ColumnOrderings(column),
  );

  $$CreditsTableOrderingComposer get creditId {
    final $$CreditsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditId,
      referencedTable: $db.credits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditsTableOrderingComposer(
            $db: $db,
            $table: $db.credits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstallmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstallmentsTable> {
  $$InstallmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get principal =>
      $composableBuilder(column: $table.principal, builder: (column) => column);

  GeneratedColumn<double> get interest =>
      $composableBuilder(column: $table.interest, builder: (column) => column);

  GeneratedColumn<bool> get paid =>
      $composableBuilder(column: $table.paid, builder: (column) => column);

  GeneratedColumn<String> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get interestWaived => $composableBuilder(
    column: $table.interestWaived,
    builder: (column) => column,
  );

  $$CreditsTableAnnotationComposer get creditId {
    final $$CreditsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditId,
      referencedTable: $db.credits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditsTableAnnotationComposer(
            $db: $db,
            $table: $db.credits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstallmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstallmentsTable,
          InstallmentRow,
          $$InstallmentsTableFilterComposer,
          $$InstallmentsTableOrderingComposer,
          $$InstallmentsTableAnnotationComposer,
          $$InstallmentsTableCreateCompanionBuilder,
          $$InstallmentsTableUpdateCompanionBuilder,
          (InstallmentRow, $$InstallmentsTableReferences),
          InstallmentRow,
          PrefetchHooks Function({bool creditId})
        > {
  $$InstallmentsTableTableManager(_$AppDatabase db, $InstallmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstallmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstallmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstallmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> creditId = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<String> dueDate = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<double> principal = const Value.absent(),
                Value<double> interest = const Value.absent(),
                Value<bool> paid = const Value.absent(),
                Value<String?> paymentDate = const Value.absent(),
                Value<bool> interestWaived = const Value.absent(),
              }) => InstallmentsCompanion(
                rowId: rowId,
                creditId: creditId,
                number: number,
                dueDate: dueDate,
                amount: amount,
                principal: principal,
                interest: interest,
                paid: paid,
                paymentDate: paymentDate,
                interestWaived: interestWaived,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String creditId,
                required int number,
                required String dueDate,
                required double amount,
                required double principal,
                required double interest,
                Value<bool> paid = const Value.absent(),
                Value<String?> paymentDate = const Value.absent(),
                Value<bool> interestWaived = const Value.absent(),
              }) => InstallmentsCompanion.insert(
                rowId: rowId,
                creditId: creditId,
                number: number,
                dueDate: dueDate,
                amount: amount,
                principal: principal,
                interest: interest,
                paid: paid,
                paymentDate: paymentDate,
                interestWaived: interestWaived,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InstallmentsTable, InstallmentRow>(table),
                  $$InstallmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({creditId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (creditId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.creditId,
                                referencedTable: $$InstallmentsTableReferences
                                    ._creditIdTable(db),
                                referencedColumn: $$InstallmentsTableReferences
                                    ._creditIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InstallmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstallmentsTable,
      InstallmentRow,
      $$InstallmentsTableFilterComposer,
      $$InstallmentsTableOrderingComposer,
      $$InstallmentsTableAnnotationComposer,
      $$InstallmentsTableCreateCompanionBuilder,
      $$InstallmentsTableUpdateCompanionBuilder,
      (InstallmentRow, $$InstallmentsTableReferences),
      InstallmentRow,
      PrefetchHooks Function({bool creditId})
    >;
typedef $$CardMovementsTableCreateCompanionBuilder =
    CardMovementsCompanion Function({
      Value<int> rowId,
      required String creditId,
      required String date,
      required String type,
      required double amount,
      Value<String> note,
      Value<int?> advanceInstallments,
      Value<double?> advanceInterestRate,
      Value<String?> advanceInterestRateType,
      Value<double?> advanceCommission,
      Value<String?> advanceFirstPaymentDate,
      Value<String?> advanceDestination,
      Value<String?> categoria,
    });
typedef $$CardMovementsTableUpdateCompanionBuilder =
    CardMovementsCompanion Function({
      Value<int> rowId,
      Value<String> creditId,
      Value<String> date,
      Value<String> type,
      Value<double> amount,
      Value<String> note,
      Value<int?> advanceInstallments,
      Value<double?> advanceInterestRate,
      Value<String?> advanceInterestRateType,
      Value<double?> advanceCommission,
      Value<String?> advanceFirstPaymentDate,
      Value<String?> advanceDestination,
      Value<String?> categoria,
    });

final class $$CardMovementsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CardMovementsTable, CardMovementRow> {
  $$CardMovementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CreditsTable _creditIdTable(_$AppDatabase db) =>
      db.credits.createAlias('card_movements__credit_id__credits__id');

  $$CreditsTableProcessedTableManager get creditId {
    final $_column = $_itemColumn<String>('credit_id')!;

    final manager = $$CreditsTableTableManager(
      $_db,
      $_db.credits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_creditIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CardMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $CardMovementsTable> {
  $$CardMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get advanceInstallments => $composableBuilder(
    column: $table.advanceInstallments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get advanceInterestRate => $composableBuilder(
    column: $table.advanceInterestRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get advanceInterestRateType => $composableBuilder(
    column: $table.advanceInterestRateType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get advanceCommission => $composableBuilder(
    column: $table.advanceCommission,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get advanceFirstPaymentDate => $composableBuilder(
    column: $table.advanceFirstPaymentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get advanceDestination => $composableBuilder(
    column: $table.advanceDestination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  $$CreditsTableFilterComposer get creditId {
    final $$CreditsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditId,
      referencedTable: $db.credits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditsTableFilterComposer(
            $db: $db,
            $table: $db.credits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardMovementsTable> {
  $$CardMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get advanceInstallments => $composableBuilder(
    column: $table.advanceInstallments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get advanceInterestRate => $composableBuilder(
    column: $table.advanceInterestRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get advanceInterestRateType => $composableBuilder(
    column: $table.advanceInterestRateType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get advanceCommission => $composableBuilder(
    column: $table.advanceCommission,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get advanceFirstPaymentDate => $composableBuilder(
    column: $table.advanceFirstPaymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get advanceDestination => $composableBuilder(
    column: $table.advanceDestination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  $$CreditsTableOrderingComposer get creditId {
    final $$CreditsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditId,
      referencedTable: $db.credits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditsTableOrderingComposer(
            $db: $db,
            $table: $db.credits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardMovementsTable> {
  $$CardMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get advanceInstallments => $composableBuilder(
    column: $table.advanceInstallments,
    builder: (column) => column,
  );

  GeneratedColumn<double> get advanceInterestRate => $composableBuilder(
    column: $table.advanceInterestRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get advanceInterestRateType => $composableBuilder(
    column: $table.advanceInterestRateType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get advanceCommission => $composableBuilder(
    column: $table.advanceCommission,
    builder: (column) => column,
  );

  GeneratedColumn<String> get advanceFirstPaymentDate => $composableBuilder(
    column: $table.advanceFirstPaymentDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get advanceDestination => $composableBuilder(
    column: $table.advanceDestination,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  $$CreditsTableAnnotationComposer get creditId {
    final $$CreditsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditId,
      referencedTable: $db.credits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditsTableAnnotationComposer(
            $db: $db,
            $table: $db.credits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardMovementsTable,
          CardMovementRow,
          $$CardMovementsTableFilterComposer,
          $$CardMovementsTableOrderingComposer,
          $$CardMovementsTableAnnotationComposer,
          $$CardMovementsTableCreateCompanionBuilder,
          $$CardMovementsTableUpdateCompanionBuilder,
          (CardMovementRow, $$CardMovementsTableReferences),
          CardMovementRow,
          PrefetchHooks Function({bool creditId})
        > {
  $$CardMovementsTableTableManager(_$AppDatabase db, $CardMovementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> creditId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int?> advanceInstallments = const Value.absent(),
                Value<double?> advanceInterestRate = const Value.absent(),
                Value<String?> advanceInterestRateType = const Value.absent(),
                Value<double?> advanceCommission = const Value.absent(),
                Value<String?> advanceFirstPaymentDate = const Value.absent(),
                Value<String?> advanceDestination = const Value.absent(),
                Value<String?> categoria = const Value.absent(),
              }) => CardMovementsCompanion(
                rowId: rowId,
                creditId: creditId,
                date: date,
                type: type,
                amount: amount,
                note: note,
                advanceInstallments: advanceInstallments,
                advanceInterestRate: advanceInterestRate,
                advanceInterestRateType: advanceInterestRateType,
                advanceCommission: advanceCommission,
                advanceFirstPaymentDate: advanceFirstPaymentDate,
                advanceDestination: advanceDestination,
                categoria: categoria,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String creditId,
                required String date,
                required String type,
                required double amount,
                Value<String> note = const Value.absent(),
                Value<int?> advanceInstallments = const Value.absent(),
                Value<double?> advanceInterestRate = const Value.absent(),
                Value<String?> advanceInterestRateType = const Value.absent(),
                Value<double?> advanceCommission = const Value.absent(),
                Value<String?> advanceFirstPaymentDate = const Value.absent(),
                Value<String?> advanceDestination = const Value.absent(),
                Value<String?> categoria = const Value.absent(),
              }) => CardMovementsCompanion.insert(
                rowId: rowId,
                creditId: creditId,
                date: date,
                type: type,
                amount: amount,
                note: note,
                advanceInstallments: advanceInstallments,
                advanceInterestRate: advanceInterestRate,
                advanceInterestRateType: advanceInterestRateType,
                advanceCommission: advanceCommission,
                advanceFirstPaymentDate: advanceFirstPaymentDate,
                advanceDestination: advanceDestination,
                categoria: categoria,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CardMovementsTable, CardMovementRow>(table),
                  $$CardMovementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({creditId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (creditId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.creditId,
                                referencedTable: $$CardMovementsTableReferences
                                    ._creditIdTable(db),
                                referencedColumn: $$CardMovementsTableReferences
                                    ._creditIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CardMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardMovementsTable,
      CardMovementRow,
      $$CardMovementsTableFilterComposer,
      $$CardMovementsTableOrderingComposer,
      $$CardMovementsTableAnnotationComposer,
      $$CardMovementsTableCreateCompanionBuilder,
      $$CardMovementsTableUpdateCompanionBuilder,
      (CardMovementRow, $$CardMovementsTableReferences),
      CardMovementRow,
      PrefetchHooks Function({bool creditId})
    >;
typedef $$LoanAbonosTableCreateCompanionBuilder =
    LoanAbonosCompanion Function({
      Value<int> rowId,
      required String creditId,
      required String date,
      required double amount,
      Value<String> note,
      Value<int> installmentsSkipped,
      Value<double?> previousQuotaAmount,
      Value<String?> previousInstallmentsSnapshot,
    });
typedef $$LoanAbonosTableUpdateCompanionBuilder =
    LoanAbonosCompanion Function({
      Value<int> rowId,
      Value<String> creditId,
      Value<String> date,
      Value<double> amount,
      Value<String> note,
      Value<int> installmentsSkipped,
      Value<double?> previousQuotaAmount,
      Value<String?> previousInstallmentsSnapshot,
    });

final class $$LoanAbonosTableReferences
    extends BaseReferences<_$AppDatabase, $LoanAbonosTable, LoanAbonoRow> {
  $$LoanAbonosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CreditsTable _creditIdTable(_$AppDatabase db) =>
      db.credits.createAlias('loan_abonos__credit_id__credits__id');

  $$CreditsTableProcessedTableManager get creditId {
    final $_column = $_itemColumn<String>('credit_id')!;

    final manager = $$CreditsTableTableManager(
      $_db,
      $_db.credits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_creditIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LoanAbonosTableFilterComposer
    extends Composer<_$AppDatabase, $LoanAbonosTable> {
  $$LoanAbonosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installmentsSkipped => $composableBuilder(
    column: $table.installmentsSkipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get previousQuotaAmount => $composableBuilder(
    column: $table.previousQuotaAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousInstallmentsSnapshot => $composableBuilder(
    column: $table.previousInstallmentsSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  $$CreditsTableFilterComposer get creditId {
    final $$CreditsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditId,
      referencedTable: $db.credits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditsTableFilterComposer(
            $db: $db,
            $table: $db.credits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoanAbonosTableOrderingComposer
    extends Composer<_$AppDatabase, $LoanAbonosTable> {
  $$LoanAbonosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installmentsSkipped => $composableBuilder(
    column: $table.installmentsSkipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get previousQuotaAmount => $composableBuilder(
    column: $table.previousQuotaAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousInstallmentsSnapshot =>
      $composableBuilder(
        column: $table.previousInstallmentsSnapshot,
        builder: (column) => ColumnOrderings(column),
      );

  $$CreditsTableOrderingComposer get creditId {
    final $$CreditsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditId,
      referencedTable: $db.credits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditsTableOrderingComposer(
            $db: $db,
            $table: $db.credits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoanAbonosTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoanAbonosTable> {
  $$LoanAbonosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get installmentsSkipped => $composableBuilder(
    column: $table.installmentsSkipped,
    builder: (column) => column,
  );

  GeneratedColumn<double> get previousQuotaAmount => $composableBuilder(
    column: $table.previousQuotaAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previousInstallmentsSnapshot =>
      $composableBuilder(
        column: $table.previousInstallmentsSnapshot,
        builder: (column) => column,
      );

  $$CreditsTableAnnotationComposer get creditId {
    final $$CreditsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditId,
      referencedTable: $db.credits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditsTableAnnotationComposer(
            $db: $db,
            $table: $db.credits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoanAbonosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoanAbonosTable,
          LoanAbonoRow,
          $$LoanAbonosTableFilterComposer,
          $$LoanAbonosTableOrderingComposer,
          $$LoanAbonosTableAnnotationComposer,
          $$LoanAbonosTableCreateCompanionBuilder,
          $$LoanAbonosTableUpdateCompanionBuilder,
          (LoanAbonoRow, $$LoanAbonosTableReferences),
          LoanAbonoRow,
          PrefetchHooks Function({bool creditId})
        > {
  $$LoanAbonosTableTableManager(_$AppDatabase db, $LoanAbonosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoanAbonosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoanAbonosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoanAbonosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> creditId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> installmentsSkipped = const Value.absent(),
                Value<double?> previousQuotaAmount = const Value.absent(),
                Value<String?> previousInstallmentsSnapshot =
                    const Value.absent(),
              }) => LoanAbonosCompanion(
                rowId: rowId,
                creditId: creditId,
                date: date,
                amount: amount,
                note: note,
                installmentsSkipped: installmentsSkipped,
                previousQuotaAmount: previousQuotaAmount,
                previousInstallmentsSnapshot: previousInstallmentsSnapshot,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String creditId,
                required String date,
                required double amount,
                Value<String> note = const Value.absent(),
                Value<int> installmentsSkipped = const Value.absent(),
                Value<double?> previousQuotaAmount = const Value.absent(),
                Value<String?> previousInstallmentsSnapshot =
                    const Value.absent(),
              }) => LoanAbonosCompanion.insert(
                rowId: rowId,
                creditId: creditId,
                date: date,
                amount: amount,
                note: note,
                installmentsSkipped: installmentsSkipped,
                previousQuotaAmount: previousQuotaAmount,
                previousInstallmentsSnapshot: previousInstallmentsSnapshot,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LoanAbonosTable, LoanAbonoRow>(table),
                  $$LoanAbonosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({creditId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (creditId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.creditId,
                                referencedTable: $$LoanAbonosTableReferences
                                    ._creditIdTable(db),
                                referencedColumn: $$LoanAbonosTableReferences
                                    ._creditIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LoanAbonosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoanAbonosTable,
      LoanAbonoRow,
      $$LoanAbonosTableFilterComposer,
      $$LoanAbonosTableOrderingComposer,
      $$LoanAbonosTableAnnotationComposer,
      $$LoanAbonosTableCreateCompanionBuilder,
      $$LoanAbonosTableUpdateCompanionBuilder,
      (LoanAbonoRow, $$LoanAbonosTableReferences),
      LoanAbonoRow,
      PrefetchHooks Function({bool creditId})
    >;
typedef $$PagosRealizadosTableCreateCompanionBuilder =
    PagosRealizadosCompanion Function({
      Value<int> rowId,
      required String creditId,
      required String fecha,
      required double monto,
      required String tipo,
      Value<int?> numeroCuota,
      Value<String> nota,
    });
typedef $$PagosRealizadosTableUpdateCompanionBuilder =
    PagosRealizadosCompanion Function({
      Value<int> rowId,
      Value<String> creditId,
      Value<String> fecha,
      Value<double> monto,
      Value<String> tipo,
      Value<int?> numeroCuota,
      Value<String> nota,
    });

final class $$PagosRealizadosTableReferences
    extends
        BaseReferences<_$AppDatabase, $PagosRealizadosTable, PagoRealizadoRow> {
  $$PagosRealizadosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CreditsTable _creditIdTable(_$AppDatabase db) =>
      db.credits.createAlias('pagos_realizados__credit_id__credits__id');

  $$CreditsTableProcessedTableManager get creditId {
    final $_column = $_itemColumn<String>('credit_id')!;

    final manager = $$CreditsTableTableManager(
      $_db,
      $_db.credits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_creditIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PagosRealizadosTableFilterComposer
    extends Composer<_$AppDatabase, $PagosRealizadosTable> {
  $$PagosRealizadosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numeroCuota => $composableBuilder(
    column: $table.numeroCuota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nota => $composableBuilder(
    column: $table.nota,
    builder: (column) => ColumnFilters(column),
  );

  $$CreditsTableFilterComposer get creditId {
    final $$CreditsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditId,
      referencedTable: $db.credits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditsTableFilterComposer(
            $db: $db,
            $table: $db.credits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PagosRealizadosTableOrderingComposer
    extends Composer<_$AppDatabase, $PagosRealizadosTable> {
  $$PagosRealizadosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numeroCuota => $composableBuilder(
    column: $table.numeroCuota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nota => $composableBuilder(
    column: $table.nota,
    builder: (column) => ColumnOrderings(column),
  );

  $$CreditsTableOrderingComposer get creditId {
    final $$CreditsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditId,
      referencedTable: $db.credits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditsTableOrderingComposer(
            $db: $db,
            $table: $db.credits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PagosRealizadosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PagosRealizadosTable> {
  $$PagosRealizadosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<int> get numeroCuota => $composableBuilder(
    column: $table.numeroCuota,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nota =>
      $composableBuilder(column: $table.nota, builder: (column) => column);

  $$CreditsTableAnnotationComposer get creditId {
    final $$CreditsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditId,
      referencedTable: $db.credits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditsTableAnnotationComposer(
            $db: $db,
            $table: $db.credits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PagosRealizadosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PagosRealizadosTable,
          PagoRealizadoRow,
          $$PagosRealizadosTableFilterComposer,
          $$PagosRealizadosTableOrderingComposer,
          $$PagosRealizadosTableAnnotationComposer,
          $$PagosRealizadosTableCreateCompanionBuilder,
          $$PagosRealizadosTableUpdateCompanionBuilder,
          (PagoRealizadoRow, $$PagosRealizadosTableReferences),
          PagoRealizadoRow,
          PrefetchHooks Function({bool creditId})
        > {
  $$PagosRealizadosTableTableManager(
    _$AppDatabase db,
    $PagosRealizadosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PagosRealizadosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PagosRealizadosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PagosRealizadosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> creditId = const Value.absent(),
                Value<String> fecha = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<int?> numeroCuota = const Value.absent(),
                Value<String> nota = const Value.absent(),
              }) => PagosRealizadosCompanion(
                rowId: rowId,
                creditId: creditId,
                fecha: fecha,
                monto: monto,
                tipo: tipo,
                numeroCuota: numeroCuota,
                nota: nota,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String creditId,
                required String fecha,
                required double monto,
                required String tipo,
                Value<int?> numeroCuota = const Value.absent(),
                Value<String> nota = const Value.absent(),
              }) => PagosRealizadosCompanion.insert(
                rowId: rowId,
                creditId: creditId,
                fecha: fecha,
                monto: monto,
                tipo: tipo,
                numeroCuota: numeroCuota,
                nota: nota,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PagosRealizadosTable, PagoRealizadoRow>(table),
                  $$PagosRealizadosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({creditId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (creditId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.creditId,
                                referencedTable:
                                    $$PagosRealizadosTableReferences
                                        ._creditIdTable(db),
                                referencedColumn:
                                    $$PagosRealizadosTableReferences
                                        ._creditIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PagosRealizadosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PagosRealizadosTable,
      PagoRealizadoRow,
      $$PagosRealizadosTableFilterComposer,
      $$PagosRealizadosTableOrderingComposer,
      $$PagosRealizadosTableAnnotationComposer,
      $$PagosRealizadosTableCreateCompanionBuilder,
      $$PagosRealizadosTableUpdateCompanionBuilder,
      (PagoRealizadoRow, $$PagosRealizadosTableReferences),
      PagoRealizadoRow,
      PrefetchHooks Function({bool creditId})
    >;
typedef $$FinanceAccountsTableCreateCompanionBuilder =
    FinanceAccountsCompanion Function({
      required String id,
      required String nombre,
      required String tipo,
      required String icono,
      required String color,
      Value<double> saldoInicial,
      Value<bool> activa,
      Value<String> orden,
      Value<bool> esFavorito,
      Value<int> rowid,
    });
typedef $$FinanceAccountsTableUpdateCompanionBuilder =
    FinanceAccountsCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<String> tipo,
      Value<String> icono,
      Value<String> color,
      Value<double> saldoInicial,
      Value<bool> activa,
      Value<String> orden,
      Value<bool> esFavorito,
      Value<int> rowid,
    });

final class $$FinanceAccountsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FinanceAccountsTable,
          FinanceAccountRow
        > {
  $$FinanceAccountsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$FinanceTemplatesTable, List<FinanceTemplateRow>>
  _financeTemplatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.financeTemplates,
    aliasName: 'finance_accounts__id__finance_templates__libro_id',
  );

  $$FinanceTemplatesTableProcessedTableManager get financeTemplatesRefs {
    final manager = $$FinanceTemplatesTableTableManager(
      $_db,
      $_db.financeTemplates,
    ).filter((f) => f.libroId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _financeTemplatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FinanceAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $FinanceAccountsTable> {
  $$FinanceAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icono => $composableBuilder(
    column: $table.icono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get saldoInicial => $composableBuilder(
    column: $table.saldoInicial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activa => $composableBuilder(
    column: $table.activa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get esFavorito => $composableBuilder(
    column: $table.esFavorito,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> financeTemplatesRefs(
    Expression<bool> Function($$FinanceTemplatesTableFilterComposer f) f,
  ) {
    final $$FinanceTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.financeTemplates,
      getReferencedColumn: (t) => t.libroId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.financeTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FinanceAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinanceAccountsTable> {
  $$FinanceAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icono => $composableBuilder(
    column: $table.icono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get saldoInicial => $composableBuilder(
    column: $table.saldoInicial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activa => $composableBuilder(
    column: $table.activa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get esFavorito => $composableBuilder(
    column: $table.esFavorito,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FinanceAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinanceAccountsTable> {
  $$FinanceAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get icono =>
      $composableBuilder(column: $table.icono, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<double> get saldoInicial => $composableBuilder(
    column: $table.saldoInicial,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activa =>
      $composableBuilder(column: $table.activa, builder: (column) => column);

  GeneratedColumn<String> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);

  GeneratedColumn<bool> get esFavorito => $composableBuilder(
    column: $table.esFavorito,
    builder: (column) => column,
  );

  Expression<T> financeTemplatesRefs<T extends Object>(
    Expression<T> Function($$FinanceTemplatesTableAnnotationComposer a) f,
  ) {
    final $$FinanceTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.financeTemplates,
      getReferencedColumn: (t) => t.libroId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.financeTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FinanceAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinanceAccountsTable,
          FinanceAccountRow,
          $$FinanceAccountsTableFilterComposer,
          $$FinanceAccountsTableOrderingComposer,
          $$FinanceAccountsTableAnnotationComposer,
          $$FinanceAccountsTableCreateCompanionBuilder,
          $$FinanceAccountsTableUpdateCompanionBuilder,
          (FinanceAccountRow, $$FinanceAccountsTableReferences),
          FinanceAccountRow,
          PrefetchHooks Function({bool financeTemplatesRefs})
        > {
  $$FinanceAccountsTableTableManager(
    _$AppDatabase db,
    $FinanceAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinanceAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinanceAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinanceAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> icono = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<double> saldoInicial = const Value.absent(),
                Value<bool> activa = const Value.absent(),
                Value<String> orden = const Value.absent(),
                Value<bool> esFavorito = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinanceAccountsCompanion(
                id: id,
                nombre: nombre,
                tipo: tipo,
                icono: icono,
                color: color,
                saldoInicial: saldoInicial,
                activa: activa,
                orden: orden,
                esFavorito: esFavorito,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                required String tipo,
                required String icono,
                required String color,
                Value<double> saldoInicial = const Value.absent(),
                Value<bool> activa = const Value.absent(),
                Value<String> orden = const Value.absent(),
                Value<bool> esFavorito = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinanceAccountsCompanion.insert(
                id: id,
                nombre: nombre,
                tipo: tipo,
                icono: icono,
                color: color,
                saldoInicial: saldoInicial,
                activa: activa,
                orden: orden,
                esFavorito: esFavorito,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FinanceAccountsTable, FinanceAccountRow>(table),
                  $$FinanceAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({financeTemplatesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (financeTemplatesRefs) db.financeTemplates,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (financeTemplatesRefs)
                    await $_getPrefetchedData<
                      FinanceAccountRow,
                      $FinanceAccountsTable,
                      FinanceTemplateRow
                    >(
                      currentTable: table,
                      referencedTable: $$FinanceAccountsTableReferences
                          ._financeTemplatesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FinanceAccountsTableReferences(
                            db,
                            table,
                            p0,
                          ).financeTemplatesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.libroId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FinanceAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinanceAccountsTable,
      FinanceAccountRow,
      $$FinanceAccountsTableFilterComposer,
      $$FinanceAccountsTableOrderingComposer,
      $$FinanceAccountsTableAnnotationComposer,
      $$FinanceAccountsTableCreateCompanionBuilder,
      $$FinanceAccountsTableUpdateCompanionBuilder,
      (FinanceAccountRow, $$FinanceAccountsTableReferences),
      FinanceAccountRow,
      PrefetchHooks Function({bool financeTemplatesRefs})
    >;
typedef $$FinanceCategoriesTableCreateCompanionBuilder =
    FinanceCategoriesCompanion Function({
      required String id,
      required String nombre,
      required String icono,
      required String color,
      required String tipo,
      Value<bool> archivada,
      Value<String?> parentId,
      Value<int> rowid,
    });
typedef $$FinanceCategoriesTableUpdateCompanionBuilder =
    FinanceCategoriesCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<String> icono,
      Value<String> color,
      Value<String> tipo,
      Value<bool> archivada,
      Value<String?> parentId,
      Value<int> rowid,
    });

final class $$FinanceCategoriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FinanceCategoriesTable,
          FinanceCategoryRow
        > {
  $$FinanceCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FinanceCategoriesTable _parentIdTable(_$AppDatabase db) => db
      .financeCategories
      .createAlias('finance_categories__parent_id__finance_categories__id');

  $$FinanceCategoriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$FinanceCategoriesTableTableManager(
      $_db,
      $_db.financeCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FinanceCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $FinanceCategoriesTable> {
  $$FinanceCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icono => $composableBuilder(
    column: $table.icono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archivada => $composableBuilder(
    column: $table.archivada,
    builder: (column) => ColumnFilters(column),
  );

  $$FinanceCategoriesTableFilterComposer get parentId {
    final $$FinanceCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.financeCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.financeCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinanceCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FinanceCategoriesTable> {
  $$FinanceCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icono => $composableBuilder(
    column: $table.icono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archivada => $composableBuilder(
    column: $table.archivada,
    builder: (column) => ColumnOrderings(column),
  );

  $$FinanceCategoriesTableOrderingComposer get parentId {
    final $$FinanceCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.financeCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.financeCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinanceCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinanceCategoriesTable> {
  $$FinanceCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get icono =>
      $composableBuilder(column: $table.icono, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<bool> get archivada =>
      $composableBuilder(column: $table.archivada, builder: (column) => column);

  $$FinanceCategoriesTableAnnotationComposer get parentId {
    final $$FinanceCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.parentId,
          referencedTable: $db.financeCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinanceCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.financeCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$FinanceCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinanceCategoriesTable,
          FinanceCategoryRow,
          $$FinanceCategoriesTableFilterComposer,
          $$FinanceCategoriesTableOrderingComposer,
          $$FinanceCategoriesTableAnnotationComposer,
          $$FinanceCategoriesTableCreateCompanionBuilder,
          $$FinanceCategoriesTableUpdateCompanionBuilder,
          (FinanceCategoryRow, $$FinanceCategoriesTableReferences),
          FinanceCategoryRow,
          PrefetchHooks Function({bool parentId})
        > {
  $$FinanceCategoriesTableTableManager(
    _$AppDatabase db,
    $FinanceCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinanceCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinanceCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinanceCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> icono = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<bool> archivada = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinanceCategoriesCompanion(
                id: id,
                nombre: nombre,
                icono: icono,
                color: color,
                tipo: tipo,
                archivada: archivada,
                parentId: parentId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                required String icono,
                required String color,
                required String tipo,
                Value<bool> archivada = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinanceCategoriesCompanion.insert(
                id: id,
                nombre: nombre,
                icono: icono,
                color: color,
                tipo: tipo,
                archivada: archivada,
                parentId: parentId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FinanceCategoriesTable, FinanceCategoryRow>(
                    table,
                  ),
                  $$FinanceCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({parentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (parentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.parentId,
                                referencedTable:
                                    $$FinanceCategoriesTableReferences
                                        ._parentIdTable(db),
                                referencedColumn:
                                    $$FinanceCategoriesTableReferences
                                        ._parentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FinanceCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinanceCategoriesTable,
      FinanceCategoryRow,
      $$FinanceCategoriesTableFilterComposer,
      $$FinanceCategoriesTableOrderingComposer,
      $$FinanceCategoriesTableAnnotationComposer,
      $$FinanceCategoriesTableCreateCompanionBuilder,
      $$FinanceCategoriesTableUpdateCompanionBuilder,
      (FinanceCategoryRow, $$FinanceCategoriesTableReferences),
      FinanceCategoryRow,
      PrefetchHooks Function({bool parentId})
    >;
typedef $$FinanceTransactionsTableCreateCompanionBuilder =
    FinanceTransactionsCompanion Function({
      required String id,
      required String accountId,
      required String categoryId,
      required String tipo,
      required double monto,
      required String fecha,
      Value<String> nota,
      Value<bool> esRecurrente,
      Value<String?> recurrenciaConfig,
      Value<String?> personaSitio,
      Value<String?> hora,
      Value<String?> transferToAccountId,
      Value<int> rowid,
    });
typedef $$FinanceTransactionsTableUpdateCompanionBuilder =
    FinanceTransactionsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> categoryId,
      Value<String> tipo,
      Value<double> monto,
      Value<String> fecha,
      Value<String> nota,
      Value<bool> esRecurrente,
      Value<String?> recurrenciaConfig,
      Value<String?> personaSitio,
      Value<String?> hora,
      Value<String?> transferToAccountId,
      Value<int> rowid,
    });

final class $$FinanceTransactionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FinanceTransactionsTable,
          FinanceTransactionRow
        > {
  $$FinanceTransactionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FinanceAccountsTable _accountIdTable(_$AppDatabase db) => db
      .financeAccounts
      .createAlias('finance_transactions__account_id__finance_accounts__id');

  $$FinanceAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$FinanceAccountsTableTableManager(
      $_db,
      $_db.financeAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FinanceAccountsTable _transferToAccountIdTable(_$AppDatabase db) =>
      db.financeAccounts.createAlias(
        'finance_transactions__transfer_to_account_id__finance_accounts__id',
      );

  $$FinanceAccountsTableProcessedTableManager? get transferToAccountId {
    final $_column = $_itemColumn<String>('transfer_to_account_id');
    if ($_column == null) return null;
    final manager = $$FinanceAccountsTableTableManager(
      $_db,
      $_db.financeAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transferToAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FinanceTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $FinanceTransactionsTable> {
  $$FinanceTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nota => $composableBuilder(
    column: $table.nota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get esRecurrente => $composableBuilder(
    column: $table.esRecurrente,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenciaConfig => $composableBuilder(
    column: $table.recurrenciaConfig,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personaSitio => $composableBuilder(
    column: $table.personaSitio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hora => $composableBuilder(
    column: $table.hora,
    builder: (column) => ColumnFilters(column),
  );

  $$FinanceAccountsTableFilterComposer get accountId {
    final $$FinanceAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.financeAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceAccountsTableFilterComposer(
            $db: $db,
            $table: $db.financeAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinanceAccountsTableFilterComposer get transferToAccountId {
    final $$FinanceAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transferToAccountId,
      referencedTable: $db.financeAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceAccountsTableFilterComposer(
            $db: $db,
            $table: $db.financeAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinanceTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinanceTransactionsTable> {
  $$FinanceTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nota => $composableBuilder(
    column: $table.nota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get esRecurrente => $composableBuilder(
    column: $table.esRecurrente,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenciaConfig => $composableBuilder(
    column: $table.recurrenciaConfig,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personaSitio => $composableBuilder(
    column: $table.personaSitio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hora => $composableBuilder(
    column: $table.hora,
    builder: (column) => ColumnOrderings(column),
  );

  $$FinanceAccountsTableOrderingComposer get accountId {
    final $$FinanceAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.financeAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.financeAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinanceAccountsTableOrderingComposer get transferToAccountId {
    final $$FinanceAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transferToAccountId,
      referencedTable: $db.financeAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.financeAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinanceTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinanceTransactionsTable> {
  $$FinanceTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get nota =>
      $composableBuilder(column: $table.nota, builder: (column) => column);

  GeneratedColumn<bool> get esRecurrente => $composableBuilder(
    column: $table.esRecurrente,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenciaConfig => $composableBuilder(
    column: $table.recurrenciaConfig,
    builder: (column) => column,
  );

  GeneratedColumn<String> get personaSitio => $composableBuilder(
    column: $table.personaSitio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hora =>
      $composableBuilder(column: $table.hora, builder: (column) => column);

  $$FinanceAccountsTableAnnotationComposer get accountId {
    final $$FinanceAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.financeAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.financeAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinanceAccountsTableAnnotationComposer get transferToAccountId {
    final $$FinanceAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transferToAccountId,
      referencedTable: $db.financeAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.financeAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinanceTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinanceTransactionsTable,
          FinanceTransactionRow,
          $$FinanceTransactionsTableFilterComposer,
          $$FinanceTransactionsTableOrderingComposer,
          $$FinanceTransactionsTableAnnotationComposer,
          $$FinanceTransactionsTableCreateCompanionBuilder,
          $$FinanceTransactionsTableUpdateCompanionBuilder,
          (FinanceTransactionRow, $$FinanceTransactionsTableReferences),
          FinanceTransactionRow,
          PrefetchHooks Function({bool accountId, bool transferToAccountId})
        > {
  $$FinanceTransactionsTableTableManager(
    _$AppDatabase db,
    $FinanceTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinanceTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinanceTransactionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FinanceTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<String> fecha = const Value.absent(),
                Value<String> nota = const Value.absent(),
                Value<bool> esRecurrente = const Value.absent(),
                Value<String?> recurrenciaConfig = const Value.absent(),
                Value<String?> personaSitio = const Value.absent(),
                Value<String?> hora = const Value.absent(),
                Value<String?> transferToAccountId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinanceTransactionsCompanion(
                id: id,
                accountId: accountId,
                categoryId: categoryId,
                tipo: tipo,
                monto: monto,
                fecha: fecha,
                nota: nota,
                esRecurrente: esRecurrente,
                recurrenciaConfig: recurrenciaConfig,
                personaSitio: personaSitio,
                hora: hora,
                transferToAccountId: transferToAccountId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String categoryId,
                required String tipo,
                required double monto,
                required String fecha,
                Value<String> nota = const Value.absent(),
                Value<bool> esRecurrente = const Value.absent(),
                Value<String?> recurrenciaConfig = const Value.absent(),
                Value<String?> personaSitio = const Value.absent(),
                Value<String?> hora = const Value.absent(),
                Value<String?> transferToAccountId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinanceTransactionsCompanion.insert(
                id: id,
                accountId: accountId,
                categoryId: categoryId,
                tipo: tipo,
                monto: monto,
                fecha: fecha,
                nota: nota,
                esRecurrente: esRecurrente,
                recurrenciaConfig: recurrenciaConfig,
                personaSitio: personaSitio,
                hora: hora,
                transferToAccountId: transferToAccountId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FinanceTransactionsTable, FinanceTransactionRow>(
                    table,
                  ),
                  $$FinanceTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({accountId = false, transferToAccountId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (accountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.accountId,
                                    referencedTable:
                                        $$FinanceTransactionsTableReferences
                                            ._accountIdTable(db),
                                    referencedColumn:
                                        $$FinanceTransactionsTableReferences
                                            ._accountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (transferToAccountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.transferToAccountId,
                                    referencedTable:
                                        $$FinanceTransactionsTableReferences
                                            ._transferToAccountIdTable(db),
                                    referencedColumn:
                                        $$FinanceTransactionsTableReferences
                                            ._transferToAccountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$FinanceTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinanceTransactionsTable,
      FinanceTransactionRow,
      $$FinanceTransactionsTableFilterComposer,
      $$FinanceTransactionsTableOrderingComposer,
      $$FinanceTransactionsTableAnnotationComposer,
      $$FinanceTransactionsTableCreateCompanionBuilder,
      $$FinanceTransactionsTableUpdateCompanionBuilder,
      (FinanceTransactionRow, $$FinanceTransactionsTableReferences),
      FinanceTransactionRow,
      PrefetchHooks Function({bool accountId, bool transferToAccountId})
    >;
typedef $$FinanceBudgetsTableCreateCompanionBuilder =
    FinanceBudgetsCompanion Function({
      Value<int> rowId,
      required String categoryId,
      required int anio,
      required int mes,
      required double montoLimite,
    });
typedef $$FinanceBudgetsTableUpdateCompanionBuilder =
    FinanceBudgetsCompanion Function({
      Value<int> rowId,
      Value<String> categoryId,
      Value<int> anio,
      Value<int> mes,
      Value<double> montoLimite,
    });

class $$FinanceBudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $FinanceBudgetsTable> {
  $$FinanceBudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anio => $composableBuilder(
    column: $table.anio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mes => $composableBuilder(
    column: $table.mes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get montoLimite => $composableBuilder(
    column: $table.montoLimite,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FinanceBudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinanceBudgetsTable> {
  $$FinanceBudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anio => $composableBuilder(
    column: $table.anio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mes => $composableBuilder(
    column: $table.mes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get montoLimite => $composableBuilder(
    column: $table.montoLimite,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FinanceBudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinanceBudgetsTable> {
  $$FinanceBudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get anio =>
      $composableBuilder(column: $table.anio, builder: (column) => column);

  GeneratedColumn<int> get mes =>
      $composableBuilder(column: $table.mes, builder: (column) => column);

  GeneratedColumn<double> get montoLimite => $composableBuilder(
    column: $table.montoLimite,
    builder: (column) => column,
  );
}

class $$FinanceBudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinanceBudgetsTable,
          FinanceBudgetRow,
          $$FinanceBudgetsTableFilterComposer,
          $$FinanceBudgetsTableOrderingComposer,
          $$FinanceBudgetsTableAnnotationComposer,
          $$FinanceBudgetsTableCreateCompanionBuilder,
          $$FinanceBudgetsTableUpdateCompanionBuilder,
          (
            FinanceBudgetRow,
            BaseReferences<
              _$AppDatabase,
              $FinanceBudgetsTable,
              FinanceBudgetRow
            >,
          ),
          FinanceBudgetRow,
          PrefetchHooks Function()
        > {
  $$FinanceBudgetsTableTableManager(
    _$AppDatabase db,
    $FinanceBudgetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinanceBudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinanceBudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinanceBudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> anio = const Value.absent(),
                Value<int> mes = const Value.absent(),
                Value<double> montoLimite = const Value.absent(),
              }) => FinanceBudgetsCompanion(
                rowId: rowId,
                categoryId: categoryId,
                anio: anio,
                mes: mes,
                montoLimite: montoLimite,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String categoryId,
                required int anio,
                required int mes,
                required double montoLimite,
              }) => FinanceBudgetsCompanion.insert(
                rowId: rowId,
                categoryId: categoryId,
                anio: anio,
                mes: mes,
                montoLimite: montoLimite,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FinanceBudgetsTable, FinanceBudgetRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FinanceBudgetsTable,
                    FinanceBudgetRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FinanceBudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinanceBudgetsTable,
      FinanceBudgetRow,
      $$FinanceBudgetsTableFilterComposer,
      $$FinanceBudgetsTableOrderingComposer,
      $$FinanceBudgetsTableAnnotationComposer,
      $$FinanceBudgetsTableCreateCompanionBuilder,
      $$FinanceBudgetsTableUpdateCompanionBuilder,
      (
        FinanceBudgetRow,
        BaseReferences<_$AppDatabase, $FinanceBudgetsTable, FinanceBudgetRow>,
      ),
      FinanceBudgetRow,
      PrefetchHooks Function()
    >;
typedef $$FinancePlacesTableCreateCompanionBuilder =
    FinancePlacesCompanion Function({
      required String id,
      required String nombre,
      Value<int> usados,
      Value<int> rowid,
    });
typedef $$FinancePlacesTableUpdateCompanionBuilder =
    FinancePlacesCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<int> usados,
      Value<int> rowid,
    });

class $$FinancePlacesTableFilterComposer
    extends Composer<_$AppDatabase, $FinancePlacesTable> {
  $$FinancePlacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usados => $composableBuilder(
    column: $table.usados,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FinancePlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancePlacesTable> {
  $$FinancePlacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usados => $composableBuilder(
    column: $table.usados,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FinancePlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancePlacesTable> {
  $$FinancePlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<int> get usados =>
      $composableBuilder(column: $table.usados, builder: (column) => column);
}

class $$FinancePlacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinancePlacesTable,
          FinancePlaceRow,
          $$FinancePlacesTableFilterComposer,
          $$FinancePlacesTableOrderingComposer,
          $$FinancePlacesTableAnnotationComposer,
          $$FinancePlacesTableCreateCompanionBuilder,
          $$FinancePlacesTableUpdateCompanionBuilder,
          (
            FinancePlaceRow,
            BaseReferences<_$AppDatabase, $FinancePlacesTable, FinancePlaceRow>,
          ),
          FinancePlaceRow,
          PrefetchHooks Function()
        > {
  $$FinancePlacesTableTableManager(_$AppDatabase db, $FinancePlacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancePlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinancePlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinancePlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<int> usados = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinancePlacesCompanion(
                id: id,
                nombre: nombre,
                usados: usados,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                Value<int> usados = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinancePlacesCompanion.insert(
                id: id,
                nombre: nombre,
                usados: usados,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FinancePlacesTable, FinancePlaceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FinancePlacesTable,
                    FinancePlaceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FinancePlacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinancePlacesTable,
      FinancePlaceRow,
      $$FinancePlacesTableFilterComposer,
      $$FinancePlacesTableOrderingComposer,
      $$FinancePlacesTableAnnotationComposer,
      $$FinancePlacesTableCreateCompanionBuilder,
      $$FinancePlacesTableUpdateCompanionBuilder,
      (
        FinancePlaceRow,
        BaseReferences<_$AppDatabase, $FinancePlacesTable, FinancePlaceRow>,
      ),
      FinancePlaceRow,
      PrefetchHooks Function()
    >;
typedef $$FinanceTemplatesTableCreateCompanionBuilder =
    FinanceTemplatesCompanion Function({
      required String id,
      required String nombre,
      Value<String?> libroId,
      required String categoryId,
      required String tipo,
      Value<double?> monto,
      Value<String?> personaSitio,
      Value<String?> nota,
      Value<int> rowid,
    });
typedef $$FinanceTemplatesTableUpdateCompanionBuilder =
    FinanceTemplatesCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<String?> libroId,
      Value<String> categoryId,
      Value<String> tipo,
      Value<double?> monto,
      Value<String?> personaSitio,
      Value<String?> nota,
      Value<int> rowid,
    });

final class $$FinanceTemplatesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FinanceTemplatesTable,
          FinanceTemplateRow
        > {
  $$FinanceTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FinanceAccountsTable _libroIdTable(_$AppDatabase db) => db
      .financeAccounts
      .createAlias('finance_templates__libro_id__finance_accounts__id');

  $$FinanceAccountsTableProcessedTableManager? get libroId {
    final $_column = $_itemColumn<String>('libro_id');
    if ($_column == null) return null;
    final manager = $$FinanceAccountsTableTableManager(
      $_db,
      $_db.financeAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_libroIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FinanceTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $FinanceTemplatesTable> {
  $$FinanceTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personaSitio => $composableBuilder(
    column: $table.personaSitio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nota => $composableBuilder(
    column: $table.nota,
    builder: (column) => ColumnFilters(column),
  );

  $$FinanceAccountsTableFilterComposer get libroId {
    final $$FinanceAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libroId,
      referencedTable: $db.financeAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceAccountsTableFilterComposer(
            $db: $db,
            $table: $db.financeAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinanceTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $FinanceTemplatesTable> {
  $$FinanceTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personaSitio => $composableBuilder(
    column: $table.personaSitio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nota => $composableBuilder(
    column: $table.nota,
    builder: (column) => ColumnOrderings(column),
  );

  $$FinanceAccountsTableOrderingComposer get libroId {
    final $$FinanceAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libroId,
      referencedTable: $db.financeAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.financeAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinanceTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinanceTemplatesTable> {
  $$FinanceTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get personaSitio => $composableBuilder(
    column: $table.personaSitio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nota =>
      $composableBuilder(column: $table.nota, builder: (column) => column);

  $$FinanceAccountsTableAnnotationComposer get libroId {
    final $$FinanceAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libroId,
      referencedTable: $db.financeAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.financeAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinanceTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinanceTemplatesTable,
          FinanceTemplateRow,
          $$FinanceTemplatesTableFilterComposer,
          $$FinanceTemplatesTableOrderingComposer,
          $$FinanceTemplatesTableAnnotationComposer,
          $$FinanceTemplatesTableCreateCompanionBuilder,
          $$FinanceTemplatesTableUpdateCompanionBuilder,
          (FinanceTemplateRow, $$FinanceTemplatesTableReferences),
          FinanceTemplateRow,
          PrefetchHooks Function({bool libroId})
        > {
  $$FinanceTemplatesTableTableManager(
    _$AppDatabase db,
    $FinanceTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinanceTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinanceTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinanceTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> libroId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<double?> monto = const Value.absent(),
                Value<String?> personaSitio = const Value.absent(),
                Value<String?> nota = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinanceTemplatesCompanion(
                id: id,
                nombre: nombre,
                libroId: libroId,
                categoryId: categoryId,
                tipo: tipo,
                monto: monto,
                personaSitio: personaSitio,
                nota: nota,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                Value<String?> libroId = const Value.absent(),
                required String categoryId,
                required String tipo,
                Value<double?> monto = const Value.absent(),
                Value<String?> personaSitio = const Value.absent(),
                Value<String?> nota = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinanceTemplatesCompanion.insert(
                id: id,
                nombre: nombre,
                libroId: libroId,
                categoryId: categoryId,
                tipo: tipo,
                monto: monto,
                personaSitio: personaSitio,
                nota: nota,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FinanceTemplatesTable, FinanceTemplateRow>(
                    table,
                  ),
                  $$FinanceTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({libroId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (libroId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.libroId,
                                referencedTable:
                                    $$FinanceTemplatesTableReferences
                                        ._libroIdTable(db),
                                referencedColumn:
                                    $$FinanceTemplatesTableReferences
                                        ._libroIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FinanceTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinanceTemplatesTable,
      FinanceTemplateRow,
      $$FinanceTemplatesTableFilterComposer,
      $$FinanceTemplatesTableOrderingComposer,
      $$FinanceTemplatesTableAnnotationComposer,
      $$FinanceTemplatesTableCreateCompanionBuilder,
      $$FinanceTemplatesTableUpdateCompanionBuilder,
      (FinanceTemplateRow, $$FinanceTemplatesTableReferences),
      FinanceTemplateRow,
      PrefetchHooks Function({bool libroId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CommercialQuotasTableTableManager get commercialQuotas =>
      $$CommercialQuotasTableTableManager(_db, _db.commercialQuotas);
  $$CreditsTableTableManager get credits =>
      $$CreditsTableTableManager(_db, _db.credits);
  $$InstallmentsTableTableManager get installments =>
      $$InstallmentsTableTableManager(_db, _db.installments);
  $$CardMovementsTableTableManager get cardMovements =>
      $$CardMovementsTableTableManager(_db, _db.cardMovements);
  $$LoanAbonosTableTableManager get loanAbonos =>
      $$LoanAbonosTableTableManager(_db, _db.loanAbonos);
  $$PagosRealizadosTableTableManager get pagosRealizados =>
      $$PagosRealizadosTableTableManager(_db, _db.pagosRealizados);
  $$FinanceAccountsTableTableManager get financeAccounts =>
      $$FinanceAccountsTableTableManager(_db, _db.financeAccounts);
  $$FinanceCategoriesTableTableManager get financeCategories =>
      $$FinanceCategoriesTableTableManager(_db, _db.financeCategories);
  $$FinanceTransactionsTableTableManager get financeTransactions =>
      $$FinanceTransactionsTableTableManager(_db, _db.financeTransactions);
  $$FinanceBudgetsTableTableManager get financeBudgets =>
      $$FinanceBudgetsTableTableManager(_db, _db.financeBudgets);
  $$FinancePlacesTableTableManager get financePlaces =>
      $$FinancePlacesTableTableManager(_db, _db.financePlaces);
  $$FinanceTemplatesTableTableManager get financeTemplates =>
      $$FinanceTemplatesTableTableManager(_db, _db.financeTemplates);
}
