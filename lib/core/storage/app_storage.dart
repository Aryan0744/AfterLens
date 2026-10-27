import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _databaseFileName = 'afterlens.sqlite';

const _storageSecurityChannel = MethodChannel(
  'com.aryansanghvi.afterlens/storage_security',
);

File? _preparedDatabaseFile;

Future<void> prepareAppStorage() async {
  _preparedDatabaseFile = await _prepareDatabaseFile();
}

Future<File> getAppDatabaseFile() async {
  final prepared = _preparedDatabaseFile;

  if (prepared != null) {
    return prepared;
  }

  final file = await _prepareDatabaseFile();

  _preparedDatabaseFile = file;

  return file;
}

Future<File> _prepareDatabaseFile() async {
  if (!Platform.isIOS) {
    final documentsDirectory = await getApplicationDocumentsDirectory();

    return File(p.join(documentsDirectory.path, _databaseFileName));
  }

  final supportDirectory = await getApplicationSupportDirectory();

  final afterLensDirectory = Directory(
    p.join(supportDirectory.path, 'AfterLens'),
  );

  await afterLensDirectory.create(recursive: true);

  final targetDatabase = File(
    p.join(afterLensDirectory.path, _databaseFileName),
  );

  await _migrateLegacyIosDatabase(targetDatabase);

  await _excludeFromIosBackup(afterLensDirectory);

  return targetDatabase;
}

Future<void> _migrateLegacyIosDatabase(File targetDatabase) async {
  final documentsDirectory = await getApplicationDocumentsDirectory();

  final legacyDatabase = File(
    p.join(documentsDirectory.path, _databaseFileName),
  );

  if (!await legacyDatabase.exists()) {
    return;
  }

  await _moveDatabaseFamily(
    sourceBasePath: legacyDatabase.path,
    targetBasePath: targetDatabase.path,
  );
}

Future<void> _moveDatabaseFamily({
  required String sourceBasePath,
  required String targetBasePath,
}) async {
  const suffixes = <String>['', '-wal', '-shm'];

  for (final suffix in suffixes) {
    final source = File('$sourceBasePath$suffix');

    if (!await source.exists()) {
      continue;
    }

    final target = File('$targetBasePath$suffix');

    if (await target.exists()) {
      await source.delete();
      continue;
    }

    await _moveFile(source: source, target: target);
  }
}

Future<void> _moveFile({required File source, required File target}) async {
  try {
    await source.rename(target.path);
  } on FileSystemException {
    await source.copy(target.path);

    await source.delete();
  }
}

Future<void> _excludeFromIosBackup(Directory directory) async {
  if (!Platform.isIOS) {
    return;
  }

  await _storageSecurityChannel.invokeMethod<void>(
    'excludeFromBackup',
    <String, Object?>{'path': directory.path},
  );
}
