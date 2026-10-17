# SmartLine - Bakı Ağıllı Şəhər və Tullantı İdarəetmə Sistemi

Yeni nəsil ağıllı şəhər və kommunal tullantıların idarəetmə platforması. Layihə tamamilə ağ arxa plan və layihədəki `Frame 12.png` rəsmi ilə brendləşdirilmişdir.

---

## 🌟 Əsas Xüsusiyyətlər və İkiqat Rol Sistemi

Tətbiqə daxil olduqda istifadəçiyə iki aydın seçim təqdim olunur:
1. **Zibil Maşını Sürücüsü Kimi Daxil Olma**
2. **Sakin (Vətəndaş) Kimi Daxil Olma**

---

### 🚛 1. Zibil Maşını Sürücüsü İnterfeysi
Əvvəlki funksionallıq tam qorunub saxlanılmış və yenilənmiş loqo ilə təchiz edilmişdir:
- **İdarəetmə Paneli (Dashboard):** Bakı üzrə ümumi tullantı konteynerlərinin sayı, doluluq səviyyələri və kritik stansiyalar.
- **Canlı Şəhər Xəritəsi (Live City Map):** OpenStreetMap üzərində real vaxtda tullantı stansiyaları, boşaltma depoları və hərəkət edən tullantı maşınları.
- **Marşrutum (My Route):** Optimal tullantı toplama marşrutu və stansiyaların boşaldılma statusu.
- **Analitika:** Təkrar emal faizləri, həftəlik tullantı həcmləri və ekoloji təsir göstəriciləri.

---

### 👤 2. Sakin İnterfeysi (Plandakı kimi yenilənmiş)
- **Ağ Arxa Plan & "Frame 12.png" Loqosu:** Təmiz, müasir və yüksək kontrastlı dizayn.
- **"+ Problemi bildir" Düyməsi:** Əsas ekranda dərhal gözə çarpan, böyük yaşıl fəaliyyət düyməsi.
- **3 Fərqli Bildirmə Üsulu:**
  1. 📷 **Şəkil ilə problemi bildir:** Kamera və ya qalereyadan foto çəkilir, AI görüntünü analiz edərək problemi avtomatik təsnif edir.
  2. 🎙️ **Səs ilə problemi bildir:** İstifadəçi problemini danışır, AI səsi transkripsiya edir və aidiyyəti orqanı müəyyənləşdirir.
  3. ✍️ **Mətn ilə problemi bildir:** Vətəndaş mətni daxil edir və ya hazır nümunə şablonlardan birini seçir, AI mətni təhlil edir.
- **Konumun Müəyyən Edilməsi və Xəritədə İşarələnməsi:**
  - Tətbiq avtomatik GPS və ya Bakı ünvan xidməti vasitəsilə vətəndaşın dəqiq koordinatını təyin edir.
  - Problem təsdiqlənən kimi **xəritədə qırmızı/narıncı xəbərdarlıq nişanı ilə işarələnir** və istifadəçiyə təqdim olunur.
- **Sağ Yuxarıda 3 Nöqtə Menyusu (`...`):**
  - 📋 **Keçmiş müraciətlər:**
    - **Problemin həll olub-olmadığı:** "Həll olundu" (Yaşıl) və ya "Həll olunmayıb" (Sarı) nişanı ilə aydın şəkildə qeyd olunur.
    - **Hansı aşamada olduğu:** 4 mərhələli vizual icra xətti (1. Qəbul edildi -> 2. AI Təhlili & Yönləndirmə -> 3. İcrada -> 4. Tam həll olundu).
    - "Xəritədə göstər" düyməsi ilə müraciəti xəritədə birbaşa vizuallaşdırma.
  - ⚙️ **Ayarlar:** Bildirişlər, avtomatik GPS, AI dəstəyi, qaynar xətlər (153, 185, 199, 104), rol dəyişmə və çıxış.

---

## 📂 Qovluq Strukturu (`smartline_new`)

```
smartline_new/
├── assets/
│   └── images/
│       ├── Frame 12.png        # Layihənin əsas loqosu
│       └── logo.png
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── models.dart         # ProblemReport, ReportStage, ReportStatus, Waste modelləri
│   ├── providers/
│   │   ├── auth_provider.dart  # Sürücü və Sakin rolları, autentifikasiya
│   │   ├── reports_provider.dart # Müraciətlərin yaddaşda saxlanması və xəritə fokuslanması
│   │   └── waste_provider.dart # Sürücü tullantı simulyasiyası və marşrutlar
│   ├── services/
│   │   ├── ai_service.dart     # Şəkil, səs və mətn üçün Süni İntellekt mühərriki
│   │   └── location_service.dart # GPS və Bakı məkan təyini
│   ├── theme/
│   │   └── app_theme.dart      # Ağ arxa plan və rəng sxemi
│   └── views/
│       ├── root_view.dart      # Rol əsaslı naviqasiya
│       ├── auth/
│       │   └── login_view.dart # İki seçimli giriş ekranı
│       ├── citizen/
│       │   ├── citizen_home_view.dart     # Canlı xəritə, + butonu və 3 nöqtə menyusu
│       │   ├── photo_problem_view.dart    # Şəkil ilə bildirmə
│       │   ├── voice_problem_view.dart    # Səs ilə bildirmə
│       │   ├── text_problem_view.dart     # Mətn ilə bildirmə
│       │   ├── reports_history_view.dart  # Keçmiş müraciətlər, həll və aşama izləməsi
│       │   └── citizen_settings_view.dart # Ayarlar
│       └── driver/
│           ├── dashboard_view.dart        # Sürücü idarəetmə paneli
│           ├── full_map_view.dart         # Sürücü tullantı xəritəsi
│           ├── my_route_view.dart         # Sürücü marşrutu
│           └── analytics_view.dart        # Sürücü analitikası
└── test/
    └── citizen_and_ai_test.dart
```

---

## 🚀 Tətbiqi İcra Etmək

```bash
cd smartline_new
flutter pub get
flutter run
```
