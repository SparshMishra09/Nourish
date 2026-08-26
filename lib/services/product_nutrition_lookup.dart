import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/food_analysis.dart';

abstract interface class ProductNutritionLookup {
  Future<ProductNutritionMatch?> lookup(FoodAnalysis visualAnalysis);
}

class HybridProductNutritionLookup implements ProductNutritionLookup {
  HybridProductNutritionLookup({
    OpenFoodFactsProductLookup? openFoodFacts,
    GoogleGroundedProductLookup? googleSearch,
    PublicWebLabelLookup? publicWeb,
  }) : _openFoodFacts = openFoodFacts ?? OpenFoodFactsProductLookup(),
       _googleSearch = googleSearch ?? GoogleGroundedProductLookup(),
       _publicWeb = publicWeb ?? PublicWebLabelLookup();

  final OpenFoodFactsProductLookup _openFoodFacts;
  final GoogleGroundedProductLookup _googleSearch;
  final PublicWebLabelLookup _publicWeb;

  @override
  Future<ProductNutritionMatch?> lookup(FoodAnalysis visualAnalysis) async {
    try {
      final labelMatch = await _openFoodFacts.lookup(visualAnalysis);
      if (labelMatch != null) return labelMatch;
    } catch (error) {
      debugPrint('Open Food Facts lookup skipped: $error');
    }

    try {
      final groundedMatch = await _googleSearch.lookup(visualAnalysis);
      if (groundedMatch != null) return groundedMatch;
    } catch (error) {
      debugPrint('Grounded product search skipped: $error');
    }

    try {
      return await _publicWeb.lookup(visualAnalysis);
    } catch (error) {
      debugPrint('Public web-label lookup skipped: $error');
      return null;
    }
  }
}

class OpenFoodFactsProductLookup implements ProductNutritionLookup {
  OpenFoodFactsProductLookup({http.Client? client})
    : _client = client ?? http.Client();

  static const _userAgent =
      'Nourish/1.10.0 Android (https://github.com/SparshMishra09/Nourish)';
  static const _fields = <String>[
    'code',
    'product_name',
    'brands',
    'serving_size',
    'serving_quantity',
    'serving_quantity_unit',
    'nutriments',
  ];

  final http.Client _client;

  @override
  Future<ProductNutritionMatch?> lookup(FoodAnalysis visualAnalysis) async {
    final barcode = _digitsOnly(visualAnalysis.barcode);
    if (barcode.length >= 8 && barcode.length <= 14) {
      final product = await _getByBarcode(barcode);
      final match = _matchFromProduct(
        product,
        visualAnalysis,
        exactBarcode: barcode,
      );
      if (match != null) return match;
    }

    final query = [
      visualAnalysis.brandName,
      visualAnalysis.productName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    if (_meaningfulTokens(query).length < 2) return null;

    final response = await _client
        .post(
          Uri.parse('https://search.openfoodfacts.org/search'),
          headers: const {
            'User-Agent': _userAgent,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'q': query,
            'page_size': 8,
            'page': 1,
            'fields': _fields,
            'langs': ['en'],
            'boost_phrase': true,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    final hits = decoded['hits'];
    if (hits is! List) return null;

    ProductNutritionMatch? best;
    for (final hit in hits.whereType<Map>()) {
      final match = _matchFromProduct(
        Map<String, dynamic>.from(hit),
        visualAnalysis,
      );
      if (match != null &&
          (best == null || match.matchConfidence > best.matchConfidence)) {
        best = match;
      }
    }
    return best;
  }

  Future<Map<String, dynamic>?> _getByBarcode(String barcode) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v3/product/$barcode',
    ).replace(queryParameters: {'fields': _fields.join(',')});
    final response = await _client
        .get(
          uri,
          headers: const {
            'User-Agent': _userAgent,
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['product'] is! Map) return null;
    return Map<String, dynamic>.from(decoded['product'] as Map);
  }

  ProductNutritionMatch? _matchFromProduct(
    Map<String, dynamic>? product,
    FoodAnalysis visualAnalysis, {
    String exactBarcode = '',
  }) {
    if (product == null) return null;
    final productName = _text(product['product_name']);
    final brandName = _text(product['brands']);
    final code = _digitsOnly(_text(product['code']));
    final expected =
        '${visualAnalysis.brandName} ${visualAnalysis.productName}';
    final found = '$brandName $productName';
    final exactCode = exactBarcode.isNotEmpty && code == exactBarcode;
    final score = exactCode ? 1.0 : _productMatchScore(expected, found);
    if (!exactCode && score < 0.78) return null;

    final nutrimentsValue = product['nutriments'];
    if (nutrimentsValue is! Map) return null;
    final nutriments = Map<String, dynamic>.from(nutrimentsValue);
    final servingGrams = _servingGrams(product, visualAnalysis);
    if (servingGrams == null) return null;
    final values = _nutritionForServing(nutriments, servingGrams);
    if (values == null) return null;

    final servingSize = _text(product['serving_size']);
    final servingLabel = servingSize.isNotEmpty
        ? servingSize
        : '${_cleanNumber(servingGrams)} g serving';
    final sourceUrl = code.isEmpty
        ? 'https://world.openfoodfacts.org/'
        : 'https://world.openfoodfacts.org/product/$code';
    return ProductNutritionMatch(
      productName: productName.isEmpty
          ? visualAnalysis.productName
          : productName,
      brandName: brandName.isEmpty ? visualAnalysis.brandName : brandName,
      barcode: code.isEmpty ? exactBarcode : code,
      servingLabel: servingLabel,
      servingGrams: servingGrams,
      calories: values.calories.round(),
      protein: values.protein,
      carbs: values.carbs,
      fat: values.fat,
      fiber: values.fiber,
      sugar: values.sugar,
      sodiumMg: values.sodiumMg.round(),
      matchConfidence: score.clamp(0, 1),
      nutritionSource: 'openFoodFacts',
      sourceNote:
          'Matched to a live community label record. Confirm the exact flavour and pack size.',
      sources: [
        NutritionSourceRef(
          title: 'Open Food Facts product label',
          url: sourceUrl,
        ),
      ],
    );
  }
}

class GoogleGroundedProductLookup implements ProductNutritionLookup {
  GoogleGroundedProductLookup({GenerativeModel? model})
    : _model = model ?? _buildModel();

  final GenerativeModel _model;

  static GenerativeModel _buildModel() {
    return FirebaseAI.googleAI().generativeModel(
      // Grounding is kept on the currently supported stable search model. The
      // vision pass can evolve independently from product verification.
      model: 'gemini-3.6-flash',
      tools: [Tool.googleSearch()],
      generationConfig: GenerationConfig(temperature: 0, maxOutputTokens: 2048),
      systemInstruction: Content.system(
        'You verify packaged-food nutrition using current web sources. Match the exact '
        'brand, product variant, flavour, country, pack, and barcode when available. '
        'Prioritize the manufacturer and a published nutrition label. Never substitute '
        'a similar product. If the exact product or serving cannot be verified, return '
        'exactProductMatch false. Nutrients must describe one stated serving.',
      ),
    );
  }

  @override
  Future<ProductNutritionMatch?> lookup(FoodAnalysis visualAnalysis) async {
    final identity = [
      visualAnalysis.brandName,
      visualAnalysis.productName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    if (_meaningfulTokens(identity).length < 2 &&
        _digitsOnly(visualAnalysis.barcode).length < 8) {
      return null;
    }
    final visualServing = visualAnalysis.items.isEmpty
        ? ''
        : visualAnalysis.items.first.quantity;
    final prompt =
        '''
Search the public web for the exact nutrition label of this photographed packaged food.
Brand seen: ${visualAnalysis.brandName}
Product and variant seen: ${visualAnalysis.productName}
Barcode seen: ${visualAnalysis.barcode}
Visual serving clue: $visualServing

Return only one JSON object with these keys:
exactProductMatch (boolean), productName, brandName, barcode, servingLabel,
servingGrams, calories, protein, carbs, fat, fiber, sugar, sodiumMg,
confidence (0 to 1), sourceNote.
Use numbers, not strings, for nutrition. If any name/variant is ambiguous or only
a similar product is found, set exactProductMatch false. Do not estimate missing
primary nutrition values from a different product.
''';
    final response = await _model
        .generateContent([Content.text(prompt)])
        .timeout(const Duration(seconds: 35));
    if (response.candidates.isEmpty) return null;
    final metadata = response.candidates.first.groundingMetadata;
    if (metadata == null) return null;
    final sources = <NutritionSourceRef>[];
    final seen = <String>{};
    for (final chunk in metadata.groundingChunks) {
      final web = chunk.web;
      final uri = web?.uri?.trim() ?? '';
      if (uri.isEmpty || !seen.add(uri)) continue;
      sources.add(
        NutritionSourceRef(
          title: web?.title?.trim().isNotEmpty == true
              ? web!.title!.trim()
              : 'Web nutrition source',
          url: uri,
        ),
      );
      if (sources.length == 4) break;
    }
    if (sources.isEmpty) return null;

    final json = _decodeJsonObject(response.text);
    if (json == null || json['exactProductMatch'] != true) return null;
    final productName = _text(json['productName']);
    final brandName = _text(json['brandName']);
    final foundIdentity = '$brandName $productName';
    final identityScore = _productMatchScore(identity, foundIdentity);
    final barcode = _digitsOnly(_text(json['barcode']));
    final expectedBarcode = _digitsOnly(visualAnalysis.barcode);
    final barcodeMatch =
        expectedBarcode.length >= 8 && barcode == expectedBarcode;
    if (!barcodeMatch && identityScore < 0.72) return null;

    final servingGrams = _number(json['servingGrams']);
    final calories = _number(json['calories']);
    final protein = _number(json['protein']);
    final carbs = _number(json['carbs']);
    final fat = _number(json['fat']);
    final confidence = _number(json['confidence']);
    if (servingGrams == null ||
        servingGrams <= 0 ||
        servingGrams > 1000 ||
        calories == null ||
        calories < 0 ||
        protein == null ||
        carbs == null ||
        fat == null ||
        confidence == null ||
        confidence < 0.75) {
      return null;
    }

    final servingLabel = _text(json['servingLabel']);
    return ProductNutritionMatch(
      productName: productName,
      brandName: brandName,
      barcode: barcode.isEmpty ? expectedBarcode : barcode,
      servingLabel: servingLabel.isEmpty
          ? '${_cleanNumber(servingGrams)} g serving'
          : servingLabel,
      servingGrams: servingGrams,
      calories: calories.round(),
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: _number(json['fiber']) ?? 0,
      sugar: _number(json['sugar']) ?? 0,
      sodiumMg: (_number(json['sodiumMg']) ?? 0).round(),
      matchConfidence: confidence.clamp(0, 1),
      nutritionSource: 'googleSearch',
      sourceNote: _text(json['sourceNote']).isEmpty
          ? 'Verified against current web sources for the exact product.'
          : _text(json['sourceNote']),
      sources: sources,
      searchEntryPointHtml: metadata.searchEntryPoint?.renderedContent ?? '',
    );
  }
}

class PublicWebLabelLookup implements ProductNutritionLookup {
  PublicWebLabelLookup({http.Client? client, GenerativeModel? labelModel})
    : _client = client ?? http.Client(),
      _labelModels = labelModel == null ? _buildLabelModels() : [labelModel];

  static const _browserAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 '
      'Chrome/124.0 Mobile Safari/537.36 Nourish/1.10';

  final http.Client _client;
  final List<GenerativeModel> _labelModels;

  static List<GenerativeModel> _buildLabelModels() => [
    _buildLabelModel('gemini-3.7-flash'),
    _buildLabelModel('gemini-3.5-flash'),
    _buildLabelModel('gemini-3.5-flash-lite'),
  ];

  static GenerativeModel _buildLabelModel(String modelName) {
    final schema = Schema.object(
      properties: {
        'exactProductMatch': Schema.boolean(),
        'productName': Schema.string(),
        'brandName': Schema.string(),
        'barcode': Schema.string(),
        'servingLabel': Schema.string(),
        'servingGrams': Schema.number(minimum: 0),
        'calories': Schema.number(minimum: 0),
        'protein': Schema.number(minimum: 0),
        'carbs': Schema.number(minimum: 0),
        'fat': Schema.number(minimum: 0),
        'fiber': Schema.number(minimum: 0),
        'sugar': Schema.number(minimum: 0),
        'sodiumMg': Schema.number(minimum: 0),
        'confidence': Schema.number(minimum: 0, maximum: 1),
        'sourceNote': Schema.string(),
      },
      propertyOrdering: const [
        'exactProductMatch',
        'productName',
        'brandName',
        'barcode',
        'servingLabel',
        'servingGrams',
        'calories',
        'protein',
        'carbs',
        'fat',
        'fiber',
        'sugar',
        'sodiumMg',
        'confidence',
        'sourceNote',
      ],
    );
    return FirebaseAI.googleAI().generativeModel(
      model: modelName,
      generationConfig: GenerationConfig(
        temperature: 0,
        maxOutputTokens: 2048,
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
      systemInstruction: Content.system(
        'You read nutrition panels from current public product-page images. '
        'Use only the supplied web evidence. Require the exact brand, product, '
        'flavour, and serving. Prefer a complete nutrition table over rounded '
        'front-of-pack claims. Never combine values from different products or '
        'infer a missing primary nutrient. Return exactProductMatch false when '
        'the complete label or exact identity is not supported.',
      ),
    );
  }

  @override
  Future<ProductNutritionMatch?> lookup(FoodAnalysis visualAnalysis) async {
    final identity = [
      visualAnalysis.brandName,
      visualAnalysis.productName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    if (_meaningfulTokens(identity).length < 3) return null;

    final results = await _search('$identity nutrition facts serving');
    final exactResults = results
        .where(
          (result) =>
              _productMatchScore(identity, result.title) >= 0.74 ||
              _productMatchScore(
                    identity,
                    '${result.title} ${result.snippet}',
                  ) >=
                  0.78,
        )
        .toList();
    if (exactResults.isEmpty) return null;
    exactResults.sort((left, right) {
      int quality(_WebSearchResult result) {
        final host = result.url.host.toLowerCase();
        final brandSlug = visualAnalysis.brandName.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '-',
        );
        if (brandSlug.isNotEmpty && host.contains(brandSlug)) return 100;
        if (host.contains('bigbasket')) return 80;
        if (host.contains('mynetdiary')) return 70;
        if (host.contains('apollo')) return 55;
        if (host.contains('amazon')) return 30;
        return 10;
      }

      return quality(right).compareTo(quality(left));
    });
    if (exactResults.length > 4) {
      exactResults.removeRange(4, exactResults.length);
    }

    final parts = <Part>[
      TextPart(
        '''Read the precise nutrition panel for the exact photographed product.
Expected identity: $identity
Visible barcode: ${visualAnalysis.barcode}
Visible serving estimate: ${visualAnalysis.items.isEmpty ? '' : visualAnalysis.items.first.quantity}

The following images were downloaded live from exact-name web search results.
Accept only a complete label for this exact variant. Prefer per-serving values;
convert per-100 g values only when an exact serving weight is printed. Front
claims such as "10 g protein" are supporting identity clues, not a substitute
for the detailed nutrition table.''',
      ),
    ];
    final sources = <NutritionSourceRef>[];
    final pages = await Future.wait(
      exactResults.map((result) => _fetchPage(result.url)),
    );
    final imageCandidates = <({Uri url, _WebSearchResult result})>[];
    for (var index = 0; index < exactResults.length; index++) {
      final page = pages[index];
      if (page == null) continue;
      for (final imageUrl in _extractProductImages(
        page,
        exactResults[index].url,
        identity,
      ).take(4)) {
        imageCandidates.add((url: imageUrl, result: exactResults[index]));
        if (imageCandidates.length == 8) break;
      }
      if (imageCandidates.length == 8) break;
    }
    final downloadedImages = await Future.wait(
      imageCandidates.map((candidate) => _downloadImage(candidate.url)),
    );
    final addedSources = <String>{};
    var imageCount = 0;
    for (var index = 0; index < downloadedImages.length; index++) {
      final downloaded = downloadedImages[index];
      if (downloaded == null) continue;
      final result = imageCandidates[index].result;
      if (addedSources.add(result.url.toString())) {
        parts.add(TextPart('Source page: ${result.title}\n${result.url}'));
        sources.add(
          NutritionSourceRef(title: result.title, url: result.url.toString()),
        );
      }
      parts.add(InlineDataPart(downloaded.mimeType, downloaded.bytes));
      imageCount++;
    }
    if (imageCount == 0 || sources.isEmpty) return null;

    Object? lastError;
    for (var index = 0; index < _labelModels.length; index++) {
      try {
        final response = await _labelModels[index]
            .generateContent([Content.multi(parts)])
            .timeout(const Duration(seconds: 45));
        final json = _decodeJsonObject(response.text);
        final match = json == null || json['exactProductMatch'] != true
            ? null
            : _matchFromWebJson(json, visualAnalysis, sources);
        if (match != null) return match;
        debugPrint(
          'Web-label vision attempt ${index + 1}/${_labelModels.length} did not find a complete exact label.',
        );
        if (index + 1 == _labelModels.length) return null;
      } catch (error) {
        lastError = error;
        debugPrint(
          'Web-label vision attempt ${index + 1}/${_labelModels.length} failed: $error',
        );
        final retryable =
            error is FirebaseAIException ||
            error is FirebaseAISdkException ||
            error is TimeoutException;
        if (!retryable || index + 1 == _labelModels.length) rethrow;
      }
    }
    debugPrint('Web-label vision ended without a result: $lastError');
    return null;
  }

  Future<List<_WebSearchResult>> _search(String query) async {
    final uri = Uri.https('html.duckduckgo.com', '/html/', {'q': query});
    final response = await _client
        .get(
          uri,
          headers: const {
            'User-Agent': _browserAgent,
            'Accept': 'text/html,application/xhtml+xml',
          },
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return const [];
    final document = html_parser.parse(response.body);
    final results = <_WebSearchResult>[];
    for (final block in document.querySelectorAll('.result')) {
      final anchor = block.querySelector('.result__a');
      if (anchor == null) continue;
      final url = _unwrapSearchUrl(anchor.attributes['href']);
      if (url == null) continue;
      results.add(
        _WebSearchResult(
          title: anchor.text.trim(),
          url: url,
          snippet: block.querySelector('.result__snippet')?.text.trim() ?? '',
        ),
      );
      if (results.length == 8) break;
    }
    return results;
  }

  Future<String?> _fetchPage(Uri uri) async {
    try {
      final response = await _client
          .get(
            uri,
            headers: const {
              'User-Agent': _browserAgent,
              'Accept': 'text/html,application/xhtml+xml',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || response.body.length > 4000000) {
        return null;
      }
      return response.body;
    } catch (_) {
      return null;
    }
  }

  List<Uri> _extractProductImages(String page, Uri pageUri, String identity) {
    final document = html_parser.parse(page);
    final candidates = <Uri>[];
    final seen = <String>{};

    void add(String? raw) {
      if (raw == null || raw.trim().isEmpty) return;
      var value = raw.trim().replaceAll(r'\/', '/').replaceAll('&amp;', '&');
      if (value.startsWith('//')) value = '${pageUri.scheme}:$value';
      final parsed = Uri.tryParse(value);
      final resolved = parsed == null ? null : pageUri.resolveUri(parsed);
      if (resolved == null ||
          (resolved.scheme != 'http' && resolved.scheme != 'https') ||
          !RegExp(
            r'\.(?:jpe?g|png|webp)(?:$|\?)',
            caseSensitive: false,
          ).hasMatch(resolved.toString()) ||
          !seen.add(resolved.toString())) {
        return;
      }
      candidates.add(resolved);
    }

    for (final meta in document.querySelectorAll(
      'meta[property="og:image"], meta[name="twitter:image"]',
    )) {
      add(meta.attributes['content']);
    }
    for (final image in document.querySelectorAll('img')) {
      add(image.attributes['data-zoom-image']);
      add(image.attributes['data-src']);
      add(image.attributes['data-original']);
      add(image.attributes['src']);
      final srcSet = image.attributes['srcset'];
      if (srcSet != null) {
        for (final entry in srcSet.split(',')) {
          final pieces = entry.trim().split(RegExp(r'\s+'));
          if (pieces.isNotEmpty) add(pieces.first);
        }
      }
    }
    final rawImagePattern = RegExp(
      r'''https?:\\?/\\?/[^"'<>\s]+?\.(?:jpe?g|png|webp)(?:\?[^"'<>\s\\]*)?''',
      caseSensitive: false,
    );
    for (final match in rawImagePattern.allMatches(page)) {
      add(match.group(0));
    }

    final identityTokens = _meaningfulTokens(identity);
    final originalOrder = <String, int>{
      for (var index = 0; index < candidates.length; index++)
        candidates[index].toString(): index,
    };
    candidates.sort((left, right) {
      int score(Uri uri) {
        final value = uri.toString().toLowerCase();
        final matches = identityTokens.where(value.contains).length;
        final penalty = value.contains('logo') || value.contains('icon')
            ? 8
            : 0;
        final quality = value.contains('/xxl/')
            ? 8
            : value.contains('/xl/')
            ? 6
            : value.contains('/l/')
            ? 4
            : 0;
        return matches * 2 + quality - penalty;
      }

      final difference = score(right).compareTo(score(left));
      return difference != 0
          ? difference
          : originalOrder[left.toString()]!.compareTo(
              originalOrder[right.toString()]!,
            );
    });
    return candidates.take(12).toList();
  }

  Future<_DownloadedWebImage?> _downloadImage(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: const {'User-Agent': _browserAgent})
          .timeout(const Duration(seconds: 9));
      if (response.statusCode != 200 ||
          response.bodyBytes.length < 5000 ||
          response.bodyBytes.length > 4000000) {
        return null;
      }
      final bytes = response.bodyBytes;
      final mimeType =
          bytes.length >= 3 &&
              bytes[0] == 0xff &&
              bytes[1] == 0xd8 &&
              bytes[2] == 0xff
          ? 'image/jpeg'
          : bytes.length >= 8 &&
                bytes[0] == 0x89 &&
                bytes[1] == 0x50 &&
                bytes[2] == 0x4e &&
                bytes[3] == 0x47
          ? 'image/png'
          : bytes.length >= 12 &&
                String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
                String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP'
          ? 'image/webp'
          : null;
      if (mimeType == null) return null;
      return (bytes: bytes, mimeType: mimeType);
    } catch (_) {
      return null;
    }
  }

  ProductNutritionMatch? _matchFromWebJson(
    Map<String, dynamic> json,
    FoodAnalysis visualAnalysis,
    List<NutritionSourceRef> sources,
  ) {
    final productName = _text(json['productName']);
    final brandName = _text(json['brandName']);
    final expectedIdentity =
        '${visualAnalysis.brandName} ${visualAnalysis.productName}';
    final identityScore = _productMatchScore(
      expectedIdentity,
      '$brandName $productName',
    );
    if (identityScore < 0.72) return null;
    final servingGrams = _number(json['servingGrams']);
    final calories = _number(json['calories']);
    final protein = _number(json['protein']);
    final carbs = _number(json['carbs']);
    final fat = _number(json['fat']);
    final fiber = _number(json['fiber']);
    final sugar = _number(json['sugar']);
    final sodiumMg = _number(json['sodiumMg']);
    final confidence = _number(json['confidence']);
    if (servingGrams == null ||
        servingGrams < 5 ||
        servingGrams > 1000 ||
        calories == null ||
        protein == null ||
        carbs == null ||
        fat == null ||
        fiber == null ||
        sugar == null ||
        sodiumMg == null ||
        confidence == null ||
        confidence < 0.8) {
      return null;
    }
    final servingLabel = _text(json['servingLabel']);
    return ProductNutritionMatch(
      productName: productName,
      brandName: brandName,
      barcode: _digitsOnly(_text(json['barcode'])),
      servingLabel: servingLabel.isEmpty
          ? '${_cleanNumber(servingGrams)} g serving'
          : servingLabel,
      servingGrams: servingGrams,
      calories: calories.round(),
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
      sodiumMg: sodiumMg.round(),
      matchConfidence: confidence.clamp(0, 1),
      nutritionSource: 'publicWebLabel',
      sourceNote: _text(json['sourceNote']).isEmpty
          ? 'Read from a current exact-product nutrition panel found on the public web.'
          : _text(json['sourceNote']),
      sources: sources,
    );
  }
}

typedef _DownloadedWebImage = ({Uint8List bytes, String mimeType});

class _WebSearchResult {
  const _WebSearchResult({
    required this.title,
    required this.url,
    required this.snippet,
  });

  final String title;
  final Uri url;
  final String snippet;
}

Uri? _unwrapSearchUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  var value = raw.trim();
  if (value.startsWith('//')) value = 'https:$value';
  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  final destination = uri.queryParameters['uddg'];
  final resolved = destination == null ? uri : Uri.tryParse(destination);
  if (resolved == null ||
      (resolved.scheme != 'http' && resolved.scheme != 'https')) {
    return null;
  }
  return resolved;
}

typedef _ServingNutrition = ({
  double calories,
  double protein,
  double carbs,
  double fat,
  double fiber,
  double sugar,
  double sodiumMg,
});

_ServingNutrition? _nutritionForServing(
  Map<String, dynamic> nutrients,
  double servingGrams,
) {
  final servingCalories = _number(nutrients['energy-kcal_serving']);
  final servingProtein = _number(nutrients['proteins_serving']);
  final servingCarbs = _number(nutrients['carbohydrates_serving']);
  final servingFat = _number(nutrients['fat_serving']);
  if (servingCalories != null &&
      servingProtein != null &&
      servingCarbs != null &&
      servingFat != null) {
    return (
      calories: servingCalories,
      protein: servingProtein,
      carbs: servingCarbs,
      fat: servingFat,
      fiber: _number(nutrients['fiber_serving']) ?? 0,
      sugar: _number(nutrients['sugars_serving']) ?? 0,
      sodiumMg: (_number(nutrients['sodium_serving']) ?? 0) * 1000,
    );
  }

  final calories100 = _number(nutrients['energy-kcal_100g']);
  final protein100 = _number(nutrients['proteins_100g']);
  final carbs100 = _number(nutrients['carbohydrates_100g']);
  final fat100 = _number(nutrients['fat_100g']);
  if (calories100 == null ||
      protein100 == null ||
      carbs100 == null ||
      fat100 == null) {
    return null;
  }
  final scale = servingGrams / 100;
  return (
    calories: calories100 * scale,
    protein: protein100 * scale,
    carbs: carbs100 * scale,
    fat: fat100 * scale,
    fiber: (_number(nutrients['fiber_100g']) ?? 0) * scale,
    sugar: (_number(nutrients['sugars_100g']) ?? 0) * scale,
    sodiumMg: (_number(nutrients['sodium_100g']) ?? 0) * scale * 1000,
  );
}

double? _servingGrams(
  Map<String, dynamic> product,
  FoodAnalysis visualAnalysis,
) {
  final quantity = _number(product['serving_quantity']);
  final unit = _text(product['serving_quantity_unit']).toLowerCase();
  if (quantity != null &&
      quantity >= 5 &&
      quantity <= 1000 &&
      (unit.isEmpty || unit == 'g' || unit == 'ml')) {
    return quantity;
  }
  final servingSize = _text(product['serving_size']);
  final match = RegExp(
    r'(\d+(?:\.\d+)?)\s*(?:g|ml)\b',
    caseSensitive: false,
  ).firstMatch(servingSize);
  final parsed = match == null ? null : double.tryParse(match.group(1)!);
  if (parsed != null && parsed >= 5 && parsed <= 1000) return parsed;
  if (visualAnalysis.items.isNotEmpty) {
    final visualGrams = visualAnalysis.items.first.estimatedGrams;
    if (visualGrams >= 5 && visualGrams <= 1000) return visualGrams;
  }
  return null;
}

double _productMatchScore(String expected, String found) {
  final expectedTokens = _meaningfulTokens(expected);
  final foundTokens = _meaningfulTokens(found);
  if (expectedTokens.isEmpty || foundTokens.isEmpty) return 0;
  final overlap = expectedTokens.where(foundTokens.contains).length;
  final coverage = overlap / expectedTokens.length;
  final precision = overlap / foundTokens.length;
  return (coverage * 0.8 + precision * 0.2).clamp(0, 1);
}

Set<String> _meaningfulTokens(String value) {
  const ignored = {
    'a',
    'an',
    'and',
    'the',
    'with',
    'of',
    'pack',
    'packed',
    'food',
    'item',
  };
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .split(' ')
      .where((token) => token.length > 1 && !ignored.contains(token))
      .toSet();
}

Map<String, dynamic>? _decodeJsonObject(String? responseText) {
  if (responseText == null) return null;
  final text = responseText.trim();
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    final decoded = jsonDecode(text.substring(start, end + 1));
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  } catch (_) {
    return null;
  }
}

double? _number(Object? value) {
  if (value is num && value.isFinite) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

String _text(Object? value) {
  if (value is String) return value.trim();
  if (value is List) {
    return value.map(_text).where((part) => part.isNotEmpty).join(', ');
  }
  return '';
}

String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

String _cleanNumber(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(1);
