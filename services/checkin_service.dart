import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CheckInService {
  static const String _storageKey = 'checkin_history';

  
  static Future<void> addCheckIn(String fairName, int points) async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? historyString = prefs.getString(_storageKey);
    List<dynamic> historyList = historyString != null ? jsonDecode(historyString) : [];

    
    DateTime now = DateTime.now();
    String formattedTime = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

   
    Map<String, dynamic> newRecord = {
      'fairName': fairName,
      'points': points,
      'timestamp': formattedTime,
    };

    // 添加并保存
    historyList.add(newRecord);
    await prefs.setString(_storageKey, jsonEncode(historyList));
  }

  
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString(_storageKey);
    
    if (historyString == null) {
      return [];
    }

    List<dynamic> decodedList = jsonDecode(historyString);
    return decodedList.map((item) => item as Map<String, dynamic>).toList();
  }
}
