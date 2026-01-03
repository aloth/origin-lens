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

  static const String _imgbbKeyPrefKey = 'user_imgbb_key';

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
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Multi-Engine Search',
                          style: AppTypography.labelLarge.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Context search uses Bing, Yandex, TinEye, and Google for comprehensive results - no API keys required!',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final imgbbKey = _imgbbKeyController.text.trim();
                  _saveUserImgbbKey(imgbbKey.isNotEmpty ? imgbbKey : null);
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
    _setLoading(true, 'Downloading image...');
    _setImage(null, null, url);

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      final contentType = response.headers['content-type'] ?? 'image/jpeg';
      String mimeType = 'image/jpeg';
      if (contentType.contains('png'))
        mimeType = 'image/png';
      else if (contentType.contains('webp'))
        mimeType = 'image/webp';
      else if (contentType.contains('heic'))
        mimeType = 'image/heif';

      setState(() {
        _imageBytes = bytes;
      });

      debugPrint(
        '═══════════════════════════════════════════════════════════════',
      );
      debugPrint('C2PA ANALYSIS: Starting URL bytes analysis');
      debugPrint('  URL: $url');
      debugPrint('  Bytes: ${bytes.length}');
      debugPrint('  MIME: $mimeType');
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

      // Fallback: If no C2PA manifest, try SynthID
      if (!_hasManifest(result.status)) {
        _analyzeSynthIdFromBytes(bytes);
      }
    } catch (e, stackTrace) {
      debugPrint('C2PA ANALYSIS (URL): Exception: $e');
      debugPrint('Stack trace: $stackTrace');
      _setLoading(false, '');
      _showError('Failed: $e');
    }
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

      // Fallback: If no C2PA manifest, try SynthID
      if (!_hasManifest(result.status)) {
        _analyzeSynthIdFromFile(_selectedImage!);
      }
    } catch (e, stackTrace) {
      debugPrint('C2PA ANALYSIS: Exception: $e');
      debugPrint('Stack trace: $stackTrace');
      _setLoading(false, '');
      _showError('Analysis failed: $e');
    }
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
        child: Center(
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
    final hasCredentials = _hasManifest(result.status);
    final isAi = result.aiInfo?.isAiGenerated ?? false;
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusDesc;

    if (isAi) {
      statusColor = AppColors.aiGenerated;
      statusIcon = Icons.auto_awesome_rounded;
      statusTitle = 'AI Generated';
      statusDesc = 'Content contains AI generation markers';
    } else if (result.status is VerificationStatus_Verified) {
      statusColor = AppColors.verified;
      statusIcon = Icons.verified_rounded;
      statusTitle = 'Verified Authentic';
      statusDesc = 'Digital signature is valid and trusted';
    } else if (!hasCredentials) {
      statusColor = AppColors.warning;
      statusIcon = Icons.help_outline_rounded;
      statusTitle = 'No Credentials';
      statusDesc = 'No C2PA metadata found';
    } else {
      statusColor = AppColors.danger;
      statusIcon = Icons.warning_rounded;
      statusTitle = 'Verification Failed';
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

  Widget _buildProvenanceCard() {
    final result = _analysisResult!;
    final hasCredentials = _hasManifest(result.status);
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
                  .take(5)
                  .map(
                    (a) => _buildCleanDetailRow(
                      a.action,
                      a.softwareAgent ?? 'Unknown',
                    ),
                  ),
              if (result.actions.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    '+${result.actions.length - 5} more actions',
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
      error: (_) => false,
    );
  }
}
