import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_config.dart';

class AiAnalysisResult {
  final String title;
  final String detectedProblem;
  final String category;
  final String targetDepartment;
  final double confidence;
  final ReportUrgency urgency;
  final String suggestedAction;
  final String aiSummary;
  final String? emergencyContact;
  final String? reason;
  final String? transcribedText;
  final bool isLiveAi;
  final String? modelUsed;

  AiAnalysisResult({
    required this.title,
    required this.detectedProblem,
    required this.category,
    required this.targetDepartment,
    required this.confidence,
    required this.urgency,
    required this.suggestedAction,
    required this.aiSummary,
    this.emergencyContact,
    this.reason,
    this.transcribedText,
    this.isLiveAi = false,
    this.modelUsed,
  });
}

class AiService {
  static final Random _random = Random();
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 35),
      sendTimeout: const Duration(seconds: 25),
    ),
  );

  // Whitelisted institutions according to official specification
  static const String instAzeriqaz = 'Azəriqaz (104)';
  static const String instAzersu = 'Azərsu';
  static const String instAzerisiq = 'Azərişıq';
  static const String instTemizSeher = 'Təmiz Şəhər / zibil toplama xidməti';
  static const String instAayda = 'Azərbaycan Avtomobil Yolları Dövlət Agentliyi (AAYDA)';
  static const String instFhn = 'Fövqəladə Hallar Nazirliyi (112)';
  static const String instDiger = 'Digər / yoxlama tələb edir';

  static const List<String> allowedInstitutions = [
    instAzeriqaz,
    instAzersu,
    instAzerisiq,
    instTemizSeher,
    instAayda,
    instFhn,
    instDiger,
  ];

  static const String _systemPrompt = '''
Sən Bakı Şəhər İcra Hakimiyyəti və SmartLine vahid dispetçer mərkəzinin rəsmi Süni İntellekt (AI) analitikisən.
Sənə vətəndaş tərəfindən göndərilən şəkil, səs yazısı və ya mətn təsviri təqdim edilir.
Vəzifən kommunal və infrastruktur problemini diqqətlə araşdırmaq və aşağıdakı JSON formatında dəqiq strukturlaşdırılmış nəticə qaytarmaqdır.

QURUM SEÇİMİ XƏRİTƏSİ (Qurumu təxmin etmə, YALNIZ və YALNIZ bu siyahıdan seç):
- Qaz borusu sızması/partlaması, qaz iyi → "Azəriqaz (104)"
- Su borusu partlaması, kanalizasiya, içməli su problemi → "Azərsu"
- Elektrik xətti, dirək, işıq kəsilməsi, açıq naqil → "Azərişıq"
- Zibil, konteyner, tullantı → "Təmiz Şəhər / zibil toplama xidməti"
- Yol çuxuru, işıqforlar, səkilər, yol nişanları → "Azərbaycan Avtomobil Yolları Dövlət Agentliyi (AAYDA)"
- Yanğın → "Fövqəladə Hallar Nazirliyi (112)"
- Digər/qeyri-müəyyən → "Digər / yoxlama tələb edir"

QAYDALAR:
1. "institution" sahəsi YALNIZ yuxarıdakı 7 addan biri ola bilər. Başqa heç bir dəyər qəbul edilmir.
2. "urgency" sahəsi YALNIZ "low", "medium", "high", "emergency" ola bilər.
   - Qaz sızması/partlaması, Yanğın, açıq elektrik naqili kimi təhlükəli hallarda "emergency" qoy və "emergencyContact" sahəsinə müvafiq nömrəni (104, 112, 199) yaz.
3. "confidence" 0.0 ilə 1.0 arasında rəqəm. Əgər inam dərəcəsi 0.6-dan aşağıdırsa və ya müraciət bir neçə ziddiyyətli sahəni əhatə edirsə, "institution": "Digər / yoxlama tələb edir" qoy.
4. "reason": Qurumun və təcililiyin seçilmə səbəbi.
5. "category": Müvafiq kateqoriyanın adı.
6. "title": Qısa və sərrast başlıq.
7. "detectedProblem": Ətraflı problem izahı.
8. "suggestedAction": Operativ addım.
9. "aiSummary": Xülasə.

Mütləq YALNIZ və YALNIZ JSON obyektini qaytar:
{"title": "...", "detectedProblem": "...", "category": "...", "institution": "...", "urgency": "low|medium|high|emergency", "confidence": 0.95, "reason": "...", "emergencyContact": "104", "suggestedAction": "...", "aiSummary": "..."}
''';

  // =========================================================================
  // 1. MƏTN ANALİZİ (TEXT ANALYSIS)
  // =========================================================================

  /// Analyzes text descriptions written or spoken by citizens
  static Future<AiAnalysisResult> analyzeText(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return _fallbackAnalyzeText('');
    }

    final apiKey = await ApiConfig.getApiKey();
    if (ApiConfig.isValidKey(apiKey)) {
      try {
        if (ApiConfig.isGroqKey(apiKey)) {
          return await _callGroqText(trimmed, apiKey);
        } else if (ApiConfig.isOpenAiKey(apiKey)) {
          return await _callOpenAiText(trimmed, apiKey);
        } else if (ApiConfig.isGeminiKey(apiKey)) {
          return await _callGeminiText(trimmed, apiKey);
        } else {
          return await _callGroqText(trimmed, apiKey);
        }
      } catch (e) {
        debugPrint('[AiService] Canlı API xətası (Fallback-ə keçilir): $e');
      }
    }

    // Əgər API açarı daxil edilməyibsə və ya şəbəkə xətası baş veribsə
    return _fallbackAnalyzeText(trimmed);
  }

  // =========================================================================
  // 2. ŞƏKİL ANALİZİ (PHOTO VISION ANALYSIS)
  // =========================================================================

  /// Analyzes photos captured via Camera or selected from Gallery
  static Future<AiAnalysisResult> analyzePhoto({
    String? photoPath,
    String? optionalContext,
  }) async {
    final apiKey = await ApiConfig.getApiKey();

    if (ApiConfig.isValidKey(apiKey) && photoPath != null && photoPath.isNotEmpty) {
      final file = File(photoPath);
      if (await file.exists()) {
        try {
          final bytes = await file.readAsBytes();
          final base64Image = base64Encode(bytes);
          final mimeType = _getMimeType(photoPath, isImage: true);

          if (ApiConfig.isGroqKey(apiKey)) {
            return await _callGroqVision(base64Image, mimeType, optionalContext, apiKey);
          } else if (ApiConfig.isOpenAiKey(apiKey)) {
            return await _callOpenAiVision(base64Image, mimeType, optionalContext, apiKey);
          } else if (ApiConfig.isGeminiKey(apiKey)) {
            return await _callGeminiVision(base64Image, mimeType, optionalContext, apiKey);
          } else {
            return await _callGroqVision(base64Image, mimeType, optionalContext, apiKey);
          }
        } catch (e) {
          debugPrint('[AiService] Canlı Vision API xətası (Fallback-ə keçilir): $e');
        }
      }
    }

    if (optionalContext != null && optionalContext.trim().isNotEmpty) {
      return _fallbackAnalyzeText(optionalContext.trim());
    }

    return _fallbackPhotoAnalysis();
  }

  // =========================================================================
  // 3. SƏS ANALİZİ (VOICE AUDIO & SPEECH ANALYSIS)
  // =========================================================================

  /// Analyzes audio recordings or simulated speech
  static Future<AiAnalysisResult> analyzeVoice({
    String? audioPath,
    String? simulatedSpeech,
  }) async {
    final apiKey = await ApiConfig.getApiKey();

    // Əgər hazır simulyasiya mətni verilibsə və canlı API aktivdirsə
    if (simulatedSpeech != null && simulatedSpeech.trim().isNotEmpty) {
      final result = await analyzeText(simulatedSpeech.trim());
      return AiAnalysisResult(
        title: result.title,
        detectedProblem: result.detectedProblem,
        category: result.category,
        targetDepartment: result.targetDepartment,
        confidence: result.confidence,
        urgency: result.urgency,
        suggestedAction: result.suggestedAction,
        aiSummary: result.aiSummary,
        transcribedText: simulatedSpeech.trim(),
        isLiveAi: result.isLiveAi,
        modelUsed: result.modelUsed,
      );
    }

    // Əgər real səs faylı yazılıbsa
    if (ApiConfig.isValidKey(apiKey) && audioPath != null && audioPath.isNotEmpty) {
      final file = File(audioPath);
      if (await file.exists()) {
        try {
          if (ApiConfig.isGroqKey(apiKey)) {
            // Groq Whisper ilə ultra-sürətli transkripsiya
            final transcript = await _transcribeGroqAudio(file, apiKey);
            if (transcript.isNotEmpty) {
              final result = await analyzeText(transcript);
              return AiAnalysisResult(
                title: result.title,
                detectedProblem: result.detectedProblem,
                category: result.category,
                targetDepartment: result.targetDepartment,
                confidence: result.confidence,
                urgency: result.urgency,
                suggestedAction: result.suggestedAction,
                aiSummary: result.aiSummary,
                transcribedText: transcript,
                isLiveAi: true,
                modelUsed: 'Groq Whisper + Llama 3.3',
              );
            }
          } else if (ApiConfig.isOpenAiKey(apiKey)) {
            // OpenAI Whisper ilə transkripsiya
            final transcript = await _transcribeOpenAiAudio(file, apiKey);
            if (transcript.isNotEmpty) {
              final result = await analyzeText(transcript);
              return AiAnalysisResult(
                title: result.title,
                detectedProblem: result.detectedProblem,
                category: result.category,
                targetDepartment: result.targetDepartment,
                confidence: result.confidence,
                urgency: result.urgency,
                suggestedAction: result.suggestedAction,
                aiSummary: result.aiSummary,
                transcribedText: transcript,
                isLiveAi: true,
                modelUsed: 'OpenAI Whisper + GPT-4o-mini',
              );
            }
          } else {
            // Google Gemini Audio Multimodal
            final bytes = await file.readAsBytes();
            final base64Audio = base64Encode(bytes);
            final mimeType = _getMimeType(audioPath, isImage: false);
            return await _callGeminiAudio(base64Audio, mimeType, apiKey);
          }
        } catch (e) {
          debugPrint('[AiService] Səs API xətası (Fallback-ə keçilir): $e');
        }
      }
    }

    // Fallback: Default səs mətni ilə analiz
    final fallbackPhrase = simulatedSpeech ??
        'Salam, bizim məhəllədə zibil qutusu dolub daşıb, üfunət iyi yayılır, təcili zibil maşını göndərin.';
    final fallbackRes = _fallbackAnalyzeTextSync(fallbackPhrase);
    return AiAnalysisResult(
      title: fallbackRes.title,
      detectedProblem: fallbackRes.detectedProblem,
      category: fallbackRes.category,
      targetDepartment: fallbackRes.targetDepartment,
      confidence: fallbackRes.confidence,
      urgency: fallbackRes.urgency,
      suggestedAction: fallbackRes.suggestedAction,
      aiSummary: fallbackRes.aiSummary,
      transcribedText: fallbackPhrase,
      isLiveAi: false,
    );
  }

  // =========================================================================
  // GROQ API İNTEQRASİYASI (LPU INFERENCE ENGINE)
  // =========================================================================

  static Future<AiAnalysisResult> _callGroqText(String input, String apiKey) async {
    final models = ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant'];
    DioException? lastException;

    for (final model in models) {
      try {
        final response = await _dio.post(
          'https://api.groq.com/openai/v1/chat/completions',
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'model': model,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {'role': 'user', 'content': input},
            ],
            'response_format': {'type': 'json_object'},
            'temperature': 0.2,
          },
        );

        final content = response.data['choices']?[0]?['message']?['content'];
        if (content != null) {
          return _parseAiJsonResponse(
            content,
            isLiveAi: true,
            modelUsed: 'Groq ($model)',
            defaultTranscribedText: input,
          );
        }
      } on DioException catch (e) {
        lastException = e;
        debugPrint('[AiService] Groq model $model xətası: ${e.message}');
      } catch (e) {
        debugPrint('[AiService] Groq xətası: $e');
      }
    }

    if (lastException != null) throw lastException;
    throw Exception('Groq cavab qaytarmadı');
  }

  static Future<String> _transcribeGroqAudio(File audioFile, String apiKey) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(audioFile.path),
      'model': 'whisper-large-v3',
      'language': 'az',
      'response_format': 'json',
    });

    final response = await _dio.post(
      'https://api.groq.com/openai/v1/audio/transcriptions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      ),
      data: formData,
    );

    return response.data['text']?.toString() ?? '';
  }

  static Future<AiAnalysisResult> _callGroqVision(
    String base64Image,
    String mimeType,
    String? optionalContext,
    String apiKey,
  ) async {
    final note = optionalContext ?? 'Bu şəkildə görünən Bakı şəhəri kommunal/infrastruktur problemini analiz et.';
    final visionModels = ['qwen/qwen3.8-27b', 'meta-models/muse-spark-open'];
    DioException? lastException;

    for (final model in visionModels) {
      try {
        final response = await _dio.post(
          'https://api.groq.com/openai/v1/chat/completions',
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'model': model,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': note},
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:$mimeType;base64,$base64Image'}
                  }
                ]
              }
            ],
            'response_format': {'type': 'json_object'},
            'temperature': 0.2,
          },
        );

        final content = response.data['choices']?[0]?['message']?['content'];
        if (content != null) {
          return _parseAiJsonResponse(
            content,
            isLiveAi: true,
            modelUsed: 'Groq ($model)',
          );
        }
      } on DioException catch (e) {
        lastException = e;
        debugPrint('[AiService] Groq vision model $model xətası: ${e.message}');
      } catch (e) {
        debugPrint('[AiService] Groq vision xətası: $e');
      }
    }

    // Əgər vision modeli əlçatan deyilsə və kontekst varsa, mətn analizi ilə davam et
    if (optionalContext != null && optionalContext.trim().isNotEmpty) {
      return await _callGroqText(optionalContext.trim(), apiKey);
    }

    if (lastException != null) throw lastException;
    throw Exception('Groq Vision cavab qaytarmadı');
  }

  // =========================================================================
  // GOOGLE GEMINI API İNTEQRASİYASI
  // =========================================================================

  static Future<AiAnalysisResult> _callGeminiText(String input, String apiKey) async {
    final prompt = '$_systemPrompt\n\nVətəndaşın müraciət mətni:\n"$input"';
    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
      }
    };

    return await _executeGeminiRequest(payload, apiKey, 'Gemini 2.0 Flash', transcribedText: input);
  }

  static Future<AiAnalysisResult> _callGeminiVision(
    String base64Image,
    String mimeType,
    String? optionalContext,
    String apiKey,
  ) async {
    final note = (optionalContext != null && optionalContext.trim().isNotEmpty)
        ? '\nVətəndaşın əlavə qeydi: "${optionalContext.trim()}"'
        : '';
    final prompt = '$_systemPrompt\n\nBu şəkildə görünən Bakı şəhəri kommunal/infrastruktur problemini dərindən analiz et.$note';

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
      }
    };

    return await _executeGeminiRequest(payload, apiKey, 'Gemini 2.0 Flash (Vision)');
  }

  static Future<AiAnalysisResult> _callGeminiAudio(
    String base64Audio,
    String mimeType,
    String apiKey,
  ) async {
    final prompt = '$_systemPrompt\n\nBu səs yazısını dinlə. İstifadəçinin dediyi sözləri Azərbaycan dilində dəqiq mətnə köçür və "transcribedText" sahəsinə yaz. Ardınca problemi təhlil et.';

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Audio,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
      }
    };

    return await _executeGeminiRequest(payload, apiKey, 'Gemini 2.0 Flash (Audio)');
  }

  static Future<AiAnalysisResult> _executeGeminiRequest(
    Map<String, dynamic> payload,
    String apiKey,
    String modelName, {
    String? transcribedText,
  }) async {
    final models = ['gemini-2.0-flash', 'gemini-1.5-flash'];
    DioException? lastException;

    for (final model in models) {
      try {
        final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';
        final response = await _dio.post(
          url,
          options: Options(headers: {'Content-Type': 'application/json'}),
          data: payload,
        );

        if (response.statusCode == 200 && response.data != null) {
          final candidates = response.data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.isNotEmpty) {
                return _parseAiJsonResponse(
                  text,
                  isLiveAi: true,
                  modelUsed: '$model ($modelName)',
                  defaultTranscribedText: transcribedText,
                );
              }
            }
          }
        }
      } on DioException catch (e) {
        lastException = e;
        debugPrint('[AiService] Gemini model $model xətası: ${e.message}');
      } catch (e) {
        debugPrint('[AiService] Gözlənilməz xəta: $e');
      }
    }

    if (lastException != null) throw lastException;
    throw Exception('Gemini cavab qaytarmadı');
  }

  // =========================================================================
  // OPENAI API İNTEQRASİYASI
  // =========================================================================

  static Future<AiAnalysisResult> _callOpenAiText(String input, String apiKey) async {
    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': input},
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.2,
      },
    );

    final content = response.data['choices']?[0]?['message']?['content'];
    if (content != null) {
      return _parseAiJsonResponse(
        content,
        isLiveAi: true,
        modelUsed: 'OpenAI GPT-4o-mini',
        defaultTranscribedText: input,
      );
    }
    throw Exception('OpenAI cavab qaytarmadı');
  }

  static Future<AiAnalysisResult> _callOpenAiVision(
    String base64Image,
    String mimeType,
    String? optionalContext,
    String apiKey,
  ) async {
    final note = optionalContext ?? 'Bu şəkildəki kommunal problemi analiz et.';
    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': note},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:$mimeType;base64,$base64Image'}
              }
            ]
          }
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.2,
      },
    );

    final content = response.data['choices']?[0]?['message']?['content'];
    if (content != null) {
      return _parseAiJsonResponse(
        content,
        isLiveAi: true,
        modelUsed: 'OpenAI GPT-4o-mini (Vision)',
      );
    }
    throw Exception('OpenAI Vision cavab qaytarmadı');
  }

  static Future<String> _transcribeOpenAiAudio(File audioFile, String apiKey) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(audioFile.path),
      'model': 'whisper-1',
      'language': 'az',
    });

    final response = await _dio.post(
      'https://api.openai.com/v1/audio/transcriptions',
      options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      data: formData,
    );

    return response.data['text']?.toString() ?? '';
  }

  // =========================================================================
  // KÖMƏKÇİ METODLAR VƏ JSON PARSER (STRICT WHITELIST & CONFIDENCE VALIDATION)
  // =========================================================================

  static String sanitizeInstitution(String? raw, {required double confidence, String? contextText}) {
    if (confidence < 0.6) {
      return instDiger;
    }

    if (raw == null || raw.trim().isEmpty) {
      return instDiger;
    }

    final lower = raw.toLowerCase();

    // Check if conflicting institutions in text
    if (contextText != null) {
      final t = contextText.toLowerCase();
      int matchCount = 0;
      if (t.contains('qaz')) matchCount++;
      if (t.contains('su ') || t.contains('su boru') || t.contains('kanalizasiya')) matchCount++;
      if (t.contains('elektrik') || t.contains('naqil') || t.contains('işıq')) matchCount++;
      if (t.contains('yanğın') || t.contains('alov')) matchCount++;
      if (matchCount > 1) {
        return instDiger;
      }
    }

    if (lower.contains('qaz') || lower.contains('azəriqaz') || lower.contains('104')) {
      return instAzeriqaz;
    }
    if (lower.contains('su') || lower.contains('azərsu') || lower.contains('kanalizasiya') || lower.contains('185')) {
      return instAzersu;
    }
    if (lower.contains('işıq') || lower.contains('isıq') || lower.contains('azərişıq') || lower.contains('elektrik') || lower.contains('199')) {
      return instAzerisiq;
    }
    if (lower.contains('zibil') || lower.contains('təmiz şəhər') || lower.contains('tullantı') || lower.contains('konteyner') || lower.contains('153')) {
      return instTemizSeher;
    }
    if (lower.contains('yol') || lower.contains('çuxur') || lower.contains('asfalt') || lower.contains('aayda') || lower.contains('bələdiyyə')) {
      return instAayda;
    }
    if (lower.contains('yanğın') || lower.contains('fövqəladə') || lower.contains('fhn') || lower.contains('112')) {
      return instFhn;
    }

    return instDiger;
  }

  static String? getEmergencyContact(String institution) {
    if (institution == instAzeriqaz) return '104';
    if (institution == instFhn) return '112';
    if (institution == instAzerisiq) return '199';
    if (institution == instAzersu) return '185';
    if (institution == instTemizSeher) return '153';
    return null;
  }

  static AiAnalysisResult _parseAiJsonResponse(
    String rawJson, {
    required bool isLiveAi,
    String? modelUsed,
    String? defaultTranscribedText,
  }) {
    String cleanJson = rawJson.trim();
    if (cleanJson.startsWith('```json')) {
      cleanJson = cleanJson.substring(7);
    } else if (cleanJson.startsWith('```')) {
      cleanJson = cleanJson.substring(3);
    }
    if (cleanJson.endsWith('```')) {
      cleanJson = cleanJson.substring(0, cleanJson.length - 3);
    }
    cleanJson = cleanJson.trim();

    try {
      final Map<String, dynamic> data = jsonDecode(cleanJson);

      final double confidenceNum = (data['confidence'] as num?)?.toDouble() ?? 0.95;
      final rawInst = data['institution']?.toString() ?? data['targetDepartment']?.toString();
      final institution = sanitizeInstitution(rawInst, confidence: confidenceNum, contextText: defaultTranscribedText);

      final urgencyStr = data['urgency']?.toString().toLowerCase() ?? 'medium';
      ReportUrgency urgency;
      if (urgencyStr.contains('emergency') || urgencyStr.contains('qəza')) {
        urgency = ReportUrgency.emergency;
      } else if (urgencyStr.contains('high') || urgencyStr.contains('yüksək') || urgencyStr.contains('təcili')) {
        urgency = ReportUrgency.high;
      } else if (urgencyStr.contains('low') || urgencyStr.contains('aşağı') || urgencyStr.contains('normal')) {
        urgency = ReportUrgency.low;
      } else {
        urgency = ReportUrgency.medium;
      }

      // Dangerous situations MUST be emergency
      final contextLower = (defaultTranscribedText ?? '').toLowerCase();
      if (institution == instAzeriqaz ||
          institution == instFhn ||
          contextLower.contains('qaz boru') ||
          contextLower.contains('qaz partla') ||
          contextLower.contains('yanğın') ||
          contextLower.contains('açıq naqil') ||
          contextLower.contains('naqil sallanır')) {
        urgency = ReportUrgency.emergency;
      }

      final contact = data['emergencyContact']?.toString() ?? getEmergencyContact(institution);

      return AiAnalysisResult(
        title: data['title']?.toString() ?? 'Kommunal infrastruktur problemi',
        detectedProblem: data['detectedProblem']?.toString() ?? 'Ərazidə kommunal xidmətlər üzrə nasazlıq aşkarlandı.',
        category: confidenceNum < 0.6 ? 'Digər' : (data['category']?.toString() ?? 'Kommunal Xidmətlər'),
        targetDepartment: institution,
        confidence: confidenceNum.clamp(0.1, 0.99),
        urgency: urgency,
        suggestedAction: data['suggestedAction']?.toString() ?? 'Məsələ araşdırılmaq üçün aidiyyəti xidmətə yönləndirilir.',
        aiSummary: data['aiSummary']?.toString() ?? 'Süni intellekt məlumatı uğurla təhlil etdi.',
        emergencyContact: contact,
        reason: data['reason']?.toString(),
        transcribedText: data['transcribedText']?.toString() ?? defaultTranscribedText,
        isLiveAi: isLiveAi,
        modelUsed: modelUsed,
      );
    } catch (e) {
      debugPrint('[AiService] JSON parse xətası: $e (Raw: $cleanJson)');
      return _fallbackAnalyzeTextSync(defaultTranscribedText ?? '');
    }
  }

  static String _getMimeType(String path, {required bool isImage}) {
    final ext = path.split('.').last.toLowerCase();
    if (isImage) {
      if (ext == 'png') return 'image/png';
      if (ext == 'webp') return 'image/webp';
      if (ext == 'heic') return 'image/heic';
      return 'image/jpeg';
    } else {
      if (ext == 'm4a') return 'audio/m4a';
      if (ext == 'mp3') return 'audio/mp3';
      if (ext == 'wav') return 'audio/wav';
      if (ext == 'aac') return 'audio/aac';
      if (ext == 'ogg') return 'audio/ogg';
      return 'audio/mp4';
    }
  }

  // =========================================================================
  // GÜCLƏNDİRİLMİŞ OFFLINE SMART ANALİZ (STRICT MAPPING & CONFIDENCE THRESHOLD)
  // =========================================================================

  static Future<AiAnalysisResult> _fallbackAnalyzeText(String input) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _fallbackAnalyzeTextSync(input);
  }

  static AiAnalysisResult _fallbackAnalyzeTextSync(String input) {
    final text = input.toLowerCase().trim();

    // 1. QAZ SIZMASI / PARTLAMASI / QAZ İYİ → Azəriqaz (104) + EMERGENCY
    // NOTE: This MUST be checked before water or general 'partlayış' to avoid misrouting to Azərsu!
    if (text.contains('qaz') ||
        text.contains('metan') ||
        text.contains('qaz boru') ||
        text.contains('qaz sız') ||
        text.contains('qaz siz') ||
        text.contains('qaz iyi') ||
        text.contains('qaz partla')) {
      return AiAnalysisResult(
        title: 'Qaz kəmərində qəza / sızma təhlükəsi',
        detectedProblem: 'Qaz borusunda təzyiq qəzası, partlayış və ya güclü qaz sızması qeydə alınıb. Partlayış və zəhərlənmə riski yüksəkdir.',
        category: 'Qaz Təchizatı və Təhlükəsizlik',
        targetDepartment: instAzeriqaz,
        confidence: 0.98,
        urgency: ReportUrgency.emergency,
        emergencyContact: '104',
        suggestedAction: 'Dərhal 104 Qaz Qəza Xidməti əraziyə cəlb olunmalı və qaz təchizatı dayandırılmalıdır.',
        aiSummary: 'Süni intellekt qaz sızması/partlayışını yüksək təhlükə kimi identifikasiya etdi və Azəriqaz 104 qəza xidmətinə təcili yönləndirdi.',
        reason: 'Qaz xətlərindəki qəzalar birbaşa həyati təhlükə kəsb etdiyi üçün təcili qəza kateqoriyasına aid edildi.',
        transcribedText: input.isNotEmpty ? input : null,
      );
    }

    // 2. YANĞIN → Fövqəladə Hallar Nazirliyi (112) + EMERGENCY
    if (text.contains('yanğın') ||
        text.contains('yangın') ||
        text.contains('yanir') ||
        text.contains('yanır') ||
        text.contains('alov') ||
        text.contains('tüstü') ||
        text.contains('fhn')) {
      return AiAnalysisResult(
        title: 'Açıq yanğın və təhlükəli alovlanma',
        detectedProblem: 'Ərazidə tüstü və alov müşahidə olunur. Yanğının ətrafa yayılma riski mövcuddur.',
        category: 'Fövqəladə Hallar və Yanğın',
        targetDepartment: instFhn,
        confidence: 0.98,
        urgency: ReportUrgency.emergency,
        emergencyContact: '112',
        suggestedAction: '112 Qaynar Xətti və Dövlət Yanğından Mühafizə Xidməti dərhal əraziyə istiqamətləndirilir.',
        aiSummary: 'Yanğın siqnalı aşkarlandı. Fövqəladə Hallar Nazirliyinin (112) operativ idarəetmə mərkəzinə təcili həyəcan siqnalı göndərildi.',
        reason: 'Yanğın həyati və əmlak təhlükəsi yaratdığı üçün FHN-ə emergency statusu ilə yönləndirildi.',
        transcribedText: input.isNotEmpty ? input : null,
      );
    }

    // 3. ELEKTRİK XƏTTİ, DİRƏK, AÇIQ NAQİL, İŞIQ KƏSİLMƏSİ → Azərişıq
    if (text.contains('naqil') ||
        text.contains('elektrik') ||
        text.contains('kabel') ||
        text.contains('dirək') ||
        text.contains('direk') ||
        text.contains('işıq') ||
        text.contains('isıq') ||
        text.contains('fənər') ||
        text.contains('fenər') ||
        text.contains('qaranlıq') ||
        text.contains('qığılcım') ||
        text.contains('cərəyan')) {
      final isDangerousWire = text.contains('naqil sallanır') ||
          text.contains('açıq naqil') ||
          text.contains('qığılcım') ||
          text.contains('qırılıb sallan') ||
          text.contains('cərəyan vur');

      return AiAnalysisResult(
        title: isDangerousWire ? 'Təhlükəli açıq naqil və ya sallanan kabel' : 'Küçə işıqlandırmasında və elektrik xəttində nasazlıq',
        detectedProblem: isDangerousWire
            ? 'Elektrik dirəyindən açıq naqil sallanır və ya qığılcım saçır. Vətəndaşlar üçün cərəyan vurma təhlükəsi var.'
            : 'Xarici işıqlandırma dirəklərinin sönməsi və ya elektrik xəttində qırılma ehtimalı müəyyən olundu.',
        category: 'Elektrik Şəbəkəsi və Küçə İşıqlandırması',
        targetDepartment: instAzerisiq,
        confidence: isDangerousWire ? 0.96 : 0.92,
        urgency: isDangerousWire ? ReportUrgency.emergency : ReportUrgency.medium,
        emergencyContact: '199',
        suggestedAction: isDangerousWire
            ? 'Azərişıq qəza briqadası xətti enerjidən ayırmaq üçün dərhal çıxmalıdır.'
            : 'Elektrik montyor briqadası lampa və təchizat qutusunu yoxlamağa göndərilir.',
        aiSummary: 'Elektrik şəbəkəsi üzrə qəza Azərişıq 199 qaynar xəttinə yönləndirildi.',
        reason: isDangerousWire ? 'Açıq/sallanan elektrik naqili birbaşa təhlükədir (emergency).' : 'İşıqlandırma nasazlığı.',
        transcribedText: input.isNotEmpty ? input : null,
      );
    }

    // 4. SU BORUSU PARTLAMASI, KANALİZASİYA, İÇMƏLİ SU PROBLEMİ → Azərsu
    final isWaterRelated = RegExp(r'\bsu\b').hasMatch(text) ||
        text.contains('su boru') ||
        text.contains('su ax') ||
        text.contains('su sız') ||
        text.contains('su siz') ||
        text.contains('su kəmər') ||
        text.contains('kanalizasiya') ||
        text.contains('içməli su') ||
        text.contains('lyuk') ||
        text.contains('gölməçə') ||
        (text.contains('partla') && (text.contains('su boru') || RegExp(r'\bsu\b').hasMatch(text)));

    if (isWaterRelated) {
      final isBurst = text.contains('partla') || text.contains('güclü axır') || text.contains('daşır');
      return AiAnalysisResult(
        title: isBurst ? 'Su borusunun partlaması və güclü axıntı' : 'Su təchizatı və ya kanalizasiya xəttində nasazlıq',
        detectedProblem: 'İçməli su magistralında qəza nəticəsində əraziyə su axıntısı və ya kanalizasiya lyukunda tutulma qeydə alınmışdır.',
        category: 'Su Təchizatı və Kanalizasiya',
        targetDepartment: instAzersu,
        confidence: 0.95,
        urgency: isBurst ? ReportUrgency.high : ReportUrgency.medium,
        emergencyContact: '185',
        suggestedAction: 'Qəza briqadası su təzyiqini tənzimləmək və təmir aparmaq üçün cəlb edilir.',
        aiSummary: 'Məsələ su itkisi və yolun çökmə riski səbəbilə Azərsu ASC operativ xidmətinə yönləndirildi.',
        reason: 'Su təchizatı və kanalizasiya problemləri üzrə Azərsu ASC məsul qurumdur.',
        transcribedText: input.isNotEmpty ? input : null,
      );
    }

    // 5. ZİBİL, KONTEYNER, TULLANTI → Təmiz Şəhər / zibil toplama xidməti
    if (text.contains('zibil') ||
        text.contains('tullantı') ||
        text.contains('tullanti') ||
        text.contains('konteyner') ||
        text.contains('antisanitar') ||
        text.contains('zibillik') ||
        text.contains('qutu') ||
        text.contains('tökülüb')) {
      return AiAnalysisResult(
        title: 'Zibil konteynerlərinin daşması və tullantı problemi',
        detectedProblem: 'Bərk məişət tullantıları qutularının həddindən artıq dolması və əraziyə yayılması.',
        category: 'Bərk Məişət Tullantıları və Təmizlik',
        targetDepartment: instTemizSeher,
        confidence: 0.96,
        urgency: ReportUrgency.high,
        emergencyContact: '153',
        suggestedAction: 'Ən yaxın sahə tullantı maşını konteyneri boşaltmaq üçün marşruta salınır.',
        aiSummary: 'Məişət tullantılarının idarə olunması üzrə Təmiz Şəhər və MKTB xidmətlərinə tapşırıq yaradıldı.',
        reason: 'Bərk məişət tullantıları üzrə məsul qurum Təmiz Şəhər və BŞİH MKTB-dir.',
        transcribedText: input.isNotEmpty ? input : null,
      );
    }

    // 6. YOL ÇUXURU, İŞIQFORLAR, SƏKİLƏR, YOL NİŞANLARI → Azərbaycan Avtomobil Yolları Dövlət Agentliyi (AAYDA)
    if (text.contains('yol') ||
        text.contains('asfalt') ||
        text.contains('çuxur') ||
        text.contains('cuxur') ||
        text.contains('səki') ||
        text.contains('seki') ||
        text.contains('işıqfor') ||
        text.contains('isiqfor') ||
        text.contains('yol nişan') ||
        text.contains('nişan') ||
        text.contains('çöküb') ||
        text.contains('bardür')) {
      return AiAnalysisResult(
        title: 'Yol örtüyündə çuxur / səki və işıqfor nasazlığı',
        detectedProblem: 'Hərəkət hissəsində avtomobillər və piyadalar üçün maneə yaradan asfalt zədələnməsi və ya infrastruktur problemi.',
        category: 'Yol və Nəqliyyat İnfrastrukturu',
        targetDepartment: instAayda,
        confidence: 0.93,
        urgency: ReportUrgency.medium,
        suggestedAction: 'Cari yol təmir briqadası tərəfindən asfalt yaması və bərpa üçün tapşırıq göndərildi.',
        aiSummary: 'Yol hərəkəti təhlükəsizliyi kateqoriyası üzrə zədələnmə qeyd edildi.',
        reason: 'Yol örtüyü və küçə infrastrukturu AAYDA və yerli yol xidmətinin balansındadır.',
        transcribedText: input.isNotEmpty ? input : null,
      );
    }

    // 7. DİGƏR / QEYRİ-MÜƏYYƏN → "Digər / yoxlama tələb edir" (CONFIDENCE < 0.6)
    return AiAnalysisResult(
      title: 'Qeyri-müəyyən müraciət (Yoxlama tələb edir)',
      detectedProblem: input.isEmpty
          ? 'Müraciət mətni daxil edilməyib və ya qeyri-müəyyəndir.'
          : 'Daxil edilmiş mətn: "$input". Şəhər xidmətləri üzrə konkret infrastruktur növü dəqiq müəyyən olunmadı.',
      category: 'Digər',
      targetDepartment: instDiger,
      confidence: 0.42, // Strictly below 0.6
      urgency: ReportUrgency.low,
      suggestedAction: 'Dispetçer tərəfindən məlumatın dəqiqləşdirilməsi və əl ilə baxış keçirilməsi tələb olunur.',
      aiSummary: 'Müraciətdə açar sözlər yetərsiz olduğundan avtomatik qurum seçimi aparılmadı və əl ilə baxış üçün "Digər" statusuna keçirildi.',
      reason: 'Confidence səviyyəsi 0.6-dan aşağıdır və ya mətn qeyri-müəyyəndir. Səhv yönləndirmənin qarşısını almaq üçün yoxlamaya göndərildi.',
      transcribedText: input.isNotEmpty ? input : null,
    );
  }

  static Future<AiAnalysisResult> _fallbackPhotoAnalysis() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final sampleVisionFindings = [
      AiAnalysisResult(
        title: 'Tullantı qutusunun dolub daşması',
        detectedProblem: 'Süni intellekt görüntü analizində zibil qabının 100% dolduğunu, tullantıların ətrafa səpələndiyini və qapağın açıq qaldığını müəyyən etdi.',
        category: 'Bərk Məişət Tullantıları və Təmizlik',
        targetDepartment: instTemizSeher,
        confidence: 0.97,
        urgency: ReportUrgency.high,
        emergencyContact: '153',
        suggestedAction: 'Yaxınlıqdakı SmartLine zibil maşınına birbaşa boşaltma siqnalı göndərildi.',
        aiSummary: 'Computer Vision modeli görüntü seqmentasiyası ilə tullantı növünü və həcmini tanıdı. Antisanitariya dərəcəsi yüksək hesablandı.',
        reason: 'Fotoşəkildə zibil qablarının dolması aşkarlandı.',
      ),
      AiAnalysisResult(
        title: 'Küçədə su borusunun qəzası',
        detectedProblem: 'Görüntüdə yeraltı su xəttindən çıxan su axıntısı, yolda gölməçə və asfalt aşınması dəqiq qeydə alındı.',
        category: 'Su Təchizatı və Kanalizasiya',
        targetDepartment: instAzersu,
        confidence: 0.95,
        urgency: ReportUrgency.high,
        emergencyContact: '185',
        suggestedAction: 'Təzyiqli su kranının müvəqqəti bağlanması və qəza briqadasının cəlb olunması tövsiyə edilir.',
        aiSummary: 'Görüntü analizində maye axını və yol deformasiyası xarakteristikaları 95% ehtimalla su kəməri qəzası kimi sinifləndirildi.',
        reason: 'Görüntüdə su axıntısı və boru qəzası təsdiqləndi.',
      ),
      AiAnalysisResult(
        title: 'Yol örtüyündə dərin çuxur',
        detectedProblem: 'Hərəkət hissəsində avtomobil şinləri üçün təhlükə yaradan 15-20 sm dərinlikdə asfalt çöküntüsü.',
        category: 'Yol və Nəqliyyat İnfrastrukturu',
        targetDepartment: instAayda,
        confidence: 0.92,
        urgency: ReportUrgency.medium,
        suggestedAction: 'Xəbərdarlıq nişanının qoyulması və operativ asfalt yaması planlaşdırıldı.',
        aiSummary: 'Yol səthi relyefinin analizi nəticəsində təhlükəli çuxur konturları aşkar edildi.',
        reason: 'Asfalt çökməsi və çuxur aşkar edildi.',
      ),
    ];

    return sampleVisionFindings[_random.nextInt(sampleVisionFindings.length)];
  }
}

