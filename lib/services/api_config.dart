import 'package:shared_preferences/shared_preferences.dart';

/// SmartLine AI Konfiqurasiyası
/// 
/// API Açarınızı həm bu faylda birbaşa qeyd edə bilərsiniz,
/// həm də tətbiqin daxilində "Ayarlar -> AI Parametrləri & API Açarı"
/// bölməsindən daxil edə bilərsiniz.
class ApiConfig {
  /// =========================================================================
  /// 🔑 AI API AÇARI KONFİQURASİYASI (GITHUB ÜÇÜN TƏHLÜKƏSİZ)
  /// =========================================================================
  /// 
  /// Təhlükəsizlik məqsədilə və GitHub-a yüklənərkən açarların sızmaması üçün
  /// şəxsi API açarları kod daxilində açıq şəkildə saxlanılmır.
  /// 
  /// API açarını təmin etməyin 2 rahat və təhlükəsiz yolu:
  /// 1. Tətbiq daxilində: "Ayarlar -> AI Parametrləri & API Açarı" bölməsindən
  ///    öz açarınızı daxil edin (yerli cihazda SharedPreferences-də saxlanılır).
  /// 
  /// 2. Dart define vasitəsilə:
  ///    flutter run --dart-define=GROQ_API_KEY=gsk_sizin_acariniz
  /// 
  /// Dəstəklənən AI Provayderləri:
  /// - Groq API (Tövsiyə olunur - https://console.groq.com/keys)
  /// - Google Gemini API (https://aistudio.google.com/)
  /// - OpenAI API (https://platform.openai.com/api-keys)
  /// =========================================================================
  static const String defaultApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  static const String _prefKey = 'smartline_user_custom_api_key';

  /// Aktiv API açarını əldə edir (Əvvəlcə SharedPreferences-dən, yoxdursa defaultApiKey-dən)
  static Future<String> getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = prefs.getString(_prefKey);
      if (custom != null && custom.trim().isNotEmpty) {
        return custom.trim();
      }
    } catch (_) {}
    return defaultApiKey.trim();
  }

  /// İstifadəçinin açarı tətbiq daxilindən yadda saxlaması üçün
  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key.trim());
  }

  /// Açarı silmək və susmaya görə vəziyyətə qaytarmaq
  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  /// Açarın daxil edilib-edilmədiyini yoxlayır
  static bool isValidKey(String? key) {
    if (key == null) return false;
    final k = key.trim();
    return k.isNotEmpty &&
        k != 'BURAYA_GROQ_API_KEY_YAPISDIRIN' &&
        k != 'BURAYA_API_KEY_YAPISDIRIN' &&
        k != 'YOUR_API_KEY_HERE' &&
        k.length >= 15;
  }

  /// Açarın Groq açarı olub-olmadığını müəyyənləşdirir
  static bool isGroqKey(String key) {
    final k = key.trim();
    return k.startsWith('gsk_');
  }

  /// Açarın Google Gemini açarı olub-olmadığını müəyyənləşdirir
  static bool isGeminiKey(String key) {
    final k = key.trim();
    return k.startsWith('AIzaSy') || k.startsWith('AIza');
  }

  /// Açarın OpenAI açarı olub-olmadığını müəyyənləşdirir
  static bool isOpenAiKey(String key) {
    final k = key.trim();
    return k.startsWith('sk-');
  }

  /// Açarın aid olduğu provayder adını qaytarır
  static String getProviderName(String key) {
    if (isGroqKey(key)) return 'Groq LPU AI';
    if (isGeminiKey(key)) return 'Google Gemini';
    if (isOpenAiKey(key)) return 'OpenAI';
    return 'Groq / AI';
  }
}
