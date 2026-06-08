import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageHelper {
  static const _printerKey = 'saved_printer';

  static Future<void> savePrinter(String name, String address) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {'name': name, 'address': address};
    await prefs.setString(_printerKey, jsonEncode(data));
  }

  static Future<Map<String, String>?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_printerKey);
    if (data == null) return null;
    final json = jsonDecode(data);
    return {'name': json['name'], 'address': json['address']};
  }

  static Future<void> clearPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_printerKey);
  }
}
