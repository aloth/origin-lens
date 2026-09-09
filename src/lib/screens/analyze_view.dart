import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/c2pa_service.dart';
import '../services/reverse_image_search_service.dart';
import '../services/synthid_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AnalyzeView extends StatefulWidget {
  final File? initialImage;
  const AnalyzeView({super.key, this.initialImage});

  @override
  State<AnalyzeView> createState() => _AnalyzeViewState();
}

class _AnalyzeViewState extends State<AnalyzeView>
    with TickerProviderStateMixin {
  File? _selectedImage;
  Uint8List? _imageBytes;
  String? _imageUrl;
  C2paAnalysisResult? _analysisResult;
  ReverseImageSearchResult? _contextResult;
  SynthIdResult? _synthIdResult;
  bool _isLoading = false;
  bool _isContextSearching = false;
  bool _isSynthIdLoading = false;
  String _loadingMessage = '';

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _imgbbKeyController = TextEditingController();
  final TextEditingController _serpApiKeyController = TextEditingController();

  static const String _imgbbKeyPrefKey = 'user_imgbb_key';
  static const String _serpApiKeyPrefKey = 'user_serpapi_key';
  static const String _remoteConsentPrefKey = 'remote_assessment_consent';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    C2paService.instance.initialize();
    _loadUserApiKey();

    if (widget.initialImage != null) {
      _setImage(widget.initialImage, null, null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _analyzeImage();
      });
    }

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  Future<void> _loadUserApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedImgbbKey = prefs.getString(_imgbbKeyPrefKey);
      if (savedImgbbKey != null && savedImgbbKey.isNotEmpty) {
        _imgbbKeyController.text = savedImgbbKey;
        ReverseImageSearchService.instance.setUserImgbbApiKey(savedImgbbKey);
        debugPrint('Loaded user imgbb key from preferences');
      }
      final savedSerpApiKey = prefs.getString(_serpApiKeyPrefKey);
      if (savedSerpApiKey != null && savedSerpApiKey.isNotEmpty) {
        _serpApiKeyController.text = savedSerpApiKey;
        ReverseImageSearchService.instance.setUserApiKey(savedSerpApiKey);
        debugPrint('Loaded user SerpAPI key from preferences');
      }
    } catch (e) {
      debugPrint('Error loading user API keys: $e');
    }
  }

  Future<void> _saveUserImgbbKey(String? apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (apiKey != null && apiKey.isNotEmpty) {
        await prefs.setString(_imgbbKeyPrefKey, apiKey);
        ReverseImageSearchService.instance.setUserImgbbApiKey(apiKey);
        debugPrint('Saved user imgbb key to preferences');
      } else {
        await prefs.remove(_imgbbKeyPrefKey);
        ReverseImageSearchService.instance.setUserImgbbApiKey(null);
        debugPrint('Cleared user imgbb key from preferences');
      }
    } catch (e) {
      debugPrint('Error saving user imgbb key: $e');
    }
  }

  Future<void> _saveUserSerpApiKey(String? apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (apiKey != null && apiKey.isNotEmpty) {
        await prefs.setString(_serpApiKeyPrefKey, apiKey);
        ReverseImageSearchService.instance.setUserApiKey(apiKey);
        debugPrint('Saved user SerpAPI key to preferences');
      } else {
        await prefs.remove(_serpApiKeyPrefKey);
        ReverseImageSearchService.instance.setUserApiKey(null);
        debugPrint('Cleared user SerpAPI key from preferences');
      }
    } catch (e) {
      debugPrint('Error saving user SerpAPI key: $e');
    }
  }

  void _showSettingsDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(Icons.settings_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Settings',
                  style: AppTypography.titleLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            // Multi-engine search info
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Multi-Engine Search',
                          style: AppTypography.labelMedium.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Context search uses Bing, Yandex, TinEye, and Google for comprehensive results - no API keys required!',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'imgbb API Key (Optional)',
              style: AppTypography.labelLarge.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Optional: Used for uploading local images to enable URL-based search. Get a free key at api.imgbb.com',
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _imgbbKeyController,
              decoration: InputDecoration(
                hintText: 'Enter your imgbb key (optional)',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.cloud_upload_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _imgbbKeyController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _imgbbKeyController.clear();
                          _saveUserImgbbKey(null);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('imgbb key cleared'),
                              backgroundColor: theme.colorScheme.secondary,
                            ),
                          );
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'SerpAPI Key (Optional)',
              style: AppTypography.labelLarge.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Optional: Provides additional search results. Get a free key at serpapi.com',
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _serpApiKeyController,
              decoration: InputDecoration(
                hintText: 'Enter your SerpAPI key (optional)',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.key_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _serpApiKeyController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _serpApiKeyController.clear();
                          _saveUserSerpApiKey(null);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('SerpAPI key cleared'),
                              backgroundColor: theme.colorScheme.secondary,
                            ),
                          );
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final imgbbKey = _imgbbKeyController.text.trim();
                  final serpApiKey = _serpApiKeyController.text.trim();
                  _saveUserImgbbKey(imgbbKey.isNotEmpty ? imgbbKey : null);
                  _saveUserSerpApiKey(serpApiKey.isNotEmpty ? serpApiKey : null);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Settings saved'),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(AnalyzeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImage != null &&
        widget.initialImage != oldWidget.initialImage) {
      _setImage(widget.initialImage, null, null);
      _analyzeImage();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _imgbbKeyController.dispose();
    _serpApiKeyController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _pickFromFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'heic',
          'heif',
          'avif',
        ],
      );
      if (result != null && result.files.single.path != null) {
        _setImage(File(result.files.single.path!), null, null);
        await _analyzeImage();
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        _setImage(File(pickedFile.path), null, null);
        await _analyzeImage();
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  /// Checks if a URL is from a known service that strips C2PA metadata
  bool _isMetadataStrippingService(String url) {
    final strippingPatterns = [
      // Social media platforms (always strip metadata)
      'pbs.twimg.com', // Twitter/X
      'instagram.com',
      'cdninstagram.com',
      'facebook.com',
      'fbcdn.net',
      'tiktok.com',
      'snapchat.com',
      // Image optimization/CDN services that may strip metadata
      'cloudinary.com',
      'imgix.net',
      'images.unsplash.com',
      'res.cloudinary.com',
      'imagekit.io',
      'thumbor',
      'imageshack.com',
      'tinypic.com',
      'postimg.cc',
      'ibb.co', // imgbb
      'i.ibb.co',
      'imgur.com',
      'i.imgur.com',
      // Google services
      'googleusercontent.com',
      'ggpht.com',
      'lh3.google.com',
      // Resize/transform parameters
      '?w=', '&w=', // width parameter
      '?h=', '&h=', // height parameter
      '?resize=',
      '?fit=',
      '?quality=',
      '?auto=format',
      '?auto=compress',
      '_thumb',
      '_small',
      '_medium',
      '_large',
    ];

    final lowerUrl = url.toLowerCase();
    return strippingPatterns.any((pattern) => lowerUrl.contains(pattern));
  }

  /// Attempts to get the original/raw image URL from common CDN patterns
  String _tryGetOriginalUrl(String url) {
    var originalUrl = url;

    // Remove common resize/quality parameters
    final paramsToRemove = [
      RegExp(r'[?&]w=\d+'),
      RegExp(r'[?&]h=\d+'),
      RegExp(r'[?&]width=\d+'),
      RegExp(r'[?&]height=\d+'),
      RegExp(r'[?&]resize=[\w\d]+'),
      RegExp(r'[?&]fit=[\w]+'),
      RegExp(r'[?&]quality=\d+'),
      RegExp(r'[?&]q=\d+'),
      RegExp(r'[?&]auto=[\w,]+'),
      RegExp(r'[?&]format=[\w]+'),
      RegExp(r'[?&]fm=[\w]+'),
    ];

    for (final pattern in paramsToRemove) {
      originalUrl = originalUrl.replaceAll(pattern, '');
    }

    // Clean up URL if we removed parameters
    originalUrl = originalUrl.replaceAll('?&', '?').replaceAll('&&', '&');
    if (originalUrl.endsWith('?') || originalUrl.endsWith('&')) {
      originalUrl = originalUrl.substring(0, originalUrl.length - 1);
    }

    return originalUrl;
  }

  Future<void> _analyzeFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('Please enter a URL');
      return;
    }

    Uri? uri;
    try {
      uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.scheme.startsWith('http')) {
        _showError('Please enter a valid URL');
        return;
      }
    } catch (e) {
      _showError('Invalid URL');
      return;
    }

    Navigator.pop(context);

    // Check if URL is from a known metadata-stripping service
    final isStrippingService = _isMetadataStrippingService(url);
    if (isStrippingService) {
      debugPrint('⚠️ URL is from a service known to strip C2PA metadata');
    }

    // Try to get original URL without resize parameters
    final originalUrl = _tryGetOriginalUrl(url);
    final effectiveUri = Uri.parse(originalUrl);

    _setLoading(true, 'Downloading original image...');
    _setImage(null, null, url);

    try {
      // Use headers that request the original, unmodified image
      // These headers tell the server we want the raw file, not an optimized version
      final response = await http.get(
        effectiveUri,
        headers: {
          // Request original format, avoid WebP conversion
          'Accept':
              'image/jpeg, image/png, image/heic, image/heif, image/avif, image/tiff, image/webp, */*',
          // Disable caching to get fresh content
          'Cache-Control': 'no-cache, no-transform',
          // Some CDNs use this to skip optimization
          'X-No-Transform': 'true',
          // Pretend to be a standard browser
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      final contentType = response.headers['content-type'] ?? 'image/jpeg';

      debugPrint('Response headers:');
      debugPrint('  Content-Type: $contentType');
      debugPrint('  Content-Length: ${response.headers['content-length']}');
      debugPrint('  Cache-Control: ${response.headers['cache-control']}');
      debugPrint('  X-Cache: ${response.headers['x-cache']}');

      String mimeType = 'image/jpeg';
      if (contentType.contains('png'))
        mimeType = 'image/png';
      else if (contentType.contains('webp'))
        mimeType = 'image/webp';
      else if (contentType.contains('heic') || contentType.contains('heif'))
        mimeType = 'image/heif';
      else if (contentType.contains('avif'))
        mimeType = 'image/avif';
      else if (contentType.contains('tiff'))
        mimeType = 'image/tiff';

      // Check for C2PA Link header (external manifest reference per C2PA spec)
      final linkHeader = response.headers['link'];
      String? externalManifestUrl;
      if (linkHeader != null && linkHeader.contains('rel=c2pa-manifest')) {
        debugPrint('Found C2PA Link header: $linkHeader');
        // Parse the Link header to extract manifest URL
        final linkMatch = RegExp(
          r'<([^>]+)>.*rel=c2pa-manifest',
        ).firstMatch(linkHeader);
        if (linkMatch != null) {
          externalManifestUrl = linkMatch.group(1);
          debugPrint('External manifest URL: $externalManifestUrl');
        }
      }

      setState(() {
        _imageBytes = bytes;
      });

      debugPrint(
        '═══════════════════════════════════════════════════════════════',
      );
      debugPrint('C2PA ANALYSIS: Starting URL bytes analysis');
      debugPrint('  URL: $url');
      debugPrint('  Effective URL: $originalUrl');
      debugPrint('  Is stripping service: $isStrippingService');
      debugPrint('  Bytes: ${bytes.length}');
      debugPrint('  MIME: $mimeType');
      if (externalManifestUrl != null) {
        debugPrint('  External manifest: $externalManifestUrl');
      }
      debugPrint(
        '═══════════════════════════════════════════════════════════════',
      );

      _setLoading(true, 'Analyzing credentials...');
      final result = await C2paService.instance.analyzeBytes(bytes, mimeType);

      debugPrint(
        '═══════════════════════════════════════════════════════════════',
      );
      debugPrint('C2PA ANALYSIS (URL): Complete');
      debugPrint('  Status: ${result.status}');
      debugPrint('  AI Info: ${result.aiInfo?.isAiGenerated ?? false}');
      debugPrint('  Generator: ${result.aiInfo?.generatorName}');
      debugPrint('  Actions: ${result.actions.length}');
      debugPrint(
        '  Signer: ${result.signer?.name ?? result.signer?.organization ?? "none"}',
      );
      debugPrint('  EXIF: ${result.exifInfo != null}');
      debugPrint('  Has manifest: ${result.rawManifestJson != null}');
      debugPrint(
        '═══════════════════════════════════════════════════════════════',
      );

      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });

      // Show warning if URL is from a metadata-stripping service and no manifest found
      if (isStrippingService && !_hasManifest(result.status)) {
        _showMetadataStrippingWarning(url);
      }

      // Fallback: offer the remote assessment. Offered, not performed: this is
      // the only path on which the image leaves the device.
      if (!_hasManifest(result.status) && await _confirmRemoteAssessment()) {
        _analyzeSynthIdFromBytes(bytes);
      }
    } catch (e, stackTrace) {
      debugPrint('C2PA ANALYSIS (URL): Exception: $e');
      debugPrint('Stack trace: $stackTrace');
      _setLoading(false, '');
      _showError('Failed: $e');
    }
  }

  void _showMetadataStrippingWarning(String url) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Metadata may have been stripped',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'This URL is from a service known to strip C2PA metadata. '
              'Try downloading the original file or use a direct source URL.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Learn More',
          textColor: Colors.white,
          onPressed: () {
            launchUrl(Uri.parse('https://contentcredentials.org/verify'));
          },
        ),
      ),
    );
  }

  void _setImage(File? file, Uint8List? bytes, String? url) {
    setState(() {
      _selectedImage = file;
      _imageBytes = bytes;
      _imageUrl = url;
      _analysisResult = null;
      _contextResult = null;
      _synthIdResult = null;
      _isSynthIdLoading = false;
    });
  }

  void _setLoading(bool loading, String message) {
    setState(() {
      _isLoading = loading;
      _loadingMessage = message;
    });
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    debugPrint(
      '═══════════════════════════════════════════════════════════════',
    );
    debugPrint('C2PA ANALYSIS: Starting file analysis');
    debugPrint('  Path: ${_selectedImage!.path}');
    debugPrint(
      '═══════════════════════════════════════════════════════════════',
    );

    _setLoading(true, 'Analyzing credentials...');

    try {
      final result = await C2paService.instance.analyzeFile(
        _selectedImage!.path,
      );

      debugPrint(
        '═══════════════════════════════════════════════════════════════',
      );
      debugPrint('C2PA ANALYSIS: Complete');
      debugPrint('  Status: ${result.status}');
      debugPrint('  AI Info: ${result.aiInfo?.isAiGenerated ?? false}');
      debugPrint('  Generator: ${result.aiInfo?.generatorName}');
      debugPrint('  Actions: ${result.actions.length}');
      debugPrint(
        '  Signer: ${result.signer?.name ?? result.signer?.organization ?? "none"}',
      );
      debugPrint('  EXIF: ${result.exifInfo != null}');
      debugPrint('  Has manifest: ${result.rawManifestJson != null}');
      debugPrint(
        '═══════════════════════════════════════════════════════════════',
      );

      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });

      // Fallback: offer the remote assessment. Offered, not performed: this is
      // the only path on which the image leaves the device.
      if (!_hasManifest(result.status) && await _confirmRemoteAssessment()) {
        _analyzeSynthIdFromFile(_selectedImage!);
      }
    } catch (e, stackTrace) {
      debugPrint('C2PA ANALYSIS: Exception: $e');
      debugPrint('Stack trace: $stackTrace');
      _setLoading(false, '');
      _showError('Analysis failed: $e');
    }
  }

  /// Ask before the image leaves the device.
  ///
  /// Everything else in the analysis runs locally. The AI assessment posts the
  /// full image to a third-party API, so it is offered rather than performed as
  /// a silent fallback. No dialog is shown when no API key is configured, since
  /// nothing would be sent in that case.
  Future<bool> _confirmRemoteAssessment() async {
    if (!SynthIdService.instance.isConfigured) return false;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_remoteConsentPrefKey) == true) return true;

    if (!mounted) return false;
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send this image for AI assessment?'),
        content: const Text(
          'No Content Credentials were found in this image. Origin Lens can ask '
          'a general-purpose AI model whether it looks AI-generated.\n\n'
          'This sends the full image to Google\'s Gemini API. Every other check '
          'in this analysis ran on your device. The model returns an opinion, '
          'not a watermark reading.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'no'),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'once'),
            child: const Text('Send once'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'always'),
            child: const Text('Always send'),
          ),
        ],
      ),
    );

    if (choice == 'always') {
      await prefs.setBool(_remoteConsentPrefKey, true);
      return true;
    }
    return choice == 'once';
  }

  Future<void> _analyzeSynthIdFromFile(File file) async {
    setState(() {
      _isSynthIdLoading = true;
    });

    try {
      final result = await SynthIdService.instance.detectFromFile(file);
      if (mounted) {
        setState(() {
          _synthIdResult = result;
          _isSynthIdLoading = false;
        });
      }
    } catch (e) {
      debugPrint('SynthID error: $e');
      if (mounted) {
        setState(() {
          _isSynthIdLoading = false;
        });
      }
    }
  }

  Future<void> _analyzeSynthIdFromBytes(Uint8List bytes) async {
    setState(() {
      _isSynthIdLoading = true;
    });

    try {
      final result = await SynthIdService.instance.detectFromBytes(bytes);
      if (mounted) {
        setState(() {
          _synthIdResult = result;
          _isSynthIdLoading = false;
        });
      }
    } catch (e) {
      debugPrint('SynthID error: $e');
      if (mounted) {
        setState(() {
          _isSynthIdLoading = false;
        });
      }
    }
  }

  Future<void> _searchContext() async {
    final searchService = ReverseImageSearchService.instance;

    debugPrint(
      '═══════════════════════════════════════════════════════════════',
    );
    debugPrint('CONTEXT SEARCH: Starting multi-engine search...');
    debugPrint('  imageUrl: $_imageUrl');
    debugPrint('  imageBytes: ${_imageBytes?.length ?? 0} bytes');
    debugPrint('  selectedImage: ${_selectedImage?.path}');
    debugPrint('  Engines: Bing, Yandex, TinEye, Google');
    debugPrint(
      '═══════════════════════════════════════════════════════════════',
    );

    setState(() {
      _isContextSearching = true;
    });

    try {
      ReverseImageSearchResult result;

      if (_imageUrl != null) {
        debugPrint('CONTEXT SEARCH: Using smartSearchByUrl');
        result = await searchService.smartSearchByUrl(_imageUrl!);
      } else if (_imageBytes != null) {
        debugPrint(
          'CONTEXT SEARCH: Using smartSearchByBytes (${_imageBytes!.length} bytes)',
        );
        result = await searchService.smartSearchByBytes(_imageBytes!);
      } else if (_selectedImage != null) {
        debugPrint('CONTEXT SEARCH: Using smartSearchByFile');
        result = await searchService.smartSearchByFile(_selectedImage!);
      } else {
        debugPrint('CONTEXT SEARCH: No image available!');
        setState(() {
          _isContextSearching = false;
        });
        _showError('No image to search');
        return;
      }

      debugPrint(
        '═══════════════════════════════════════════════════════════════',
      );
      debugPrint('CONTEXT SEARCH: Complete');
      debugPrint('  success: ${result.success}');
      debugPrint('  errorMessage: ${result.errorMessage}');
      debugPrint('  queryDisplayed: ${result.queryDisplayed}');
      debugPrint('  totalResults: ${result.totalResults}');
      debugPrint('  hasMatches: ${result.hasMatches}');
      debugPrint('  matches count: ${result.matches.length}');
      debugPrint(
        '═══════════════════════════════════════════════════════════════',
      );

      setState(() {
        _contextResult = result;
        _isContextSearching = false;
      });
    } catch (e, stackTrace) {
      debugPrint('CONTEXT SEARCH: Exception: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isContextSearching = false;
      });
      _showError('Search failed: $e');
    }
  }

  void _clearAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
      _imageUrl = null;
      _analysisResult = null;
      _contextResult = null;
      _synthIdResult = null;
      _isLoading = false;
      _isSynthIdLoading = false;
      _loadingMessage = '';
      _urlController.clear();
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _selectedImage != null || _imageBytes != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? _buildLoadingState()
          : hasImage
          ? _buildAnalysisView()
          : _buildWelcomeView(),
    );
  }

  Widget _buildWelcomeView() {
    final theme = Theme.of(context);

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Settings button in top right
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: IconButton(
                icon: Icon(
                  Icons.settings_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: _showSettingsDialog,
                tooltip: 'Settings',
              ),
            ),
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Area
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  'Origin Lens',
                  style: AppTypography.displayMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Verify content authenticity',
                  style: AppTypography.bodyLarge.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Primary Action: Files
                _buildPrimaryActionCard(context),

                const SizedBox(height: AppSpacing.lg),

                // Secondary Actions Row
                Row(
                  children: [
                    Expanded(
                      child: _buildSecondaryActionCard(
                        context,
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: _pickFromGallery,
                        isLeft: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildSecondaryActionCard(
                        context,
                        icon: Icons.link_rounded,
                        label: 'URL',
                        onTap: _showUrlDialog,
                        isRight: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Helper text
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Use Files for best metadata results',
                        style: AppTypography.labelSmall.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryActionCard(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickFromFiles,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 28, // Reduced from 40
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select from Files',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Recommended for analysis',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLeft = false,
    bool isRight = false,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedProgressRing(
            size: 80,
            strokeWidth: 6,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            _loadingMessage,
            style: AppTypography.titleMedium.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please wait...',
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisView() {
    final theme = Theme.of(context);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            centerTitle: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            title: Text(
              'Analysis Results',
              style: AppTypography.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.settings_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: _showSettingsDialog,
                tooltip: 'Settings',
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.error,
                    size: 18,
                  ),
                ),
                onPressed: _clearAll,
                tooltip: 'Start over',
              ),
              const SizedBox(width: AppSpacing.md),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImagePreview(),

                  const SizedBox(height: AppSpacing.xl),

                  if (_analysisResult != null) ...[
                    _buildVerificationCard(),
                    _buildAiAnalysisCard(),
                    _buildSynthIdCard(),
                    _buildProvenanceCard(),
                  ],

                  if (_contextResult == null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildContextSearchCard(),
                  ],

                  if (_contextResult != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildContextResultsCard(),
                  ],

                  const SizedBox(height: AppSpacing.huge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final theme = Theme.of(context);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_selectedImage != null)
              Image.file(_selectedImage!, fit: BoxFit.cover)
            else if (_imageBytes != null)
              Image.memory(_imageBytes!, fit: BoxFit.cover)
            else
              Center(
                child: Icon(
                  Icons.image_outlined,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  size: 48,
                ),
              ),
            if (_selectedImage != null || _imageUrl != null)
              Positioned(
                bottom: AppSpacing.md,
                right: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _imageUrl != null
                            ? Icons.link_rounded
                            : Icons.folder_open_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          _imageUrl ?? _selectedImage!.path.split('/').last,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationCard() {
    final result = _analysisResult!;
    final isAi = result.aiInfo?.isAiGenerated ?? false;
    final theme = Theme.of(context);
    final isFromUrl = _imageUrl != null;

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusDesc;

    // Determine status based on verification result following the semantic color system:
    // - Verified (Green): Valid C2PA credentials, intact signature, trusted chain
    // - AI Generated (Purple): C2PA assertions indicate AI generation
    // - Warning (Orange): Ambiguities - expired certs, incomplete trust, parsing errors, no manifest
    // - Invalid (Red): Manifest found but hash mismatch - indicates manipulation

    if (isAi) {
      // AI Generated (Purple) - Content contains AI generation markers
      statusColor = AppColors.aiGenerated;
      statusIcon = Icons.auto_awesome_rounded;
      statusTitle = 'AI Generated';
      statusDesc = 'Content contains AI generation markers';
    } else if (result.status is VerificationStatus_Verified) {
      // Verified (Green) - Valid credentials and trusted chain
      statusColor = AppColors.verified;
      statusIcon = Icons.verified_rounded;
      statusTitle = 'Verified Authentic';
      statusDesc = 'Digital signature is valid and trusted';
    } else if (result.status is VerificationStatus_SignatureInvalid) {
      // Invalid (Red) - Signature mismatch indicates manipulation
      statusColor = AppColors.danger;
      statusIcon = Icons.dangerous_rounded;
      statusTitle = 'Invalid Signature';
      statusDesc = 'Content may have been modified after signing';
    } else if (result.status is VerificationStatus_CertificateExpired) {
      // Warning (Orange) - Certificate expired but content may still be authentic
      statusColor = AppColors.warning;
      statusIcon = Icons.schedule_rounded;
      statusTitle = 'Certificate Expired';
      statusDesc = 'Credentials are valid but the certificate has expired';
    } else if (result.status is VerificationStatus_CertificateUntrusted) {
      // Warning (Orange) - Untrusted certificate chain
      statusColor = AppColors.warning;
      statusIcon = Icons.security_rounded;
      statusTitle = 'Untrusted Certificate';
      statusDesc = 'Certificate could not be verified against trusted sources';
    } else if (result.status is VerificationStatus_NoManifest) {
      // Warning (Orange) - No C2PA data found
      statusColor = AppColors.warning;
      statusIcon = Icons.help_outline_rounded;
      statusTitle = 'No Credentials';
      if (isFromUrl) {
        statusDesc = 'No C2PA metadata found. The source may have stripped it.';
      } else {
        statusDesc = 'No C2PA metadata found';
      }
    } else if (result.status is VerificationStatus_Error) {
      // Check if error message indicates C2PA data that couldn't be parsed
      final errorStatus = result.status as VerificationStatus_Error;
      final errorMsg = errorStatus.message.toLowerCase();

      if (errorMsg.contains('c2pa data') ||
          errorMsg.contains('could not be parsed') ||
          errorMsg.contains('unsupported format') ||
          errorMsg.contains('corrupted')) {
        // Warning (Orange) - C2PA data exists but couldn't be processed
        statusColor = AppColors.warning;
        statusIcon = Icons.warning_amber_rounded;
        statusTitle = 'Parsing Issue';
        statusDesc = 'C2PA data found but could not be fully verified';
      } else if (errorMsg.contains('remote') || errorMsg.contains('fetch')) {
        // Warning (Orange) - Remote manifest issue
        statusColor = AppColors.warning;
        statusIcon = Icons.cloud_off_rounded;
        statusTitle = 'Connection Issue';
        statusDesc = 'Could not retrieve remote credentials';
      } else {
        // Warning (Orange) - Generic error
        statusColor = AppColors.warning;
        statusIcon = Icons.error_outline_rounded;
        statusTitle = 'Analysis Issue';
        statusDesc = errorStatus.message.isNotEmpty
            ? errorStatus.message
            : 'Could not verify credentials';
      }
    } else {
      // Fallback - treat as warning
      statusColor = AppColors.warning;
      statusIcon = Icons.help_outline_rounded;
      statusTitle = 'Unknown Status';
      statusDesc = _getStatusSubtitle(result.status);
    }

    return GlassCard(
      borderColor: statusColor.withOpacity(0.3),
      borderWidth: 1.5,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, size: 48, color: statusColor),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            statusTitle,
            style: AppTypography.headlineMedium.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            statusDesc,
            style: AppTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSynthIdCard() {
    if (_isSynthIdLoading) {
      return _buildSection(
        title: 'SynthID Check',
        icon: Icons.water_drop_rounded,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Checking for invisible watermarks...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_synthIdResult == null || !_synthIdResult!.hasSynthId) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'SynthID Detected',
      icon: Icons.water_drop_rounded,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.aiGenerated.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.aiGenerated.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.aiGenerated,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'AI Generated Content',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.aiGenerated,
                    ),
                  ),
                ],
              ),
              if (_synthIdResult!.explanation != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _synthIdResult!.explanation!,
                  style: AppTypography.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiAnalysisCard() {
    final result = _analysisResult!;
    final aiInfo = result.aiInfo;
    if (aiInfo == null || !aiInfo.isAiGenerated) return const SizedBox.shrink();

    return _buildSection(
      title: 'AI Analysis',
      icon: Icons.auto_awesome_rounded,
      children: [
        _buildCleanDetailRow('Generator', aiInfo.generatorName ?? 'Unknown'),
        _buildCleanDetailRow('Model', aiInfo.modelName ?? 'Unknown'),
        _buildCleanDetailRow(
          'Source',
          aiInfo.detectionSource ?? 'C2PA Manifest',
          isLast: true,
        ),
      ],
    );
  }

  /// Convert C2PA action name to human-readable format
  String _formatActionName(String action) {
    // Remove c2pa. prefix and convert to readable format
    var name = action.replaceFirst('c2pa.', '');
    // Convert snake_case or camelCase to Title Case
    name = name
        .replaceAllMapped(RegExp(r'[_.]'), (match) => ' ')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        );
    // Capitalize first letter of each word
    return name
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Parse action parameters JSON and return a human-readable description
  String? _formatActionParameters(String? parametersJson) {
    if (parametersJson == null || parametersJson.isEmpty) return null;
    try {
      final params = jsonDecode(parametersJson) as Map<String, dynamic>;
      if (params.isEmpty) return null;

      // Format parameters into a readable string
      final parts = <String>[];
      for (final entry in params.entries) {
        final key = entry.key;
        final value = entry.value;

        // Skip very long or binary values
        if (value is String && value.startsWith('<')) continue;

        // Handle Adobe ACR parameters specially
        if (key == 'com.adobe.acr') {
          parts.add(value.toString());
        } else if (key == 'com.adobe.acr.value') {
          // This is the value for the previous parameter
          if (parts.isNotEmpty) {
            parts[parts.length - 1] = '${parts.last}: $value';
          }
        } else if (key == 'description') {
          parts.add(value.toString());
        } else {
          // Generic parameter display
          parts.add('$key: $value');
        }
      }
      return parts.isEmpty ? null : parts.join(', ');
    } catch (e) {
      debugPrint('Error parsing action parameters: $e');
      return null;
    }
  }

  Widget _buildActionRow(ContentAction action, {bool isLast = false}) {
    final theme = Theme.of(context);
    final formattedName = _formatActionName(action.action);
    final parameterDetails = _formatActionParameters(action.parameters);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  formattedName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (action.softwareAgent != null)
                Text(
                  action.softwareAgent!,
                  style: AppTypography.labelSmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (parameterDetails != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 16),
              child: Text(
                parameterDetails,
                style: AppTypography.labelSmall.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          if (action.when != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                action.when!,
                style: AppTypography.labelSmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCleanDetailRow(
    String label,
    String value, {
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvenanceCard() {
    final result = _analysisResult!;
    final hasCredentials = _hasManifest(result.status);
    final hasC2paIssues = _hasC2paDataWithIssues(result.status);
    final theme = Theme.of(context);

    // Show info card for C2PA data that couldn't be parsed
    if (!hasCredentials && hasC2paIssues) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderColor: AppColors.warning.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Credential Details Unavailable',
                      style: AppTypography.titleMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'This image contains C2PA metadata, but the credentials could not be fully parsed. '
                'This may be due to:',
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildBulletPoint('An unsupported or newer C2PA format'),
              _buildBulletPoint('Corrupted or incomplete credential data'),
              _buildBulletPoint(
                'A cloud-based manifest that could not be retrieved',
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'The presence of C2PA data indicates this image was processed by a C2PA-aware application.',
                style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!hasCredentials) return const SizedBox.shrink();

    return Column(
      children: [
        if (result.signer != null)
          _buildSection(
            title: 'Creator Info',
            icon: Icons.person_outline_rounded,
            children: [
              if (result.signer!.name != null)
                _buildCleanDetailRow('Name', result.signer!.name!),
              if (result.signer!.organization != null)
                _buildCleanDetailRow(
                  'Organization',
                  result.signer!.organization!,
                ),
              if (result.signer!.issuedBy != null)
                _buildCleanDetailRow('Issued By', result.signer!.issuedBy!),
              if (result.signer!.timestamp != null)
                _buildCleanDetailRow(
                  'Timestamp',
                  result.signer!.timestamp!,
                  isLast: true,
                ),
            ],
          ),

        if (result.actions.isNotEmpty)
          _buildSection(
            title: 'Edit History',
            icon: Icons.history_rounded,
            children: [
              ...result.actions
                  .asMap()
                  .entries
                  .take(8)
                  .map(
                    (entry) => _buildActionRow(
                      entry.value,
                      isLast:
                          entry.key == result.actions.length - 1 ||
                          entry.key == 7,
                    ),
                  ),
              if (result.actions.length > 8)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    '+${result.actions.length - 8} more actions',
                    style: AppTypography.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),

        if (result.exifInfo != null)
          _buildSection(
            title: 'EXIF Data',
            icon: Icons.camera_alt_outlined,
            children: [
              if (result.exifInfo!.software != null)
                _buildCleanDetailRow('Software', result.exifInfo!.software!),
              if (result.exifInfo!.make != null)
                _buildCleanDetailRow('Camera Make', result.exifInfo!.make!),
              if (result.exifInfo!.model != null)
                _buildCleanDetailRow('Camera Model', result.exifInfo!.model!),
              if (result.exifInfo!.dateTimeOriginal != null)
                _buildCleanDetailRow(
                  'Date Taken',
                  result.exifInfo!.dateTimeOriginal!,
                  isLast: true,
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            title: Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            initiallyExpanded: true,
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    ThemeData theme,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.labelLarge.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: valueColor ?? theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextSearchCard() {
    final theme = Theme.of(context);
    final hasImage =
        _imageUrl != null || _imageBytes != null || _selectedImage != null;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isContextSearching ? 48 : 200,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: _isContextSearching
            ? Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              )
            : InkWell(
                onTap: hasImage ? _searchContext : null,
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.travel_explore_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Check Online Context',
                      style: AppTypography.labelLarge.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildContextResultsCard() {
    final result = _contextResult!;
    final theme = Theme.of(context);
    final isWarning = result.possiblyOutOfContext;

    return _buildSection(
      title: 'Context Check',
      icon: Icons.travel_explore_rounded,
      children: [
        if (isWarning)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Appears in multiple contexts',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (result.totalResults > 0)
          _buildCleanDetailRow('Matches Found', '${result.totalResults}'),

        if (result.firstSeenDate != null)
          _buildCleanDetailRow('First Seen', result.firstSeenDate!),

        if (result.hasMatches) ...[
          const SizedBox(height: AppSpacing.lg),
          ...result.matches.take(3).map((match) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildSourceTile(match),
            );
          }),
          if (result.matches.length > 3)
            Center(
              child: TextButton(
                onPressed: () => _showAllSources(result),
                child: Text(
                  'View all ${result.matches.length} sources',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ),
        ] else if (result.hasSearchLinks) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.searchLinks
                .map(
                  (link) => ActionChip(
                    avatar: Icon(
                      _getSearchEngineIcon(link.engineName),
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      link.engineName,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.05,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    onPressed: () => _launchUrl(link.searchUrl),
                  ),
                )
                .toList(),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'No matches found online',
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSourceTile(ImageSearchMatch match) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchUrl(match.link),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  width: 40,
                  height: 40,
                  color: theme.colorScheme.surface,
                  child: match.thumbnail != null
                      ? Image.network(
                          match.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.link_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        )
                      : Icon(
                          Icons.link_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (match.source != null)
                      Text(
                        match.source!,
                        style: AppTypography.labelSmall.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllSources(ReverseImageSearchResult result) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    Text(
                      'All Sources',
                      style: AppTypography.headlineMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusBadge(
                      label: '${result.matches.length}',
                      color: theme.colorScheme.primary,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),

              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  itemCount: result.matches.length,
                  itemBuilder: (context, index) =>
                      _buildSourceTile(result.matches[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUrlDialog() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: AppSpacing.xxl,
          right: AppSpacing.xxl,
          top: AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              Text(
                'Enter Image URL',
                style: AppTypography.headlineMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'Paste a direct link to an image to analyze',
                style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'https://example.com/image.jpg',
                  prefixIcon: Icon(
                    Icons.link_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _urlController.text = data!.text!;
                      }
                    },
                  ),
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                onSubmitted: (_) => _analyzeFromUrl(),
              ),

              const SizedBox(height: AppSpacing.lg),

              // C2PA URL Tips
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Tips for C2PA Verification',
                          style: AppTypography.labelMedium.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '• Use direct links from original sources (news sites, official sources)\n'
                      '• Avoid social media links (Twitter, Facebook, Instagram strip metadata)\n'
                      '• Avoid CDN/thumbnail URLs with resize parameters\n'
                      '• Links ending in .jpg, .png, .heic work best',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              GradientButton(
                label: 'Analyze Image',
                icon: Icons.search_rounded,
                onPressed: _analyzeFromUrl,
                width: double.infinity,
              ),

              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSearchEngineIcon(String engineName) {
    switch (engineName.toLowerCase()) {
      case 'google lens':
      case 'google images':
        return Icons.search_rounded;
      case 'bing visual search':
        return Icons.image_search_rounded;
      case 'yandex images':
        return Icons.travel_explore_rounded;
      case 'tineye':
        return Icons.find_in_page_rounded;
      default:
        return Icons.open_in_browser_rounded;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getStatusSubtitle(VerificationStatus status) {
    return status.when(
      verified: () => 'Content credentials verified',
      signatureInvalid: () => 'Digital signature is invalid',
      certificateExpired: () => 'Certificate has expired',
      certificateUntrusted: () => 'Certificate is not trusted',
      noManifest: () => 'No C2PA data found',
      error: (msg) => msg.isNotEmpty ? msg : 'Analysis error',
    );
  }

  bool _hasManifest(VerificationStatus status) {
    return status.when(
      verified: () => true,
      signatureInvalid: () => true,
      certificateExpired: () => true,
      certificateUntrusted: () => true,
      noManifest: () => false,
      error: (msg) {
        // Check if error message indicates C2PA data exists but couldn't be parsed
        final lowerMsg = msg.toLowerCase();
        return lowerMsg.contains('c2pa') ||
            lowerMsg.contains('manifest') ||
            lowerMsg.contains('could not be parsed') ||
            lowerMsg.contains('unsupported format');
      },
    );
  }

  /// Check if the status indicates C2PA data was found but had issues
  bool _hasC2paDataWithIssues(VerificationStatus status) {
    if (status is VerificationStatus_Error) {
      final lowerMsg = status.message.toLowerCase();
      return lowerMsg.contains('c2pa') ||
          lowerMsg.contains('manifest') ||
          lowerMsg.contains('could not be parsed') ||
          lowerMsg.contains('unsupported format') ||
          lowerMsg.contains('corrupted');
    }
    return false;
  }
}
