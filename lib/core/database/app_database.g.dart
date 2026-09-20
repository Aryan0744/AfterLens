// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MoodTag, int> moodTag =
      GeneratedColumn<int>(
        'mood_tag',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<MoodTag>($TransactionsTable.$convertermoodTag);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amount,
    description,
    moodTag,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      moodTag: $TransactionsTable.$convertermoodTag.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}mood_tag'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MoodTag, int, int> $convertermoodTag =
      const EnumIndexConverter<MoodTag>(MoodTag.values);
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final double amount;
  final String description;
  final MoodTag moodTag;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Transaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.moodTag,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['amount'] = Variable<double>(amount);
    map['description'] = Variable<String>(description);
    {
      map['mood_tag'] = Variable<int>(
        $TransactionsTable.$convertermoodTag.toSql(moodTag),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      amount: Value(amount),
      description: Value(description),
      moodTag: Value(moodTag),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      description: serializer.fromJson<String>(json['description']),
      moodTag: $TransactionsTable.$convertermoodTag.fromJson(
        serializer.fromJson<int>(json['moodTag']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'amount': serializer.toJson<double>(amount),
      'description': serializer.toJson<String>(description),
      'moodTag': serializer.toJson<int>(
        $TransactionsTable.$convertermoodTag.toJson(moodTag),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Transaction copyWith({
    String? id,
    double? amount,
    String? description,
    MoodTag? moodTag,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Transaction(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    description: description ?? this.description,
    moodTag: moodTag ?? this.moodTag,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      description: data.description.present
          ? data.description.value
          : this.description,
      moodTag: data.moodTag.present ? data.moodTag.value : this.moodTag,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('moodTag: $moodTag, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, amount, description, moodTag, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.description == this.description &&
          other.moodTag == this.moodTag &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<double> amount;
  final Value<String> description;
  final Value<MoodTag> moodTag;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.description = const Value.absent(),
    this.moodTag = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required double amount,
    required String description,
    required MoodTag moodTag,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       amount = Value(amount),
       description = Value(description),
       moodTag = Value(moodTag);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<double>? amount,
    Expression<String>? description,
    Expression<int>? moodTag,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (moodTag != null) 'mood_tag': moodTag,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<double>? amount,
    Value<String>? description,
    Value<MoodTag>? moodTag,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      moodTag: moodTag ?? this.moodTag,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (moodTag.present) {
      map['mood_tag'] = Variable<int>(
        $TransactionsTable.$convertermoodTag.toSql(moodTag.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('moodTag: $moodTag, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RegretCheckinsTable extends RegretCheckins
    with TableInfo<$RegretCheckinsTable, RegretCheckin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RegretCheckinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transactions (id)',
    ),
  );
  static const VerificationMeta _promptedAtMeta = const VerificationMeta(
    'promptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> promptedAt = GeneratedColumn<DateTime>(
    'prompted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta(
    'answeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> answeredAt = GeneratedColumn<DateTime>(
    'answered_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wasWorthItMeta = const VerificationMeta(
    'wasWorthIt',
  );
  @override
  late final GeneratedColumn<bool> wasWorthIt = GeneratedColumn<bool>(
    'was_worth_it',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_worth_it" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    promptedAt,
    answeredAt,
    wasWorthIt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'regret_checkins';
  @override
  VerificationContext validateIntegrity(
    Insertable<RegretCheckin> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('prompted_at')) {
      context.handle(
        _promptedAtMeta,
        promptedAt.isAcceptableOrUnknown(data['prompted_at']!, _promptedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_promptedAtMeta);
    }
    if (data.containsKey('answered_at')) {
      context.handle(
        _answeredAtMeta,
        answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta),
      );
    }
    if (data.containsKey('was_worth_it')) {
      context.handle(
        _wasWorthItMeta,
        wasWorthIt.isAcceptableOrUnknown(
          data['was_worth_it']!,
          _wasWorthItMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RegretCheckin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RegretCheckin(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      promptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}prompted_at'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}answered_at'],
      ),
      wasWorthIt: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_worth_it'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RegretCheckinsTable createAlias(String alias) {
    return $RegretCheckinsTable(attachedDatabase, alias);
  }
}

class RegretCheckin extends DataClass implements Insertable<RegretCheckin> {
  final String id;
  final String transactionId;
  final DateTime promptedAt;
  final DateTime? answeredAt;
  final bool? wasWorthIt;
  final DateTime updatedAt;
  const RegretCheckin({
    required this.id,
    required this.transactionId,
    required this.promptedAt,
    this.answeredAt,
    this.wasWorthIt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['prompted_at'] = Variable<DateTime>(promptedAt);
    if (!nullToAbsent || answeredAt != null) {
      map['answered_at'] = Variable<DateTime>(answeredAt);
    }
    if (!nullToAbsent || wasWorthIt != null) {
      map['was_worth_it'] = Variable<bool>(wasWorthIt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RegretCheckinsCompanion toCompanion(bool nullToAbsent) {
    return RegretCheckinsCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      promptedAt: Value(promptedAt),
      answeredAt: answeredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(answeredAt),
      wasWorthIt: wasWorthIt == null && nullToAbsent
          ? const Value.absent()
          : Value(wasWorthIt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RegretCheckin.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RegretCheckin(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      promptedAt: serializer.fromJson<DateTime>(json['promptedAt']),
      answeredAt: serializer.fromJson<DateTime?>(json['answeredAt']),
      wasWorthIt: serializer.fromJson<bool?>(json['wasWorthIt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'promptedAt': serializer.toJson<DateTime>(promptedAt),
      'answeredAt': serializer.toJson<DateTime?>(answeredAt),
      'wasWorthIt': serializer.toJson<bool?>(wasWorthIt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RegretCheckin copyWith({
    String? id,
    String? transactionId,
    DateTime? promptedAt,
    Value<DateTime?> answeredAt = const Value.absent(),
    Value<bool?> wasWorthIt = const Value.absent(),
    DateTime? updatedAt,
  }) => RegretCheckin(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    promptedAt: promptedAt ?? this.promptedAt,
    answeredAt: answeredAt.present ? answeredAt.value : this.answeredAt,
    wasWorthIt: wasWorthIt.present ? wasWorthIt.value : this.wasWorthIt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RegretCheckin copyWithCompanion(RegretCheckinsCompanion data) {
    return RegretCheckin(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      promptedAt: data.promptedAt.present
          ? data.promptedAt.value
          : this.promptedAt,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
      wasWorthIt: data.wasWorthIt.present
          ? data.wasWorthIt.value
          : this.wasWorthIt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RegretCheckin(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('promptedAt: $promptedAt, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('wasWorthIt: $wasWorthIt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionId,
    promptedAt,
    answeredAt,
    wasWorthIt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RegretCheckin &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.promptedAt == this.promptedAt &&
          other.answeredAt == this.answeredAt &&
          other.wasWorthIt == this.wasWorthIt &&
          other.updatedAt == this.updatedAt);
}

class RegretCheckinsCompanion extends UpdateCompanion<RegretCheckin> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<DateTime> promptedAt;
  final Value<DateTime?> answeredAt;
  final Value<bool?> wasWorthIt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RegretCheckinsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.promptedAt = const Value.absent(),
    this.answeredAt = const Value.absent(),
    this.wasWorthIt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RegretCheckinsCompanion.insert({
    required String id,
    required String transactionId,
    required DateTime promptedAt,
    this.answeredAt = const Value.absent(),
    this.wasWorthIt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionId = Value(transactionId),
       promptedAt = Value(promptedAt);
  static Insertable<RegretCheckin> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<DateTime>? promptedAt,
    Expression<DateTime>? answeredAt,
    Expression<bool>? wasWorthIt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (promptedAt != null) 'prompted_at': promptedAt,
      if (answeredAt != null) 'answered_at': answeredAt,
      if (wasWorthIt != null) 'was_worth_it': wasWorthIt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RegretCheckinsCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionId,
    Value<DateTime>? promptedAt,
    Value<DateTime?>? answeredAt,
    Value<bool?>? wasWorthIt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RegretCheckinsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      promptedAt: promptedAt ?? this.promptedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      wasWorthIt: wasWorthIt ?? this.wasWorthIt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (promptedAt.present) {
      map['prompted_at'] = Variable<DateTime>(promptedAt.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<DateTime>(answeredAt.value);
    }
    if (wasWorthIt.present) {
      map['was_worth_it'] = Variable<bool>(wasWorthIt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RegretCheckinsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('promptedAt: $promptedAt, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('wasWorthIt: $wasWorthIt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $RegretCheckinsTable regretCheckins = $RegretCheckinsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactions,
    regretCheckins,
  ];
}

typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required double amount,
      required String description,
      required MoodTag moodTag,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<double> amount,
      Value<String> description,
      Value<MoodTag> moodTag,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RegretCheckinsTable, List<RegretCheckin>>
  _regretCheckinsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.regretCheckins,
    aliasName: 'transactions__id__regret_checkins__transaction_id',
  );

  $$RegretCheckinsTableProcessedTableManager get regretCheckinsRefs {
    final manager = $$RegretCheckinsTableTableManager(
      $_db,
      $_db.regretCheckins,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_regretCheckinsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
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

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MoodTag, MoodTag, int> get moodTag =>
      $composableBuilder(
        column: $table.moodTag,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> regretCheckinsRefs(
    Expression<bool> Function($$RegretCheckinsTableFilterComposer f) f,
  ) {
    final $$RegretCheckinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.regretCheckins,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RegretCheckinsTableFilterComposer(
            $db: $db,
            $table: $db.regretCheckins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
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

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get moodTag => $composableBuilder(
    column: $table.moodTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MoodTag, int> get moodTag =>
      $composableBuilder(column: $table.moodTag, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> regretCheckinsRefs<T extends Object>(
    Expression<T> Function($$RegretCheckinsTableAnnotationComposer a) f,
  ) {
    final $$RegretCheckinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.regretCheckins,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RegretCheckinsTableAnnotationComposer(
            $db: $db,
            $table: $db.regretCheckins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (Transaction, $$TransactionsTableReferences),
          Transaction,
          PrefetchHooks Function({bool regretCheckinsRefs})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<MoodTag> moodTag = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                amount: amount,
                description: description,
                moodTag: moodTag,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required double amount,
                required String description,
                required MoodTag moodTag,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                amount: amount,
                description: description,
                moodTag: moodTag,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, Transaction>(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({regretCheckinsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (regretCheckinsRefs) db.regretCheckins,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (regretCheckinsRefs)
                    await $_getPrefetchedData<
                      Transaction,
                      $TransactionsTable,
                      RegretCheckin
                    >(
                      currentTable: table,
                      referencedTable: $$TransactionsTableReferences
                          ._regretCheckinsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TransactionsTableReferences(
                            db,
                            table,
                            p0,
                          ).regretCheckinsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.transactionId == item.id,
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

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (Transaction, $$TransactionsTableReferences),
      Transaction,
      PrefetchHooks Function({bool regretCheckinsRefs})
    >;
typedef $$RegretCheckinsTableCreateCompanionBuilder =
    RegretCheckinsCompanion Function({
      required String id,
      required String transactionId,
      required DateTime promptedAt,
      Value<DateTime?> answeredAt,
      Value<bool?> wasWorthIt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$RegretCheckinsTableUpdateCompanionBuilder =
    RegretCheckinsCompanion Function({
      Value<String> id,
      Value<String> transactionId,
      Value<DateTime> promptedAt,
      Value<DateTime?> answeredAt,
      Value<bool?> wasWorthIt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$RegretCheckinsTableReferences
    extends BaseReferences<_$AppDatabase, $RegretCheckinsTable, RegretCheckin> {
  $$RegretCheckinsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) => db
      .transactions
      .createAlias('regret_checkins__transaction_id__transactions__id');

  $$TransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RegretCheckinsTableFilterComposer
    extends Composer<_$AppDatabase, $RegretCheckinsTable> {
  $$RegretCheckinsTableFilterComposer({
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

  ColumnFilters<DateTime> get promptedAt => $composableBuilder(
    column: $table.promptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasWorthIt => $composableBuilder(
    column: $table.wasWorthIt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RegretCheckinsTableOrderingComposer
    extends Composer<_$AppDatabase, $RegretCheckinsTable> {
  $$RegretCheckinsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get promptedAt => $composableBuilder(
    column: $table.promptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasWorthIt => $composableBuilder(
    column: $table.wasWorthIt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RegretCheckinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RegretCheckinsTable> {
  $$RegretCheckinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get promptedAt => $composableBuilder(
    column: $table.promptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wasWorthIt => $composableBuilder(
    column: $table.wasWorthIt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RegretCheckinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RegretCheckinsTable,
          RegretCheckin,
          $$RegretCheckinsTableFilterComposer,
          $$RegretCheckinsTableOrderingComposer,
          $$RegretCheckinsTableAnnotationComposer,
          $$RegretCheckinsTableCreateCompanionBuilder,
          $$RegretCheckinsTableUpdateCompanionBuilder,
          (RegretCheckin, $$RegretCheckinsTableReferences),
          RegretCheckin,
          PrefetchHooks Function({bool transactionId})
        > {
  $$RegretCheckinsTableTableManager(
    _$AppDatabase db,
    $RegretCheckinsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RegretCheckinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RegretCheckinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RegretCheckinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<DateTime> promptedAt = const Value.absent(),
                Value<DateTime?> answeredAt = const Value.absent(),
                Value<bool?> wasWorthIt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RegretCheckinsCompanion(
                id: id,
                transactionId: transactionId,
                promptedAt: promptedAt,
                answeredAt: answeredAt,
                wasWorthIt: wasWorthIt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionId,
                required DateTime promptedAt,
                Value<DateTime?> answeredAt = const Value.absent(),
                Value<bool?> wasWorthIt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RegretCheckinsCompanion.insert(
                id: id,
                transactionId: transactionId,
                promptedAt: promptedAt,
                answeredAt: answeredAt,
                wasWorthIt: wasWorthIt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RegretCheckinsTable, RegretCheckin>(table),
                  $$RegretCheckinsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false}) {
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
                    if (transactionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transactionId,
                        referencedTable: $$RegretCheckinsTableReferences
                            ._transactionIdTable(db),
                        referencedColumn: $$RegretCheckinsTableReferences
                            ._transactionIdTable(db)
                            .id,
                      ) as T;
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

typedef $$RegretCheckinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RegretCheckinsTable,
      RegretCheckin,
      $$RegretCheckinsTableFilterComposer,
      $$RegretCheckinsTableOrderingComposer,
      $$RegretCheckinsTableAnnotationComposer,
      $$RegretCheckinsTableCreateCompanionBuilder,
      $$RegretCheckinsTableUpdateCompanionBuilder,
      (RegretCheckin, $$RegretCheckinsTableReferences),
      RegretCheckin,
      PrefetchHooks Function({bool transactionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$RegretCheckinsTableTableManager get regretCheckins =>
      $$RegretCheckinsTableTableManager(_db, _db.regretCheckins);
}
