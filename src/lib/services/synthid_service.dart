import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Result from SynthID detection
class SynthIdResult {
  final bool success;
  final bool isAiGenerated;
  final bool hasSynthId;
  final String? explanation;
  final String? errorMessage;

  const SynthIdResult({
    required this.success,
    required this.isAiGenerated,
    required this.hasSynthId,
    this.explanation,
    this.errorMessage,
  });

  factory SynthIdResult.notDetected() {
    return const SynthIdResult(
      success: true,
      isAiGenerated: false,
      hasSynthId: false,
      explanation: 'No SynthID watermark detected in this image.',
    );
  }

  factory SynthIdResult.detected(String explanation) {
    return SynthIdResult(
      success: true,
      isAiGenerated: true,
      hasSynthId: true,
      explanation: explanation,
    );
  }

  factory SynthIdResult.error(String message) {
    return SynthIdResult(
      success: false,
      isAiGenerated: false,
      hasSynthId: false,
      errorMessage: message,
    );
  }

  factory SynthIdResult.skipped() {
    return const SynthIdResult(
      success: false,
      isAiGenerated: false,
      hasSynthId: false,
      errorMessage: 'SynthID detection skipped - API key not configured',
    );
  }
}

/// Service for detecting Google SynthID watermarks using Gemini API
class SynthIdService {
  static SynthIdService? _instance;
  String? _apiKey;
  String? _userApiKey;
  bool _isConfigured = false;

  // Using gemini-2.5-flash as the stable model for image analysis
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  SynthIdService._();

  static SynthIdService get instance {
    _instance ??= SynthIdService._();
    return _instance!;
  }

  /// Configure the service with Google API key
  void configure({required String apiKey}) {
    _apiKey = apiKey;
    _isConfigured = apiKey.isNotEmpty;
    debugPrint('═══════════════════════════════════════════════════════════════');
    debugPrint('SynthID Service: Configured');
    debugPrint('  API key: ${apiKey.isNotEmpty ? "${apiKey.substring(0, 8)}..." : "NOT SET"}');
    debugPrint('  isConfigured: $_isConfigured');
    debugPrint('═══════════════════════════════════════════════════════════════');
  }

  /// Set user-provided API key (takes priority over app default)
  void setUserApiKey(String? apiKey) {
    _userApiKey = apiKey?.isNotEmpty == true ? apiKey : null;
    debugPrint('SynthID Service: User API key ${_userApiKey != null ? "set" : "cleared"}');
  }

  /// Get the effective API key (user key takes priority)
  String? get _effectiveApiKey => _userApiKey ?? _apiKey;

  /// Check if user has provided their own API key
  bool get hasUserApiKey => _userApiKey != null && _userApiKey!.isNotEmpty;

  /// Check if service is configured
  bool get isConfigured => _effectiveApiKey != null && _effectiveApiKey!.isNotEmpty;

  /// Detect SynthID in an image file
  Future<SynthIdResult> detectFromFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return detectFromBytes(bytes);
    } catch (e) {
      debugPrint('SynthID Service: File read error: $e');
      return SynthIdResult.error('Failed to read file');
    }
  }

  /// Detect SynthID in image bytes
  Future<SynthIdResult> detectFromBytes(Uint8List bytes) async {
    if (!isConfigured) {
      debugPrint('SynthID Service: Not configured, skipping detection');
      return SynthIdResult.skipped();
    }

    try {
      debugPrint('═══════════════════════════════════════════════════════════════');
      debugPrint('SynthID Service: Starting detection');
      debugPrint('  Image size: ${bytes.length} bytes');
      debugPrint('  Using ${hasUserApiKey ? "user" : "default"} API key');
      debugPrint('═══════════════════════════════════════════════════════════════');

      final base64Image = base64Encode(bytes);

      // Determine MIME type from image bytes
      String mimeType = 'image/jpeg';
      if (bytes.length > 8) {
        if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
          mimeType = 'image/png';
        } else if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
          mimeType = 'image/webp';
        }
      }

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '@SynthID Is this image AI-generated? Please respond with a clear YES or NO at the beginning, followed by a brief explanation.'
              },
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 256,
        }
      };

      final uri = Uri.parse('$_baseUrl?key=${_effectiveApiKey!}');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('SynthID Service: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseResponse(json);
      } else {
        // Don't log detailed error for rate limiting - just silently fail
        debugPrint('SynthID Service: API error ${response.statusCode}');
        return SynthIdResult.error('API request failed');
      }
    } catch (e) {
      debugPrint('SynthID Service: Exception: $e');
      return SynthIdResult.error('Detection failed');
    }
  }

  /// Detect SynthID from image URL
  Future<SynthIdResult> detectFromUrl(String imageUrl) async {
    if (!isConfigured) {
      return SynthIdResult.skipped();
    }

    try {
      debugPrint('SynthID Service: Downloading image from URL: $imageUrl');
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        return detectFromBytes(response.bodyBytes);
      } else {
        debugPrint('SynthID Service: Failed to download image: ${response.statusCode}');
        return SynthIdResult.error('Failed to download image');
      }
    } catch (e) {
      debugPrint('SynthID Service: URL download error: $e');
      return SynthIdResult.error('Failed to download image');
    }
  }

  /// Parse the Gemini API response
  SynthIdResult _parseResponse(Map<String, dynamic> json) {
    try {
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        debugPrint('SynthID Service: No candidates in response');
        return SynthIdResult.notDetected();
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) {
        return SynthIdResult.notDetected();
      }

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        return SynthIdResult.notDetected();
      }

      final text = parts[0]['text'] as String? ?? '';
      debugPrint('SynthID Service: Response text: $text');

      // Parse the response to determine if SynthID was detected
      final lowerText = text.toLowerCase();
      
      // Check for positive indicators
      final hasYes = lowerText.startsWith('yes') || 
                     lowerText.contains('yes,') ||
                     lowerText.contains('synthid watermark detected') ||
                     lowerText.contains('contains synthid') ||
                     lowerText.contains('has synthid') ||
                     lowerText.contains('synthid is present');

      // Check for negative indicators
      final hasNo = lowerText.startsWith('no') ||
                    lowerText.contains('no synthid') ||
                    lowerText.contains('not detect') ||
                    lowerText.contains('cannot detect') ||
                    lowerText.contains('no watermark') ||
                    lowerText.contains('does not contain');

      // Clean up the explanation text for display
      final cleanExplanation = _cleanExplanation(text);

      if (hasYes && !hasNo) {
        debugPrint('SynthID Service: SynthID DETECTED');
        return SynthIdResult.detected(cleanExplanation);
      } else {
        debugPrint('SynthID Service: SynthID NOT detected');
        return SynthIdResult(
          success: true,
          isAiGenerated: false,
          hasSynthId: false,
          explanation: cleanExplanation,
        );
      }
    } catch (e) {
      debugPrint('SynthID Service: Parse error: $e');
      return SynthIdResult.notDetected();
    }
  }

  /// Clean up the explanation text for better UX
  String _cleanExplanation(String text) {
    String cleaned = text.trim();
    
    // Replace line breaks with spaces
    cleaned = cleaned.replaceAll(RegExp(r'[\r\n]+'), ' ');
    
    // Remove multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove leading YES/NO patterns (case insensitive)
    cleaned = cleaned.replaceFirst(RegExp(r'^(yes|no)[.,:\s]*', caseSensitive: false), '');
    
    // Trim again and capitalize first letter
    cleaned = cleaned.trim();
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    
    return cleaned;
  }
}
