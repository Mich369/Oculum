import 'oculum_lite_save_files_stub.dart'
    if (dart.library.io) 'oculum_lite_save_files_native.dart'
    as platform;

abstract interface class OculumLiteSaveFiles {
  Future<Object?> read(String key);
  Future<void> replace(String key, String value);
}

Future<OculumLiteSaveFiles?> openOculumLiteSaveFiles() => platform.open();
