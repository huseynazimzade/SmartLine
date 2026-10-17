# ƏVVƏLCƏ OXU

Bu fayl SmartLine (Flutter/Dart) layihəsi üzrə AI agentlərin əlaqələndirilməsi və işin fasiləsiz davam etdirilməsi üçün iş gündəliyidir. Əgər hər hansı səbəbdən (token limiti, sessiya kəsilməsi və s.) iş yarımçıq qalarsa, **növbəti agent bu faylı əvvəldən oxuyub qaldığı yerdən davam etməlidir**.

---

## 1. Məqsəd
SmartLine Bakı Ağıllı Şəhər və Tullantı İdarəetmə tətbiqində mövcud zibil maşını sürücüsü hissəsinə toxunmadan (ekranlar, dizayn və məntiq qorunur), ikiqat rol seçimi (Sürücü və Sakin) və tam funksional Sakin (Vətəndaş) interfeysini qurmaq:
- Açılışda rol seçimi ("Zibil maşını sürücüsü kimi daxil ol" və "Sakin kimi daxil ol"), yadda saxlanma və ayarlarda rol dəyişmə.
- Brendinq: `Frame 12.png` loqosu (splash, login, tətbiq ikonu), ağ arxa fon, mövcud rəng palitrası və şrift.
- Sakin ana ekranı: böyük "+" ("Problemi bildir") düyməsi, 3 nöqtə menyusu ("Ayarlar" və "Keçmiş müraciətlər"), problem xəritəsi.
- 3 bildirmə üsulu: Şəkil (kamera/qalereya), Səs (mikrofon), Mətn.
- AI arxitekturası (Firebase AI Logic / Gemini): `AiService` abstrakt interfeysi (`MockAiService` default, `GeminiAiService`, `CustomModelAiService`), növ, məsul qurum, etibarlılıq və təsvir.
- Qurum təyini: `assets/config/organizations.json` konfiqurasiyası əsasında avtomatik və dəqiq mapping, istifadəçi tərəfindən redaktə imkanı.
- Etibarlılıq astanası (0.6) və növ konfiqurasiyası (`assets/config/problem_types.json`).
- OFFLINE REJİM: İnternet olmadıqda GPS və vaxt dərhal qeyd olunur, müraciət və media lokal növbədə (`sqflite`) saxlanır, internet gələndə (`connectivity_plus`) avtomatik sinxronizasiya edilir, bildiriş verilir, təkrarlanma (idempotency) və xəta idarəsi (exponential backoff) təmin edilir.
- Keçmiş müraciətlər siyahısı və ətraflı status mərhələləri.
- Təhlükəsizlik qaydaları: Firestore və Storage (`firestore.rules`, `storage.rules`).
- Bütün mətnlər Azərbaycan dilində, 0 lint xətası (`flutter analyze`), unit testlər və ətraflı `README.md`.

---

## 2. Texnologiya və Qərarlar

| Sahə | Texnologiya / Paket | Seçim Səbəbi |
|---|---|---|
| Freymvork | Flutter 3.47+ / Dart 3.13+ | Mövcud layihə bazası |
| State Management | `provider` (^6.1.5) | Layihənin mövcud arxitekturasına tam uyğun |
| Xəritə | `flutter_map` (^8.3.2) + `latlong2` | Mövcud xəritə həlli, kənar ödənişli SDK tələb etmir |
| Lokal Məlumat və Növbə | `sqflite` + `path_provider` + `path` | Offline müraciətlər və media yollarının etibarlı saxlanması |
| Şəbəkə İzlənməsi | `connectivity_plus` | Offline rejimdən onlayna keçidin avtomatik aşkarlanması |
| Şəkil Seçimi | `image_picker` | Kamera və qalereyadan şəkillərin çəkilməsi/seçilməsi |
| Geolocation | `geolocator` | Dəqiq GPS koordinatlarının internet olmadan da təyini |
| Unikal İdentifikatorlar | `uuid` | Müraciətlərin idempotency və təkrar göndərilməsinin qarşısını almaq üçün |
| Tarix / Formatlama | `intl` | Azərbaycan lokalına uyğun tarix və vaxt formatlaması |
| Tətbiq İkonu | `flutter_launcher_icons` | `Frame 12.png` loqosunun Android/iOS tətbiq ikonuna çevrilməsi |
| AI Xidməti | Abstrakt `AiService` | Mock default olaraq işləyir; Firebase qurulduqda Gemini aktivləşir |

---

## 3. Tamamlanıb

- [x] **Mərhələ 0**: `smartline_new` qovluğunun hazırlanması, layihə fayllarının analizi və `AGENT_LOG.md` yaradılması.

---

## 4. İndi Üzərində İşlənir
- `smartline_new` daxilində git anbarının inisializasiyası (`git init`).
- Zibil maşını sürücüsü hissəsinin orijinallığının yoxlanması və zəmanət altına alınması.
- `pubspec.yaml` asılılıqlarının zəruri paketlərlə yenilənməsi (`sqflite`, `path_provider`, `connectivity_plus`, `geolocator`, `image_picker`, `flutter_launcher_icons`).

---

## 5. Növbəti Addımlar (Sıra ilə)
1. `smartline_new` qovluğunda `git init` etmək və ilkin təmiz vəziyyəti commit etmək (`git commit -m "chore: initial copy of project"`).
2. `pubspec.yaml` və assets konfiqurasiyasını tamamlamaq (`assets/config/organizations.json`, `assets/config/problem_types.json`, `assets/images/Frame 12.png`, `flutter_launcher_icons`).
3. Model təbəqəsi: `ProblemReport` modelinə tələb olunan bütün sahələrin (`id`, `userId`, `type`, `organization`, `confidence`, `lat`, `lng`, `capturedAt`, `submittedAt`, `mediaUrl`, `text`, `status` enum və s.) dəqiq əlavə edilməsi.
4. AI Xidmət təbəqəsi: `lib/services/ai_service.dart` faylında abstrakt `AiService`, `MockAiService`, `GeminiAiService`, `CustomModelAiService` siniflərinin yaradılması.
5. Lokal Növbə və Verilənlər Bazası: `lib/services/offline_queue_service.dart` və `lib/services/database_service.dart` (`sqflite`, media fayllarının diskdə saxlanması, `connectivity_plus` ilə avto-sinxronizasiya).
6. Provider təbəqəsi: `ReportsProvider` və `AuthProvider` məntiqlərinin zənginləşdirilməsi (rol seçimi, SharedPreferences yaddaşı, online/offline müraciət axını).
7. Sakin İnterfeysi:
   - Giriş / Rol seçimi ekranı (`login_view.dart`)
   - Sakin ana ekranı (`citizen_home_view.dart` - böyük +, 3 nöqtə menyusu, xəritədə fərqli ikonlu markerlər, marker popup)
   - 3 bildirmə üsulu modal vərəqi və Təsdiq ekranı (növ, qurum, GPS, xəritə, astana yoxlaması, offline xəbərdarlıq)
   - Keçmiş müraciətlər ekranı (`reports_history_view.dart` - statuslar, offline nişanı, detal və tarixçə)
   - Sakin ayarları (`citizen_settings_view.dart` - dil, bildiriş, rolu dəyiş, haqqında)
8. Sürücü İnterfeysi: Orijinal sürücü ekranlarına toxunulmadan, girişdən sürücü axınına yönləndirmə təmin edilməsi.
9. İcazələr və Təhlükəsizlik:
   - `AndroidManifest.xml` və `Info.plist` fayllarında Kamera, Mikrofon, Konum və Şəbəkə icazələri
   - `firestore.rules` və `storage.rules` qaydaları
10. Testlər və Keyfiyyət Yoxlaması:
    - Offline növbə və AI xidməti üçün unit testlər (`test/offline_queue_test.dart`)
    - `flutter analyze` icra edilməsi (0 xəta)
11. Sənədləşdirmə: `README.md` və `AGENT_LOG.md` fayllarının yekun yenilənməsi.

---

## 6. Məlum Problemlər, TODO və Test Edilməmiş Yerlər
- TODO: `organizations.json` faylında dövlət qurumu placeholder-ləri (`TODO_QURUM`, `TODO_YOL_QURUM`, `TODO_ISIQ_QURUM`) README-də qeyd olunmalıdır.
- TODO: Cihaz offline olanda xəritə plitələri yüklənmədikdə koordinatların mətn formasında aydın göstərilməsi təmin olunmalıdır.
- TODO: Səs yazma zamanı mikrofon icazəsi və ya platform fərqlilikləri nəzərə alınmalıdır.

---

## 7. İşə Salma və Test Əmrləri
```bash
# Asılılıqları yükləmək:
cd smartline_new
flutter pub get

# Statik analiz (xətasız olmalıdır):
flutter analyze

# Vahid (Unit) testləri işə salmaq:
flutter test

# Tətbiqi işə salmaq:
flutter run
```

---

## 8. Başqa Agentə Qeyd
- **DİQQƏT**: Zibil maşını sürücüsü interfeysi (`lib/views/dashboard/` və ya `lib/views/driver/`) hazırdır. Onun dizaynını, ekranlarını və daxili məntiqini QƏTİYYƏN DƏYİŞMƏ. Yalnız rol seçimindən sonra ora keçidi təmin et.
- Bütün istifadəçi mətnləri mütləq Azərbaycan dilində olmalıdır.
- Hər mərhələ bitdikdən sonra git commit et və bu `AGENT_LOG.md` faylını yenilə.
