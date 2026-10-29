import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_config.dart';
import '../../theme/app_theme.dart';

class CitizenSettingsView extends StatefulWidget {
  const CitizenSettingsView({super.key});

  @override
  State<CitizenSettingsView> createState() => _CitizenSettingsViewState();
}

class _CitizenSettingsViewState extends State<CitizenSettingsView> {
  bool _enableNotifications = true;
  bool _autoGps = true;
  bool _aiAssistance = true;

  final TextEditingController _apiKeyController = TextEditingController();
  bool _isApiKeyConfigured = false;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _loadApiKeyStatus();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKeyStatus() async {
    final key = await ApiConfig.getApiKey();
    if (mounted) {
      setState(() {
        _isApiKeyConfigured = ApiConfig.isValidKey(key);
        if (_isApiKeyConfigured) {
          _apiKeyController.text = key;
        }
      });
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty) {
      await ApiConfig.saveApiKey(key);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ API açarı yadda saxlanıldı! Canlı AI aktivdir.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } else {
      await ApiConfig.clearApiKey();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API açarı sıfırlandı.')),
        );
      }
    }
    _loadApiKeyStatus();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Ayarlar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.currentUser?.username ?? 'Hörmətli Sakin',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+994 ${auth.currentUser?.phoneNumber ?? "50 123 45 67"}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Sakin Portalı',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Preferences
          const Text(
            'TƏTBİQ PARAMETRLƏRİ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Bildirişləri aktiv et',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Problemin həll statusu dəyişdikdə xəbərdar et',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  value: _enableNotifications,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _enableNotifications = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text(
                    'Avtomatik GPS Lokasiya',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Problemin baş verdiyi məkanı xəritədə dərhal işarələ',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  value: _autoGps,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _autoGps = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text(
                    'Süni İntellekt (AI) Dəstəyi',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Şəkil, səs və mətni AI ilə təsnifləşdir',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  value: _aiAssistance,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _aiAssistance = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // AI Model & API Key section
          const Text(
            'SÜNİ İNTELLEKT (AI) VƏ API AÇARI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isApiKeyConfigured
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : Colors.grey.withValues(alpha: 0.15),
                width: _isApiKeyConfigured ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isApiKeyConfigured
                            ? AppColors.airGreen.withValues(alpha: 0.15)
                            : AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isApiKeyConfigured ? Icons.check_circle_rounded : Icons.key_rounded,
                        color: _isApiKeyConfigured ? AppColors.airGreen : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Mühərriki İnteqrasiyası',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          Text(
                            _isApiKeyConfigured
                                ? 'Canlı AI Aktivdir (${ApiConfig.getProviderName(_apiKeyController.text)})'
                                : 'Lokal / Smart Analiz Rejimi (Açar daxil edilməyib)',
                            style: TextStyle(
                              fontSize: 11,
                              color: _isApiKeyConfigured ? AppColors.airGreen : AppColors.textMuted,
                              fontWeight: _isApiKeyConfigured ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Groq API (gsk_...), Google Gemini (AIzaSy...) və ya OpenAI açarınızı bura yapışdırın:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureKey,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'gsk_... (Groq API Açarı)',
                    hintStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureKey ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveApiKey,
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Yadda saxla', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    if (_isApiKeyConfigured) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          _apiKeyController.clear();
                          _saveApiKey();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.critical,
                          side: const BorderSide(color: AppColors.critical),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Sıfırla', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '💡 Qeyd: Açarınızı kod daxilində "lib/services/api_config.dart" faylında da birbaşa yapışdıra bilərsiniz.',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Hotlines
          const Text(
            'BƏLƏDİYYƏ VƏ DÖVLƏT QAYNAR XƏTTLƏRİ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                _hotlineRow('Təmiz Şəhər ASC & BŞİH MKTB', '153'),
                const Divider(height: 18),
                _hotlineRow('Azərsu ASC (Su qəzaları)', '185'),
                const Divider(height: 18),
                _hotlineRow('Azərişıq ASC (Elektrik şəbəkəsi)', '199'),
                const Divider(height: 18),
                _hotlineRow('Azəriqaz İB (Qaz təchizatı)', '104'),
                const Divider(height: 18),
                _hotlineRow('AAYDA (Avtomobil Yolları Agentliyi)', '118'),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Logout
          ElevatedButton.icon(
            onPressed: () {
              auth.logout();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            label: const Text(
              'Çıxış et',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _hotlineRow(String name, String number) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
