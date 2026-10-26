import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:origin_lens/app_info.dart';
import 'package:origin_lens/screens/faq_view.dart';
import 'package:origin_lens/src/rust/api/c2pa_reader.dart';
import 'package:origin_lens/verdict.dart';
import 'package:origin_lens/widgets/verdict_card.dart';

C2paAnalysisResult _result(
  VerificationStatus status, {
  SignerInfo? signer,
  AiInfo? ai,
  ExifInfo? exif,
}) => C2paAnalysisResult(
  status: status,
  signer: signer,
  actions: const [],
  aiInfo: ai,
  exifInfo: exif,
);

const _adobe = SignerInfo(name: 'Adobe Product Services', organization: 'Adobe Inc.');

const _signedAi = AiInfo(
  isAiGenerated: true,
  generatorName: 'Adobe Firefly',
  detectionSource: 'c2pa',
  watermarkDeclared: false,
);

const _exifAi = AiInfo(
  isAiGenerated: true,
  generatorName: 'midjourney',
  detectionSource: 'exif',
  watermarkDeclared: false,
);

ExifInfo _exif({bool screenshot = false, bool ai = false}) => ExifInfo(
  userComment: screenshot ? 'Screenshot' : null,
  aiDetected: ai,
  aiGenerator: ai ? 'midjourney' : null,
  isScreenshot: screenshot,
);

String _normalize(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  group('Verdict mapping', () {
    test('verified with signer is green and names the issuer', () {
      final v = computeVerdict(
        _result(const VerificationStatus.verified(), signer: _adobe),
      );
      expect(v.level, VerdictLevel.green);
      expect(v.title, 'Content Credentials Valid');
      expect(
        v.description,
        'Signed by Adobe Inc. The signature is valid and the image is unchanged since signing. The signer was not checked against a trust list.',
      );
      expect(v.secondary, isEmpty);
    });

    test('verified without signer drops the "Signed by" sentence', () {
      final v = computeVerdict(_result(const VerificationStatus.verified()));
      expect(v.level, VerdictLevel.green);
      expect(
        v.description,
        'The signature is valid and the image is unchanged since signing. The signer was not checked against a trust list.',
      );
    });

    test('verified with a signed AI declaration is purple', () {
      final v = computeVerdict(
        _result(
          const VerificationStatus.verified(),
          signer: _adobe,
          ai: _signedAi,
        ),
      );
      expect(v.level, VerdictLevel.purple);
      expect(v.title, 'AI-Generated (Signed)');
      expect(
        v.description,
        'Signed Content Credentials from Adobe Inc. declare this image as AI-generated.',
      );
    });

    test('purple without a known issuer', () {
      final v = computeVerdict(
        _result(const VerificationStatus.verified(), ai: _signedAi),
      );
      expect(
        v.description,
        'Signed Content Credentials declare this image as AI-generated.',
      );
    });

    test('purple also when manifest and EXIF both name AI', () {
      final v = computeVerdict(
        _result(
          const VerificationStatus.verified(),
          ai: const AiInfo(
            isAiGenerated: true,
            detectionSource: 'both',
            watermarkDeclared: false,
          ),
        ),
      );
      expect(v.level, VerdictLevel.purple);
    });

    test('EXIF-only AI keyword never sets the headline', () {
      final v = computeVerdict(
        _result(
          const VerificationStatus.verified(),
          ai: _exifAi,
          exif: _exif(ai: true),
        ),
      );
      expect(v.level, VerdictLevel.green);
      expect(v.secondary, contains('AI tool named in unsigned metadata'));

      final none = computeVerdict(
        _result(
          const VerificationStatus.noManifest(),
          ai: _exifAi,
          exif: _exif(ai: true),
        ),
      );
      expect(none.level, VerdictLevel.yellow);
      expect(none.title, 'No Content Credentials');
      expect(none.secondary, contains('AI tool named in unsigned metadata'));
    });

    test('invalid signature is red even with an AI declaration', () {
      final v = computeVerdict(
        _result(
          const VerificationStatus.signatureInvalid(),
          signer: _adobe,
          ai: _signedAi,
        ),
      );
      expect(v.level, VerdictLevel.red);
      expect(v.title, 'Credentials Invalid');
      expect(
        v.description,
        'These credentials fail validation. Do not rely on the claims below.',
      );
      expect(v.secondary, contains('Failed credentials name an AI tool'));
      expect(v.credentialsFailed, isTrue);
    });

    test('changed content is red with its own copy', () {
      final v = computeVerdict(
        _result(
          const VerificationStatus.contentChanged(
            codes: ['assertion.dataHash.mismatch'],
          ),
          ai: _signedAi,
        ),
      );
      expect(v.level, VerdictLevel.red);
      expect(v.title, "Credentials Don't Match This Image");
      expect(v.description, 'The image was changed after it was signed.');
      expect(v.secondary, contains('Failed credentials name an AI tool'));
      expect(
        v.secondary.any((l) => l.contains('assertion.dataHash.mismatch')),
        isTrue,
      );
    });

    test('expired certificate is yellow', () {
      final v = computeVerdict(
        _result(const VerificationStatus.certificateExpired(), ai: _signedAi),
      );
      expect(v.level, VerdictLevel.yellow);
      expect(v.title, 'Certificate Expired');
      expect(
        v.description,
        'The signing certificate has expired, so the signature could not be checked.',
      );
      expect(v.secondary, contains('Failed credentials name an AI tool'));
    });

    test('untrusted certificate is yellow', () {
      final v = computeVerdict(
        _result(const VerificationStatus.certificateUntrusted()),
      );
      expect(v.level, VerdictLevel.yellow);
      expect(v.title, 'Signer Not Verified');
      expect(v.description, 'The signing certificate could not be validated.');
    });

    test('no credentials, local and from URL', () {
      final local = computeVerdict(_result(const VerificationStatus.noManifest()));
      expect(local.level, VerdictLevel.yellow);
      expect(local.title, 'No Content Credentials');
      expect(
        local.description,
        'Most images carry none. This alone is not a sign of manipulation.',
      );
      final web = computeVerdict(
        _result(const VerificationStatus.noManifest()),
        fromUrl: true,
      );
      expect(
        web.description,
        'Most images carry none. This alone is not a sign of manipulation. The website may have removed them.',
      );
    });

    test('screenshot only without a manifest', () {
      final shot = computeVerdict(
        _result(
          const VerificationStatus.noManifest(),
          exif: _exif(screenshot: true),
        ),
      );
      expect(shot.level, VerdictLevel.yellow);
      expect(shot.title, 'Screenshot');
      expect(
        shot.description,
        "This is a screenshot. A screenshot is a new image and never carries the original's Content Credentials, so where it came from cannot be checked here. Look for the original file.",
      );

      final signed = computeVerdict(
        _result(
          const VerificationStatus.verified(),
          exif: _exif(screenshot: true),
        ),
      );
      expect(signed.level, VerdictLevel.green);
    });

    test('credentials held elsewhere keep their text', () {
      final v = computeVerdict(
        _result(
          const VerificationStatus.remoteManifestPending(
            url: 'https://cai-manifests.adobe.com/manifests/x',
          ),
        ),
      );
      expect(v.level, VerdictLevel.yellow);
      expect(v.title, 'Credentials Held Elsewhere');
      expect(
        v.description,
        'This image points to credentials stored at cai-manifests.adobe.com, which have not been fetched',
      );
    });

    test('connection issue keeps its text', () {
      final v = computeVerdict(
        _result(
          const VerificationStatus.error(
            message: 'Could not reach the manifest host: timeout',
          ),
        ),
      );
      expect(v.level, VerdictLevel.yellow);
      expect(v.title, 'Connection Issue');
      expect(v.description, 'Could not retrieve remote credentials');
    });

    test('parse and analysis issues use plain sentences, codes go below', () {
      final parse = computeVerdict(
        _result(
          const VerificationStatus.error(
            message:
                'This image contains C2PA data that could not be parsed. It may be corrupted or use an unsupported format.',
          ),
        ),
      );
      expect(parse.level, VerdictLevel.yellow);
      expect(parse.title, 'Parsing Issue');
      expect(parse.description, isNot(contains('C2PA data that')));

      final other = computeVerdict(
        _result(const VerificationStatus.error(message: 'ProhibitedAction xyz')),
      );
      expect(other.title, 'Analysis Issue');
      expect(other.description, 'Origin Lens could not analyze this image.');
      expect(other.secondary.single, contains('ProhibitedAction xyz'));
    });

    test('no verdict claims authenticity or trust', () {
      final statuses = <VerificationStatus>[
        const VerificationStatus.verified(),
        const VerificationStatus.signatureInvalid(),
        const VerificationStatus.certificateExpired(),
        const VerificationStatus.certificateUntrusted(),
        const VerificationStatus.contentChanged(codes: ['x']),
        const VerificationStatus.noManifest(),
        const VerificationStatus.remoteManifestPending(url: 'https://a.b/c'),
        const VerificationStatus.error(message: ''),
      ];
      for (final s in statuses) {
        for (final ai in [null, _signedAi]) {
          final v = computeVerdict(_result(s, signer: _adobe, ai: ai));
          final text = '${v.title} ${v.description}';
          expect(text, isNot(contains('Verified Authentic')));
          expect(text, isNot(contains(' trusted')));
        }
      }
    });

    test('semantics label', () {
      final v = computeVerdict(_result(const VerificationStatus.noManifest()));
      expect(
        v.semanticsLabel,
        'Verdict: No Content Credentials. Most images carry none. This alone is not a sign of manipulation.',
      );
    });
  });

  group('AI opinion', () {
    test('three outcomes', () {
      expect(
        aiOpinionOutcome(success: true, hasSynthId: true),
        AiOpinionOutcome.watermarkReported,
      );
      expect(
        aiOpinionOutcome(success: true, hasSynthId: false),
        AiOpinionOutcome.noneReported,
      );
      expect(
        aiOpinionOutcome(success: false, hasSynthId: false),
        AiOpinionOutcome.noAnswer,
      );
      expect(kAiOpinionTitle, 'AI Opinion (Gemini, experimental)');
    });
  });

  group('Contrast', () {
    test('every band color pair reaches 4.5:1', () {
      for (final level in VerdictLevel.values) {
        final ratio = contrastRatio(level.bandColor, level.onBandColor);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$level: ${ratio.toStringAsFixed(2)}:1',
        );
      }
    });

    test('contrast formula matches known values', () {
      expect(
        contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01),
      );
      expect(
        contrastRatio(const Color(0xFF777777), const Color(0xFFFFFFFF)),
        closeTo(4.48, 0.01),
      );
    });
  });

  group('Citation', () {
    test('cite text matches CITATION.cff', () {
      final cff = _normalize(File('../CITATION.cff').readAsStringSync());
      final text = _normalize(kCiteOriginLensText);

      const doi = '10.1145/3795513.3806658';
      expect(cff, contains('doi: "$doi"'));
      expect(text, contains('https://doi.org/$doi'));

      const webSciTitle =
          'Origin Lens: Reclaiming Trust on the AI-Mediated Web Through On-Device Image Provenance Verification';
      const arxivTitle =
          'Origin Lens: A Privacy-First Mobile Framework for Cryptographic Image Provenance and AI Detection';
      for (final title in [webSciTitle, arxivTitle]) {
        expect(cff, contains(title), reason: 'CITATION.cff lacks "$title"');
        expect(text, contains(title), reason: 'cite text lacks "$title"');
      }
      expect(cff, contains('arXiv:2602.03423'));
      expect(text, contains('arXiv:2602.03423'));
      expect(kCiteOriginLensText.split('\n\n'), hasLength(2));
    });

    test('version fallback matches pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final version = RegExp(
        r'^version:\s*([0-9.]+)\+',
        multiLine: true,
      ).firstMatch(pubspec)!.group(1);
      expect(kAppVersion, version);
    });
  });

  group('Widgets', () {
    testWidgets('verdict card exposes one semantics label', (tester) async {
      final v = computeVerdict(_result(const VerificationStatus.signatureInvalid()));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: VerdictCard(verdict: v))),
      );
      expect(
        find.bySemanticsLabel(
          'Verdict: Credentials Invalid. These credentials fail validation. Do not rely on the claims below.',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('FAQ view renders and the cite row copies both papers', (
      tester,
    ) async {
      PackageInfo.setMockInitialValues(
        appName: 'Origin Lens',
        packageName: 'origin_lens',
        version: '1.4.1',
        buildNumber: '9',
        buildSignature: '',
      );
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );

      await tester.pumpWidget(const MaterialApp(home: FaqView()));
      await tester.pumpAndSettle();

      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('What is Origin Lens?'), findsOneWidget);

      final cite = find.text('Cite Origin Lens');
      await tester.ensureVisible(cite);
      await tester.pumpAndSettle();
      expect(find.text('Copy references to both papers'), findsOneWidget);
      await tester.tap(cite);
      await tester.pump();
      expect(copied, kCiteOriginLensText);
      expect(find.text('References copied'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  });
}
