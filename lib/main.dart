import 'package:flutter/material.dart';

import 'core/theme/cinema_theme.dart';
import 'data/database/database.dart';
import 'data/platform/local_storage_manager_impl.dart';
import 'data/platform/storage_identity_service_impl.dart';
import 'domain/services/local_storage_manager.dart';
import 'domain/services/storage_identity_service.dart';
import 'presentation/shell/cinema_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final StorageIdentityService storageIdentityService =
      StorageIdentityServiceImpl();
  final LocalStorageManager localStorageManager = LocalStorageManagerImpl();

  runApp(
    ReelhouseApp(
      database: database,
      storageIdentityService: storageIdentityService,
      localStorageManager: localStorageManager,
    ),
  );
}

class ReelhouseApp extends StatelessWidget {
  final AppDatabase database;
  final StorageIdentityService storageIdentityService;
  final LocalStorageManager localStorageManager;

  const ReelhouseApp({
    super.key,
    required this.database,
    required this.storageIdentityService,
    required this.localStorageManager,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REELHOUSE',
      debugShowCheckedModeBanner: false,
      theme: CinemaTheme.darkTheme,
      home: CinemaShell(
        database: database,
        storageIdentityService: storageIdentityService,
        localStorageManager: localStorageManager,
      ),
    );
  }
}
