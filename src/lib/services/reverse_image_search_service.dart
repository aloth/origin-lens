import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result from a single reverse image search match
class ImageSearchMatch {
  final String title;
  final String link;
  final String? source;
  final String? thumbnail;
  final String? snippet;
  final String? date;
  final String? favicon;

  const ImageSearchMatch({
    required this.title,
    required this.link,
    this.source,
    this.thumbnail,
    this.snippet,
    this.date,
    this.favicon,
  });
}

/// Link to a manual search on a specific engine
class SearchLink {
  final String engineName;
  final String searchUrl;

  const SearchLink({required this.engineName, required this.searchUrl});
}

/// Result from reverse image search
class ReverseImageSearchResult {
  final bool success;
  final String? queryDisplayed; // What Google thinks the image is
  final List<ImageSearchMatch> matches;
  final List<SearchLink> searchLinks;
  final String? firstSeenDate;
  final String? errorMessage;
  final int totalResults;

  const ReverseImageSearchResult({
    required this.success,
    this.queryDisplayed,
    this.matches = const [],
    this.searchLinks = const [],
    this.firstSeenDate,
    this.errorMessage,
    this.totalResults = 0,
  });

  factory ReverseImageSearchResult.error(String message) {
    return ReverseImageSearchResult(success: false, errorMessage: message);
  }

  factory ReverseImageSearchResult.manual(List<SearchLink> links) {
    return ReverseImageSearchResult(success: true, searchLinks: links);
  }

  factory ReverseImageSearchResult.fromSerpApiResponse(
    Map<String, dynamic> json,
  ) {
    final matches = <ImageSearchMatch>[];
    String? firstSeen;
    String? queryDisplayed;

    if (json['search_information'] != null) {
      queryDisplayed = json['search_information']['query_displayed'];
    }

    if (json['image_results'] != null) {
      for (var result in json['image_results']) {
        final date = result['date'];
        if (date != null && (firstSeen == null)) {
          firstSeen = date;
        }
        matches.add(
          ImageSearchMatch(
            title: result['title'] ?? 'Search result',
            link: result['link'] ?? '',
            source: result['source'],
            thumbnail: result['thumbnail'],
            snippet: result['snippet'],
            date: date,
            favicon: result['favicon'],
          ),
        );
      }
    }

    if (json['inline_images'] != null) {
      for (var img in json['inline_images']) {
        matches.add(
          ImageSearchMatch(
            title: img['title'] ?? 'Related image',
            link: img['link'] ?? img['original'] ?? '',
            source: img['source'],
            thumbnail: img['thumbnail'],
          ),
        );
      }
    }

    if (json['knowledge_graph'] != null) {
      final kg = json['knowledge_graph'];
      if (kg['title'] != null) {
        matches.insert(
          0,
          ImageSearchMatch(
            title: kg['title'],
            link: kg['website'] ?? kg['source']?['link'] ?? '',
            source: 'Knowledge Graph',
            snippet: kg['description'],
            thumbnail: kg['header_images']?[0]?['image'],
          ),
        );
      }
    }

    final totalFromApi =
        json['search_information']?['total_results'] ?? matches.length;

    return ReverseImageSearchResult(
      success: true,
      queryDisplayed: queryDisplayed,
      matches: matches,
      firstSeenDate: firstSeen,
      totalResults: totalFromApi is int
          ? totalFromApi
          : int.tryParse(totalFromApi.toString()) ?? matches.length,
    );
  }

  bool get hasMatches => matches.isNotEmpty;

  bool get hasSearchLinks => searchLinks.isNotEmpty;

  /// Check if image might be used out of context based on search results
  bool get possiblyOutOfContext {
    final uniqueSources = matches
        .map((m) => m.source)
        .whereType<String>()
        .toSet();
    return uniqueSources.length > 3;
  }
}

/// Service for reverse image search using SerpAPI
class ReverseImageSearchService {
  static ReverseImageSearchService? _instance;
  String? _apiKey;
  String? _userApiKey; // User-provided API key takes priority
  String? _imgbbApiKey;
  String? _userImgbbApiKey; // User-provided imgbb key takes priority
  bool _isConfigured = false;

  static const String _baseUrl = 'https://serpapi.com/search.json';
  static const String _imgbbUploadUrl = 'https://api.imgbb.com/1/upload';
  static const String _userApiKeyPrefKey = 'user_serpapi_key';

  ReverseImageSearchService._();

  static ReverseImageSearchService get instance {
    _instance ??= ReverseImageSearchService._();
    return _instance!;
  }

  /// Configure the service with SerpAPI key and optional imgbb key for local file support
  void configure({required String apiKey, String? imgbbApiKey}) {
    _apiKey = apiKey;
    _imgbbApiKey = imgbbApiKey;
    _isConfigured = apiKey.isNotEmpty;
    debugPrint(
      '═══════════════════════════════════════════════════════════════',
    );
    debugPrint('ReverseImageSearch: Service configured');
    debugPrint(
      '  SerpAPI key: ${apiKey.isNotEmpty ? "${apiKey.substring(0, 8)}..." : "NOT SET"}',
    );
    debugPrint(
      '  imgbb key: ${imgbbApiKey?.isNotEmpty == true ? "${imgbbApiKey!.substring(0, 8)}..." : "NOT SET"}',
    );
    debugPrint('  isConfigured: $_isConfigured');
    debugPrint('  canSearchLocalFiles: $canSearchLocalFiles');
    debugPrint(
      '═══════════════════════════════════════════════════════════════',
    );
  }

  /// Set user-provided API key (takes priority over app default)
  void setUserApiKey(String? apiKey) {
    _userApiKey = apiKey?.isNotEmpty == true ? apiKey : null;
    debugPrint(
      'ReverseImageSearch: User SerpAPI key ${_userApiKey != null ? "set" : "cleared"}',
    );
  }

  /// Set user-provided imgbb API key (takes priority over app default)
  void setUserImgbbApiKey(String? apiKey) {
    _userImgbbApiKey = apiKey?.isNotEmpty == true ? apiKey : null;
    debugPrint(
      'ReverseImageSearch: User imgbb key ${_userImgbbApiKey != null ? "set" : "cleared"}',
    );
  }

  /// Get the effective API key (user key takes priority)
  String? get _effectiveApiKey => _userApiKey ?? _apiKey;

  /// Get the effective imgbb API key (user key takes priority)
  String? get _effectiveImgbbApiKey => _userImgbbApiKey ?? _imgbbApiKey;

  /// Check if user has provided their own API key
  bool get hasUserApiKey => _userApiKey != null && _userApiKey!.isNotEmpty;

  /// Check if user has provided their own imgbb API key
  bool get hasUserImgbbApiKey =>
      _userImgbbApiKey != null && _userImgbbApiKey!.isNotEmpty;

  bool get isConfigured =>
      _effectiveApiKey != null && _effectiveApiKey!.isNotEmpty;
  bool get canSearchLocalFiles =>
      _effectiveImgbbApiKey != null && _effectiveImgbbApiKey!.isNotEmpty;

  /// Upload image to imgbb and return the URL
  Future<String?> _uploadToImgbb(Uint8List imageBytes) async {
    final imgbbKey = _effectiveImgbbApiKey;
    if (imgbbKey == null || imgbbKey.isEmpty) {
      debugPrint('ReverseImageSearch: imgbb API key not configured');
      return null;
    }

    try {
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(_imgbbUploadUrl),
        body: {
          'key': imgbbKey,
          'image': base64Image,
          'expiration': '300', // 5 minutes - enough for the search
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final url = json['data']['url'] as String?;
          debugPrint('ReverseImageSearch: Uploaded to imgbb: $url');
          return url;
        }
      }
      debugPrint('ReverseImageSearch: imgbb upload failed: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('ReverseImageSearch: imgbb upload error: $e');
      return null;
    }
  }

  /// Search by local image file
  Future<ReverseImageSearchResult> searchByFile(File file) async {
    if (!isConfigured) {
      return ReverseImageSearchResult.error('SerpAPI key not configured');
    }

    if (!canSearchLocalFiles) {
      return ReverseImageSearchResult.error(
        'Local file search requires imgbb API key',
      );
    }

    try {
      debugPrint('ReverseImageSearch: Uploading local file for search...');
      final bytes = await file.readAsBytes();
      final imageUrl = await _uploadToImgbb(bytes);

      if (imageUrl == null) {
        return ReverseImageSearchResult.error(
          'Failed to upload image for search',
        );
      }

      return searchByUrl(imageUrl);
    } catch (e) {
      return ReverseImageSearchResult.error('File search failed: $e');
    }
  }

  /// Search by image bytes
  Future<ReverseImageSearchResult> searchByBytes(Uint8List bytes) async {
    if (!isConfigured) {
      return ReverseImageSearchResult.error('SerpAPI key not configured');
    }

    if (!canSearchLocalFiles) {
      return ReverseImageSearchResult.error(
        'Local file search requires imgbb API key',
      );
    }

    try {
      debugPrint('ReverseImageSearch: Uploading bytes for search...');
      final imageUrl = await _uploadToImgbb(bytes);

      if (imageUrl == null) {
        return ReverseImageSearchResult.error(
          'Failed to upload image for search',
        );
      }

      return searchByUrl(imageUrl);
    } catch (e) {
      return ReverseImageSearchResult.error('Bytes search failed: $e');
    }
  }

  /// Search by image URL
  Future<ReverseImageSearchResult> searchByUrl(String imageUrl) async {
    if (!isConfigured) {
      return ReverseImageSearchResult.error('SerpAPI key not configured');
    }

    try {
      debugPrint('ReverseImageSearch: Searching URL: $imageUrl');
      debugPrint(
        'ReverseImageSearch: Using ${hasUserApiKey ? "user" : "default"} API key',
      );

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'engine': 'google_reverse_image',
          'image_url': imageUrl,
          'api_key': _effectiveApiKey!,
        },
      );

      final response = await http.get(uri);
      debugPrint('ReverseImageSearch: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint(
          'ReverseImageSearch: Found ${json['image_results']?.length ?? 0} image results',
        );
        return ReverseImageSearchResult.fromSerpApiResponse(json);
      } else {
        try {
          final error = jsonDecode(response.body);
          return ReverseImageSearchResult.error(
            error['error'] ?? 'HTTP ${response.statusCode}',
          );
        } catch (_) {
          return ReverseImageSearchResult.error('HTTP ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('ReverseImageSearch Error: $e');
      return ReverseImageSearchResult.error('Search failed: $e');
    }
  }

  /// Search using Google Lens (supports more image sources)
  Future<ReverseImageSearchResult> searchWithLens(String imageUrl) async {
    if (!isConfigured) {
      return ReverseImageSearchResult.error('SerpAPI key not configured');
    }

    try {
      debugPrint('ReverseImageSearch: Using Google Lens for: $imageUrl');

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'engine': 'google_lens',
          'url': imageUrl,
          'api_key': _effectiveApiKey!,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseGoogleLensResponse(json);
      } else {
        return ReverseImageSearchResult.error(
          'Lens search failed: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('ReverseImageSearch Lens Error: $e');
      return ReverseImageSearchResult.error('Lens search failed: $e');
    }
  }

  ReverseImageSearchResult _parseGoogleLensResponse(Map<String, dynamic> json) {
    final matches = <ImageSearchMatch>[];

    if (json['visual_matches'] != null) {
      for (var match in json['visual_matches']) {
        matches.add(
          ImageSearchMatch(
            title: match['title'] ?? 'Visual match',
            link: match['link'] ?? '',
            source: match['source'],
            thumbnail: match['thumbnail'],
          ),
        );
      }
    }

    if (json['knowledge_graph'] != null && json['knowledge_graph'] is List) {
      for (var item in json['knowledge_graph']) {
        matches.add(
          ImageSearchMatch(
            title: item['title'] ?? 'Related',
            link: item['link'] ?? '',
            source: 'Knowledge Graph',
            snippet: item['subtitle'],
          ),
        );
      }
    }

    return ReverseImageSearchResult(
      success: true,
      matches: matches,
      totalResults: matches.length,
    );
  }

  /// Check if we can search (either via SerpAPI or Google direct)
  bool get canSearch => true; // Always true - we have Google fallback

  /// Try Google Lens upload endpoint
  Future<ReverseImageSearchResult> _tryGoogleLensUpload(
    Uint8List imageBytes,
  ) async {
    try {
      debugPrint('ReverseImageSearch: Trying Google Lens endpoint...');

      // Encode image as base64 for the data URL approach
      final base64Image = base64Encode(imageBytes);

      // Use TinEye as an alternative - it's more API-friendly
      // Or try Yandex which is often less restrictive
      final yandexResult = await _tryYandexImageSearch(imageBytes);
      if (yandexResult.success && yandexResult.hasMatches) {
        return yandexResult;
      }

      return ReverseImageSearchResult(
        success: false,
        errorMessage: 'Lens search not available',
        matches: [],
        totalResults: 0,
      );
    } catch (e) {
      debugPrint('ReverseImageSearch: Lens upload error: $e');
      return ReverseImageSearchResult(
        success: false,
        errorMessage: 'Lens search failed: $e',
        matches: [],
        totalResults: 0,
      );
    }
  }

  /// Try Yandex image search as fallback (often less restrictive)
  Future<ReverseImageSearchResult> _tryYandexImageSearch(
    Uint8List imageBytes,
  ) async {
    try {
      debugPrint('ReverseImageSearch: Trying Yandex image search...');

      final uri = Uri.parse('https://yandex.com/images/search');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          'upfile',
          imageBytes,
          filename: 'image.jpg',
        ),
      );

      request.fields['rpt'] = 'imageview';
      request.fields['format'] = 'json';

      request.headers.addAll({
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept':
            'application/json, text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        'ReverseImageSearch: Yandex response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          debugPrint('ReverseImageSearch: Yandex redirect to: $redirectUrl');
          return await _fetchAndParseYandexResults(redirectUrl);
        }
        return _parseYandexHtml(response.body);
      }

      return ReverseImageSearchResult(
        success: false,
        errorMessage: 'Yandex search failed: HTTP ${response.statusCode}',
        matches: [],
        totalResults: 0,
      );
    } catch (e) {
      debugPrint('ReverseImageSearch: Yandex error: $e');
      return ReverseImageSearchResult(
        success: false,
        errorMessage: 'Yandex search failed: $e',
        matches: [],
        totalResults: 0,
      );
    }
  }

  /// Fetch and parse Yandex results
  Future<ReverseImageSearchResult> _fetchAndParseYandexResults(
    String url,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );

      if (response.statusCode == 200) {
        return _parseYandexHtml(response.body);
      }

      return ReverseImageSearchResult(
        success: false,
        errorMessage: 'Yandex fetch failed',
        matches: [],
        totalResults: 0,
      );
    } catch (e) {
      return ReverseImageSearchResult(
        success: false,
        errorMessage: 'Yandex fetch failed: $e',
        matches: [],
        totalResults: 0,
      );
    }
  }

  /// Parse Yandex HTML results
  ReverseImageSearchResult _parseYandexHtml(String html) {
    final matches = <ImageSearchMatch>[];

    debugPrint(
      'ReverseImageSearch: Parsing Yandex HTML (${html.length} chars)',
    );

    try {
      // Look for similar images links
      final linkRegex = RegExp(
        r'<a[^>]+href="(https?://(?!yandex\.)[^"]+)"[^>]*>([^<]+)</a>',
        caseSensitive: false,
      );

      for (final match in linkRegex.allMatches(html)) {
        final link = match.group(1);
        final title = match.group(2);

        if (link != null && title != null && title.length > 5) {
          // Filter out unwanted results
          if (_shouldFilterResult(link, title)) {
            continue;
          }

          final uri = Uri.tryParse(link);
          final source = uri?.host.replaceFirst('www.', '');

          matches.add(
            ImageSearchMatch(
              title: _decodeHtmlEntities(title),
              link: link,
              source: source,
            ),
          );
        }
      }

      // Remove duplicates
      final uniqueMatches = <String, ImageSearchMatch>{};
      for (final match in matches) {
        if (!uniqueMatches.containsKey(match.link)) {
          uniqueMatches[match.link] = match;
        }
      }

      debugPrint(
        'ReverseImageSearch: Yandex found ${uniqueMatches.length} results',
      );

      return ReverseImageSearchResult(
        success: uniqueMatches.isNotEmpty,
        matches: uniqueMatches.values.toList(),
        totalResults: uniqueMatches.length,
      );
    } catch (e) {
      debugPrint('ReverseImageSearch: Yandex parse error: $e');
      return ReverseImageSearchResult(
        success: false,
        errorMessage: 'Yandex parse failed: $e',
        matches: [],
        totalResults: 0,
      );
    }
  }

  /// Filter out unwanted results (login pages, auth, etc.)
  bool _shouldFilterResult(String link, String title) {
    final linkLower = link.toLowerCase();
    final titleLower = title.toLowerCase();

    // Filter login/auth pages
    final blockedDomains = [
      'passport.yandex',
      'accounts.google',
      'login.',
      'signin.',
      'auth.',
      'oauth.',
      'sso.',
      'account.',
    ];

    for (final blocked in blockedDomains) {
      if (linkLower.contains(blocked)) {
        debugPrint('ReverseImageSearch: Filtering blocked domain: $link');
        return true;
      }
    }

    // Filter login/signup titles
    final blockedTitles = [
      'log in',
      'login',
      'sign in',
      'signin',
      'sign up',
      'signup',
      'register',
      'authentication',
      'cookie',
      'privacy policy',
      'terms of service',
      'captcha',
    ];

    for (final blocked in blockedTitles) {
      if (titleLower.contains(blocked)) {
        debugPrint('ReverseImageSearch: Filtering blocked title: $title');
        return true;
      }
    }

    // Filter search engine results pages
    final searchEngines = [
      'google.com/search',
      'bing.com/search',
      'yandex.com/search',
      'duckduckgo.com',
      'yahoo.com/search',
    ];

    for (final engine in searchEngines) {
      if (linkLower.contains(engine)) {
        return true;
      }
    }

    return false;
  }

  /// Try Bing Visual Search
  Future<ReverseImageSearchResult> _tryBingVisualSearch(
    Uint8List imageBytes,
  ) async {
    try {
      debugPrint('ReverseImageSearch: Trying Bing Visual Search...');

      // Add a small random delay to appear more human (100-500ms)
      await Future.delayed(
        Duration(milliseconds: 100 + DateTime.now().millisecond % 400),
      );

      final uri = Uri.parse(
        'https://www.bing.com/images/search?view=detailv2&iss=sbi&form=SBIVSP&sbisrc=UrlPaste',
      );
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          'imageBin',
          imageBytes,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      // More human-like headers for Bing
      request.headers.addAll({
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Sec-Ch-Ua':
            '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
        'Sec-Ch-Ua-Mobile': '?0',
        'Sec-Ch-Ua-Platform': '"macOS"',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'same-origin',
        'Sec-Fetch-User': '?1',
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        'ReverseImageSearch: Bing response status: ${response.statusCode}',
      );
      debugPrint('ReverseImageSearch: Bing headers: ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          debugPrint('ReverseImageSearch: Bing redirect to: $redirectUrl');
          return await _fetchAndParseBingResults(redirectUrl);
        }
        return _parseBingHtml(response.body);
      }

      return ReverseImageSearchResult(
        success: false,
        errorMessage: 'Bing search failed: HTTP ${response.statusCode}',
        matches: [],
        totalResults: 0,
      );
    } catch (e) {
      debugPrint('ReverseImageSearch: Bing error: $e');
      return ReverseImageSearchResult(
        success: false,
        errorMessage: 'Bing search failed: $e',
        matches: [],
        totalResults: 0,
      );
    }
  }

  /// Fetch and parse Bing results
  Future<ReverseImageSearchResult> _fetchAndParseBingResults(String url) async {
    try {
      // Small delay to appear human
      await Future.delayed(
        Duration(milliseconds: 50 + DateTime.now().millisecond % 150),
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );

      debugPrint(
        'ReverseImageSearch: Bing fetch status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        return _parseBingHtml(response.body);
      }

      return ReverseImageSearchResult(
        success: false,
        errorMessage: 'Bing fetch failed',
        matches: [],
        totalResults: 0,
      );
    } catch (e) {
      return ReverseImageSearchResult(
        success: false,
        errorMessage: 'Bing fetch failed: $e',
        matches: [],
        totalResults: 0,
      );
    }
  }

  /// Parse Bing HTML results
  ReverseImageSearchResult _parseBingHtml(String html) {
    final matches = <ImageSearchMatch>[];
    String? queryDisplayed;

    debugPrint('ReverseImageSearch: Parsing Bing HTML (${html.length} chars)');

    // Log preview for debugging
    if (html.length > 500) {
      debugPrint('Bing HTML preview: ${html.substring(0, 500)}');
    }

    try {
      // Check for bot detection
      if (html.contains('unusual traffic') ||
          html.contains('captcha') ||
          html.contains('blocked')) {
        debugPrint('ReverseImageSearch: Bing bot detection triggered');
        return ReverseImageSearchResult(
          success: false,
          errorMessage: 'Bing blocked the request',
          matches: [],
          totalResults: 0,
        );
      }

      // Try to extract "Pages that include this image" or similar
      final pagesRegex = RegExp(
        r'Pages that include[^<]*<[^>]*>([^<]+)',
        caseSensitive: false,
      );
      final pagesMatch = pagesRegex.firstMatch(html);
      if (pagesMatch != null) {
        queryDisplayed = 'Pages including this image';
      }

      // Look for visual search results
      // Bing uses various patterns for results
      final patterns = [
        // Pattern 1: Standard links with titles
        RegExp(
          r'<a[^>]+href="(https?://(?!bing\.com|microsoft\.com)[^"]+)"[^>]*title="([^"]+)"',
          caseSensitive: false,
        ),
        // Pattern 2: Links in result containers
        RegExp(
          r'class="[^"]*sitelink[^"]*"[^>]*href="(https?://[^"]+)"[^>]*>([^<]+)',
          caseSensitive: false,
        ),
        // Pattern 3: Image result links
        RegExp(
          r'"purl":"(https?://[^"]+)"[^}]*"t":"([^"]+)"',
          caseSensitive: false,
        ),
      ];

      for (final pattern in patterns) {
        for (final match in pattern.allMatches(html)) {
          final link = match.group(1);
          final title = match.group(2);

          if (link != null && title != null && title.length > 3) {
            if (_shouldFilterResult(link, title)) {
              continue;
            }

            final uri = Uri.tryParse(link);
            final source = uri?.host.replaceFirst('www.', '');

            matches.add(
              ImageSearchMatch(
                title: _decodeHtmlEntities(title),
                link: link,
                source: source,
              ),
            );
          }
        }
      }

      // Remove duplicates
      final uniqueMatches = <String, ImageSearchMatch>{};
      for (final match in matches) {
        if (!uniqueMatches.containsKey(match.link)) {
          uniqueMatches[match.link] = match;
        }
      }

      debugPrint(
        'ReverseImageSearch: Bing found ${uniqueMatches.length} results',
      );

      return ReverseImageSearchResult(
        success: uniqueMatches.isNotEmpty,
        queryDisplayed: queryDisplayed,
        matches: uniqueMatches.values.toList(),
        totalResults: uniqueMatches.length,
      );
    } catch (e) {
      debugPrint('ReverseImageSearch: Bing parse error: $e');
      return ReverseImageSearchResult(
        success: false,
        errorMessage: 'Bing parse failed: $e',
        matches: [],
        totalResults: 0,
      );
    }
  }

  /// Search using Google's direct upload endpoint (fallback when no SerpAPI key)
  Future<ReverseImageSearchResult> searchWithGoogleDirect(
    Uint8List imageBytes,
  ) async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('ReverseImageSearch: Starting multi-engine search...');
      debugPrint('Image size: ${imageBytes.length} bytes');

      // Try Bing first (often most reliable for scraping)
      debugPrint('ReverseImageSearch: Attempting Bing Visual Search...');
      final bingResult = await _tryBingVisualSearch(imageBytes);
      if (bingResult.success && bingResult.hasMatches) {
        debugPrint(
          'ReverseImageSearch: Bing succeeded with ${bingResult.matches.length} results',
        );
        return bingResult;
      }
      debugPrint('ReverseImageSearch: Bing failed or no results');

      // Add delay between engines to appear more human
      await Future.delayed(
        Duration(milliseconds: 300 + DateTime.now().millisecond % 500),
      );

      // Try Yandex as fallback
      debugPrint('ReverseImageSearch: Attempting Yandex...');
      final yandexResult = await _tryYandexImageSearch(imageBytes);
      if (yandexResult.success && yandexResult.hasMatches) {
        debugPrint(
          'ReverseImageSearch: Yandex succeeded with ${yandexResult.matches.length} results',
        );
        return yandexResult;
      }
      debugPrint('ReverseImageSearch: Yandex failed or no results');

      // Add delay before Google
      await Future.delayed(
        Duration(milliseconds: 200 + DateTime.now().millisecond % 300),
      );

      debugPrint('ReverseImageSearch: Attempting Google searchbyimage...');

      // Create multipart request for traditional endpoint
      final uri = Uri.parse('https://www.google.com/searchbyimage/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add the image as multipart form data
      request.files.add(
        http.MultipartFile.fromBytes(
          'encoded_image',
          imageBytes,
          filename: 'image.jpg',
        ),
      );

      // Add headers to appear as a browser
      request.headers.addAll({
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'same-origin',
        'Sec-Fetch-User': '?1',
        'Cache-Control': 'max-age=0',
      });

      // Send the request
      debugPrint('ReverseImageSearch: Sending request to Google...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('ReverseImageSearch: Response received');
      debugPrint('  Status code: ${response.statusCode}');
      debugPrint('  Headers: ${response.headers}');
      debugPrint('  Body length: ${response.body.length} chars');

      // Handle redirect (302) or success (200)
      if (response.statusCode == 302 || response.statusCode == 200) {
        // Get the redirect URL or parse the response
        final redirectUrl = response.headers['location'];

        if (redirectUrl != null) {
          debugPrint('ReverseImageSearch: Got redirect URL');
          debugPrint('  Redirect to: $redirectUrl');
          // Follow the redirect to get the search results page
          return _fetchAndParseGoogleResults(redirectUrl);
        } else {
          debugPrint(
            'ReverseImageSearch: No redirect, parsing response body directly',
          );
          // Log first 1000 chars of response for debugging
          final preview = response.body.length > 1000
              ? response.body.substring(0, 1000)
              : response.body;
          debugPrint('Response body preview: $preview');
          // Parse the response body directly
          return _parseGoogleHtml(response.body);
        }
      } else {
        debugPrint(
          'ReverseImageSearch: Unexpected status code ${response.statusCode}',
        );
        debugPrint('Response body: ${response.body}');
        return ReverseImageSearchResult.error(
          'Google search failed: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('ReverseImageSearch Google direct error: $e');
      return ReverseImageSearchResult.error('Google search failed: $e');
    }
  }

  /// Fetch and parse Google search results page
  Future<ReverseImageSearchResult> _fetchAndParseGoogleResults(
    String url,
  ) async {
    try {
      debugPrint('ReverseImageSearch: Fetching results page...');
      debugPrint('  URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
        },
      );

      debugPrint('ReverseImageSearch: Results page response');
      debugPrint('  Status: ${response.statusCode}');
      debugPrint('  Body length: ${response.body.length} chars');

      if (response.statusCode == 200) {
        // Log a preview of the HTML for debugging
        final preview = response.body.length > 2000
            ? response.body.substring(0, 2000)
            : response.body;
        debugPrint('HTML preview: $preview');
        return _parseGoogleHtml(response.body);
      } else {
        debugPrint(
          'ReverseImageSearch: Failed to fetch - ${response.statusCode}',
        );
        debugPrint('Response: ${response.body}');
        return ReverseImageSearchResult.error(
          'Failed to fetch results: HTTP ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('ReverseImageSearch: Fetch error: $e');
      debugPrint('Stack trace: $stackTrace');
      return ReverseImageSearchResult.error('Failed to fetch results: $e');
    }
  }

  /// Parse Google search results HTML
  ReverseImageSearchResult _parseGoogleHtml(String html) {
    final matches = <ImageSearchMatch>[];
    String? queryDisplayed;

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('ReverseImageSearch: Parsing HTML (${html.length} chars)');

    try {
      // Check if Google is blocking us (JavaScript required page)
      if (html.contains('/httpservice/retry/enablejs') ||
          (html.contains('<noscript>') && html.contains('enablejs'))) {
        debugPrint(
          'ReverseImageSearch: Detected JavaScript-required page (bot detection)',
        );
        debugPrint('ReverseImageSearch: Google is blocking automated requests');

        // Return informative result
        return ReverseImageSearchResult(
          success: false,
          errorMessage:
              'Google blocked the request. Try using a SerpAPI key for reliable results.',
          matches: [],
          totalResults: 0,
        );
      }

      // Check for CAPTCHA
      if (html.contains('captcha') || html.contains('unusual traffic')) {
        debugPrint('ReverseImageSearch: CAPTCHA or unusual traffic detection');
        return ReverseImageSearchResult(
          success: false,
          errorMessage:
              'Google requires CAPTCHA verification. Try again later.',
          matches: [],
          totalResults: 0,
        );
      }

      // Extract "Best guess for this image" or similar query
      final queryRegex = RegExp(
        r'Best guess for this image[:\s]*</[^>]+>\s*<[^>]+>([^<]+)<',
        caseSensitive: false,
      );
      final queryMatch = queryRegex.firstMatch(html);
      if (queryMatch != null) {
        queryDisplayed = queryMatch.group(1)?.trim();
        debugPrint('Found query displayed: $queryDisplayed');
      } else {
        debugPrint('No "Best guess" found in HTML');
      }

      // Alternative query pattern
      if (queryDisplayed == null) {
        final altQueryRegex = RegExp(r'"qdr":"([^"]+)"', caseSensitive: false);
        final altMatch = altQueryRegex.firstMatch(html);
        if (altMatch != null) {
          queryDisplayed = altMatch.group(1);
        }
      }

      // Extract search result links - pattern for Google search results
      // Look for result containers with titles and links
      final resultRegex = RegExp(
        r'<a\s+href="(/url\?q=|)(https?://[^"&]+)[^"]*"[^>]*>.*?<h3[^>]*>([^<]+)</h3>',
        caseSensitive: false,
        dotAll: true,
      );

      for (final match in resultRegex.allMatches(html)) {
        final link = match.group(2);
        final title = match.group(3);

        if (link != null && title != null && !link.contains('google.com')) {
          // Filter unwanted results
          if (_shouldFilterResult(link, title)) {
            continue;
          }

          // Extract domain as source
          final uri = Uri.tryParse(link);
          final source = uri?.host.replaceFirst('www.', '');

          matches.add(
            ImageSearchMatch(
              title: _decodeHtmlEntities(title),
              link: link,
              source: source,
            ),
          );
        }
      }

      debugPrint(
        'ReverseImageSearch: Found ${matches.length} results with primary regex',
      );

      // Alternative pattern for simpler link extraction
      if (matches.isEmpty) {
        debugPrint('ReverseImageSearch: Trying alternative regex...');
        final simpleLinkRegex = RegExp(
          r'<a[^>]+href="(https?://(?!www\.google\.)[^"]+)"[^>]*>([^<]+)</a>',
          caseSensitive: false,
        );

        int altMatchCount = 0;
        for (final match in simpleLinkRegex.allMatches(html)) {
          altMatchCount++;
          final link = match.group(1);
          final title = match.group(2);

          if (link != null &&
              title != null &&
              title.length > 5 &&
              !link.contains('google.com') &&
              !link.contains('gstatic.com')) {
            // Filter unwanted results
            if (_shouldFilterResult(link, title)) {
              continue;
            }

            final uri = Uri.tryParse(link);
            final source = uri?.host.replaceFirst('www.', '');

            matches.add(
              ImageSearchMatch(
                title: _decodeHtmlEntities(title),
                link: link,
                source: source,
              ),
            );
          }
        }
        debugPrint(
          'ReverseImageSearch: Alt regex found $altMatchCount raw matches, ${matches.length} valid',
        );
      }

      // Remove duplicates
      final uniqueMatches = <String, ImageSearchMatch>{};
      for (final match in matches) {
        if (!uniqueMatches.containsKey(match.link)) {
          uniqueMatches[match.link] = match;
        }
      }

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('ReverseImageSearch: FINAL RESULTS');
      debugPrint('  Query displayed: $queryDisplayed');
      debugPrint('  Total unique matches: ${uniqueMatches.length}');
      for (var i = 0; i < uniqueMatches.length && i < 5; i++) {
        final m = uniqueMatches.values.elementAt(i);
        debugPrint(
          '  [$i] ${m.title.substring(0, m.title.length > 50 ? 50 : m.title.length)}...',
        );
        debugPrint('      ${m.link}');
      }
      debugPrint('═══════════════════════════════════════════════════════');

      return ReverseImageSearchResult(
        success: true,
        queryDisplayed: queryDisplayed,
        matches: uniqueMatches.values.toList(),
        totalResults: uniqueMatches.length,
      );
    } catch (e, stackTrace) {
      debugPrint('ReverseImageSearch: HTML parsing error: $e');
      debugPrint('Stack trace: $stackTrace');
      return ReverseImageSearchResult(
        success: true,
        queryDisplayed: queryDisplayed,
        matches: matches,
        totalResults: matches.length,
      );
    }
  }

  /// Decode HTML entities
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  /// Smart search - uses SerpAPI if available, falls back to Google direct
  Future<ReverseImageSearchResult> smartSearchByBytes(Uint8List bytes) async {
    debugPrint(
      '═══════════════════════════════════════════════════════════════',
    );
    debugPrint('ReverseImageSearch: smartSearchByBytes called');
    debugPrint('  isConfigured (SerpAPI): $isConfigured');
    debugPrint('  canSearchLocalFiles (imgbb): $canSearchLocalFiles');
    debugPrint('  hasUserApiKey: $hasUserApiKey');
    debugPrint(
      '═══════════════════════════════════════════════════════════════',
    );

    // If SerpAPI is configured and imgbb is available, use that
    if (isConfigured && canSearchLocalFiles) {
      debugPrint('ReverseImageSearch: Using SerpAPI + imgbb upload');
      return searchByBytes(bytes);
    }

    // Otherwise use Google direct upload
    debugPrint(
      'ReverseImageSearch: Falling back to direct search engines (no SerpAPI+imgbb)',
    );
    return searchWithGoogleDirect(bytes);
  }

  /// Smart search by file
  Future<ReverseImageSearchResult> smartSearchByFile(File file) async {
    final bytes = await file.readAsBytes();
    return smartSearchByBytes(bytes);
  }

  /// Smart search by URL - downloads first if using Google direct
  Future<ReverseImageSearchResult> smartSearchByUrl(String imageUrl) async {
    debugPrint(
      '═══════════════════════════════════════════════════════════════',
    );
    debugPrint('ReverseImageSearch: smartSearchByUrl called');
    debugPrint('  URL: $imageUrl');
    debugPrint('  isConfigured (SerpAPI): $isConfigured');
    debugPrint('  hasUserApiKey: $hasUserApiKey');
    debugPrint(
      '═══════════════════════════════════════════════════════════════',
    );

    // If SerpAPI is configured, use it directly
    if (isConfigured) {
      debugPrint('ReverseImageSearch: Using SerpAPI for URL search');
      return searchByUrl(imageUrl);
    }

    // Otherwise download the image and use Google direct
    debugPrint(
      'ReverseImageSearch: Falling back to direct search engines (no SerpAPI)',
    );
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return searchWithGoogleDirect(response.bodyBytes);
      } else {
        return ReverseImageSearchResult.error(
          'Failed to download image: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return ReverseImageSearchResult.error('Failed to download image: $e');
    }
  }
}
