import 'dart:io';
import 'package:flutter/foundation.dart';

import '../src/rust/frb_generated.dart';
import '../src/rust/api/c2pa_reader.dart' as rust;

export '../src/rust/api/c2pa_reader.dart'
    show
        AiInfo,
        C2paAnalysisResult,
        ContentAction,
        ExifInfo,
        SignerInfo,
        VerificationStatus,
        VerificationStatus_Verified,
        VerificationStatus_SignatureInvalid,
        VerificationStatus_CertificateExpired,
        VerificationStatus_CertificateUntrusted,
        VerificationStatus_NoManifest,
        VerificationStatus_Error;

/// Service for analyzing C2PA content credentials
///
/// This service wraps the Rust c2pa-rs library via flutter_rust_bridge.
class C2paService {
  static C2paService? _instance;
  bool _isInitialized = false;

  C2paService._();

  static C2paService get instance {
    _instance ??= C2paService._();
    return _instance!;
  }

  /// Initialize the C2PA service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;
    debugPrint('C2PA Service initialized (SDK: ${getSdkVersion()})');
  }

  /// Analyze a file at the given path for C2PA metadata
  Future<rust.C2paAnalysisResult> analyzeFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return rust.C2paAnalysisResult(
          status: const rust.VerificationStatus.error(
            message: 'File not found',
          ),
          actions: [],
        );
      }

      final fileSize = await file.length();
      final extension = filePath.split('.').last.toLowerCase();
      debugPrint(
        'C2PA Analysis: File=$filePath, Size=${fileSize}bytes, Ext=$extension',
      );

      final result = rust.analyzeC2PaFromPath(filePath: filePath);

      debugPrint(
        'C2PA Result: status=${result.status}, hasAiInfo=${result.aiInfo != null}, claimGen=${result.claimGenerator}',
      );
      if (result.rawManifestJson != null) {
        debugPrint(
          'C2PA: Manifest found (${result.rawManifestJson!.length} chars)',
        );
      } else {
        debugPrint('C2PA: No manifest in file');
      }

      return result;
    } catch (e) {
      debugPrint('C2PA Error: $e');
      return rust.C2paAnalysisResult(
        status: rust.VerificationStatus.error(message: e.toString()),
        actions: [],
      );
    }
  }

  /// Analyze raw bytes for C2PA metadata
  Future<rust.C2paAnalysisResult> analyzeBytes(
    Uint8List data,
    String mimeType,
  ) async {
    try {
      debugPrint('C2PA Analysis (bytes): Size=${data.length}bytes, MIME=$mimeType');
      
      final result = rust.analyzeC2PaFromBytes(data: data, mimeType: mimeType);
      
      debugPrint('C2PA Result (bytes): status=${result.status}');
      debugPrint('  hasAiInfo=${result.aiInfo != null}, isAI=${result.aiInfo?.isAiGenerated}');
      debugPrint('  claimGen=${result.claimGenerator}');
      debugPrint('  actionsCount=${result.actions.length}');
      debugPrint('  hasSigner=${result.signer != null}');
      debugPrint('  hasExif=${result.exifInfo != null}');
      
      if (result.rawManifestJson != null) {
        debugPrint('C2PA: Manifest found (${result.rawManifestJson!.length} chars)');
        // Log first 500 chars of manifest for debugging
        final preview = result.rawManifestJson!.length > 500 
            ? result.rawManifestJson!.substring(0, 500) 
            : result.rawManifestJson!;
        debugPrint('C2PA Manifest preview: $preview');
      } else {
        debugPrint('C2PA: No manifest in bytes');
      }
      
      if (result.exifInfo != null) {
        final exif = result.exifInfo!;
        debugPrint('EXIF: software=${exif.software}, make=${exif.make}, model=${exif.model}');
        debugPrint('EXIF: aiDetected=${exif.aiDetected}, aiGenerator=${exif.aiGenerator}');
      }
      
      return result;
    } catch (e, stackTrace) {
      debugPrint('C2PA Error (bytes): $e');
      debugPrint('Stack trace: $stackTrace');
      return rust.C2paAnalysisResult(
        status: rust.VerificationStatus.error(message: e.toString()),
        actions: [],
      );
    }
  }

  /// Get the C2PA SDK version
  String getSdkVersion() {
    try {
      return rust.c2PaSdkVersion();
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Check if the native C2PA library is available
  bool isAvailable() {
    try {
      return rust.isC2PaAvailable();
    } catch (e) {
      return false;
    }
  }
}
