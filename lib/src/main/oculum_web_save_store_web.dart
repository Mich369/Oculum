import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

const String _databaseName = 'oculum_app_storage';
const String _storeName = 'save_blobs';

Future<web.IDBDatabase>? _databaseFuture;

Future<web.IDBDatabase> _openDatabase() {
  final cached = _databaseFuture;
  if (cached != null) return cached;
  final future = _openDatabaseOnce();
  _databaseFuture = future;
  return future.catchError((Object error) {
    _databaseFuture = null;
    throw error;
  });
}

Future<web.IDBDatabase> _openDatabaseOnce() {
  final completer = Completer<web.IDBDatabase>();
  final request = web.window.indexedDB.open(_databaseName, 1);
  request.onupgradeneeded = ((web.Event _) {
    final database = request.result as web.IDBDatabase;
    if (!database.objectStoreNames.contains(_storeName)) {
      database.createObjectStore(_storeName);
    }
  }).toJS;
  request.onblocked = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('IndexedDB upgrade blocked'));
    }
  }).toJS;
  request.onerror = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(
        StateError(
          'IndexedDB open failed: ${request.error?.message ?? 'error'}',
        ),
      );
    }
  }).toJS;
  request.onsuccess = ((web.Event _) {
    final database = request.result as web.IDBDatabase;
    database.onversionchange = ((web.Event _) {
      database.close();
      _databaseFuture = null;
    }).toJS;
    if (!completer.isCompleted) completer.complete(database);
  }).toJS;
  return completer.future.timeout(const Duration(seconds: 5));
}

Future<String?> oculumWebSaveRead(String key) async {
  final database = await _openDatabase();
  final transaction = database.transaction(_storeName.toJS, 'readonly');
  final request = transaction.objectStore(_storeName).get(key.toJS);
  final completer = Completer<String?>();
  request.onerror = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(
        StateError(
          'IndexedDB read failed: ${request.error?.message ?? 'error'}',
        ),
      );
    }
  }).toJS;
  request.onsuccess = ((web.Event _) {
    if (completer.isCompleted) return;
    final value = request.result?.dartify();
    completer.complete(value is String ? value : null);
  }).toJS;
  return completer.future.timeout(const Duration(seconds: 5));
}

Future<bool> oculumWebSaveWrite(String key, String value) async {
  final database = await _openDatabase();
  final transaction = database.transaction(_storeName.toJS, 'readwrite');
  final completer = Completer<bool>();
  transaction.oncomplete = ((web.Event _) {
    if (!completer.isCompleted) completer.complete(true);
  }).toJS;
  transaction.onerror = ((web.Event _) {
    if (!completer.isCompleted) completer.complete(false);
  }).toJS;
  transaction.onabort = ((web.Event _) {
    if (!completer.isCompleted) completer.complete(false);
  }).toJS;
  transaction.objectStore(_storeName).put(value.toJS, key.toJS);
  return completer.future.timeout(const Duration(seconds: 5));
}

Future<bool> oculumWebSaveDelete(String key) async {
  final database = await _openDatabase();
  final transaction = database.transaction(_storeName.toJS, 'readwrite');
  final completer = Completer<bool>();
  transaction.oncomplete = ((web.Event _) {
    if (!completer.isCompleted) completer.complete(true);
  }).toJS;
  transaction.onerror = ((web.Event _) {
    if (!completer.isCompleted) completer.complete(false);
  }).toJS;
  transaction.onabort = ((web.Event _) {
    if (!completer.isCompleted) completer.complete(false);
  }).toJS;
  transaction.objectStore(_storeName).delete(key.toJS);
  return completer.future.timeout(const Duration(seconds: 5));
}
