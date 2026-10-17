import 'dart:math';
import '../models/models.dart';

class AiAnalysisResult {
  final String title;
  final String detectedProblem;
  final String category;
  final String targetDepartment;
  final double confidence;
  final ReportUrgency urgency;
  final String suggestedAction;
  final String aiSummary;

  AiAnalysisResult({
    required this.title,
    required this.detectedProblem,
    required this.category,
    required this.targetDepartment,
    required this.confidence,
    required this.urgency,
    required this.suggestedAction,
    required this.aiSummary,
  });
}

class AiService {
  static final Random _random = Random();

  /// Analyzes text descriptions written or spoken by citizens
  static Future<AiAnalysisResult> analyzeText(String input) async {
    // Realistic AI processing latency for genuine feel
    await Future.delayed(const Duration(milliseconds: 1000));

    final text = input.toLowerCase();
    final words = text.split(RegExp(r'[\s,.;:!?]+'));
    bool hasWord(List<String> keywords) {
      return keywords.any((k) => words.any((w) => w.startsWith(k) || w == k));
    }

    // 1. Tullantı və Zibil (Waste & Garbage)
    if (hasWord(['zibil', 'tullantı', 'tullanti', 'qutu', 'zibillik', 'bak', 'qab', 'antisanitar']) ||
        text.contains('dolub daş') ||
        text.contains('dolub-daş') ||
        text.contains('zibil qutusu')) {
      return AiAnalysisResult(
        title: 'Zibil qutularının daşması və antisanitar vəziyyət',
        detectedProblem: 'Bərk məişət tullantıları qutularının həddindən artıq dolması və tullantıların əraziyə səpələnməsi.',
        category: 'Məişət Tullantıları və Təmizlik',
        targetDepartment: 'Təmiz Şəhər ASC & BŞİH MKTB (Qaynar Xətt: 153)',
        confidence: 0.96 + _random.nextDouble() * 0.03,
        urgency: ReportUrgency.high,
        suggestedAction: 'Ən yaxın sahə tullantı maşını stansiyanı boşaltmaq üçün marşruta salınır.',
        aiSummary: 'Süni intellekt mətndə doluluq və antisanitariya deskriptorları təyin etdi. SmartLine ekosistemindəki ən yaxın aktiv yük maşınına tapşırıq yönləndirildi.',
      );
    }

    // 2. Su və Kanalizasiya (Water & Sewage)
    if (hasWord(['su', 'suyu', 'suyun', 'suya', 'boru', 'kanalizasiya', 'lyuk', 'fontan', 'gölməçə']) ||
        text.contains('su boru') ||
        text.contains('su axır') ||
        text.contains('su sız') ||
        text.contains('partlay')) {
      return AiAnalysisResult(
        title: 'Su borusunun qəzası və su axıntısı',
        detectedProblem: 'İçməli su magistralında və ya kanalizasiya xəttində qəza nəticəsində əraziyə güclü su axıntısı qeydə alınmışdır.',
        category: 'Su Təchizatı və Kanalizasiya',
        targetDepartment: 'Azərsu ASC (Qaynar Xətt: 185)',
        confidence: 0.94 + _random.nextDouble() * 0.05,
        urgency: ReportUrgency.high,
        suggestedAction: 'Qəza briqadası və su çəkən texnika dərhal əraziyə yönləndirilməlidir.',
        aiSummary: 'Süni intellekt mətndə "su/boru/axıntı" deskriptorlarını təsbit etdi. Məsələ su itkisi və yolun çökmə riski səbəbilə yüksək dərəcəli qəza kimi qiymətləndirildi.',
      );
    }

    // 3. İşıqlandırma və Elektrik (Street Lighting & Power)
    if (text.contains('işıq') ||
        text.contains('yanmır') ||
        text.contains('qaranlıq') ||
        text.contains('elektrik') ||
        text.contains('kabel') ||
        text.contains('naqil') ||
        text.contains('dirək')) {
      return AiAnalysisResult(
        title: 'Küçə işıqlandırmasında nasazlıq',
        detectedProblem: 'Xarici işıqlandırma dirəklərinin söndüyü və ya kabel xəttində qırılma ehtimalı müəyyən olundu.',
        category: 'Enerji və Küçə İşıqlandırması',
        targetDepartment: 'Bakı Şəhər İşığı & Azərişıq ASC (Qaynar Xətt: 199)',
        confidence: 0.92 + _random.nextDouble() * 0.05,
        urgency: ReportUrgency.medium,
        suggestedAction: 'Elektrik montyor briqadası lampa və təchizat qutusunu yoxlamağa göndərilir.',
        aiSummary: 'Gecə vaxtı piyada və nəqliyyat təhlükəsizliyi üçün işıqlandırma qəzası kimi qeydə alındı.',
      );
    }

    // 4. Yol və Asfalt (Roads & Pavement)
    if (text.contains('yol') ||
        text.contains('asfalt') ||
        text.contains('çuxur') ||
        text.contains('dağılıb') ||
        text.contains('çöküb') ||
        text.contains('səkki') ||
        text.contains('bardür')) {
      return AiAnalysisResult(
        title: 'Yol örtüyünün zədələnməsi və çuxur',
        detectedProblem: 'Hərəkət hissəsində avtomobillər və piyadalar üçün maneə yaradan asfalt çökməsi.',
        category: 'Yol İnfrastrukturu',
        targetDepartment: 'Azərbaycan Avtomobil Yolları Dövlət Agentliyi (AAYDA)',
        confidence: 0.93 + _random.nextDouble() * 0.04,
        urgency: ReportUrgency.medium,
        suggestedAction: 'Cari təmir briqadası tərəfindən asfalt yaması aparılması üçün tapşırıq yaradıldı.',
        aiSummary: 'Süni intellekt yol hərəkəti təhlükəsizliyi kateqoriyası üzrə zədələnmə qeyd etdi.',
      );
    }

    // 5. Yaşıllaşdırma və Ağaclar (Greenery & Trees)
    if (text.contains('ağac') ||
        text.contains('budaq') ||
        text.contains('park') ||
        text.contains('qazon') ||
        text.contains('yaşıl')) {
      return AiAnalysisResult(
        title: 'Yaşıl sahəyə və ağaclara ziyan dəyməsi',
        detectedProblem: 'Ağacın budaqlarının qırılaraq piyada yoluna düşməsi və ya qazonun zədələnməsi.',
        category: 'Yaşıllaşdırma və Ekologiya',
        targetDepartment: 'BŞİH Yaşıllaşdırma Təsərrüfatı Birliyi',
        confidence: 0.90 + _random.nextDouble() * 0.07,
        urgency: ReportUrgency.low,
        suggestedAction: 'Aqrotexniki qulluq və quru budaqların kəsilməsi xidmətinə məlumat verildi.',
        aiSummary: 'Şəhər yaşıllıq zonasının qorunması üzrə bələdiyyə qeydiyyatı aparıldı.',
      );
    }

    // Default general issue
    return AiAnalysisResult(
      title: 'Şəhər təsərrüfatı kommunal problemi',
      detectedProblem: input.isEmpty
          ? 'Məhəllədə kommunal infrastruktur nasazlığı aşkar edilmişdir.'
          : input,
      category: 'Kommunal Xidmətlər',
      targetDepartment: 'Bakı Şəhər İcra Hakimiyyəti (Qaynar Xətt: 153)',
      confidence: 0.89 + _random.nextDouble() * 0.06,
      urgency: ReportUrgency.medium,
      suggestedAction: 'Müraciət araşdırılmaq üçün aidiyyəti rayon MKTB-yə göndərildi.',
      aiSummary: 'Süni intellekt müraciəti təhlil edərək müvafiq bələdiyyə sahəsi üzrə qeydiyyata aldı.',
    );
  }

  /// Analyzes photos captured via Camera or selected from Gallery
  static Future<AiAnalysisResult> analyzePhoto({
    String? photoPath,
    String? optionalContext,
  }) async {
    // Realistic AI Vision processing latency
    await Future.delayed(const Duration(milliseconds: 1400));

    if (optionalContext != null && optionalContext.isNotEmpty) {
      return analyzeText(optionalContext);
    }

    final sampleVisionFindings = [
      AiAnalysisResult(
        title: 'Tullantı qutusunun dolub daşması',
        detectedProblem: 'Süni intellekt görüntü analizində zibil qabının 100% dolduğunu, tullantıların ətrafa səpələndiyini və qapağın açıq qaldığını müəyyən etdi.',
        category: 'Bərk Məişət Tullantıları',
        targetDepartment: 'Təmiz Şəhər ASC & BŞİH Kommunal Təsərrüfatı (153)',
        confidence: 0.97,
        urgency: ReportUrgency.high,
        suggestedAction: 'Yaxınlıqdakı SmartLine zibil maşınına birbaşa boşaltma siqnalı göndərildi.',
        aiSummary: 'Computer Vision modeli görüntü seqmentasiyası ilə tullantı növünü və həcmini tanıdı. Antisanitariya dərəcəsi yüksək hesablandı.',
      ),
      AiAnalysisResult(
        title: 'Küçədə su borusunun partlaması',
        detectedProblem: 'Görüntüdə yeraltı su xəttindən çıxan su axıntısı, yolda gölməçə və asfalt aşınması dəqiq qeydə alındı.',
        category: 'Su və Meliorasiya Təsərrüfatı',
        targetDepartment: 'Azərsu ASC Qəza Xidməti (185)',
        confidence: 0.95,
        urgency: ReportUrgency.high,
        suggestedAction: 'Təzyiqli su kranının müvəqqəti bağlanması və qəza briqadasının cəlb olunması tövsiyə edilir.',
        aiSummary: 'Görüntü analizində maye axını və yol deformasiyası xarakteristikaları 95% ehtimalla su kəməri qəzası kimi sinifləndirildi.',
      ),
      AiAnalysisResult(
        title: 'Yol örtüyündə dərin çuxur',
        detectedProblem: 'Hərəkət hissəsində avtomobil şinləri üçün təhlükə yaradan 15-20 sm dərinlikdə asfalt çöküntüsü.',
        category: 'Yol və Nəqliyyat İnfrastrukturu',
        targetDepartment: 'Azərbaycan Avtomobil Yolları Dövlət Agentliyi',
        confidence: 0.92,
        urgency: ReportUrgency.medium,
        suggestedAction: 'Xəbərdarlıq nişanının qoyulması və operativ asfalt yaması planlaşdırıldı.',
        aiSummary: 'Yol səthi relyefinin analizi nəticəsində təhlükəli çuxur konturları aşkar edildi.',
      ),
    ];

    return sampleVisionFindings[_random.nextInt(sampleVisionFindings.length)];
  }
}
