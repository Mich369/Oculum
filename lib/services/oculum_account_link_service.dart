import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OculumAccountLinkService extends ChangeNotifier {
  OculumAccountLinkService._();

  static final OculumAccountLinkService instance = OculumAccountLinkService._();

  Future<bool> linkExistingLocalSaveToAccount({
    required String accountId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final hasLocal = prefs.containsKey('oculum.home.save');
    if (!hasLocal) return false;
    await prefs.setString('oculum.auth.linked_account_id', accountId);
    return true;
  }

  Future<bool> hasLocalSavePendingMigration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('oculum.home.save');
  }
}
