/// MelodyBox 全局常量
class AppConstants {
  AppConstants._();

  // ---- Jamendo API ----
  /// 在 https://developer.jamendo.com/v3.0 免费注册获取
  static const String jamendoClientId = 'YOUR_CLIENT_ID';

  static const String jamendoBaseUrl = 'https://api.jamendo.com/v3.0';

  // ---- 应用信息 ----
  static const String appName = 'MelodyBox';
  static const String appVersion = '1.0.0';
  static const String appSubtitle = '探索你的音乐世界';

  // ---- 下载路径 ----
  static const String downloadDirName = 'melody_box_downloads';
  static const String favoritesFileName = 'favorites.json';

  // ---- API 分页 ----
  static const int defaultPageSize = 20;
  static const int searchPageSize = 30;
}
