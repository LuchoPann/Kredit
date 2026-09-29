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
          ..write('earlyPaymentWaivesInterest: $earlyPaymentWaivesInterest')
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
          other.earlyPaymentWaivesInterest == this.earlyPaymentWaivesInterest);
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
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    creditId,
    date,
    type,
    amount,
    note,
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
  const CardMovementRow({
    required this.rowId,
    required this.creditId,
    required this.date,
    required this.type,
    required this.amount,
    required this.note,
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
    };
  }

  CardMovementRow copyWith({
    int? rowId,
    String? creditId,
    String? date,
    String? type,
    double? amount,
    String? note,
  }) => CardMovementRow(
    rowId: rowId ?? this.rowId,
    creditId: creditId ?? this.creditId,
    date: date ?? this.date,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    note: note ?? this.note,
  );
  CardMovementRow copyWithCompanion(CardMovementsCompanion data) {
    return CardMovementRow(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      creditId: data.creditId.present ? data.creditId.value : this.creditId,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      note: data.note.present ? data.note.value : this.note,
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
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, creditId, date, type, amount, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardMovementRow &&
          other.rowId == this.rowId &&
          other.creditId == this.creditId &&
          other.date == this.date &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.note == this.note);
}

class CardMovementsCompanion extends UpdateCompanion<CardMovementRow> {
  final Value<int> rowId;
  final Value<String> creditId;
  final Value<String> date;
  final Value<String> type;
  final Value<double> amount;
  final Value<String> note;
  const CardMovementsCompanion({
    this.rowId = const Value.absent(),
    this.creditId = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
  });
  CardMovementsCompanion.insert({
    this.rowId = const Value.absent(),
    required String creditId,
    required String date,
    required String type,
    required double amount,
    this.note = const Value.absent(),
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
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (creditId != null) 'credit_id': creditId,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (note != null) 'note': note,
    });
  }

  CardMovementsCompanion copyWith({
    Value<int>? rowId,
    Value<String>? creditId,
    Value<String>? date,
    Value<String>? type,
    Value<double>? amount,
    Value<String>? note,
  }) {
    return CardMovementsCompanion(
      rowId: rowId ?? this.rowId,
      creditId: creditId ?? this.creditId,
      date: date ?? this.date,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
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
          ..write('note: $note')
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
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (installmentsRefs) db.installments,
                    if (cardMovementsRefs) db.cardMovements,
                    if (loanAbonosRefs) db.loanAbonos,
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
    });
typedef $$CardMovementsTableUpdateCompanionBuilder =
    CardMovementsCompanion Function({
      Value<int> rowId,
      Value<String> creditId,
      Value<String> date,
      Value<String> type,
      Value<double> amount,
      Value<String> note,
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
              }) => CardMovementsCompanion(
                rowId: rowId,
                creditId: creditId,
                date: date,
                type: type,
                amount: amount,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String creditId,
                required String date,
                required String type,
                required double amount,
                Value<String> note = const Value.absent(),
              }) => CardMovementsCompanion.insert(
                rowId: rowId,
                creditId: creditId,
                date: date,
                type: type,
                amount: amount,
                note: note,
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
}
