import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../utils/constants.dart';

class StorageService extends GetxService {
  late GetStorage _box;

  Future<StorageService> init() async {
    _box = GetStorage();
    return this;
  }

  // Token Management
  String? getToken() {
    return _box.read(AppConstants.tokenKey);
  }

  void setToken(String token) {
    _box.write(AppConstants.tokenKey, token);
  }

  void removeToken() {
    _box.remove(AppConstants.tokenKey);
  }

  bool hasToken() {
    return _box.hasData(AppConstants.tokenKey);
  }

  // User Data Management
  Map<String, dynamic>? getUserData() {
    return _box.read(AppConstants.userKey);
  }

  void setUserData(Map<String, dynamic> userData) {
    _box.write(AppConstants.userKey, userData);
  }

  void removeUserData() {
    _box.remove(AppConstants.userKey);
  }

  bool hasUserData() {
    return _box.hasData(AppConstants.userKey);
  }

  // Refresh Token Management (for future use)
  String? getRefreshToken() {
    return _box.read(AppConstants.refreshTokenKey);
  }

  void setRefreshToken(String refreshToken) {
    _box.write(AppConstants.refreshTokenKey, refreshToken);
  }

  void removeRefreshToken() {
    _box.remove(AppConstants.refreshTokenKey);
  }

  // Generic Storage Methods
  T? read<T>(String key) {
    return _box.read<T>(key);
  }

  void write(String key, dynamic value) {
    _box.write(key, value);
  }

  void remove(String key) {
    _box.remove(key);
  }

  bool hasData(String key) {
    return _box.hasData(key);
  }

  // Clear All Data
  void clearAll() {
    _box.erase();
  }

  // Authentication Status
  bool isLoggedIn() {
    return hasToken() && hasUserData();
  }

  // Logout - Clear Auth Data
  void logout() {
    removeToken();
    removeUserData();
    removeRefreshToken();
  }

  // App Settings (for future use)
  void setAppSetting(String key, dynamic value) {
    write('app_$key', value);
  }

  T? getAppSetting<T>(String key) {
    return read<T>('app_$key');
  }

  // Quiz Settings
  void setQuizPreferences(Map<String, dynamic> preferences) {
    write('quiz_preferences', preferences);
  }

  Map<String, dynamic>? getQuizPreferences() {
    return read<Map<String, dynamic>>('quiz_preferences');
  }

  // Voice Settings
  void setVoicePreferences(Map<String, dynamic> preferences) {
    write('voice_preferences', preferences);
  }

  Map<String, dynamic>? getVoicePreferences() {
    return read<Map<String, dynamic>>('voice_preferences');
  }

  // Cache Management
  void setCacheData(String key, dynamic data, {Duration? expiry}) {
    final cacheItem = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    };
    write('cache_$key', cacheItem);
  }

  T? getCacheData<T>(String key) {
    final cacheItem = read<Map<String, dynamic>>('cache_$key');
    if (cacheItem == null) return null;

    final timestamp = cacheItem['timestamp'] as int?;
    final expiry = cacheItem['expiry'] as int?;

    if (expiry != null && timestamp != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > expiry) {
        remove('cache_$key');
        return null;
      }
    }

    return cacheItem['data'] as T?;
  }

  void clearCache() {
    final keys = _box.getKeys().where((key) => key.toString().startsWith('cache_'));
    for (final key in keys) {
      remove(key);
    }
  }

  // First Time Launch
  bool isFirstTimeLaunch() {
    return !hasData('not_first_time');
  }

  void setNotFirstTime() {
    write('not_first_time', true);
  }
}