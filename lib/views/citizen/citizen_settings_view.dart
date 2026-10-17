import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
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

          // Switch Role
          OutlinedButton.icon(
            onPressed: () {
              auth.switchRole(UserRole.driver);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.truckBlue),
            label: const Text(
              'Zibil Maşını Sürücüsü Rejiminə Keç',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.truckBlue),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.truckBlue, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),

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
