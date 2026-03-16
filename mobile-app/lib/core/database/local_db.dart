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

@DriftDatabase(tables: [Medications, Schedules, IntakeLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'medtrack.sqlite'));
    return NativeDatabase(file);
  });
}
