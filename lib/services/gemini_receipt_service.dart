import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class ReceiptScanResult {
  final double? total;
  final String? merchant;
  final DateTime? date;
  final String category;
  final String? itemsSummary;

  ReceiptScanResult({
    this.total,
    this.merchant,
    this.date,
    required this.category,
    this.itemsSummary,
  });
}

class GeminiReceiptService {
  static final GeminiReceiptService instance = GeminiReceiptService._();
  GeminiReceiptService._();

  static const List<String> _validCategories = [
    'Spesa e Cibo',
    'Ristoranti & Bar',
    'Trasporti & Auto',
    'Casa & Bollette',
    'Svago & Tempo Libero',
    'Shopping',
    'Salute & Cura',
    'Altro',
  ];

  Future<ReceiptScanResult> analyzeReceipt({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    List<String>? customCategories,
  }) async {
    if (geminiApiKey == 'INSERISCI_QUI_LA_TUA_CHIAVE' ||
        geminiApiKey.trim().isEmpty) {
      throw Exception(
        'Chiave API Gemini non impostata. Inserisci la tua chiave API in lib/constants/api_constants.dart',
      );
    }

    final categoriesList =
        (customCategories != null && customCategories.isNotEmpty)
        ? customCategories
        : _validCategories;
    final categoriesFormatted = categoriesList.map((c) => "'$c'").join(', ');

    final base64Image = base64Encode(imageBytes);

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$geminiModelName:generateContent?key=$geminiApiKey',
    );

    final prompt =
        '''
Sei un assistente specializzato nella lettura contabile di scontrini fiscali e ricevute.
Analizza l'immagine fornita ed estrai le seguenti informazioni in formato JSON rigoroso:
{
  "total": double o null (l'importo totale finale pagato, es. 24.50),
  "merchant": string o null (il nome dell'attività commerciale, negozio, ristorante o distributore),
  "date": string in formato YYYY-MM-DD o null (la data dello scontrino se visibile),
  "category": string (deve essere ESATTAMENTE una delle seguenti categorie: $categoriesFormatted),
  "items_summary": string o null (breve riassunto in italiano dei prodotti principali acquistati, separati da virgola)
}
Rispondi esclusivamente con un oggetto JSON valido. Se un valore non è leggibile con certezza, usa null.
''';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {'mime_type': mimeType, 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'temperature': 0.1,
      },
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      debugPrint(
        'Errore Gemini API (${response.statusCode}): ${response.body}',
      );
      try {
        final errJson = jsonDecode(response.body);
        final message =
            errJson['error']?['message'] ??
            'Errore chiamata API Gemini (${response.statusCode})';
        throw Exception(message);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception(
          'Errore durante la chiamata a Gemini (${response.statusCode})',
        );
      }
    }

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = responseJson['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception(
        'Nessuna risposta generata da Gemini per questa immagine.',
      );
    }

    final parts = candidates[0]['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Formato risposta non valido da parte di Gemini.');
    }

    final rawText = parts[0]['text'] as String? ?? '{}';
    Map<String, dynamic> parsedData;
    try {
      parsedData = jsonDecode(rawText) as Map<String, dynamic>;
    } catch (_) {
      // Se Gemini aggiunge blocchi ```json ... ``` ripuliamoli
      final cleanText = rawText.replaceAll(RegExp(r'```json|```'), '').trim();
      parsedData = jsonDecode(cleanText) as Map<String, dynamic>;
    }

    // Estrazione importo
    double? total;
    if (parsedData['total'] != null) {
      if (parsedData['total'] is num) {
        total = (parsedData['total'] as num).toDouble();
      } else if (parsedData['total'] is String) {
        total = double.tryParse(
          (parsedData['total'] as String).replaceAll(',', '.'),
        );
      }
    }

    // Estrazione negozio / esercente
    final merchant = parsedData['merchant'] as String?;

    // Estrazione data
    DateTime? date;
    if (parsedData['date'] is String) {
      try {
        date = DateTime.parse(parsedData['date'] as String);
      } catch (_) {}
    }

    // Estrazione categoria
    String category = parsedData['category'] as String? ?? categoriesList.first;
    if (!categoriesList.contains(category)) {
      category = categoriesList.first;
    }

    // Note / lista prodotti
    final itemsSummary = parsedData['items_summary'] as String?;

    return ReceiptScanResult(
      total: total,
      merchant: merchant,
      date: date,
      category: category,
      itemsSummary: itemsSummary,
    );
  }
}
