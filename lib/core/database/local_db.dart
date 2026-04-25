import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'local_db.g.dart';

class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get remoteId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get dosage => text().nullable()();
  IntColumn get frequencyPerDay => integer()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

class Schedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get remoteId => integer().nullable()();
  IntColumn get medicationId => integer().references(Medications, #id)();
  TextColumn get timeOfDay => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

class IntakeLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get remoteId => integer().nullable()();
  IntColumn get medicationId => integer().references(Medications, #id)();
  TextColumn get scheduledTime => text()();
  TextColumn get takenAt => text().nullable()();
  TextColumn get date => text()();
  TextColumn get status => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

class DayTicks extends Table {
  TextColumn get date => text()();
  BoolColumn get isTicked => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {date};
}

@DriftDatabase(tables: [Medications, Schedules, IntakeLogs, AppSettings, DayTicks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.test(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 3) {
          // Add newer tables here
          await m.createTable(appSettings);
        }
        if (from < 4) {
          await m.createTable(dayTicks);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'medtrack.sqlite'));
    return NativeDatabase(file);
  });
}
