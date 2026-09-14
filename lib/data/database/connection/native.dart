import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

DatabaseConnection connect() {
  return DatabaseConnection.delayed(
    Future.sync(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'reelhouse', 'reelhouse.sqlite'));
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      return NativeDatabase.createBackgroundConnection(file);
    }),
  );
}
