import 'package:shared_preferences/shared_preferences.dart';

class LocalStoreHelper {
  writeData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  removeData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }

  Future<dynamic> readTheData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(key);
  }
}
