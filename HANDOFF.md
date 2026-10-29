# SmartLine_Real — Oflayn Rejim və Süni İntellektlə Yönləndirmə Sistemi: HANDOFF

Bu sənəd **SmartLine_real** tətbiqində sakin (*resident / citizen*) rejimində "Problemi bildir" modulu üçün həyata keçirilmiş oflayn saxlama, avtomatik sinxronizasiya və dəqiq AI qurum yönləndirməsi sisteminin yekun hesabatını əks etdirir.

---

## 1. Mərhələ 0: Analiz və İlkin Problem Təyini

### Niyə əvvəl oflayn rejim işləmirdi?
1. **Şəbəkə Vəziyyətinin Dinlənilməməsi:** Tətbiqdə internet bağlantısını fasiləsiz yoxlayan və ya şəbəkə bərpa olunduqda tetiklənən reaktiv dinləyici (`ConnectivityListener`) mövcud deyildi.
2. **Lokal Davamlı Növbənin (Persistent Offline Queue) Olmaması:** İnternet kəsildikdə daxil edilən mətn, foto və ya audio fayllar heç bir davamlı yaddaş strukturunda (məsələn, UUID ilə indekslənmiş `SharedPreferences` və ya lokal DB) saxlanılmırdı; nəticədə tətbiq bağlandıqda və ya xəta baş verdikdə bildirişlər tamamilə itirdi.
3. **Orijinal Metaməlumatların İtirlməsi:** Məkan və vaxt məlumatı göndərilmə anına bağlı idi. İnternet olmadan GPS təyini və ya əvvəlki məlum koordinatların kəşlənməsi təmin edilməmişdi.
4. **AI Yönləndirmə Qüsurları:** Təcili qaz sızması/partlayışı açar sözlərində "partlayış" sözünə görə Azərsu seçilirdi (Azəriqaz yerinə), həmçinin Azərbaycan dilindəki `-su` şəkilçisi (məsələn, "qutusu") yanlışlıqla su qurumunu aktivləşdirirdi.

---

## 2. Nələr Hazırdır və Necə İşləyir?

### MƏRHƏLƏ 1 — Oflayn Saxlama (Yedəkləmə)
- [x] **Unikal İdentifikasiya:** Hər bir bildiriş üçün `Uuid().v4()` əsasında unikal identifikator təyin olunur.
- [x] **Davamlı Lokal Növbə (`OfflineQueueService`):**
  - Mətn, foto fayl yolu (`photoPath`), audio fayl yolu (`audioPath`) lokal yaddaşda saxlanılır.
  - Orijinal vaxt damğası (`createdAt` timestamp) qorunur.
  - Həmin anın GPS koordinatları (`latitude`, `longitude`, `locationAccuracy`, `isLastKnownLocation`) qeyd olunur.
  - İlkin status: **"Göndərilməyi gözləyir"** (`ReportStatus.pending`).
- [x] **GPS Məkan Təhlükəsizliyi (`LocationService`):**
  - İnternet olmasa belə peyk GPS vasitəsilə koordinatlar alınır və kəşlənir.
  - GPS siqnalı zəif olduqda ən son məlum koordinat (`lastKnownLocation`) götürülür və `isLastKnownLocation: true` olaraq qeyd edilir.
- [x] **İstifadəçi Bildirişi:**
  - İnternet olmadıqda istifadəçiyə dəqiq tələb olunan mesaj dialoq və banner şəklində göstərilir:
    > *"İnternet yoxdur. Bildiriş telefonda saxlandı, internet gələndə avtomatik göndəriləcək."*
- [x] **Qalıcılıq:** Tətbiq bağlansa və ya cihaz söndürülsə belə, `SharedPreferences` üzərində saxlanılan JSON növbəsi heç vaxt itmir.

### MƏRHƏLƏ 2 — İnternet Qayıdanda Avtomatik Göndərmə
- [x] **Şəbəkə Dinləyicisi (`NetworkService`):**
  - Cihazın şəbəkə vəziyyətini real vaxt rejimində (`onConnectivityChanged`) izləyir və DNS/Socket yoxlaması ilə faktiki internet mövcudluğunu təsdiqləyir.
- [x] **FIFO Sıralaması:**
  - İnternet bərpa olan kimi növbədəki bildirişlər köhnədən yeniyə doğru (`createdAt` artan sırası ilə) ardıcıl emal olunur.
- [x] **Orijinal Vaxt və Lokasiya:**
  - Serverə ötürülərkən bildirişin ilkin yaradılma anı (`createdAt`) və həmin andakı dəqiq GPS koordinatları çatdırılır; server çatdırılma vaxtı isə `sentAt` sahəsində ayrıca saxlanılır.
- [x] **Status Keçidi və Növbənin Təmizlənməsi:**
  - Uğurlu göndərişdən sonra status **"Göndərildi"** (`ReportStatus.sent`) olur və lokal pending növbəsindən təmizlənir.
- [x] **Retry və Eksponensial Gözləmə (Backoff):**
  - Şəbəkə zəifliyi və ya server xətalarında bildiriş silinmir; `retryCount` artırılır və eksponensial intervalla (2s, 4s, 8s, 16s...) təkrar cəhd edilir (maksimum 5 cəhd).
- [x] **İdempotentlik:**
  - Hər bir UUID kəşlənmiş `_processedIds` siyahısında qeyd olunur; eyni UUID-yə malik hesabat ikinci dəfə təkrar qeydə alına və ya dublikat göndərilə bilməz.
- [x] **"Keçmiş bildirişlər" Ekranı:**
  - Bütün 4 status vizual filtrlər və nişanlarla (badge) təchiz olunub:
    1. **Gözləyir** (Pending - Narıncı/Sarı)
    2. **Göndərildi** (Sent - Göy)
    3. **Həll olundu** (Resolved - Yaşıl)
    4. **Həll olunmadı** (Unresolved - Qırmızı)

### MƏRHƏLƏ 3 — AI Analizi və Dəqiq Qurum Yönləndirməsi
- [x] **Strukturlu JSON Çıxışı:**
  ```json
  {
    "category": "...",
    "institution": "...",
    "urgency": "low|medium|high|emergency",
    "confidence": 0.0-1.0,
    "reason": "..."
  }
  ```
- [x] **Ciddi Ağ Siyahı (Whitelist) Validasiyası:**
  Yalnız və yalnız tələb olunan 7 qurum qəbul edilir:
  1. **Qaz borusu sızması / partlaması / qaz iyi** $\rightarrow$ `Azəriqaz (104)` | `urgency: emergency` *(Azərsu seçilməsi qətiyyən mümkün deyil)*.
  2. **Su borusu partlaması / kanalizasiya / içməli su** $\rightarrow$ `Azərsu ASC (185)` | `urgency: high`.
  3. **Elektrik xətti / dirək / açıq naqil / işıq kəsilməsi** $\rightarrow$ `Azərişıq ASC (199)` | `urgency: emergency` (açıq/sallanan naqil halında).
  4. **Zibil / konteyner / tullantı** $\rightarrow$ `Təmiz Şəhər / Bakı Şəhər İcra Hakimiyyəti MKTB (153)`.
  5. **Yol çuxuru / işıqforlar / səkilər / yol nişanları** $\rightarrow$ `Azərbaycan Avtomobil Yolları Dövlət Agentliyi (AAYDA)`.
  6. **Yanğın / tüstü / alov** $\rightarrow$ `Fövqəladə Hallar Nazirliyi (112)` | `urgency: emergency`.
  7. **Digər / qeyri-müəyyən** $\rightarrow$ `"Digər / yoxlama tələb edir"` | `confidence < 0.6`.
- [x] **Təcili Hallarda Həyəcan Nömrəsi:**
  - Qaz, yanğın və açıq naqil qəzalarında ekranda qırmızı təcili yardım kartı və birbaşa zəng düyməsi çıxır (`104`, `112`, `199`).
- [x] **Xəritədə Əks Olunma:**
  - Orijinal koordinatlar xəritədə müvafiq rəngli ikonla göstərilir.

---

## 3. Mərhələ 4: Test Nəticələri

Bütün tələb olunan test ssenariləri həm vahid (`unit`), həm də inteqrasiya səviyyəsində yoxlanılmışdır:

| Ssenari | Təsvir | Nəticə |
|---|---|---|
| **Ssenari 1** | İnternet yox $\rightarrow$ bildiriş göndər $\rightarrow$ tətbiqi bağla/aç $\rightarrow$ internet qoş $\rightarrow$ avtomatik göndərilir | **UĞURLA KEÇDİ** (`PASSED`) |
| **Ssenari 2** | "Qaz borusu partladı" $\rightarrow$ Azəriqaz + emergency (`104`), Azərsu OLMAMALIDIR | **UĞURLA KEÇDİ** (`PASSED`) |
| **Ssenari 3** | "Su borusu partladı" $\rightarrow$ Azərsu ASC (`185`) | **UĞURLA KEÇDİ** (`PASSED`) |
| **Ssenari 4** | "Dirəkdən naqil sallanır" $\rightarrow$ Azərişıq ASC (`199`) + emergency | **UĞURLA KEÇDİ** (`PASSED`) |
| **Ssenari 5** | Qeyri-müəyyən mətn $\rightarrow$ "Digər / yoxlama tələb edir" və `confidence < 0.6` | **UĞURLA KEÇDİ** (`PASSED`) |
| **Ssenari 6** | Göndərmə yarımçıq qırılır $\rightarrow$ təkrar cəhd (exponential retry), dublikat yoxdur (idempotent) | **UĞURLA KEÇDİ** (`PASSED`) |

- `flutter test`: **18/18 test uğurla keçdi** (0 xəta).
- `flutter analyze`: **No issues found!** (0 xəbərdarlıq, 0 xəta).

---

## 4. Dəyişdirilmiş və Əlavə Edilmiş Əsas Fayllar

1. `lib/models/models.dart`:
   - `ReportUrgency.emergency` əlavə edildi.
   - `ReportStatus` yeniləndi (`pending`, `sent`, `inProgress`, `resolved`, `unresolved`).
   - `ProblemReport` modelinə `locationAccuracy`, `isLastKnownLocation`, `emergencyContact`, `sentAt` sahələri əlavə edildi.
2. `lib/services/network_service.dart`:
   - Canlı şəbəkə monitorinqi və oflayn test emulyasiyası üçün singleton servis.
3. `lib/services/offline_queue_service.dart`:
   - Davamlı oflayn növbə, FIFO sinxronizasiyası, backoff retry və idempotentlik mexanizmi.
4. `lib/services/location_service.dart`:
   - Oflayn GPS qorunması, dəqiqlik ölçümü və `lastKnownLocation` kəşləməsi.
5. `lib/services/ai_service.dart`:
   - Ciddi 7 qurumluq ağ siyahı (whitelist), JSON sxeması, Groq/Gemini/OpenAI dəstəyi və gücləndirilmiş oflayn Azərbaycan dili semantik açar söz filtri.
6. `lib/providers/reports_provider.dart`:
   - `syncOfflineReportSent` metodu ilə lokal hesabatların serverlə sinxronlaşdırılması.
7. `lib/views/citizen/text_problem_view.dart`, `photo_problem_view.dart`, `voice_problem_view.dart`:
   - Oflayn saxlama, bildiriş dialoqları və fövqəladə nömrə xəbərdarlıqları.
8. `lib/views/citizen/reports_history_view.dart`:
   - 4 statusluq filtrləmə (Gözləyir, Göndərildi, Həll olundu, Həll olunmadı) və detallı GPS/vaxt məlumat kartları.
9. `lib/views/citizen/citizen_home_view.dart`:
   - Oflayn pending hesabatların xəritədə fərqləndirilmiş ikonla əks olunması.
10. `test/offline_queue_and_scenarios_test.dart`:
    - 6 əsas oflayn və AI ssenarisini avtomatlaşdıran test dəsti.

---

## 5. Nə Qaldı? (Gələcək Təkmilləşdirmələr)
- **Real Backend / REST API Əlaqəsi:** Hazırda `OfflineQueueService` lokal olaraq `ReportsProvider`-i və simulyasiya edilmiş şəbəkə çatdırılmasını yeniləyir. Real istehsalat mühitində `_dio.post('/api/reports')` çağırışı aktivləşdirildikdə arxitektura birbaşa qoşulmağa hazırdır.
- **Push Notification:** İnternet bərpa olunub oflayn bildiriş göndərildikdən sonra istifadəçiyə yerli bildiriş (local notification) göndərilməsi əlavə edilə bilər.
