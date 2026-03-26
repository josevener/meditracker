import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/core/database/local_db.dart';

final databaseProvider = Provider((ref) => AppDatabase());
