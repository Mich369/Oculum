import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'oculum_lite_save_files.dart';

Future<OculumLiteSaveFiles?> open() async {
  try {
    final support = await getApplicationSupportDirectory();
    return OculumLiteNativeSaveFiles(
      Directory.fromUri(support.uri.resolve('oculum_rl_saves/')),
    );
  } on MissingPluginException {
    return null;
  }
}

class OculumLiteNativeSaveFiles implements OculumLiteSaveFiles {
  const OculumLiteNativeSaveFiles(this.directory);

  final Directory directory;

  File _file(String key) {
    if (!RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(key)) {
      throw ArgumentError.value(key, 'key');
    }
    return File.fromUri(directory.uri.resolve('$key.json'));
  }

  @override
  Future<Object?> read(String key) async {
    final file = _file(key);
    try {
      return await file.readAsString();
    } on FileSystemException catch (error) {
      // A file we cannot read must never make the slot appear available.
      final code = error.osError?.errorCode;
      if (code == 2 || (Platform.isWindows && code == 3)) return null;
      return error;
    } on FormatException catch (error) {
      return error;
    }
  }

  @override
  Future<void> replace(String key, String value) async {
    final file = _file(key);
    await directory.create(recursive: true);
    final operation = await directory.createTemp('.scrittura-');
    final temporary = File.fromUri(operation.uri.resolve('slot.json'));
    try {
      await temporary.writeAsString(value, flush: true);
      await temporary.rename(file.path);
    } finally {
      try {
        if (await temporary.exists()) await temporary.delete();
        await operation.delete();
      } on FileSystemException {
        // A leftover temporary file is never considered as a saved slot.
      }
    }
  }
}
