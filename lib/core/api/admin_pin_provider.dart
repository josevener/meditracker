import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/core/api/api_client.dart';
import 'package:medtrack_mobile/services/system_service.dart';

final systemServiceProvider = Provider((ref) => SystemService(ref.watch(apiClientProvider)));

final adminAuthProvider = StateProvider<bool>((ref) => false);
